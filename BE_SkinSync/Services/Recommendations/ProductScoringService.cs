using Microsoft.Extensions.Options;
using SkinSync.Models.Configurations;

namespace SkinSync.Services.Recommendations;

public interface IProductScoringService
{
    ScoredRecommendationCandidate ScoreProduct(
        RecommendationProfile profile,
        RecommendationRoutineSlot slot,
        RecommendationProductCatalogItem product,
        int maxPopularityCount);
}

public class ProductScoringService : IProductScoringService
{
    private readonly IIngredientScoringService _ingredientScoringService;
    private readonly RecommendationScoringOptions _options;

    public ProductScoringService(
        IIngredientScoringService ingredientScoringService,
        IOptions<RecommendationScoringOptions> options)
    {
        _ingredientScoringService = ingredientScoringService;
        _options = options.Value;
    }

    public ScoredRecommendationCandidate ScoreProduct(
        RecommendationProfile profile,
        RecommendationRoutineSlot slot,
        RecommendationProductCatalogItem product,
        int maxPopularityCount)
    {
        var components = new List<RecommendationScoreComponent>();
        var warnings = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        AddComponent(components, "base", _options.Weights.BaseScore, "Base compatibility score.");

        var ingredientScore = _ingredientScoringService.ScoreIngredients(profile, slot, product);
        AddComponent(components, "ingredients", ingredientScore.TotalScore, "Ingredient relevance based on skin type, concerns, goals, and sensitivity.");
        foreach (var warning in ingredientScore.Warnings)
        {
            warnings.Add(warning);
        }

        if (product.TargetConcerns.Any(targetConcern =>
                profile.Concerns.Any(concern => RecommendationTextNormalizer.NormalizeKey(concern) == RecommendationTextNormalizer.NormalizeKey(targetConcern))))
        {
            AddComponent(components, "concerns", _options.Weights.ProductConcernMatchBonus, "Product targets one or more of the user's concerns.");
        }

        if (profile.Goals.Any(goal =>
                RecommendationTextNormalizer.MatchesAlias(product.Description, [goal]) ||
                product.TargetConcerns.Any(targetConcern => RecommendationTextNormalizer.NormalizeKey(goal) == RecommendationTextNormalizer.NormalizeKey(targetConcern))))
        {
            AddComponent(components, "goals", _options.Weights.ProductGoalMatchBonus, "Product description or targets align with the user's goals.");
        }

        if (product.SuitableSkinTypes.Any(skinType =>
                RecommendationTextNormalizer.NormalizeKey(skinType) == RecommendationTextNormalizer.NormalizeKey(profile.SkinType) ||
                RecommendationTextNormalizer.NormalizeKey(skinType) == "all"))
        {
            AddComponent(components, "skinType", _options.Weights.ProductSkinTypeMatchBonus, "Suitable skin type match.");
        }

        if (product.AvoidConcerns.Any(avoidConcern =>
                profile.Concerns.Any(concern => RecommendationTextNormalizer.NormalizeKey(concern) == RecommendationTextNormalizer.NormalizeKey(avoidConcern))))
        {
            AddComponent(components, "avoidConcernPenalty", -_options.Weights.ProductAvoidConcernPenalty, "Product lists a concern to avoid.");
            warnings.Add("This product lists a concern that overlaps with the user's profile.");
        }

        AddComponent(components, "category", slot.CategoryWeight, "Routine slot category weight.");

        if (product.IsVerified)
        {
            AddComponent(components, "verified", _options.Weights.VerifiedProductBonus, "Verified catalog entry.");
        }

        if (!string.IsNullOrWhiteSpace(product.Description) && product.KeyIngredients.Count > 0 && product.SuitableSkinTypes.Count > 0)
        {
            AddComponent(components, "catalogCompleteness", _options.Weights.CompleteCatalogDataBonus, "Catalog record has strong supporting metadata.");
        }

        if (ingredientScore.HasLowIrritationRisk && profile.Sensitivity.Equals("High", StringComparison.OrdinalIgnoreCase))
        {
            AddComponent(components, "lowIrritation", _options.Weights.LowIrritationBonus, "Lower irritation profile for sensitive skin.");
        }

        var slotKeyword = slot.DisplayName;
        if (RecommendationTextNormalizer.MatchesAlias(product.Description, [slotKeyword]))
        {
            AddComponent(components, "description", _options.Weights.DescriptionKeywordBonus, "Description aligns with the selected slot.");
        }

        var usageScore = ComputeUsageTimeScore(slot, product.UsageTime);
        if (usageScore != 0)
        {
            AddComponent(components, "usageTime", usageScore, usageScore > 0
                ? "Product usage time aligns with the routine."
                : "Product usage time is less suitable for this routine.");
        }

        if (product.Rating.HasValue)
        {
            var ratingScore = (int)Math.Round((double)(product.Rating.Value * _options.Weights.RatingMultiplier));
            AddComponent(components, "rating", ratingScore, "Product rating contribution.");
        }

        if (maxPopularityCount > 0 && product.HistoricalRecommendationCount > 0)
        {
            var popularityScore = (int)Math.Round(
                product.HistoricalRecommendationCount / (double)maxPopularityCount * _options.Weights.PopularityMaxBonus);
            AddComponent(components, "popularity", popularityScore, "Historical recommendation popularity contribution.");
        }

        var rawScore = components.Sum(component => component.Value);
        var normalizedScore = NormalizeScore(rawScore);

        return new ScoredRecommendationCandidate
        {
            Product = product,
            Slot = slot,
            RoutineTime = slot.RoutineTime,
            RawScore = rawScore,
            Score = normalizedScore,
            IngredientScore = ingredientScore,
            Components = components,
            Warnings = warnings.ToArray()
        };
    }

    private void AddComponent(
        ICollection<RecommendationScoreComponent> components,
        string key,
        int value,
        string reason)
    {
        if (value == 0)
        {
            return;
        }

        components.Add(new RecommendationScoreComponent
        {
            Key = key,
            Value = value,
            Reason = reason
        });
    }

    private int ComputeUsageTimeScore(RecommendationRoutineSlot slot, string? usageTime)
    {
        if (string.IsNullOrWhiteSpace(usageTime) || usageTime.Equals("Both", StringComparison.OrdinalIgnoreCase))
        {
            return 0;
        }

        if (usageTime.Equals(slot.RoutineTime.ToString(), StringComparison.OrdinalIgnoreCase))
        {
            return _options.Weights.UsageTimeMatchBonus;
        }

        return -_options.Weights.UsageTimeMismatchPenalty;
    }

    private int NormalizeScore(int rawScore)
    {
        var min = _options.Weights.NormalizationMinRawScore;
        var max = _options.Weights.NormalizationMaxRawScore;
        if (max <= min)
        {
            return Math.Clamp(rawScore, 0, 100);
        }

        var normalized = (rawScore - min) / (double)(max - min) * 100d;
        return Math.Clamp((int)Math.Round(normalized), 0, 100);
    }
}
