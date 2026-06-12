using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class SubscriptionPlanFeature
{
    public Guid Id { get; set; }

    public Guid PlanId { get; set; }

    public string FeatureKey { get; set; } = null!;

    public string DisplayName { get; set; } = null!;

    public int? MonthlyLimit { get; set; }

    public bool IsEnabled { get; set; }

    public string Unit { get; set; } = null!;

    public string AllowedValues { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual SubscriptionPlan Plan { get; set; } = null!;
}
