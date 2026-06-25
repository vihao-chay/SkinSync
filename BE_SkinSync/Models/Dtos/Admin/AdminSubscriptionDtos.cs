namespace SkinSync.Models.Dtos.Admin;

public class AdminSubscriptionItemDto
{
    public Guid SubscriptionId { get; set; }
    public Guid UserId { get; set; }
    public string UserEmail { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string PlanCode { get; set; } = string.Empty;
    public string PlanName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public decimal PricePaid { get; set; }
    public string Currency { get; set; } = string.Empty;
    public string BillingPeriod { get; set; } = string.Empty;
    public DateTime StartedAt { get; set; }
    public DateTime? EndsAt { get; set; }
    public DateTime? CancelledAt { get; set; }
}

public class AdminSubscriptionsResponseDto
{
    public int TotalSubscriptions { get; set; }
    public int ActiveSubscriptions { get; set; }
    public IReadOnlyCollection<AdminSubscriptionItemDto> Items { get; set; } = Array.Empty<AdminSubscriptionItemDto>();
}
