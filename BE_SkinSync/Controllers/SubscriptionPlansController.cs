using Microsoft.AspNetCore.Mvc;
using SkinSync.Base;
using SkinSync.Models.Dtos.Subscriptions;
using SkinSync.Services;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/subscription-plans")]
public class SubscriptionPlansController : ControllerBase
{
    private readonly ISubscriptionPlanService _subscriptionPlanService;

    public SubscriptionPlansController(ISubscriptionPlanService subscriptionPlanService)
    {
        _subscriptionPlanService = subscriptionPlanService;
    }

    [HttpGet]
    public async Task<ResponseEntity<IReadOnlyCollection<SubscriptionPlanDto>>> GetPlans(CancellationToken cancellationToken)
    {
        var plans = await _subscriptionPlanService.GetPlansAsync(cancellationToken);
        return ResponseEntity<IReadOnlyCollection<SubscriptionPlanDto>>.Ok(plans, "Subscription plans fetched successfully.");
    }
}
