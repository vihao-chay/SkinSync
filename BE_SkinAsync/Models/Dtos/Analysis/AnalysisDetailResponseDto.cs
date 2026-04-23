namespace SkinAsync.Models.Dtos.Analysis;

public class AnalysisDetailResponseDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public int OverallScore { get; set; }
    public int SkinAge { get; set; }
    public int RecoveryCapacity { get; set; }
    public int UvDamage { get; set; }
    public int AgingRisk { get; set; }
    public string IssuesDetected { get; set; } = "{}";
    public string RootCauses { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
