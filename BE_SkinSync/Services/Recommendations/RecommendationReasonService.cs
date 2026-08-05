namespace SkinSync.Services.Recommendations;

public interface IRecommendationReasonService
{
    IReadOnlyCollection<string> BuildReasons(RecommendationProfile profile, ScoredRecommendationCandidate candidate);
    IReadOnlyCollection<RecommendationIngredientHighlightDtoModel> BuildIngredientHighlights(IEnumerable<ScoredRecommendationCandidate> selectedCandidates);
}

public class RecommendationReasonService : IRecommendationReasonService
{
    public IReadOnlyCollection<string> BuildReasons(RecommendationProfile profile, ScoredRecommendationCandidate candidate)
    {
        var reasons = new List<string>();

        if (candidate.Product.SuitableSkinTypes.Any(skinType =>
                RecommendationTextNormalizer.NormalizeKey(skinType) == RecommendationTextNormalizer.NormalizeKey(profile.SkinType) ||
                RecommendationTextNormalizer.NormalizeKey(skinType) == "all"))
        {
            reasons.Add($"Suitable for {profile.SkinType.ToLowerInvariant()} skin.");
        }

        foreach (var contribution in candidate.IngredientScore.Contributions
                     .Where(contribution => contribution.Score > 0)
                     .OrderByDescending(contribution => contribution.Score)
                     .Take(2))
        {
            if (contribution.MatchedBenefits.Count > 0)
            {
                reasons.Add($"Contains {contribution.Ingredient}, which supports {string.Join(", ", contribution.MatchedBenefits.Select(benefit => benefit.ToLowerInvariant()))}.");
            }
            else
            {
                reasons.Add($"Contains {contribution.Ingredient}, a strong match for this routine.");
            }
        }

        if (candidate.Product.TargetConcerns.Any(targetConcern =>
                profile.Concerns.Any(concern => RecommendationTextNormalizer.NormalizeKey(concern) == RecommendationTextNormalizer.NormalizeKey(targetConcern))))
        {
            reasons.Add($"Targets {string.Join(", ", candidate.Product.TargetConcerns.Intersect(profile.Concerns, StringComparer.OrdinalIgnoreCase).Select(concern => concern.ToLowerInvariant()))}.");
        }

        if (candidate.IngredientScore.HasLowIrritationRisk && profile.Sensitivity.Equals("High", StringComparison.OrdinalIgnoreCase))
        {
            reasons.Add("Lower irritation profile for sensitive skin.");
        }

        return reasons
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(4)
            .ToArray();
    }

    public IReadOnlyCollection<RecommendationIngredientHighlightDtoModel> BuildIngredientHighlights(IEnumerable<ScoredRecommendationCandidate> selectedCandidates)
    {
        return selectedCandidates
            .SelectMany(candidate => candidate.IngredientScore.Contributions)
            .Where(contribution => contribution.Score > 0 && contribution.MatchedBenefits.Count > 0)
            .GroupBy(contribution => contribution.Ingredient, StringComparer.OrdinalIgnoreCase)
            .Select(group => new RecommendationIngredientHighlightDtoModel
            {
                Ingredient = group.Key,
                Benefits = group
                    .SelectMany(item => item.MatchedBenefits)
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .Take(4)
                    .ToArray()
            })
            .OrderByDescending(item => item.Benefits.Count)
            .ThenBy(item => item.Ingredient)
            .Take(6)
            .ToArray();
    }
}

public class RecommendationIngredientHighlightDtoModel
{
    public string Ingredient { get; init; } = string.Empty;
    public IReadOnlyCollection<string> Benefits { get; init; } = Array.Empty<string>();
}
