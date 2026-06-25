using SkinSync.Services;

namespace SkinSync.Helpers;

public class ImpersonationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ImpersonationMiddleware> _logger;

    public ImpersonationMiddleware(RequestDelegate next, ILogger<ImpersonationMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, IImpersonationService impersonationService)
    {
        if (context.User.Identity?.IsAuthenticated == true &&
            context.User.IsInRole("admin") &&
            context.Request.Headers.TryGetValue(ImpersonationService.ImpersonationHeaderName, out var headerValues))
        {
            var token = headerValues.FirstOrDefault();
            if (!string.IsNullOrWhiteSpace(token) && impersonationService.TryValidate(token, out var validation))
            {
                if (context.TryGetActorUserId(out var actorUserId) && actorUserId == validation.OriginalAdminId)
                {
                    context.SetImpersonationContext(validation);
                    _logger.LogInformation(
                        "Impersonation request: admin {AdminId} acting as user {UserId} for {Method} {Path}",
                        validation.OriginalAdminId,
                        validation.EffectiveUserId,
                        context.Request.Method,
                        context.Request.Path.Value);
                }
            }
        }

        await _next(context);
    }
}
