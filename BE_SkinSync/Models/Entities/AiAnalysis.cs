namespace SkinSync.Models.Entities;

public class AiAnalysis
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public int OverallScore { get; set; }
    public int? SkinAge { get; set; }
    public int? RecoveryCapacity { get; set; }
    public int? UvDamage { get; set; }
    public int? AgingRisk { get; set; }
    public string? IssuesDetected { get; set; }
    public string? RootCauses { get; set; }
    public string? AiModel { get; set; }
    public string? RawResponse { get; set; }
    public string Status { get; set; } = "completed";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public ICollection<AiAnalysisIssue> AnalysisIssues { get; set; } = new List<AiAnalysisIssue>();
    public ICollection<AiRecommendation> Recommendations { get; set; } = new List<AiRecommendation>();
    public ICollection<UserRegimen> Regimens { get; set; } = new List<UserRegimen>();
}
