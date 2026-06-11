namespace SkinSync.Models.Dtos.Analysis;

public class AnalysisScanResponseDto
{
    public AnalysisDetailResponseDto Analysis { get; set; } = new();
    public Guid RegimenId { get; set; }
    public DateOnly StartDate { get; set; }
    public DateOnly? EndDate { get; set; }
    public bool IsActive { get; set; }
    public int ItemCount { get; set; }
}
