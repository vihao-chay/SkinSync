namespace SkinSync.Models.Dtos.Subscriptions;

public class SubscriptionPlanDto
{
    public Guid Id { get; set; }
    public string Code { get; set; } = "free";
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal PriceVnd { get; set; }
    public string BillingCycle { get; set; } = "monthly";
    public bool IsActive { get; set; }
    public IReadOnlyCollection<SubscriptionPlanFeatureDto> Features { get; set; } = Array.Empty<SubscriptionPlanFeatureDto>();
}

public class SubscriptionPlanFeatureDto
{
    public string FeatureKey { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public int? MonthlyLimit { get; set; }
    public bool IsUnlimited { get; set; }
    public bool IsEnabled { get; set; }
}

public class SubscriptionStatusDto
{
    public Guid? SubscriptionId { get; set; }
    public string Status { get; set; } = "active";
    public string PlanCode { get; set; } = "free";
    public DateTime? StartedAt { get; set; }
    public DateTime? CurrentPeriodStart { get; set; }
    public DateTime? CurrentPeriodEnd { get; set; }
    public DateTime? CanceledAt { get; set; }
}

public class SubscriptionUsageDto
{
    public string FeatureKey { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public int Used { get; set; }
    public int? MonthlyLimit { get; set; }
    public int? Remaining { get; set; }
    public bool IsUnlimited { get; set; }
    public bool IsEnabled { get; set; }
}

public class CurrentSubscriptionDto
{
    public SubscriptionPlanDto Plan { get; set; } = new();
    public SubscriptionStatusDto Subscription { get; set; } = new();
    public IReadOnlyCollection<SubscriptionUsageDto> Usage { get; set; } = Array.Empty<SubscriptionUsageDto>();
}

public class SubscribeRequestDto
{
    public string PlanCode { get; set; } = string.Empty;
}

public class UpdateUserPlanRequestDto
{
    public string PlanCode { get; set; } = string.Empty;
}
