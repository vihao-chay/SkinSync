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
    public Guid AnalysisId { get; set; }
    public string SkinSummary { get; set; } = string.Empty;
    public IReadOnlyCollection<AiDetectedConcernDto> DetectedConcerns { get; set; } = Array.Empty<AiDetectedConcernDto>();
    public IReadOnlyCollection<string> Recommendations { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> RiskFlags { get; set; } = Array.Empty<string>();
    public string Disclaimer { get; set; } = string.Empty;
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
    public string ReportType { get; set; } = "after_analysis";
}

public class AiReportGenerateResponseDto
{
    public Guid ReportId { get; set; }
    public string ReportType { get; set; } = "after_analysis";
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
    public string ReportType { get; set; } = "after_analysis";
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
    public string RoutineType { get; set; } = "Morning";
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
    public string RoutineType { get; set; } = "Evening";
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
