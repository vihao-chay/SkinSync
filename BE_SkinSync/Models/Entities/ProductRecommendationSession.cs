namespace SkinSync.Models.Entities;

public class ProductRecommendationSession
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid? SourceAnalysisId { get; set; }
    public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ExpiresAt { get; set; }
    public string Status { get; set; } = "completed";
    public string? Summary { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public SkinProgressAnalysis? SourceAnalysis { get; set; }
    public ICollection<ProductRecommendationItem> Items { get; set; } = new List<ProductRecommendationItem>();
}
