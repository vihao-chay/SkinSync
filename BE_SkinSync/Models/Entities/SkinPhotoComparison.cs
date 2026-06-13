namespace SkinSync.Models.Entities;

public class SkinPhotoComparison
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid BeforePhotoId { get; set; }
    public Guid AfterPhotoId { get; set; }
    public Guid BeforeAnalysisId { get; set; }
    public Guid AfterAnalysisId { get; set; }
    public string ProgressStatus { get; set; } = "insufficient_data";
    public string ComparisonSummary { get; set; } = string.Empty;
    public string Improvements { get; set; } = "[]";
    public string WorsenedAreas { get; set; } = "[]";
    public string StableAreas { get; set; } = "[]";
    public string ScoreChanges { get; set; } = "{}";
    public string Recommendations { get; set; } = "[]";
    public string? ConfidenceNote { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public SkinProgressPhoto BeforePhoto { get; set; } = null!;
    public SkinProgressPhoto AfterPhoto { get; set; } = null!;
    public SkinProgressAnalysis BeforeAnalysis { get; set; } = null!;
    public SkinProgressAnalysis AfterAnalysis { get; set; } = null!;
}
