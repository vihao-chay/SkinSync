using Microsoft.Extensions.Options;
using SkinSync.Models.Configurations;
using SkinSync.Services.Recommendations;

namespace SkinSync.Tests;

internal static class RecommendationEngineFixture
{
    public static IOptions<RecommendationScoringOptions> CreateOptions()
    {
        return Options.Create(new RecommendationScoringOptions
        {
            Weights = new RecommendationScoreWeightsOptions
            {
                BaseScore = 15,
                ProductConcernMatchBonus = 12,
                ProductGoalMatchBonus = 8,
                ProductSkinTypeMatchBonus = 12,
                ProductAvoidConcernPenalty = 18,
                VerifiedProductBonus = 4,
                CompleteCatalogDataBonus = 4,
                LowIrritationBonus = 6,
                DescriptionKeywordBonus = 4,
                RatingMultiplier = 3m,
                PopularityMaxBonus = 8,
                UsageTimeMatchBonus = 6,
                UsageTimeMismatchPenalty = 10,
                MinimumRoutineScore = 45,
                NormalizationMinRawScore = -20,
                NormalizationMaxRawScore = 140,
                SensitivityRiskPenalties = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase)
                {
                    ["medium:high"] = 6,
                    ["high:medium"] = 6,
                    ["high:high"] = 12
                }
            },
            IngredientRules =
            [
                new IngredientScoreRuleOptions
                {
                    Ingredient = "Niacinamide",
                    Aliases = ["niacinamide"],
                    SkinTypeWeights = new Dictionary<string, int> { ["Oily"] = 15 },
                    ConcernWeights = new Dictionary<string, int> { ["Acne"] = 20, ["Dark Spots"] = 15 },
                    GoalWeights = new Dictionary<string, int> { ["Oil Control"] = 20, ["Brightening"] = 15 },
                    SensitivityWeights = new Dictionary<string, int> { ["High"] = 4, ["Medium"] = 2 }
                },
                new IngredientScoreRuleOptions
                {
                    Ingredient = "Retinol",
                    Aliases = ["retinol"],
                    ConcernWeights = new Dictionary<string, int> { ["Wrinkles"] = 25 },
                    GoalWeights = new Dictionary<string, int> { ["Anti Aging"] = 25 },
                    SensitivityWeights = new Dictionary<string, int> { ["High"] = -12, ["Medium"] = -4 }
                },
                new IngredientScoreRuleOptions
                {
                    Ingredient = "Glycolic Acid",
                    Aliases = ["glycolic acid", "aha"],
                    ConcernWeights = new Dictionary<string, int> { ["Texture"] = 18 },
                    GoalWeights = new Dictionary<string, int> { ["Exfoliating"] = 18 },
                    SensitivityWeights = new Dictionary<string, int> { ["High"] = -12, ["Medium"] = -4 }
                }
            ],
            SensitiveIngredientPenalties =
            [
                new SensitiveIngredientPenaltyOptions
                {
                    Ingredient = "Alcohol Denat",
                    Aliases = ["alcohol denat"],
                    Penalty = 20
                },
                new SensitiveIngredientPenaltyOptions
                {
                    Ingredient = "Fragrance",
                    Aliases = ["fragrance", "parfum"],
                    Penalty = 15
                }
            ],
            TimingPreferences =
            [
                new TimingPreferenceRuleOptions
                {
                    Ingredient = "Retinol",
                    Aliases = ["retinol"],
                    PreferredRoutineTime = "Night",
                    Bonus = 12,
                    OppositeTimePenalty = 14
                },
                new TimingPreferenceRuleOptions
                {
                    Ingredient = "Glycolic Acid",
                    Aliases = ["glycolic acid", "aha"],
                    PreferredRoutineTime = "Night",
                    Bonus = 10,
                    OppositeTimePenalty = 8
                }
            ],
            ConflictSeverityPenalties = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase)
            {
                ["high"] = 25,
                ["medium"] = 15,
                ["low"] = 8
            },
            HighConcentrationAcidAliases = ["glycolic acid", "salicylic acid"],
            HighConcentrationAcidThresholdPercent = 8m
        });
    }

    public static RecommendationProfile CreateProfile(
        string skinType = "Oily",
        string sensitivity = "Medium",
        string[]? concerns = null,
        string[]? goals = null)
    {
        return new RecommendationProfile
        {
            SkinType = skinType,
            Sensitivity = sensitivity,
            Concerns = concerns ?? ["Acne", "Dark Spots"],
            Goals = goals ?? ["Oil Control", "Brightening"]
        };
    }

    public static RecommendationRoutineSlot CreateSlot(
        string key,
        RecommendationRoutineTime routineTime,
        int stepOrder,
        params string[] categories)
    {
        return new RecommendationRoutineSlot
        {
            Key = key,
            DisplayName = key,
            RoutineTime = routineTime,
            StepOrder = stepOrder,
            CategoryWeight = 10,
            Required = true,
            AlternativeLimit = 3,
            ProductCategories = categories
        };
    }

    public static RecommendationProductCatalogItem CreateProduct(
        string name,
        string category,
        decimal? rating,
        params RecommendationProductIngredient[] ingredients)
    {
        return new RecommendationProductCatalogItem
        {
            Id = Guid.NewGuid(),
            Name = name,
            Brand = "Test Brand",
            Category = category,
            Description = name,
            Rating = rating,
            Currency = "USD",
            IsVerified = true,
            SuitableSkinTypes = ["Oily", "Combination"],
            TargetConcerns = ["Acne", "Dark Spots"],
            KeyIngredients = ingredients.Select(ingredient => ingredient.Name).ToArray(),
            IngredientNames = ingredients.Select(ingredient => ingredient.Name).ToArray(),
            Ingredients = ingredients,
            HistoricalRecommendationCount = 5
        };
    }
}
