namespace SkinSync.Models.Entities;

public class AiUsageLog
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string FeatureName { get; set; } = string.Empty;
    public DateTime UsedAt { get; set; } = DateTime.UtcNow;
    public int? InputTokens { get; set; }
    public int? OutputTokens { get; set; }
    public string? Model { get; set; }
    public decimal? CostEstimate { get; set; }

    public User User { get; set; } = null!;
}
