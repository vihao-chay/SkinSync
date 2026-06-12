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
    private readonly ISubscriptionPlanService _subscriptionPlanService;

    public SubscriptionsController(ISubscriptionPlanService subscriptionPlanService)
    {
        _subscriptionPlanService = subscriptionPlanService;
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
            var current = await _subscriptionPlanService.GetCurrentAsync(userId, cancellationToken);
            return ResponseEntity<CurrentSubscriptionDto>.Ok(current, "Current subscription fetched successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<CurrentSubscriptionDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpPost("subscribe")]
    public Task<ResponseEntity<CurrentSubscriptionDto>> Subscribe([FromBody] SubscribeRequestDto request, CancellationToken cancellationToken) =>
        SubscribeCore(request, cancellationToken);

    [HttpPost("register")]
    public Task<ResponseEntity<CurrentSubscriptionDto>> Register([FromBody] SubscribeRequestDto request, CancellationToken cancellationToken) =>
        SubscribeCore(request, cancellationToken);

    [HttpPost("cancel")]
    public async Task<ResponseEntity<CurrentSubscriptionDto>> Cancel(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<CurrentSubscriptionDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var current = await _subscriptionPlanService.CancelAsync(userId, cancellationToken);
            return ResponseEntity<CurrentSubscriptionDto>.Ok(current, "Subscription canceled and downgraded to Free.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<CurrentSubscriptionDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    private async Task<ResponseEntity<CurrentSubscriptionDto>> SubscribeCore(SubscribeRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<CurrentSubscriptionDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var current = await _subscriptionPlanService.SubscribeAsync(userId, request.PlanCode, cancellationToken);
            return ResponseEntity<CurrentSubscriptionDto>.Ok(current, "Subscription activated successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<CurrentSubscriptionDto>.Fail(ex.Message, ex.StatusCode);
        }
    }
}
