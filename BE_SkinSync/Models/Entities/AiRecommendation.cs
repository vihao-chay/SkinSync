namespace SkinSync.Models.Entities;

public class AiRecommendation
{
    public Guid Id { get; set; }
    public Guid AnalysisId { get; set; }
    public Guid UserId { get; set; }
    public string RecommendationType { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public int Priority { get; set; } = 1;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public AiAnalysis Analysis { get; set; } = null!;
    public User User { get; set; } = null!;
}
