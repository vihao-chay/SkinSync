using System.IdentityModel.Tokens.Jwt;

namespace SkinAsync.Helpers;

public static class HttpContextUserExtensions
{
    public static bool TryGetUserId(this HttpContext httpContext, out Guid userId)
    {
        userId = Guid.Empty;

        var claimUserId = httpContext.User?.Claims.FirstOrDefault(x => x.Type == JwtRegisteredClaimNames.Sub)?.Value;
        if (Guid.TryParse(claimUserId, out userId) && userId != Guid.Empty)
        {
            return true;
        }

        if (!httpContext.Request.Headers.TryGetValue("Id", out var values))
        {
            return false;
        }

        return Guid.TryParse(values.FirstOrDefault(), out userId) && userId != Guid.Empty;
    }
}
