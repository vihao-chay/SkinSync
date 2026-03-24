using Microsoft.AspNetCore.Mvc;
using SkinAsync.Base;
using SkinAsync.Helpers;
using SkinAsync.Mappers;
using SkinAsync.Models.Dtos.Auth;
using SkinAsync.Models.Entities;
using SkinAsync.Repositories;
using SkinAsync.Services;

namespace SkinAsync.Controllers;

[ApiController]
[Route("api/auth")]
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
            return ResponseEntity<AuthUserResponseDto>.Fail(supabaseResult.ErrorMessage ?? "Đăng ký không thành công.", supabaseResult.StatusCode);
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
                Status = "active",
                CreatedAt = DateTime.UtcNow
            };

            await _userRepository.AddAsync(user, cancellationToken);
        }

        return ResponseEntity<AuthUserResponseDto>.Ok(user.ToAuthUserDto(), "Đăng ký thành công.");
    }

    [HttpPost("login")]
    public async Task<ResponseEntity<LoginResponseDto>> Login([FromBody] LoginRequestDto request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var supabaseResult = await _supabaseAuthService.SignInWithEmailPasswordAsync(email, request.Password, cancellationToken);
        if (!supabaseResult.IsSuccess || supabaseResult.User is null)
        {
            var statusCode = supabaseResult.IsSuccess ? 401 : supabaseResult.StatusCode;
            return ResponseEntity<LoginResponseDto>.Fail(supabaseResult.ErrorMessage ?? "Email hoặc mật khẩu không chính xác.", statusCode);
        }

        var user = await EnsureLocalUserFromSupabaseAsync(supabaseResult.User, cancellationToken);

        var tokenPair = _jwtAuthService.GenerateTokenPair(user.Id, user.Role);
        return ResponseEntity<LoginResponseDto>.Ok(new LoginResponseDto
        {
            AccessToken = tokenPair.AccessToken,
            RefreshToken = tokenPair.RefreshToken,
            AccessTokenExpiresAtUtc = tokenPair.AccessTokenExpiresAtUtc,
            RefreshTokenExpiresAtUtc = tokenPair.RefreshTokenExpiresAtUtc,
            User = user.ToAuthUserDto()
        }, "Đăng nhập thành công.");
    }

    [HttpGet("google/url")]
    public ResponseEntity<GoogleOAuthUrlResponseDto> GetGoogleLoginUrl([FromQuery] string redirectTo, [FromQuery] string? state = null)
    {
        if (string.IsNullOrWhiteSpace(redirectTo))
        {
            return ResponseEntity<GoogleOAuthUrlResponseDto>.Fail("Thiếu tham số redirectTo.", 400);
        }

        var url = _supabaseAuthService.BuildGoogleOAuthUrl(redirectTo, state);
        if (string.IsNullOrWhiteSpace(url))
        {
            return ResponseEntity<GoogleOAuthUrlResponseDto>.Fail("Hệ thống chưa cấu hình Supabase.", 500);
        }

        return ResponseEntity<GoogleOAuthUrlResponseDto>.Ok(new GoogleOAuthUrlResponseDto
        {
            Url = url
        }, "Tạo URL đăng nhập Google thành công.");
    }

    [HttpPost("login/google")]
    public async Task<ResponseEntity<LoginResponseDto>> LoginWithGoogle([FromBody] GoogleLoginRequestDto request, CancellationToken cancellationToken)
    {
        var supabaseUser = await _supabaseAuthService.GetUserByAccessTokenAsync(request.SupabaseAccessToken, cancellationToken);
        if (supabaseUser is null)
        {
            return ResponseEntity<LoginResponseDto>.Fail("Mã xác thực Google không hợp lệ.", 401);
        }

        var user = await EnsureLocalUserFromSupabaseAsync(supabaseUser, cancellationToken);
        var tokenPair = _jwtAuthService.GenerateTokenPair(user.Id, user.Role);

        return ResponseEntity<LoginResponseDto>.Ok(new LoginResponseDto
        {
            AccessToken = tokenPair.AccessToken,
            RefreshToken = tokenPair.RefreshToken,
            AccessTokenExpiresAtUtc = tokenPair.AccessTokenExpiresAtUtc,
            RefreshTokenExpiresAtUtc = tokenPair.RefreshTokenExpiresAtUtc,
            User = user.ToAuthUserDto()
        }, "Đăng nhập Google thành công.");
    }

    [HttpPost("refresh")]
    public async Task<ResponseEntity<LoginResponseDto>> Refresh([FromBody] RefreshTokenRequestDto request, CancellationToken cancellationToken)
    {
        if (!_jwtAuthService.TryValidateRefreshToken(request.RefreshToken, out var userId, out var role))
        {
            return ResponseEntity<LoginResponseDto>.Fail("Refresh token không hợp lệ hoặc đã hết hạn.", 401);
        }

        var user = await _userRepository.GetByIdAsync(userId, cancellationToken);
        if (user is null)
        {
            return ResponseEntity<LoginResponseDto>.Fail("Không tìm thấy người dùng.", 404);
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
        }, "Làm mới phiên bản đăng nhập thành công.");
    }

    [HttpGet("me")]
    public async Task<ResponseEntity<AuthUserResponseDto>> Me(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Thiếu thông tin định danh người dùng.");
        }

        var user = await _userRepository.GetByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Không tìm thấy người dùng.", 404);
        }

        return ResponseEntity<AuthUserResponseDto>.Ok(user.ToAuthUserDto(), "Lấy thông tin hồ sơ thành công.");
    }

    [HttpPost("logout")]
    public ResponseEntity<object> Logout()
    {
        // JWTs check exp on client-side and refresh tokens are not fully synced on server blocklist in this simplified flow.
        return ResponseEntity<object>.Ok(null, "Đăng xuất thành công.");
    }

    [HttpPost("forgot-password")]
    public async Task<ResponseEntity<object>> ForgotPassword([FromBody] ForgotPasswordRequestDto request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var user = await _userRepository.GetByEmailAsync(email, cancellationToken);
        if (user is null)
        {
            // For security, do not expose whether an email exists or not
            return ResponseEntity<object>.Ok(null, "Nếu email hợp lệ, hệ thống sẽ gửi liên kết khôi phục mật khẩu.");
        }

        var result = await _supabaseAuthService.SendResetPasswordEmailAsync(email, request.RedirectTo, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.StatusCode == 429)
            {
                // Keep a generic response to avoid exposing delivery throttling details.
                return ResponseEntity<object>.Ok(null, "Nếu email hợp lệ, hệ thống sẽ gửi liên kết khôi phục mật khẩu.");
            }

            return ResponseEntity<object>.Fail(result.ErrorMessage ?? "Không thể gửi email khôi phục.", result.StatusCode);
        }

        return ResponseEntity<object>.Ok(null, "Nếu email hợp lệ, hệ thống sẽ gửi liên kết khôi phục mật khẩu.");
    }

    [HttpPost("reset-password")]
    public async Task<ResponseEntity<object>> ResetPassword([FromBody] ResetPasswordRequestDto request, CancellationToken cancellationToken)
    {
        // Supabase expects the AccessToken mapped from the URL fragment inside the email link
        var result = await _supabaseAuthService.UpdateUserPasswordAsync(request.AccessToken, request.NewPassword, cancellationToken);
        
        if (!result.IsSuccess)
        {
            return ResponseEntity<object>.Fail(result.ErrorMessage ?? "Đặt lại mật khẩu không thành công.", result.StatusCode);
        }

        return ResponseEntity<object>.Ok(null, "Đặt lại mật khẩu thành công.");
    }

    [HttpPost("change-password")]
    public async Task<ResponseEntity<object>> ChangePassword([FromBody] ChangePasswordRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<object>.Fail("Thiếu thông tin định danh người dùng.", 401);
        }

        var user = await _userRepository.GetByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return ResponseEntity<object>.Fail("Không tìm thấy người dùng.", 404);
        }

        // To change password, we need Supabase access token. Let's get a fresh one by verifying the old password.
        var signInResult = await _supabaseAuthService.SignInWithEmailPasswordAsync(user.Email, request.OldPassword, cancellationToken);
        if (!signInResult.IsSuccess || string.IsNullOrWhiteSpace(signInResult.AccessToken))
        {
            return ResponseEntity<object>.Fail("Mật khẩu hiện tại không chính xác hoặc tài khoản đăng nhập Google chưa có mật khẩu. Vui lòng dùng chức năng Quên mật khẩu để tạo mật khẩu mới.", 401);
        }

        // Use the token to update password
        var updateResult = await _supabaseAuthService.UpdateUserPasswordAsync(signInResult.AccessToken, request.NewPassword, cancellationToken);
        if (!updateResult.IsSuccess)
        {
            return ResponseEntity<object>.Fail(updateResult.ErrorMessage ?? "Đổi mật khẩu không thành công.", updateResult.StatusCode);
        }

        return ResponseEntity<object>.Ok(null, "Đổi mật khẩu thành công.");
    }

    [HttpPut("profile")]
    public async Task<ResponseEntity<AuthUserResponseDto>> UpdateProfile([FromBody] UpdateProfileRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Thiếu thông tin định danh người dùng.", 401);
        }

        var user = await _userRepository.GetByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Không tìm thấy người dùng.", 404);
        }

        user.FullName = request.FullName.Trim();
        user.Phone = request.Phone?.Trim() ?? string.Empty;

        await _userRepository.UpdateAsync(user, cancellationToken);

        return ResponseEntity<AuthUserResponseDto>.Ok(user.ToAuthUserDto(), "Cập nhật hồ sơ thành công.");
    }

    [HttpPut("avatar")]
    public async Task<ResponseEntity<AuthUserResponseDto>> UpdateAvatar([FromForm] UpdateAvatarRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Thiếu thông tin định danh người dùng.", 401);
        }

        var user = await _userRepository.GetByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Không tìm thấy người dùng.", 404);
        }

        if (request.Avatar is null || request.Avatar.Length == 0)
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Vui lòng chọn ảnh đại diện.", 400);
        }

        const long maxSize = 5 * 1024 * 1024;
        if (request.Avatar.Length > maxSize)
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Kích thước ảnh vượt quá 5MB.", 400);
        }

        if (!request.Avatar.ContentType.StartsWith("image/", StringComparison.OrdinalIgnoreCase))
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Định dạng file không hợp lệ.", 400);
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

        return ResponseEntity<AuthUserResponseDto>.Ok(user.ToAuthUserDto(), "Cập nhật ảnh đại diện thành công.");
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
            Status = "active",
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
}
