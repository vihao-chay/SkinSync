using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;

namespace SkinSync.Helpers;

public static class HttpContextUserExtensions
{
    public static bool TryGetUserId(this HttpContext httpContext, out Guid userId)
    {
        userId = Guid.Empty;

        var claimUserId = httpContext.User?.FindFirstValue(JwtRegisteredClaimNames.Sub)
            ?? httpContext.User?.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? httpContext.User?.FindFirstValue("sub");

        return Guid.TryParse(claimUserId, out userId) && userId != Guid.Empty;
    }
}
