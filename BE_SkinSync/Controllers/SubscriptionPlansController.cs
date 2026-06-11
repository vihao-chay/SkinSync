using Microsoft.AspNetCore.Mvc;
using SkinSync.Base;
using SkinSync.Models.Dtos.Subscriptions;
using SkinSync.Services;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/subscription-plans")]
public class SubscriptionPlansController : ControllerBase
{
    private readonly ISubscriptionService _subscriptionService;

    public SubscriptionPlansController(ISubscriptionService subscriptionService)
    {
        _subscriptionService = subscriptionService;
    }

    [HttpGet]
    public async Task<ResponseEntity<IReadOnlyCollection<SubscriptionPlanDto>>> GetPlans(CancellationToken cancellationToken)
    {
        var plans = await _subscriptionService.GetPlansAsync(cancellationToken);
        return ResponseEntity<IReadOnlyCollection<SubscriptionPlanDto>>.Ok(plans, "Fetched subscription plans successfully.");
    }
}
