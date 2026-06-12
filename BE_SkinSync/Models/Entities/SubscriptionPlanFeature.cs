namespace SkinSync.Models.Entities;

public class SubscriptionPlanFeature
{
    public Guid Id { get; set; }
    public Guid PlanId { get; set; }
    public string FeatureKey { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public int? MonthlyLimit { get; set; }
    public bool IsEnabled { get; set; } = true;
    public string Unit { get; set; } = "usage";
    public string AllowedValues { get; set; } = "[]";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public SubscriptionPlan Plan { get; set; } = null!;
}
