namespace SkinSync.Models.Entities;

public class AiReport
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ReportType { get; set; } = "after_analysis";
    public string Summary { get; set; } = string.Empty;
    public string ProgressEvaluation { get; set; } = "insufficient_data";
    public string MainFindings { get; set; } = "[]";
    public string? RoutineFeedback { get; set; }
    public string? ProductFeedback { get; set; }
    public string NextPlan { get; set; } = "[]";
    public string Warnings { get; set; } = "[]";
    public string? RawAiResponse { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
}
