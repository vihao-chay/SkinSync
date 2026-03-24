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

    public AuthController(IUserRepository userRepository, IJwtAuthService jwtAuthService, ISupabaseAuthService supabaseAuthService)
    {
        _userRepository = userRepository;
        _jwtAuthService = jwtAuthService;
        _supabaseAuthService = supabaseAuthService;
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
            return ResponseEntity<AuthUserResponseDto>.Fail(supabaseResult.ErrorMessage ?? "Supabase register failed.", supabaseResult.StatusCode);
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

        return ResponseEntity<AuthUserResponseDto>.Ok(user.ToAuthUserDto(), "Register successful.");
    }

    [HttpPost("login")]
    public async Task<ResponseEntity<LoginResponseDto>> Login([FromBody] LoginRequestDto request, CancellationToken cancellationToken)
    {
        var email = request.Email.Trim().ToLowerInvariant();
        var supabaseResult = await _supabaseAuthService.SignInWithEmailPasswordAsync(email, request.Password, cancellationToken);
        if (!supabaseResult.IsSuccess || supabaseResult.User is null)
        {
            var statusCode = supabaseResult.IsSuccess ? 401 : supabaseResult.StatusCode;
            return ResponseEntity<LoginResponseDto>.Fail(supabaseResult.ErrorMessage ?? "Invalid email or password.", statusCode);
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
        }, "Login successful.");
    }

    [HttpGet("google/url")]
    public ResponseEntity<GoogleOAuthUrlResponseDto> GetGoogleLoginUrl([FromQuery] string redirectTo, [FromQuery] string? state = null)
    {
        if (string.IsNullOrWhiteSpace(redirectTo))
        {
            return ResponseEntity<GoogleOAuthUrlResponseDto>.Fail("Missing redirectTo query parameter.", 400);
        }

        var url = _supabaseAuthService.BuildGoogleOAuthUrl(redirectTo, state);
        if (string.IsNullOrWhiteSpace(url))
        {
            return ResponseEntity<GoogleOAuthUrlResponseDto>.Fail("Supabase is not configured. Please set Supabase:Url and Supabase:AnonKey.", 500);
        }

        return ResponseEntity<GoogleOAuthUrlResponseDto>.Ok(new GoogleOAuthUrlResponseDto
        {
            Url = url
        }, "Generated Google login URL.");
    }

    [HttpPost("login/google")]
    public async Task<ResponseEntity<LoginResponseDto>> LoginWithGoogle([FromBody] GoogleLoginRequestDto request, CancellationToken cancellationToken)
    {
        var supabaseUser = await _supabaseAuthService.GetUserByAccessTokenAsync(request.SupabaseAccessToken, cancellationToken);
        if (supabaseUser is null)
        {
            return ResponseEntity<LoginResponseDto>.Fail("Invalid Supabase Google access token.", 401);
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
        }, "Google login successful.");
    }

    [HttpPost("refresh")]
    public async Task<ResponseEntity<LoginResponseDto>> Refresh([FromBody] RefreshTokenRequestDto request, CancellationToken cancellationToken)
    {
        if (!_jwtAuthService.TryValidateRefreshToken(request.RefreshToken, out var userId, out var role))
        {
            return ResponseEntity<LoginResponseDto>.Fail("Invalid or expired refresh token.", 401);
        }

        var user = await _userRepository.GetByIdAsync(userId, cancellationToken);
        if (user is null)
        {
            return ResponseEntity<LoginResponseDto>.Fail("User not found.", 404);
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
        }, "Token refreshed successfully.");
    }

    [HttpGet("me")]
    public async Task<ResponseEntity<AuthUserResponseDto>> Me(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("Missing user identity.");
        }

        var user = await _userRepository.GetByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return ResponseEntity<AuthUserResponseDto>.Fail("User not found.", 404);
        }

        return ResponseEntity<AuthUserResponseDto>.Ok(user.ToAuthUserDto(), "Fetched profile successfully.");
    }

    private async Task<User> EnsureLocalUserFromSupabaseAsync(SupabaseUserProfile supabaseUser, CancellationToken cancellationToken)
    {
        var email = supabaseUser.Email.Trim().ToLowerInvariant();
        var user = await _userRepository.GetByEmailAsync(email, cancellationToken);
        if (user is not null)
        {
            return user;
        }

        var fullName = TryGetMetadataValue(supabaseUser.UserMetadata, "full_name")
            ?? TryGetMetadataValue(supabaseUser.UserMetadata, "name")
            ?? email;

        var phone = TryGetMetadataValue(supabaseUser.UserMetadata, "phone") ?? string.Empty;

        user = new User
        {
            Id = Guid.NewGuid(),
            FullName = fullName,
            Email = email,
            Phone = phone,
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
