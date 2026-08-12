using Microsoft.Extensions.Options;
using SkinSync.Models.Configurations;

namespace SkinSync.Services.Recommendations;

public interface IIngredientScoringService
{
    IngredientScoreResult ScoreIngredients(
        RecommendationProfile profile,
        RecommendationRoutineSlot slot,
        RecommendationProductCatalogItem product);
}

public class IngredientScoringService : IIngredientScoringService
{
    private readonly RecommendationScoringOptions _options;

    public IngredientScoringService(IOptions<RecommendationScoringOptions> options)
    {
        _options = options.Value;
    }

    public IngredientScoreResult ScoreIngredients(
        RecommendationProfile profile,
        RecommendationRoutineSlot slot,
        RecommendationProductCatalogItem product)
    {
        var warnings = new List<string>();
        var contributions = new List<IngredientContribution>();
        var sensitivityPenalty = 0;

        foreach (var ingredient in product.Ingredients)
        {
            var ingredientScore = 0;
            var benefitTags = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            var notes = new List<string>();
            var penalizedForSensitivity = false;

            var matchedRule = _options.IngredientRules.FirstOrDefault(rule =>
                RecommendationTextNormalizer.MatchesAlias(ingredient.Name, EnumerateAliases(rule.Ingredient, rule.Aliases)));

            if (matchedRule is not null)
            {
                ingredientScore += SumRuleWeights(matchedRule.SkinTypeWeights, profile.SkinType, benefitTags, "skin type");
                ingredientScore += SumRuleWeights(matchedRule.ConcernWeights, profile.Concerns, benefitTags, "concern");
                ingredientScore += SumRuleWeights(matchedRule.GoalWeights, profile.Goals, benefitTags, "goal");
                ingredientScore += SumRuleWeights(matchedRule.SensitivityWeights, profile.Sensitivity, benefitTags, "sensitivity");
            }

            ingredientScore += InferBenefitScore(ingredient, profile, benefitTags);

            if (RecommendationTextNormalizer.SequenceContains(ingredient.SuitableSkinTypes, profile.SkinType))
            {
                ingredientScore += 4;
                benefitTags.Add($"{profile.SkinType} support");
            }

            if (profile.Concerns.Any(concern =>
                    RecommendationTextNormalizer.SequenceContains(ingredient.NotSuitableFor, concern)))
            {
                ingredientScore -= 8;
                notes.Add($"May be less suitable for {profile.Concerns.First(concern => RecommendationTextNormalizer.SequenceContains(ingredient.NotSuitableFor, concern)).ToLowerInvariant()}.");
            }

            foreach (var sensitivePenalty in _options.SensitiveIngredientPenalties)
            {
                if (!RecommendationTextNormalizer.MatchesAlias(ingredient.Name, EnumerateAliases(sensitivePenalty.Ingredient, sensitivePenalty.Aliases)))
                {
                    continue;
                }

                if (IsMediumOrHighSensitivity(profile.Sensitivity))
                {
                    sensitivityPenalty += sensitivePenalty.Penalty;
                    penalizedForSensitivity = true;
                    warnings.Add($"Sensitive skin caution: contains {sensitivePenalty.Ingredient}.");
                }

                break;
            }

            sensitivityPenalty += ComputeRiskPenalty(profile.Sensitivity, ingredient.RiskLevel);
            if (TryExtractPercent(ingredient.Concentration, out var percent) &&
                percent >= _options.HighConcentrationAcidThresholdPercent &&
                RecommendationTextNormalizer.MatchesAlias(ingredient.Name, _options.HighConcentrationAcidAliases))
            {
                sensitivityPenalty += 10;
                penalizedForSensitivity = true;
                warnings.Add($"Higher concentration acid detected in {product.Name}; patch testing is recommended.");
            }

            foreach (var timingPreference in _options.TimingPreferences)
            {
                if (!RecommendationTextNormalizer.MatchesAlias(ingredient.Name, EnumerateAliases(timingPreference.Ingredient, timingPreference.Aliases)))
                {
                    continue;
                }

                if (timingPreference.PreferredRoutineTime.Equals(slot.RoutineTime.ToString(), StringComparison.OrdinalIgnoreCase))
                {
                    ingredientScore += timingPreference.Bonus;
                    benefitTags.Add($"{slot.RoutineTime.ToString().ToLowerInvariant()} use");
                }
                else
                {
                    ingredientScore -= timingPreference.OppositeTimePenalty;
                    notes.Add($"Better suited for the {timingPreference.PreferredRoutineTime.ToLowerInvariant()} routine.");
                }

                break;
            }

            if (ingredientScore == 0 && notes.Count == 0 && benefitTags.Count == 0 && !penalizedForSensitivity)
            {
                continue;
            }

            contributions.Add(new IngredientContribution
            {
                Ingredient = ingredient.Name,
                Score = ingredientScore,
                PenalizedForSensitivity = penalizedForSensitivity,
                MatchedBenefits = benefitTags.ToArray(),
                Notes = notes
            });
        }

        var totalScore = contributions.Sum(contribution => contribution.Score) - sensitivityPenalty;
        return new IngredientScoreResult
        {
            TotalScore = totalScore,
            SensitivityPenalty = sensitivityPenalty,
            HasLowIrritationRisk = sensitivityPenalty == 0 && contributions.All(contribution => !contribution.PenalizedForSensitivity),
            Contributions = contributions
                .OrderByDescending(contribution => contribution.Score)
                .ToArray(),
            MatchedIngredientNames = contributions
                .Where(contribution => contribution.Score > 0)
                .Select(contribution => contribution.Ingredient)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToArray(),
            Warnings = warnings
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToArray()
        };
    }

    private static IEnumerable<string> EnumerateAliases(string primary, IEnumerable<string> aliases)
    {
        yield return primary;
        foreach (var alias in aliases)
        {
            yield return alias;
        }
    }

    private static int SumRuleWeights(
        IReadOnlyDictionary<string, int> weights,
        string value,
        ISet<string> benefitTags,
        string tagPrefix)
    {
        foreach (var weight in weights)
        {
            if (!RecommendationTextNormalizer.NormalizeKey(weight.Key)
                .Equals(RecommendationTextNormalizer.NormalizeKey(value), StringComparison.Ordinal))
            {
                continue;
            }

            benefitTags.Add(weight.Key);
            return weight.Value;
        }

        return 0;
    }

    private static int SumRuleWeights(
        IReadOnlyDictionary<string, int> weights,
        IEnumerable<string> values,
        ISet<string> benefitTags,
        string tagPrefix)
    {
        var score = 0;
        foreach (var value in values)
        {
            score += SumRuleWeights(weights, value, benefitTags, tagPrefix);
        }

        return score;
    }

    private static int InferBenefitScore(
        RecommendationProductIngredient ingredient,
        RecommendationProfile profile,
        ISet<string> benefitTags)
    {
        var score = 0;
        var searchableText = $"{ingredient.Benefits} {ingredient.Description}";

        foreach (var concern in profile.Concerns)
        {
            if (!RecommendationTextNormalizer.MatchesAlias(searchableText, [concern]))
            {
                continue;
            }

            score += 4;
            benefitTags.Add(concern);
        }

        foreach (var goal in profile.Goals)
        {
            if (!RecommendationTextNormalizer.MatchesAlias(searchableText, [goal]))
            {
                continue;
            }

            score += 4;
            benefitTags.Add(goal);
        }

        if (RecommendationTextNormalizer.MatchesAlias(searchableText, [profile.SkinType]))
        {
            score += 3;
            benefitTags.Add(profile.SkinType);
        }

        return score;
    }

    private int ComputeRiskPenalty(string sensitivity, string? riskLevel)
    {
        var key = $"{RecommendationTextNormalizer.NormalizeKey(sensitivity)}:{RecommendationTextNormalizer.NormalizeKey(riskLevel)}";
        return _options.Weights.SensitivityRiskPenalties.TryGetValue(key, out var penalty)
            ? penalty
            : 0;
    }

    private static bool IsMediumOrHighSensitivity(string sensitivity)
    {
        var normalized = RecommendationTextNormalizer.NormalizeKey(sensitivity);
        return normalized is "medium" or "high";
    }

    private static bool TryExtractPercent(string? concentration, out decimal percent)
    {
        percent = 0m;
        if (string.IsNullOrWhiteSpace(concentration))
        {
            return false;
        }

        var digits = new string(concentration.Where(character => char.IsDigit(character) || character == '.').ToArray());
        return decimal.TryParse(digits, out percent);
    }
}
