namespace SkinSync.Models.Entities;

public class ProductRecommendationItem
{
    public Guid Id { get; set; }
    public Guid SessionId { get; set; }
    public Guid ProductId { get; set; }
    public string Category { get; set; } = string.Empty;
    public int MatchPercent { get; set; }
    public string WhyRecommended { get; set; } = string.Empty;
    public string Cautions { get; set; } = "[]";
    public int Rank { get; set; }
    public bool AlreadyInRoutine { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ProductRecommendationSession Session { get; set; } = null!;
    public Product Product { get; set; } = null!;
}
