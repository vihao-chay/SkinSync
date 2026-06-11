namespace SkinSync.Models.Dtos.Subscriptions;

public class SubscriptionPlanDto
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal Price { get; set; }
    public string Currency { get; set; } = "VND";
    public string BillingPeriod { get; set; } = "monthly";
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
    public string Unit { get; set; } = "usage";
    public IReadOnlyCollection<string> AllowedValues { get; set; } = Array.Empty<string>();
}

public class UserSubscriptionDto
{
    public Guid SubscriptionId { get; set; }
    public string PlanCode { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime StartedAt { get; set; }
    public DateTime? EndsAt { get; set; }
    public DateTime? CancelledAt { get; set; }
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
    public string Unit { get; set; } = "usage";
    public IReadOnlyCollection<string> AllowedValues { get; set; } = Array.Empty<string>();
}

public class CurrentSubscriptionDto
{
    public SubscriptionPlanDto Plan { get; set; } = new();
    public UserSubscriptionDto? ActiveSubscription { get; set; }
    public DateTime UsagePeriodStart { get; set; }
    public DateTime UsagePeriodEnd { get; set; }
    public IReadOnlyCollection<SubscriptionUsageDto> Usage { get; set; } = Array.Empty<SubscriptionUsageDto>();
}

public class SubscribeRequestDto
{
    public string PlanCode { get; set; } = string.Empty;
}
