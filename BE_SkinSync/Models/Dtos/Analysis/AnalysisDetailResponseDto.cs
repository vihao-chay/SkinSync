namespace SkinSync.Models.Dtos.Analysis;

public class AnalysisDetailResponseDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string SkinType { get; set; } = string.Empty;
    public int OverallScore { get; set; }
    public int ConfidenceScore { get; set; }
    public int? SkinAge { get; set; }
    public int? RecoveryCapacity { get; set; }
    public int? UvDamage { get; set; }
    public int? AgingRisk { get; set; }
    public string? IssuesDetected { get; set; }
    public string? RootCauses { get; set; }
    public string? Overview { get; set; }
    public string? AiModel { get; set; }
    public string Status { get; set; } = string.Empty;
    public string Disclaimer { get; set; } = "AI output is for skincare guidance only and does not replace medical diagnosis.";
    public IReadOnlyCollection<string> Warnings { get; set; } = Array.Empty<string>();
    public DateTime GeneratedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public IReadOnlyCollection<AnalysisIssueItemDto> Issues { get; set; } = Array.Empty<AnalysisIssueItemDto>();
    public IReadOnlyCollection<AnalysisRecommendationItemDto> Recommendations { get; set; } = Array.Empty<AnalysisRecommendationItemDto>();
}

public class AnalysisIssueItemDto
{
    public Guid Id { get; set; }
    public string IssueType { get; set; } = string.Empty;
    public int SeverityScore { get; set; }
    public int? ConfidenceScore { get; set; }
    public string? Description { get; set; }
}

public class AnalysisRecommendationItemDto
{
    public Guid Id { get; set; }
    public string RecommendationType { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public int Priority { get; set; }
}
