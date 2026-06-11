using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinSync.Base;
using SkinSync.Helpers;
using SkinSync.Models.Dtos.Subscriptions;
using SkinSync.Services;
using SkinSync.Services.AIPlatform;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/subscriptions")]
[Authorize]
public class SubscriptionsController : ControllerBase
{
    private readonly ISubscriptionService _subscriptionService;

    public SubscriptionsController(ISubscriptionService subscriptionService)
    {
        _subscriptionService = subscriptionService;
    }

    [HttpGet("me")]
    public async Task<ResponseEntity<CurrentSubscriptionDto>> Me(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<CurrentSubscriptionDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _subscriptionService.GetCurrentAsync(userId, cancellationToken);
            return ResponseEntity<CurrentSubscriptionDto>.Ok(data, "Fetched current subscription successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<CurrentSubscriptionDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpPost("subscribe")]
    public async Task<ResponseEntity<CurrentSubscriptionDto>> Subscribe([FromBody] SubscribeRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<CurrentSubscriptionDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _subscriptionService.SubscribeAsync(userId, request, cancellationToken);
            return ResponseEntity<CurrentSubscriptionDto>.Ok(data, "Subscription activated successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<CurrentSubscriptionDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpPost("cancel")]
    public async Task<ResponseEntity<CurrentSubscriptionDto>> Cancel(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<CurrentSubscriptionDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _subscriptionService.CancelAsync(userId, cancellationToken);
            return ResponseEntity<CurrentSubscriptionDto>.Ok(data, "Subscription cancelled successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<CurrentSubscriptionDto>.Fail(ex.Message, ex.StatusCode);
        }
    }
}
