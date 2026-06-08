namespace SkinSync.Models.Dtos.Analysis;

public class AnalysisHistoryItemDto
{
    public Guid Id { get; set; }
    public DateTime CreatedAt { get; set; }
    public int OverallScore { get; set; }
    public int? SkinAge { get; set; }
    public int? RecoveryCapacity { get; set; }
    public int? UvDamage { get; set; }
    public int? AgingRisk { get; set; }
    public string Status { get; set; } = string.Empty;
}
