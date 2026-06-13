namespace SkinSync.Models.Entities;

public class SkinProgressReport
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ReportCategory { get; set; } = "progress_timeline";
    public string Source { get; set; } = "system";
    public string? PeriodType { get; set; }
    public DateOnly? PeriodStart { get; set; }
    public DateOnly? PeriodEnd { get; set; }
    public Guid? RelatedAnalysisId { get; set; }
    public string ProgressStatus { get; set; } = "insufficient_data";
    public string Summary { get; set; } = string.Empty;
    public string ScoreChanges { get; set; } = "{}";
    public string MainFindings { get; set; } = "[]";
    public string? RoutineFeedback { get; set; }
    public string? ProductFeedback { get; set; }
    public string NextSuggestions { get; set; } = "[]";
    public string? RawAiResponse { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public SkinProgressAnalysis? RelatedAnalysis { get; set; }
}
