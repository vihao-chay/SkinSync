namespace SkinSync.Models.Dtos.Recommendations;

public class RecommendationRequestDto
{
    public string SkinType { get; set; } = string.Empty;
    public IReadOnlyCollection<string> Concerns { get; set; } = Array.Empty<string>();
    public string Sensitivity { get; set; } = "Medium";
    public IReadOnlyCollection<string> Goals { get; set; } = Array.Empty<string>();
}

public class RecommendationSkinSummaryDto
{
    public string SkinType { get; set; } = string.Empty;
    public IReadOnlyCollection<string> Concerns { get; set; } = Array.Empty<string>();
    public string Sensitivity { get; set; } = string.Empty;
    public IReadOnlyCollection<string> Goals { get; set; } = Array.Empty<string>();
}

public class RecommendationProductDto
{
    public Guid ProductId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Brand { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string RoutineTime { get; set; } = string.Empty;
    public int StepOrder { get; set; }
    public decimal? Price { get; set; }
    public string Currency { get; set; } = string.Empty;
    public decimal? Rating { get; set; }
    public int Score { get; set; }
    public string? ImageUrl { get; set; }
    public IReadOnlyCollection<string> KeyIngredients { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Reasons { get; set; } = Array.Empty<string>();
    public string Reason { get; set; } = string.Empty;
    public IReadOnlyCollection<string> Cautions { get; set; } = Array.Empty<string>();
}

public class RecommendationAlternativeCategoryDto
{
    public string CategoryKey { get; set; } = string.Empty;
    public string CategoryName { get; set; } = string.Empty;
    public string RoutineTime { get; set; } = string.Empty;
    public IReadOnlyCollection<RecommendationProductDto> Products { get; set; } = Array.Empty<RecommendationProductDto>();
}

public class RecommendationIngredientHighlightDto
{
    public string Ingredient { get; set; } = string.Empty;
    public IReadOnlyCollection<string> Benefits { get; set; } = Array.Empty<string>();
}

public class RecommendationResponseDto
{
    public Guid? SessionId { get; set; }
    public DateTime? ExpiresAt { get; set; }
    public int OverallCompatibilityScore { get; set; }
    public RecommendationSkinSummaryDto SkinSummary { get; set; } = new();
    public IReadOnlyCollection<RecommendationProductDto> MorningRoutine { get; set; } = Array.Empty<RecommendationProductDto>();
    public IReadOnlyCollection<RecommendationProductDto> NightRoutine { get; set; } = Array.Empty<RecommendationProductDto>();
    public IReadOnlyCollection<RecommendationAlternativeCategoryDto> Alternatives { get; set; } = Array.Empty<RecommendationAlternativeCategoryDto>();
    public IReadOnlyCollection<RecommendationIngredientHighlightDto> IngredientHighlights { get; set; } = Array.Empty<RecommendationIngredientHighlightDto>();
    public IReadOnlyCollection<string> Warnings { get; set; } = Array.Empty<string>();
    public DateTime GeneratedAt { get; set; } = DateTime.UtcNow;
}
