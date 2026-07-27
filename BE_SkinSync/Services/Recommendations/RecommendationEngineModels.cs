using SkinSync.Models.Configurations;

namespace SkinSync.Services.Recommendations;

public enum RecommendationRoutineTime
{
    Morning,
    Night
}

public class RecommendationProfile
{
    public string SkinType { get; init; } = string.Empty;
    public string Sensitivity { get; init; } = string.Empty;
    public IReadOnlyCollection<string> Concerns { get; init; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Goals { get; init; } = Array.Empty<string>();
}

public class RecommendationIngredientKnowledge
{
    public Guid? Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string RiskLevel { get; init; } = string.Empty;
    public string? Description { get; init; }
    public string? Benefits { get; init; }
    public IReadOnlyCollection<string> SuitableSkinTypes { get; init; } = Array.Empty<string>();
    public IReadOnlyCollection<string> NotSuitableFor { get; init; } = Array.Empty<string>();
}

public class RecommendationProductIngredient
{
    public Guid? IngredientId { get; init; }
    public string Name { get; init; } = string.Empty;
    public string RiskLevel { get; init; } = string.Empty;
    public string? Description { get; init; }
    public string? Benefits { get; init; }
    public string? Concentration { get; init; }
    public IReadOnlyCollection<string> SuitableSkinTypes { get; init; } = Array.Empty<string>();
    public IReadOnlyCollection<string> NotSuitableFor { get; init; } = Array.Empty<string>();
}

public class RecommendationProductCatalogItem
{
    public Guid Id { get; init; }
    public string Name { get; init; } = string.Empty;
    public string Brand { get; init; } = string.Empty;
    public string Category { get; init; } = string.Empty;
    public string? Description { get; init; }
    public decimal? Price { get; init; }
    public string Currency { get; init; } = string.Empty;
    public decimal? Rating { get; init; }
    public string? ImageUrl { get; init; }
    public string? UsageGuide { get; init; }
    public string? UsageTime { get; init; }
    public bool IsVerified { get; init; }
    public IReadOnlyCollection<string> SuitableSkinTypes { get; init; } = Array.Empty<string>();
    public IReadOnlyCollection<string> TargetConcerns { get; init; } = Array.Empty<string>();
    public IReadOnlyCollection<string> AvoidConcerns { get; init; } = Array.Empty<string>();
    public IReadOnlyCollection<string> KeyIngredients { get; init; } = Array.Empty<string>();
    public IReadOnlyCollection<string> IngredientNames { get; init; } = Array.Empty<string>();
    public IReadOnlyCollection<RecommendationProductIngredient> Ingredients { get; init; } = Array.Empty<RecommendationProductIngredient>();
    public int HistoricalRecommendationCount { get; init; }
}

public class RecommendationConflictRule
{
    public Guid Id { get; init; }
    public Guid? PrimaryIngredientId { get; init; }
    public Guid? ConflictingIngredientId { get; init; }
    public string? PrimaryIngredient { get; init; }
    public string? ConflictingIngredient { get; init; }
    public string Severity { get; init; } = string.Empty;
    public string Message { get; init; } = string.Empty;
    public string Recommendation { get; init; } = string.Empty;
}

public class RecommendationCatalogSnapshot
{
    public IReadOnlyCollection<RecommendationProductCatalogItem> Products { get; init; } = Array.Empty<RecommendationProductCatalogItem>();
    public IReadOnlyCollection<RecommendationIngredientKnowledge> Ingredients { get; init; } = Array.Empty<RecommendationIngredientKnowledge>();
    public IReadOnlyCollection<RecommendationConflictRule> ConflictRules { get; init; } = Array.Empty<RecommendationConflictRule>();
    public IReadOnlyCollection<string> Categories { get; init; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Brands { get; init; } = Array.Empty<string>();
}

public class RecommendationRoutineSlot
{
    public string Key { get; init; } = string.Empty;
    public string DisplayName { get; init; } = string.Empty;
    public RecommendationRoutineTime RoutineTime { get; init; }
    public int StepOrder { get; init; }
    public int CategoryWeight { get; init; }
    public bool Required { get; init; }
    public int AlternativeLimit { get; init; }
    public IReadOnlyCollection<string> ProductCategories { get; init; } = Array.Empty<string>();

    public static RecommendationRoutineSlot FromOptions(RecommendationRoutineSlotOptions options)
    {
        return new RecommendationRoutineSlot
        {
            Key = options.Key,
            DisplayName = options.DisplayName,
            RoutineTime = options.RoutineTime.Equals("night", StringComparison.OrdinalIgnoreCase)
                ? RecommendationRoutineTime.Night
                : RecommendationRoutineTime.Morning,
            StepOrder = options.StepOrder,
            CategoryWeight = options.CategoryWeight,
            Required = options.Required,
            AlternativeLimit = options.AlternativeLimit <= 0 ? 3 : options.AlternativeLimit,
            ProductCategories = options.ProductCategories
        };
    }
}

public class IngredientContribution
{
    public string Ingredient { get; init; } = string.Empty;
    public int Score { get; init; }
    public bool PenalizedForSensitivity { get; init; }
    public IReadOnlyCollection<string> MatchedBenefits { get; init; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Notes { get; init; } = Array.Empty<string>();
}

public class IngredientScoreResult
{
    public int TotalScore { get; init; }
    public int SensitivityPenalty { get; init; }
    public bool HasLowIrritationRisk { get; init; }
    public IReadOnlyCollection<IngredientContribution> Contributions { get; init; } = Array.Empty<IngredientContribution>();
    public IReadOnlyCollection<string> MatchedIngredientNames { get; init; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Warnings { get; init; } = Array.Empty<string>();
}

public class RecommendationScoreComponent
{
    public string Key { get; init; } = string.Empty;
    public int Value { get; init; }
    public string Reason { get; init; } = string.Empty;
}

public class ScoredRecommendationCandidate
{
    public RecommendationProductCatalogItem Product { get; init; } = null!;
    public RecommendationRoutineSlot Slot { get; init; } = null!;
    public RecommendationRoutineTime RoutineTime { get; init; }
    public int RawScore { get; set; }
    public int Score { get; set; }
    public IngredientScoreResult IngredientScore { get; init; } = null!;
    public IReadOnlyCollection<RecommendationScoreComponent> Components { get; init; } = Array.Empty<RecommendationScoreComponent>();
    public IReadOnlyCollection<string> Reasons { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Warnings { get; init; } = Array.Empty<string>();
}

public class RecommendationConflictMatch
{
    public RecommendationConflictRule Rule { get; init; } = null!;
    public ScoredRecommendationCandidate ProductA { get; init; } = null!;
    public ScoredRecommendationCandidate ProductB { get; init; } = null!;
}

public class RoutineBuildResult
{
    public IReadOnlyCollection<ScoredRecommendationCandidate> MorningRoutine { get; init; } = Array.Empty<ScoredRecommendationCandidate>();
    public IReadOnlyCollection<ScoredRecommendationCandidate> NightRoutine { get; init; } = Array.Empty<ScoredRecommendationCandidate>();
    public IReadOnlyCollection<string> Warnings { get; init; } = Array.Empty<string>();
}
