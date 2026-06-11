namespace SkinSync.Models.Entities;

public class AiAnalysisIssue
{
    public Guid Id { get; set; }
    public Guid AnalysisId { get; set; }
    public string IssueType { get; set; } = string.Empty;
    public int SeverityScore { get; set; }
    public int? ConfidenceScore { get; set; }
    public string? Description { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public AiAnalysis Analysis { get; set; } = null!;
}
