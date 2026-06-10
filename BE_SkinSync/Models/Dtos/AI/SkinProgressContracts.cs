using Microsoft.AspNetCore.Http;

namespace SkinSync.Models.Dtos.AI;

public class SkinProgressPhotoUploadRequestDto
{
    public IFormFile? Image { get; set; }
    public string? ImageUrl { get; set; }
    public DateOnly? PhotoDate { get; set; }
    public string? TimeOfDay { get; set; }
    public string? LightingCondition { get; set; }
    public string? FaceAngle { get; set; }
    public string? Note { get; set; }
}

public class SkinProgressPhotoDto
{
    public Guid PhotoId { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public DateOnly PhotoDate { get; set; }
    public string TimeOfDay { get; set; } = "unknown";
    public string LightingCondition { get; set; } = "unknown";
    public string FaceAngle { get; set; } = "unknown";
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; }
}

public class SkinProgressAnalyzeRequestDto
{
    public Guid PhotoId { get; set; }
}

public class SkinProgressScoreSetDto
{
    public int AcneScore { get; set; }
    public int RednessScore { get; set; }
    public int DarkSpotScore { get; set; }
    public int OilinessScore { get; set; }
    public int DrynessScore { get; set; }
    public int TextureScore { get; set; }
    public int SensitivityScore { get; set; }
    public int OverallScore { get; set; }
}

public class SkinProgressConcernDto
{
    public string Concern { get; set; } = "unknown";
    public string Severity { get; set; } = "low";
    public int Score { get; set; }
    public double Confidence { get; set; }
    public string Description { get; set; } = string.Empty;
}

public class SkinProgressAnalysisResponseDto
{
    public Guid AnalysisId { get; set; }
    public Guid PhotoId { get; set; }
    public string SkinTypeEstimate { get; set; } = "unknown";
    public string HydrationLevel { get; set; } = "unknown";
    public string OilinessLevel { get; set; } = "unknown";
    public SkinProgressScoreSetDto Scores { get; set; } = new();
    public IReadOnlyCollection<SkinProgressConcernDto> DetectedConcerns { get; set; } = Array.Empty<SkinProgressConcernDto>();
    public string AiSummary { get; set; } = string.Empty;
    public IReadOnlyCollection<string> Recommendations { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> RiskFlags { get; set; } = Array.Empty<string>();
    public string Disclaimer { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class SkinProgressDashboardQueryDto
{
    public string PeriodType { get; set; } = "monthly";
    public DateOnly? WeekStart { get; set; }
    public string? Month { get; set; }
    public int? Year { get; set; }
}

public class SkinProgressDashboardSummaryDto
{
    public string SkinType { get; set; } = "Unknown";
    public string Hydration { get; set; } = "Unknown";
    public string Oiliness { get; set; } = "Unknown";
}

public class SkinProgressConditionScoreDto
{
    public string Label { get; set; } = string.Empty;
    public int Score { get; set; }
    public int? Change { get; set; }
}

public class SkinProgressVisualJourneyPhotoDto
{
    public Guid PhotoId { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public DateOnly Date { get; set; }
}

public class SkinProgressVisualJourneyDto
{
    public SkinProgressVisualJourneyPhotoDto? BeforePhoto { get; set; }
    public SkinProgressVisualJourneyPhotoDto? AfterPhoto { get; set; }
}

public class SkinProgressDashboardResponseDto
{
    public string PeriodType { get; set; } = "monthly";
    public string PeriodLabel { get; set; } = string.Empty;
    public SkinProgressDashboardSummaryDto Summary { get; set; } = new();
    public IReadOnlyCollection<SkinProgressConditionScoreDto> ConditionScores { get; set; } = Array.Empty<SkinProgressConditionScoreDto>();
    public SkinProgressVisualJourneyDto VisualJourney { get; set; } = new();
    public IReadOnlyCollection<SkinProgressPhotoDto> PhotoGallery { get; set; } = Array.Empty<SkinProgressPhotoDto>();
    public string ProgressStatus { get; set; } = "insufficient_data";
    public string? AiReportSummary { get; set; }
}

public class SkinProgressCompareRequestDto
{
    public Guid BeforePhotoId { get; set; }
    public Guid AfterPhotoId { get; set; }
}

public class SkinProgressScoreChangesDto
{
    public int AcneScoreChange { get; set; }
    public int RednessScoreChange { get; set; }
    public int DarkSpotScoreChange { get; set; }
    public int OilinessScoreChange { get; set; }
    public int DrynessScoreChange { get; set; }
    public int TextureScoreChange { get; set; }
    public int SensitivityScoreChange { get; set; }
    public int OverallScoreChange { get; set; }
}

public class SkinProgressCompareResponseDto
{
    public Guid ComparisonId { get; set; }
    public string ProgressStatus { get; set; } = "insufficient_data";
    public string ComparisonSummary { get; set; } = string.Empty;
    public SkinProgressScoreChangesDto ScoreChanges { get; set; } = new();
    public IReadOnlyCollection<string> Improvements { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> WorsenedAreas { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> StableAreas { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Recommendations { get; set; } = Array.Empty<string>();
    public string? ConfidenceNote { get; set; }
    public SkinProgressVisualJourneyPhotoDto? BeforePhoto { get; set; }
    public SkinProgressVisualJourneyPhotoDto? AfterPhoto { get; set; }
}

public class SkinProgressReportGenerateRequestDto
{
    public string PeriodType { get; set; } = "monthly";
    public DateOnly PeriodStart { get; set; }
    public DateOnly PeriodEnd { get; set; }
}

public class SkinProgressReportResponseDto
{
    public Guid ReportId { get; set; }
    public string PeriodType { get; set; } = "monthly";
    public DateOnly PeriodStart { get; set; }
    public DateOnly PeriodEnd { get; set; }
    public string ProgressStatus { get; set; } = "insufficient_data";
    public string Summary { get; set; } = string.Empty;
    public SkinProgressScoreChangesDto ScoreChanges { get; set; } = new();
    public IReadOnlyCollection<string> MainFindings { get; set; } = Array.Empty<string>();
    public string? RoutineFeedback { get; set; }
    public IReadOnlyCollection<string> NextSuggestions { get; set; } = Array.Empty<string>();
    public DateTime CreatedAt { get; set; }
}

public class SkinProgressReportSummaryDto
{
    public Guid ReportId { get; set; }
    public string PeriodType { get; set; } = "monthly";
    public DateOnly PeriodStart { get; set; }
    public DateOnly PeriodEnd { get; set; }
    public string ProgressStatus { get; set; } = "insufficient_data";
    public string Summary { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
