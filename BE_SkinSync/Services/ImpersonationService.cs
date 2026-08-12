using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using SkinSync.Models.Dtos.Admin;
using SkinSync.Models.Entities;

namespace SkinSync.Services;

public interface IImpersonationService
{
    ImpersonationSessionResponseDto CreateSession(User adminUser, User targetUser);
    bool TryValidate(string token, out ImpersonationValidationResult result);
}

public sealed class ImpersonationValidationResult
{
    public Guid OriginalAdminId { get; init; }
    public Guid EffectiveUserId { get; init; }
    public Guid ImpersonatedUserId { get; init; }
    public DateTime ExpiresAt { get; init; }
}

public class ImpersonationService : IImpersonationService
{
    public const string ImpersonationHeaderName = "X-Impersonation-Token";

    private readonly string _issuer;
    private readonly string _audience;
    private readonly string _signingKey;
    private readonly int _ttlMinutes;

    public ImpersonationService(IConfiguration configuration)
    {
        _issuer = configuration["Jwt:Issuer"] ?? "SkinSync";
        _audience = configuration["Jwt:Audience"] ?? "SkinSync.Client";
        _signingKey = configuration["Jwt:SigningKey"] ?? "SkinSync.SuperSecretSigningKey.ChangeMe1234567890";
        _ttlMinutes = int.TryParse(configuration["Impersonation:TokenMinutes"], out var minutes) ? Math.Max(minutes, 5) : 20;
    }

    public ImpersonationSessionResponseDto CreateSession(User adminUser, User targetUser)
    {
        var expiresAt = DateTime.UtcNow.AddMinutes(_ttlMinutes);
        var tokenHandler = new JwtSecurityTokenHandler();
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_signingKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, targetUser.Id.ToString()),
            new("token_type", "impersonation"),
            new("original_admin_id", adminUser.Id.ToString()),
            new("effective_user_id", targetUser.Id.ToString()),
            new("impersonated_user_id", targetUser.Id.ToString()),
            new(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        var token = new JwtSecurityToken(
            issuer: _issuer,
            audience: _audience,
            claims: claims,
            notBefore: DateTime.UtcNow,
            expires: expiresAt,
            signingCredentials: credentials);

        return new ImpersonationSessionResponseDto
        {
            ImpersonationToken = tokenHandler.WriteToken(token),
            OriginalAdminId = adminUser.Id,
            EffectiveUserId = targetUser.Id,
            ImpersonatedUserId = targetUser.Id,
            ImpersonatedUserName = targetUser.FullName,
            ImpersonatedUserEmail = targetUser.Email,
            ExpiresAt = expiresAt
        };
    }

    public bool TryValidate(string token, out ImpersonationValidationResult result)
    {
        result = new ImpersonationValidationResult();
        if (string.IsNullOrWhiteSpace(token))
        {
            return false;
        }

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
            var principal = new JwtSecurityTokenHandler().ValidateToken(token, parameters, out var validatedToken);
            var tokenType = principal.FindFirstValue("token_type");
            if (!string.Equals(tokenType, "impersonation", StringComparison.OrdinalIgnoreCase))
            {
                return false;
            }

            var originalAdminId = principal.FindFirstValue("original_admin_id");
            var effectiveUserId = principal.FindFirstValue("effective_user_id");
            var impersonatedUserId = principal.FindFirstValue("impersonated_user_id");
            if (!Guid.TryParse(originalAdminId, out var adminId) ||
                !Guid.TryParse(effectiveUserId, out var effectiveId) ||
                !Guid.TryParse(impersonatedUserId, out var impersonatedId))
            {
                return false;
            }

            result = new ImpersonationValidationResult
            {
                OriginalAdminId = adminId,
                EffectiveUserId = effectiveId,
                ImpersonatedUserId = impersonatedId,
                ExpiresAt = ((JwtSecurityToken)validatedToken).ValidTo
            };
            return true;
        }
        catch
        {
            return false;
        }
    }
}
