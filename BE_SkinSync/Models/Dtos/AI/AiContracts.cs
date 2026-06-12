using Microsoft.AspNetCore.Http;
using SkinSync.Models.Dtos;

namespace SkinSync.Models.Dtos.AI;

public class AiBudgetRangeDto
{
    public decimal? Min { get; set; }
    public decimal? Max { get; set; }
    public string Currency { get; set; } = "VND";
}

public class AiSkinAnalysisRequestDto
{
    public IFormFile? Image { get; set; }
    public string? ImageUrl { get; set; }
    public string? AdditionalNote { get; set; }
    public string? Source { get; set; }
    public string? CurrentRoutineContext { get; set; }
    public string? SkinProfileContext { get; set; }
}

public class AiDetectedConcernDto
{
    public string Concern { get; set; } = "unknown";
    public string Severity { get; set; } = "low";
    public double Confidence { get; set; }
    public string Description { get; set; } = string.Empty;
}

public class AiSkinAnalysisResponseDto
{
    public Guid AnalysisSessionId { get; set; }
    public Guid AnalysisResultId { get; set; }
    public Guid ProgressEntryId { get; set; }
    public Guid PhotoId { get; set; }
    public string Status { get; set; } = "completed";
    public string Source { get; set; } = "unknown";
    public string ImageUrl { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public string? AiModel { get; set; }
    public int SkinScore { get; set; }
    public string SkinType { get; set; } = "unknown";
    public int OilinessLevel { get; set; }
    public int DrynessLevel { get; set; }
    public int AcneLevel { get; set; }
    public int RednessLevel { get; set; }
    public int DarkSpotLevel { get; set; }
    public int TextureLevel { get; set; }
    public int PoreLevel { get; set; }
    public int WrinkleLevel { get; set; }
    public int SensitivityLevel { get; set; }
    public int HydrationLevel { get; set; }
    public string SkinSummary { get; set; } = string.Empty;
    public IReadOnlyCollection<AiDetectedConcernDto> DetectedConcerns { get; set; } = Array.Empty<AiDetectedConcernDto>();
    public IReadOnlyCollection<SkinProgressRecommendationDto> Recommendations { get; set; } = Array.Empty<SkinProgressRecommendationDto>();
    public SkinProgressRoutineSuggestionsDto RoutineSuggestions { get; set; } = new();
    public IReadOnlyCollection<SkinProgressProductSuggestionDto> ProductSuggestions { get; set; } = Array.Empty<SkinProgressProductSuggestionDto>();
    public IReadOnlyCollection<string> SafetyNotes { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> RiskFlags { get; set; } = Array.Empty<string>();
    public string Disclaimer { get; set; } = string.Empty;
    public decimal? ConfidenceScore { get; set; }
    public string? ErrorMessage { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
}

public class AiRoutineGenerateRequestDto
{
    public string? RoutinePreference { get; set; }
    public AiBudgetRangeDto? BudgetRange { get; set; }
}

public class AiRoutineStepDto
{
    public int StepOrder { get; set; }
    public string StepName { get; set; } = string.Empty;
    public Guid ProductId { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string Frequency { get; set; } = "daily";
    public string Instruction { get; set; } = string.Empty;
    public string AiReason { get; set; } = string.Empty;
    public string? Warning { get; set; }
}

public class AiRoutineGenerateResponseDto
{
    public Guid RoutineId { get; set; }
    public string RoutineName { get; set; } = string.Empty;
    public IReadOnlyCollection<AiRoutineStepDto> Morning { get; set; } = Array.Empty<AiRoutineStepDto>();
    public IReadOnlyCollection<AiRoutineStepDto> Night { get; set; } = Array.Empty<AiRoutineStepDto>();
    public IReadOnlyCollection<string> Warnings { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> MissingCategories { get; set; } = Array.Empty<string>();
    public string? OverallAdvice { get; set; }
}

public class AiProductRecommendRequestDto
{
    public string Category { get; set; } = "any";
    public string Concern { get; set; } = "any";
    public AiBudgetRangeDto? BudgetRange { get; set; }
}

public class AiRecommendedProductDto
{
    public Guid ProductId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Brand { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string Currency { get; set; } = "VND";
    public int MatchScore { get; set; }
    public string AiReason { get; set; } = string.Empty;
    public IReadOnlyCollection<string> Warnings { get; set; } = Array.Empty<string>();
}

public class AiProductRecommendResponseDto
{
    public IReadOnlyCollection<AiRecommendedProductDto> Products { get; set; } = Array.Empty<AiRecommendedProductDto>();
}

public class AiIngredientCheckRequestDto
{
    public string ProductName { get; set; } = string.Empty;
    public string IngredientsText { get; set; } = string.Empty;
}

public class AiIngredientReasonDto
{
    public string Ingredient { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
}

public class AiIngredientCheckResponseDto
{
    public string Suitability { get; set; } = "caution";
    public IReadOnlyCollection<AiIngredientReasonDto> BeneficialIngredients { get; set; } = Array.Empty<AiIngredientReasonDto>();
    public IReadOnlyCollection<AiIngredientReasonDto> CautionIngredients { get; set; } = Array.Empty<AiIngredientReasonDto>();
    public string OverallExplanation { get; set; } = string.Empty;
    public string UsageSuggestion { get; set; } = string.Empty;
    public IReadOnlyCollection<string> Warnings { get; set; } = Array.Empty<string>();
}

public class AiRoutineConflictCheckRequestDto
{
    public Guid RoutineId { get; set; }
}

public class AiConflictItemDto
{
    public string IngredientA { get; set; } = string.Empty;
    public string IngredientB { get; set; } = string.Empty;
    public string Severity { get; set; } = "low";
    public string Reason { get; set; } = string.Empty;
    public string Recommendation { get; set; } = string.Empty;
}

public class AiRoutineConflictCheckResponseDto
{
    public bool HasConflict { get; set; }
    public IReadOnlyCollection<AiConflictItemDto> Conflicts { get; set; } = Array.Empty<AiConflictItemDto>();
    public string OverallAdvice { get; set; } = string.Empty;
}

public class AiChatRequestDto
{
    public string Message { get; set; } = string.Empty;
    public Guid? ConversationId { get; set; }
    public string? EntryPoint { get; set; }
    public string? ReferenceId { get; set; }
    public string? PrefillContext { get; set; }
}

public class AiSuggestedActionDto
{
    public string Type { get; set; } = string.Empty;
    public string Label { get; set; } = string.Empty;
    public string Route { get; set; } = string.Empty;
    public string? ReferenceId { get; set; }
}

public class AiChatResponseDto
{
    public Guid ConversationId { get; set; }
    public string Reply { get; set; } = string.Empty;
    public IReadOnlyCollection<AiSuggestedActionDto> SuggestedActions { get; set; } = Array.Empty<AiSuggestedActionDto>();
    public bool NeedMoreInfo { get; set; }
    public IReadOnlyCollection<string> MissingInfoQuestions { get; set; } = Array.Empty<string>();
    public string SafetyWarning { get; set; } = string.Empty;
}

public class AiChatConversationCreateRequestDto
{
    public string? Title { get; set; }
}

public class AiChatMessageDto
{
    public Guid Id { get; set; }
    public string Role { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}

public class AiChatConversationSummaryDto
{
    public Guid ConversationId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? LastMessagePreview { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime LastMessageAt { get; set; }
}

public class AiChatConversationDetailDto
{
    public Guid ConversationId { get; set; }
    public string Title { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime LastMessageAt { get; set; }
    public IReadOnlyCollection<AiChatMessageDto> Messages { get; set; } = Array.Empty<AiChatMessageDto>();
}

public class AiReportGenerateRequestDto
{
    public string ReportCategory { get; set; } = "after_analysis";
    public string? Source { get; set; }
    public Guid? RelatedAnalysisId { get; set; }
    public string? PeriodType { get; set; }
    public DateOnly? PeriodStart { get; set; }
    public DateOnly? PeriodEnd { get; set; }
}

public class AiReportGenerateResponseDto
{
    public Guid ReportId { get; set; }
    public string ReportCategory { get; set; } = "after_analysis";
    public string Source { get; set; } = "system";
    public Guid? RelatedAnalysisId { get; set; }
    public string? PeriodType { get; set; }
    public DateOnly? PeriodStart { get; set; }
    public DateOnly? PeriodEnd { get; set; }
    public DateTime CreatedAt { get; set; }
    public string Summary { get; set; } = string.Empty;
    public string ProgressEvaluation { get; set; } = "insufficient_data";
    public IReadOnlyCollection<string> MainFindings { get; set; } = Array.Empty<string>();
    public string? RoutineFeedback { get; set; }
    public string? ProductFeedback { get; set; }
    public IReadOnlyCollection<string> NextPlan { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Warnings { get; set; } = Array.Empty<string>();
}

public class AiReportSummaryDto
{
    public Guid ReportId { get; set; }
    public string ReportCategory { get; set; } = "after_analysis";
    public string Source { get; set; } = "system";
    public Guid? RelatedAnalysisId { get; set; }
    public string? PeriodType { get; set; }
    public string Summary { get; set; } = string.Empty;
    public string ProgressEvaluation { get; set; } = "insufficient_data";
    public DateTime CreatedAt { get; set; }
}

public class AiReminderSuggestRequestDto
{
    public bool ApplySuggestions { get; set; } = true;
}

public class AiReminderSuggestionDto
{
    public string RoutineType { get; set; } = "morning";
    public string Time { get; set; } = "07:00";
    public string Frequency { get; set; } = "daily";
    public string Reason { get; set; } = string.Empty;
    public string Priority { get; set; } = "medium";
    public bool IsAdaptive { get; set; }
    public bool IsEnabled { get; set; } = true;
}

public class AiReminderSuggestResponseDto
{
    public IReadOnlyCollection<AiReminderSuggestionDto> Suggestions { get; set; } = Array.Empty<AiReminderSuggestionDto>();
    public string OverallAdvice { get; set; } = string.Empty;
}

public class AiAddProductToRoutineRequestDto
{
    public string RoutineType { get; set; } = "evening";
    public bool AllowConflicts { get; set; }
}

public class AiRoutineConflictWarningDto
{
    public Guid ProductAId { get; set; }
    public string ProductAName { get; set; } = string.Empty;
    public Guid ProductBId { get; set; }
    public string ProductBName { get; set; } = string.Empty;
    public string IngredientA { get; set; } = string.Empty;
    public string IngredientB { get; set; } = string.Empty;
    public string Severity { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Recommendation { get; set; } = string.Empty;
}

public class AiAddProductToRoutineResponseDto
{
    public bool Added { get; set; }
    public bool RequiresConfirmation { get; set; }
    public string Message { get; set; } = string.Empty;
    public CurrentRegimenResponseDto? Routine { get; set; }
    public IReadOnlyCollection<AiRoutineConflictWarningDto> Warnings { get; set; } = Array.Empty<AiRoutineConflictWarningDto>();
}

public class AiSaveIngredientProductRequestDto
{
    public string ProductName { get; set; } = string.Empty;
    public string IngredientsText { get; set; } = string.Empty;
    public string Category { get; set; } = "Custom";
}

public class AiSavedProductDto
{
    public Guid ProductId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Brand { get; set; } = "My Product";
    public string Category { get; set; } = "Custom";
    public bool IsCustom { get; set; }
}
