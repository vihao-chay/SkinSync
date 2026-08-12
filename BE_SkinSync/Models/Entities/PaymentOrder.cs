using System;

namespace SkinSync.Models.Entities;

public class PaymentOrder
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid PlanId { get; set; }
    public long OrderCode { get; set; }       // PayOS order code (unique int64)
    public decimal Amount { get; set; }
    public string Status { get; set; } = "pending";        // "pending", "paid", "cancelled"
    public string? PayOsPaymentLinkId { get; set; }
    public string? CheckoutUrl { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? PaidAt { get; set; }
    
    public User User { get; set; } = null!;
    public SubscriptionPlan Plan { get; set; } = null!;
}
