using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinSync.Base;
using SkinSync.Helpers;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.Auth;
using SkinSync.Models.Entities;
using SkinSync.Models.Enums;
using SkinSync.Repositories;
using SkinSync.Services;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/auth")]
[Authorize]
public class AuthController : ControllerBase
{
    private readonly IUserRepository _userRepository;
    private readonly IJwtAuthService _jwtAuthService;
    private readonly ISupabaseAuthService _supabaseAuthService;
    private readonly IWebHostEnvironment _environment;

    public AuthController(IUserRepository userRepository, IJwtAuthService jwtAuthService, ISupabaseAuthService supabaseAuthService, IWebHostEnvironment environment)
    {
        _userRepository = userRepository;
        _jwtAuthService = jwtAuthService;
        _supabaseAuthService = supabaseAuthService;
        _environment = environment;
    }

    [AllowAnonymous]
    [HttpPost("register")]
    public async Task<ResponseEntity<AuthUserResponseDto>> Register([FromBody] RegisterRequestDto request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim().ToLowerInvariant();

        var supabaseResult = await _supabaseAuthService.SignUpWithEmailPasswordAsync(
            email,
            request.Password,
            request.FullName.Trim(),
            request.Phone.Trim(),
            cancellationToken);

        if (!supabaseResult.IsSuccess)
        {
            return ResponseEntity<AuthUserResponseDto>.Fail(supabaseResult.ErrorMessage ?? "ÄÄƒng kÃ½ khÃ´ng thÃ nh cÃ´ng.", supabaseResult.StatusCode);
        }

        var user = await _userRepository.GetByEmailAsync(email, cancellationToken);
        if (user is null)
        {
            user = new User
            {
                Id = Guid.NewGuid(),
                FullName = request.FullName.Trim(),
                Email = email,
                Phone = request.Phone.Trim(),
                PasswordHash = string.Empty,
                Role = "user",
                Status = UserStatus.Active.ToDbValue(),
                CreatedAt = DateTime.UtcNow
            };

            await _userRepository.AddAsync(user, cancellationToken);
        }

        return ResponseEntity<AuthUserResponseDto>.Ok(user.ToAuthUserDto(), "ÄÄƒng kÃ½ thÃ nh cÃ´ng.");
    }

    [AllowAnonymous]
    [HttpPost("login")]
    public async Task<ResponseEntity<LoginResponseDto>> Login([FromBody] LoginRequestDto request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var supabaseResult = await _supabaseAuthService.SignInWithEmailPasswordAsync(email, request.Password, cancellationToken);
        if (!supabaseResult.IsSuccess || supabaseResult.User is null)
        {
            var statusCode = supabaseResult.IsSuccess ? 401 : supabaseResult.StatusCode;
            return ResponseEntity<LoginResponseDto>.Fail(supabaseResult.ErrorMessage ?? "Email hoáº·c máº­t kháº©u khÃ´ng chÃ­nh xÃ¡c.", statusCode);
        }

        var user = await EnsureLocalUserFromSupabaseAsync(supabaseResult.User, cancellationToken);
        if (!TryEnsureLoginAllowed(user.Status, out var blockedMessage))
        {
            return ResponseEntity<LoginResponseDto>.Fail(blockedMessage, 403);
        }

        var tokenPair = _jwtAuthService.GenerateTokenPair(user.Id, user.Role);
        return ResponseEntity<LoginResponseDto>.Ok(new LoginResponseDto
        {
            AccessToken = tokenPair.AccessToken,
            RefreshToken = tokenPair.RefreshToken,
            AccessTokenExpiresAtUtc = tokenPair.AccessTokenExpiresAtUtc,
            RefreshTokenExpiresAtUtc = tokenPair.RefreshTokenExpiresAtUtc,
            User = user.ToAuthUserDto()
        }, "ÄÄƒng nháº­p thÃ nh cÃ´ng.");
    }

    [AllowAnonymous]
    [HttpGet("google/url")]
    public ResponseEntity<GoogleOAuthUrlResponseDto> GetGoogleLoginUrl([FromQuery] string redirectTo, [FromQuery] string? state = null)
    {
        if (string.IsNullOrWhiteSpace(redirectTo))
        {
            return ResponseEntity<GoogleOAuthUrlResponseDto>.Fail("Thiáº¿u tham sá»‘ redirectTo.", 400);
        }

        var url = _supabaseAuthService.BuildGoogleOAuthUrl(redirectTo, state);
        if (string.IsNullOrWhiteSpace(url))
        {
            return ResponseEntity<GoogleOAuthUrlResponseDto>.Fail("Há»‡ thá»‘ng chÆ°a cáº¥u hÃ¬nh Supabase.", 500);
        }

        return ResponseEntity<GoogleOAuthUrlResponseDto>.Ok(new GoogleOAuthUrlResponseDto
        {
            Url = url
        }, "Táº¡o URL Ä‘Äƒng nháº­p Google thÃ nh cÃ´ng.");
    }

    [AllowAnonymous]
    [HttpPost("login/google")]
    public async Task<ResponseEntity<LoginResponseDto>> LoginWithGoogle([FromBody] GoogleLoginRequestDto request, CancellationToken cancellationToken)
    {
        var supabaseUser = await _supabaseAuthService.GetUserByAccessTokenAsync(request.SupabaseAccessToken, cancellationToken);
        if (supabaseUser is null)
        {
            return ResponseEntity<LoginResponseDto>.Fail("MÃ£ xÃ¡c thá»±c Google khÃ´ng há»£p lá»‡.", 401);
        }

        var user = await EnsureLocalUserFromSupabaseAsync(supabaseUser, cancellationToken);
        if (!TryEnsureLoginAllowed(user.Status, out var blockedMessage))
        {
            return ResponseEntity<LoginResponseDto>.Fail(blockedMessage, 403);
        }

        var tokenPair = _jwtAuthService.GenerateTokenPair(user.Id, user.Role);

        return ResponseEntity<LoginResponseDto>.Ok(new LoginResponseDto
        {
            AccessToken = tokenPair.AccessToken,
            RefreshToken = tokenPair.RefreshToken,
            AccessTokenExpiresAtUtc = tokenPair.AccessTokenExpiresAtUtc,
            RefreshTokenExpiresAtUtc = tokenPair.RefreshTokenExpiresAtUtc,
            User = user.ToAuthUserDto()
        }, "ÄÄƒng nháº­p Google thÃ nh cÃ´ng.");
    }

    [AllowAnonymous]
    [HttpPost("refresh")]
    public async Task<ResponseEntity<LoginResponseDto>> Refresh([FromBody] RefreshTokenRequestDto request, CancellationToken cancellationToken)
    {
        if (!_jwtAuthService.TryValidateRefreshToken(request.RefreshToken, out var userId, out var role))
        {
            return ResponseEntity<LoginResponseDto>.Fail("Refresh token khÃ´ng há»£p lá»‡ hoáº·c Ä‘Ã£ háº¿t háº¡n.", 401);
        }

        var user = await _userRepository.GetByIdAsync(userId, cancellationToken);
        if (user is null)
        {
            return ResponseEntity<LoginResponseDto>.Fail("KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng.", 404);
        }

        if (!TryEnsureLoginAllowed(user.Status, out var blockedMessage))
        {
            return ResponseEntity<LoginResponseDto>.Fail(blockedMessage, 403);
        }

        var resolvedRole = string.IsNullOrWhiteSpace(role) ? user.Role : role;
        var tokenPair = _jwtAuthService.GenerateTokenPair(user.Id, resolvedRole);

        return ResponseEntity<LoginResponseDto>.Ok(new LoginResponseDto
        {
            AccessToken = tokenPair.AccessToken,
            RefreshToken = tokenPair.RefreshToken,
            AccessTokenExpiresAtUtc = tokenPair.AccessTokenExpiresAtUtc,
            RefreshTokenExpiresAtUtc = tokenPair.RefreshTokenExpiresAtUtc,
            User = user.ToAuthUserDto()
        }, "LÃ m má»›i phiÃªn báº£n Ä‘Äƒng nháº­p thÃ nh cÃ´ng.");
    }

    [HttpGet("me")]
    public async Task<ResponseEntity<AuthUserResponseDto>> Me(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Thiáº¿u thÃ´ng tin Ä‘á»‹nh danh ngÆ°á»i dÃ¹ng.");
        }

        var user = await _userRepository.GetByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng.", 404);
        }

        return ResponseEntity<AuthUserResponseDto>.Ok(user.ToAuthUserDto(), "Láº¥y thÃ´ng tin há»“ sÆ¡ thÃ nh cÃ´ng.");
    }

    [HttpPost("logout")]
    public ResponseEntity<object> Logout()
    {
        // JWTs check exp on client-side and refresh tokens are not fully synced on server blocklist in this simplified flow.
        return ResponseEntity<object>.Ok(null, "ÄÄƒng xuáº¥t thÃ nh cÃ´ng.");
    }

    [AllowAnonymous]
    [HttpPost("forgot-password")]
    public async Task<ResponseEntity<object>> ForgotPassword([FromBody] ForgotPasswordRequestDto request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var user = await _userRepository.GetByEmailAsync(email, cancellationToken);
        if (user is null)
        {
            // For security, do not expose whether an email exists or not
            return ResponseEntity<object>.Ok(null, "Náº¿u email há»£p lá»‡, há»‡ thá»‘ng sáº½ gá»­i liÃªn káº¿t khÃ´i phá»¥c máº­t kháº©u.");
        }

        var result = await _supabaseAuthService.SendResetPasswordEmailAsync(email, request.RedirectTo, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.StatusCode == 429)
            {
                // Keep a generic response to avoid exposing delivery throttling details.
                return ResponseEntity<object>.Ok(null, "Náº¿u email há»£p lá»‡, há»‡ thá»‘ng sáº½ gá»­i liÃªn káº¿t khÃ´i phá»¥c máº­t kháº©u.");
            }

            return ResponseEntity<object>.Fail(result.ErrorMessage ?? "KhÃ´ng thá»ƒ gá»­i email khÃ´i phá»¥c.", result.StatusCode);
        }

        return ResponseEntity<object>.Ok(null, "Náº¿u email há»£p lá»‡, há»‡ thá»‘ng sáº½ gá»­i liÃªn káº¿t khÃ´i phá»¥c máº­t kháº©u.");
    }

    [AllowAnonymous]
    [HttpPost("reset-password")]
    public async Task<ResponseEntity<object>> ResetPassword([FromBody] ResetPasswordRequestDto request, CancellationToken cancellationToken)
    {
        // Supabase expects the AccessToken mapped from the URL fragment inside the email link
        var result = await _supabaseAuthService.UpdateUserPasswordAsync(request.AccessToken, request.NewPassword, cancellationToken);
        
        if (!result.IsSuccess)
        {
            return ResponseEntity<object>.Fail(result.ErrorMessage ?? "Äáº·t láº¡i máº­t kháº©u khÃ´ng thÃ nh cÃ´ng.", result.StatusCode);
        }

        return ResponseEntity<object>.Ok(null, "Äáº·t láº¡i máº­t kháº©u thÃ nh cÃ´ng.");
    }

    [HttpPost("change-password")]
    public async Task<ResponseEntity<object>> ChangePassword([FromBody] ChangePasswordRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<object>.Fail("Thiáº¿u thÃ´ng tin Ä‘á»‹nh danh ngÆ°á»i dÃ¹ng.", 401);
        }

        var user = await _userRepository.GetByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return ResponseEntity<object>.Fail("KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng.", 404);
        }

        // To change password, we need Supabase access token. Let's get a fresh one by verifying the old password.
        var signInResult = await _supabaseAuthService.SignInWithEmailPasswordAsync(user.Email, request.OldPassword, cancellationToken);
        if (!signInResult.IsSuccess || string.IsNullOrWhiteSpace(signInResult.AccessToken))
        {
            return ResponseEntity<object>.Fail("Máº­t kháº©u hiá»‡n táº¡i khÃ´ng chÃ­nh xÃ¡c. Vui lÃ²ng dÃ¹ng chá»©c nÄƒng QuÃªn máº­t kháº©u Ä‘á»ƒ táº¡o máº­t kháº©u má»›i.", 401);
        }

        // Use the token to update password
        var updateResult = await _supabaseAuthService.UpdateUserPasswordAsync(signInResult.AccessToken, request.NewPassword, cancellationToken);
        if (!updateResult.IsSuccess)
        {
            return ResponseEntity<object>.Fail(updateResult.ErrorMessage ?? "Äá»•i máº­t kháº©u khÃ´ng thÃ nh cÃ´ng.", updateResult.StatusCode);
        }

        return ResponseEntity<object>.Ok(null, "Äá»•i máº­t kháº©u thÃ nh cÃ´ng.");
    }

    [HttpPut("profile")]
    public async Task<ResponseEntity<AuthUserResponseDto>> UpdateProfile([FromBody] UpdateProfileRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Thiáº¿u thÃ´ng tin Ä‘á»‹nh danh ngÆ°á»i dÃ¹ng.", 401);
        }

        var user = await _userRepository.GetByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng.", 404);
        }

        user.FullName = request.FullName.Trim();
        user.Phone = request.Phone?.Trim() ?? string.Empty;

        await _userRepository.UpdateAsync(user, cancellationToken);

        return ResponseEntity<AuthUserResponseDto>.Ok(user.ToAuthUserDto(), "Cáº­p nháº­t há»“ sÆ¡ thÃ nh cÃ´ng.");
    }

    [HttpPut("avatar")]
    public async Task<ResponseEntity<AuthUserResponseDto>> UpdateAvatar([FromForm] UpdateAvatarRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Thiáº¿u thÃ´ng tin Ä‘á»‹nh danh ngÆ°á»i dÃ¹ng.", 401);
        }

        var user = await _userRepository.GetByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("KhÃ´ng tÃ¬m tháº¥y ngÆ°á»i dÃ¹ng.", 404);
        }

        if (request.Avatar is null || request.Avatar.Length == 0)
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Vui lÃ²ng chá»n áº£nh Ä‘áº¡i diá»‡n.", 400);
        }

        const long maxSize = 5 * 1024 * 1024;
        if (request.Avatar.Length > maxSize)
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("KÃ­ch thÆ°á»›c áº£nh vÆ°á»£t quÃ¡ 5MB.", 400);
        }

        if (!request.Avatar.ContentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Äá»‹nh dáº¡ng file khÃ´ng há»£p lá»‡.", 400);
        }

        var extension = Path.GetExtension(request.Avatar.FileName);
        if (string.IsNullOrWhiteSpace(extension))
        {
            extension = ".jpg";
        }

        var uploadRoot = Path.Combine(_environment.WebRootPath, "uploads", "avatars");
        Directory.CreateDirectory(uploadRoot);

        var fileName = $"{user.Id}_{Guid.NewGuid():N}{extension}";
        var savePath = Path.Combine(uploadRoot, fileName);

        await using (var stream = System.IO.File.Create(savePath))
        {
            await request.Avatar.CopyToAsync(stream, cancellationToken);
        }

        var avatarUrl = $"/uploads/avatars/{fileName}";
        user.AvatarUrl = avatarUrl;

        await _userRepository.UpdateAsync(user, cancellationToken);

        return ResponseEntity<AuthUserResponseDto>.Ok(user.ToAuthUserDto(), "Cáº­p nháº­t áº£nh Ä‘áº¡i diá»‡n thÃ nh cÃ´ng.");
    }

    private async Task<User> EnsureLocalUserFromSupabaseAsync(SupabaseUserProfile supabaseUser, CancellationToken cancellationToken)
    {
        var email = supabaseUser.Email.Trim().ToLowerInvariant();
        var user = await _userRepository.GetByEmailAsync(email, cancellationToken);
        var metadataAvatarUrl = TryGetMetadataValue(supabaseUser.UserMetadata, "avatar_url")
            ?? TryGetMetadataValue(supabaseUser.UserMetadata, "picture");

        if (user is not null)
        {
            if (string.IsNullOrWhiteSpace(user.AvatarUrl) && !string.IsNullOrWhiteSpace(metadataAvatarUrl))
            {
                user.AvatarUrl = metadataAvatarUrl;
                await _userRepository.UpdateAsync(user, cancellationToken);
            }

            return user;
        }

        var fullName = TryGetMetadataValue(supabaseUser.UserMetadata, "full_name")
            ?? TryGetMetadataValue(supabaseUser.UserMetadata, "name")
            ?? email;

        var phone = TryGetMetadataValue(supabaseUser.UserMetadata, "phone") ?? string.Empty;
        var avatarUrl = metadataAvatarUrl;

        user = new User
        {
            Id = Guid.NewGuid(),
            FullName = fullName,
            Email = email,
            Phone = phone,
            AvatarUrl = avatarUrl,
            PasswordHash = string.Empty,
            Role = "user",
            Status = UserStatus.Active.ToDbValue(),
            CreatedAt = DateTime.UtcNow
        };

        await _userRepository.AddAsync(user, cancellationToken);
        return user;
    }

    private static string? TryGetMetadataValue(IReadOnlyDictionary<string, System.Text.Json.JsonElement>? metadata, string key)
    {
        if (metadata is null || !metadata.TryGetValue(key, out var element))
        {
            return null;
        }

        return element.ValueKind == System.Text.Json.JsonValueKind.String
            ? element.GetString()
            : null;
    }

    private static bool TryEnsureLoginAllowed(string statusValue, out string message)
    {
        var status = UserStatusExtensions.FromDbValue(statusValue);

        if (status == UserStatus.Banned)
        {
            message = "TÃ i khoáº£n cá»§a báº¡n Ä‘Ã£ bá»‹ cáº¥m. Vui lÃ²ng liÃªn há»‡ quáº£n trá»‹ viÃªn.";
            return false;
        }

        if (status == UserStatus.Inactive)
        {
            message = "TÃ i khoáº£n cá»§a báº¡n chÆ°a Ä‘Æ°á»£c kÃ­ch hoáº¡t. Vui lÃ²ng xÃ¡c thá»±c email hoáº·c liÃªn há»‡ quáº£n trá»‹ viÃªn.";
            return false;
        }

        message = string.Empty;
        return true;
    }
}
