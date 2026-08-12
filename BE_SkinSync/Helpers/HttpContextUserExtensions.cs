using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using SkinSync.Services;

namespace SkinSync.Helpers;

public static class HttpContextUserExtensions
{
    private const string ImpersonationContextKey = "__skinsync_impersonation_context";

    public static bool TryGetUserId(this HttpContext httpContext, out Guid userId)
    {
        userId = Guid.Empty;

        if (httpContext.Items.TryGetValue(ImpersonationContextKey, out var contextValue) &&
            contextValue is ImpersonationValidationResult impersonationContext &&
            impersonationContext.EffectiveUserId != Guid.Empty)
        {
            userId = impersonationContext.EffectiveUserId;
            return true;
        }

        var claimUserId = httpContext.User?.FindFirstValue(JwtRegisteredClaimNames.Sub)
            ?? httpContext.User?.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? httpContext.User?.FindFirstValue("sub");

        return Guid.TryParse(claimUserId, out userId) && userId != Guid.Empty;
    }

    public static bool TryGetActorUserId(this HttpContext httpContext, out Guid userId)
    {
        userId = Guid.Empty;
        var claimUserId = httpContext.User?.FindFirstValue(JwtRegisteredClaimNames.Sub)
            ?? httpContext.User?.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? httpContext.User?.FindFirstValue("sub");

        return Guid.TryParse(claimUserId, out userId) && userId != Guid.Empty;
    }

    public static void SetImpersonationContext(this HttpContext httpContext, ImpersonationValidationResult context)
    {
        httpContext.Items[ImpersonationContextKey] = context;
    }

    public static bool TryGetImpersonationContext(this HttpContext httpContext, out ImpersonationValidationResult? context)
    {
        if (httpContext.Items.TryGetValue(ImpersonationContextKey, out var value) &&
            value is ImpersonationValidationResult typedValue)
        {
            context = typedValue;
            return true;
        }

        context = null;
        return false;
    }
}
