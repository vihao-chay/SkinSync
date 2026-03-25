using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using SkinAsync.Models.Auth;

namespace SkinAsync.Helpers;

public interface IJwtAuthService
{
    TokenPair GenerateTokenPair(Guid userId, string role);
    bool TryValidateRefreshToken(string refreshToken, out Guid userId, out string role);
}

public class JwtService : IJwtAuthService
{
    private readonly IConfiguration _configuration;
    private readonly string _issuer;
    private readonly string _audience;
    private readonly string _signingKey;
    private readonly int _accessTokenMinutes;
    private readonly int _refreshTokenDays;

    public JwtService(IConfiguration configuration)
    {
        _configuration = configuration;
        _issuer = _configuration["Jwt:Issuer"] ?? "SkinAsync";
        _audience = _configuration["Jwt:Audience"] ?? "SkinAsync.Client";
        _signingKey = _configuration["Jwt:SigningKey"] ?? "SkinAsync.SuperSecretSigningKey.ChangeMe1234567890";
        _accessTokenMinutes = int.TryParse(_configuration["Jwt:AccessTokenMinutes"], out var minutes) ? minutes : 30;
        _refreshTokenDays = int.TryParse(_configuration["Jwt:RefreshTokenDays"], out var days) ? days : 7;
    }

    public TokenPair GenerateTokenPair(Guid userId, string role)
    {
        var accessExpiry = DateTime.UtcNow.AddMinutes(_accessTokenMinutes);
        var refreshExpiry = DateTime.UtcNow.AddDays(_refreshTokenDays);

        return new TokenPair
        {
            AccessToken = GenerateToken(userId, role, accessExpiry, "access"),
            AccessTokenExpiresAtUtc = accessExpiry,
            RefreshToken = GenerateToken(userId, role, refreshExpiry, "refresh"),
            RefreshTokenExpiresAtUtc = refreshExpiry
        };
    }

    public bool TryValidateRefreshToken(string refreshToken, out Guid userId, out string role)
    {
        userId = Guid.Empty;
        role = string.Empty;

        if (string.IsNullOrWhiteSpace(refreshToken))
        {
            return false;
        }

        var tokenHandler = new JwtSecurityTokenHandler();
        var parameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = _issuer,
            ValidAudience = _audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_signingKey)),
            ClockSkew = TimeSpan.Zero
        };

        try
        {
            var principal = tokenHandler.ValidateToken(refreshToken, parameters, out _);
            var tokenType = principal.FindFirstValue("token_type");
            if (!string.Equals(tokenType, "refresh", StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }

            var sub = principal.FindFirstValue(JwtRegisteredClaimNames.Sub)
                ?? principal.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? principal.FindFirstValue("sub");
            var roleClaim = principal.FindFirstValue(ClaimTypes.Role) ?? string.Empty;
            if (!Guid.TryParse(sub, out userId) || userId == Guid.Empty)
            {
                return false;
            }

            role = roleClaim;
            return true;
        }
        catch
        {
            return false;
        }
    }

    private string GenerateToken(Guid userId, string role, DateTime expiresAtUtc, string tokenType)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_signingKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, userId.ToString()),
            new(ClaimTypes.Role, role),
            new("token_type", tokenType),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: _issuer,
            audience: _audience,
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: expiresAtUtc,
            signingCredentials: credentials);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}