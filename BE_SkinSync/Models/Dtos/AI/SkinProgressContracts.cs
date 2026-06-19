using Microsoft.AspNetCore.Http;

namespace SkinSync.Models.Dtos.AI;

public class SkinProgressPhotoUploadRequestDto
{
    public IFormFile? Image { get; set; }
    public string? ImageUrl { get; set; }
    public string? Source { get; set; }
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
    public string Source { get; set; } = "unknown";
    public string? ImageMetadataJson { get; set; }
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

public class SkinProgressMetricsDto
{
    public int Acne { get; set; }
    public int Redness { get; set; }
    public int Oiliness { get; set; }
    public int Dryness { get; set; }
    public int Moisture { get; set; }
    public int Texture { get; set; }
}

public class SkinProgressConcernDto
{
    public string Key { get; set; } = "unknown";
    public string Concern { get; set; } = "unknown";
    public string Label { get; set; } = string.Empty;
    public string Severity { get; set; } = "low";
    public int Score { get; set; }
    public double Confidence { get; set; }
    public string Description { get; set; } = string.Empty;
    public string Evidence { get; set; } = string.Empty;
    public string RecommendationPriority { get; set; } = "medium";
}

public class SkinProgressRecommendationDto
{
    public string Type { get; set; } = "routine";
    public string Title { get; set; } = string.Empty;
    public string Description { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public string Priority { get; set; } = "medium";
}

public class SkinProgressRoutineSuggestionsDto
{
    public IReadOnlyCollection<string> Morning { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Evening { get; set; } = Array.Empty<string>();
}

public class SkinProgressProductSuggestionDto
{
    public string Category { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public IReadOnlyCollection<string> AvoidIngredients { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> PreferredIngredients { get; set; } = Array.Empty<string>();
}

public class SkinProgressAnalysisResponseDto
{
    public Guid AnalysisId { get; set; }
    public Guid PhotoId { get; set; }
    public Guid ProgressEntryId { get; set; }
    public string Status { get; set; } = "completed";
    public string Source { get; set; } = "unknown";
    public string ImageUrl { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public string? AiModel { get; set; }
    public string SkinTypeEstimate { get; set; } = "unknown";
    /// <summary>Normalized text label from the AI response, not the public numeric moisture score.</summary>
    public string HydrationLevel { get; set; } = "unknown";
    public string OilinessLevel { get; set; } = "unknown";
    /// <summary>Canonical health score. Higher is better.</summary>
    public int SkinHealthScore { get; set; }
    /// <summary>Canonical visible concern severity. Higher means worse visible concerns.</summary>
    public int OverallConcernSeverity { get; set; }
    /// <summary>Canonical confidence percent in the 0..100 range.</summary>
    public int Confidence { get; set; }
    public SkinProgressMetricsDto Metrics { get; set; } = new();
    /// <summary>Legacy compatibility scores. OverallScore is always severity, not health.</summary>
    public SkinProgressScoreSetDto Scores { get; set; } = new();
    public IReadOnlyCollection<SkinProgressConcernDto> DetectedConcerns { get; set; } = Array.Empty<SkinProgressConcernDto>();
    public string AiSummary { get; set; } = string.Empty;
    public string Summary { get; set; } = string.Empty;
    public IReadOnlyCollection<SkinProgressRecommendationDto> Recommendations { get; set; } = Array.Empty<SkinProgressRecommendationDto>();
    public SkinProgressRoutineSuggestionsDto RoutineSuggestions { get; set; } = new();
    public IReadOnlyCollection<SkinProgressProductSuggestionDto> ProductSuggestions { get; set; } = Array.Empty<SkinProgressProductSuggestionDto>();
    public IReadOnlyCollection<string> SafetyNotes { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> RiskFlags { get; set; } = Array.Empty<string>();
    public string Disclaimer { get; set; } = string.Empty;
    public string SafetyNote { get; set; } = string.Empty;
    /// <summary>Legacy compatibility ratio in the 0..1 range. Prefer <see cref="Confidence"/> for new UI.</summary>
    public decimal? ConfidenceScore { get; set; }
    public string? ErrorMessage { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
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

public class SkinProgressOverviewResponseDto
{
    public int? LatestScore { get; set; }
    public int? ScoreDelta { get; set; }
    public Guid? LatestEntryId { get; set; }
    public int TotalEntries { get; set; }
    public int CurrentStreak { get; set; }
    public decimal? RoutineAdherenceRate { get; set; }
    public IReadOnlyCollection<string> MainConcerns { get; set; } = Array.Empty<string>();
    public string TrendSummary { get; set; } = string.Empty;
    public IReadOnlyCollection<SkinProgressChartPointDto> ChartData { get; set; } = Array.Empty<SkinProgressChartPointDto>();
}

public class SkinProgressChartPointDto
{
    public Guid EntryId { get; set; }
    public DateTime CreatedAt { get; set; }
    public int? SkinScore { get; set; }
    public int? AcneLevel { get; set; }
    public int? RednessLevel { get; set; }
    public int? DarkSpotLevel { get; set; }
    public int? TextureLevel { get; set; }
    public int? HydrationLevel { get; set; }
}

public class SkinProgressTimelineEntryDto
{
    public Guid EntryId { get; set; }
    public Guid? AnalysisId { get; set; }
    public Guid PhotoId { get; set; }
    public string EntryType { get; set; } = "analysis";
    public string Source { get; set; } = "unknown";
    public string Status { get; set; } = "completed";
    public string ImageUrl { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public int? SkinScore { get; set; }
    public int? AcneLevel { get; set; }
    public int? RednessLevel { get; set; }
    public int? DarkSpotLevel { get; set; }
    public int? TextureLevel { get; set; }
    public int? HydrationLevel { get; set; }
    public string? Summary { get; set; }
    public IReadOnlyCollection<string> MainConcerns { get; set; } = Array.Empty<string>();
    public DateTime CreatedAt { get; set; }
}

public class SkinProgressTimelineResponseDto
{
    public IReadOnlyCollection<SkinProgressTimelineEntryDto> Items { get; set; } = Array.Empty<SkinProgressTimelineEntryDto>();
}

public class SkinProgressEntryDetailDto : SkinProgressTimelineEntryDto
{
    public string SkinType { get; set; } = "unknown";
    public string OilinessLevel { get; set; } = "unknown";
    public SkinProgressScoreSetDto Scores { get; set; } = new();
    public IReadOnlyCollection<SkinProgressConcernDto> DetectedConcerns { get; set; } = Array.Empty<SkinProgressConcernDto>();
    public IReadOnlyCollection<SkinProgressRecommendationDto> Recommendations { get; set; } = Array.Empty<SkinProgressRecommendationDto>();
    public SkinProgressRoutineSuggestionsDto RoutineSuggestions { get; set; } = new();
    public IReadOnlyCollection<SkinProgressProductSuggestionDto> ProductSuggestions { get; set; } = Array.Empty<SkinProgressProductSuggestionDto>();
    public IReadOnlyCollection<string> SafetyNotes { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> RiskFlags { get; set; } = Array.Empty<string>();
    public string Disclaimer { get; set; } = string.Empty;
    public decimal? ConfidenceScore { get; set; }
    public string? Note { get; set; }
}

public class SkinProgressTimelineQueryDto
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public DateOnly? FromDate { get; set; }
    public DateOnly? ToDate { get; set; }
}

public class SkinProgressEntryCompareRequestDto
{
    public Guid BeforeEntryId { get; set; }
    public Guid AfterEntryId { get; set; }
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
    public string ReportCategory { get; set; } = "progress_timeline";
    public string Source { get; set; } = "progress";
    public Guid? RelatedAnalysisId { get; set; }
    public string? PeriodType { get; set; } = "monthly";
    public DateOnly? PeriodStart { get; set; }
    public DateOnly? PeriodEnd { get; set; }
}

public class SkinProgressReportResponseDto
{
    public Guid ReportId { get; set; }
    public string ReportCategory { get; set; } = "progress_timeline";
    public string Source { get; set; } = "system";
    public Guid? RelatedAnalysisId { get; set; }
    public string? PeriodType { get; set; }
    public DateOnly? PeriodStart { get; set; }
    public DateOnly? PeriodEnd { get; set; }
    public string ProgressStatus { get; set; } = "insufficient_data";
    public string Summary { get; set; } = string.Empty;
    public SkinProgressScoreChangesDto ScoreChanges { get; set; } = new();
    public IReadOnlyCollection<string> MainFindings { get; set; } = Array.Empty<string>();
    public string? RoutineFeedback { get; set; }
    public string? ProductFeedback { get; set; }
    public IReadOnlyCollection<string> NextSuggestions { get; set; } = Array.Empty<string>();
    public DateTime CreatedAt { get; set; }
}

public class SkinProgressReportSummaryDto
{
    public Guid ReportId { get; set; }
    public string ReportCategory { get; set; } = "progress_timeline";
    public string Source { get; set; } = "system";
    public Guid? RelatedAnalysisId { get; set; }
    public string? PeriodType { get; set; }
    public DateOnly? PeriodStart { get; set; }
    public DateOnly? PeriodEnd { get; set; }
    public string ProgressStatus { get; set; } = "insufficient_data";
    public string Summary { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
