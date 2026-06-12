using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class UserSubscription
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public Guid PlanId { get; set; }

    public string Status { get; set; } = null!;

    public DateTime StartedAt { get; set; }

    public DateTime? EndsAt { get; set; }

    public DateTime? CancelledAt { get; set; }

    public decimal PricePaid { get; set; }

    public string Currency { get; set; } = null!;

    public string BillingPeriod { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual SubscriptionPlan Plan { get; set; } = null!;

    public virtual User1 User { get; set; } = null!;
}
