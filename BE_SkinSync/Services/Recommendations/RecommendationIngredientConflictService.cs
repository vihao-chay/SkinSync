using Microsoft.Extensions.Options;
using SkinSync.Models.Configurations;

namespace SkinSync.Services.Recommendations;

public interface IRecommendationIngredientConflictService
{
    IReadOnlyCollection<RecommendationConflictMatch> FindConflicts(
        ScoredRecommendationCandidate candidate,
        IEnumerable<ScoredRecommendationCandidate> selectedCandidates,
        IReadOnlyCollection<RecommendationConflictRule> rules);
}

public class RecommendationIngredientConflictService : IRecommendationIngredientConflictService
{
    private readonly RecommendationScoringOptions _options;

    public RecommendationIngredientConflictService(IOptions<RecommendationScoringOptions> options)
    {
        _options = options.Value;
    }

    public IReadOnlyCollection<RecommendationConflictMatch> FindConflicts(
        ScoredRecommendationCandidate candidate,
        IEnumerable<ScoredRecommendationCandidate> selectedCandidates,
        IReadOnlyCollection<RecommendationConflictRule> rules)
    {
        var selectedList = selectedCandidates.ToList();
        if (selectedList.Count == 0 || rules.Count == 0)
        {
            return Array.Empty<RecommendationConflictMatch>();
        }

        var candidateIngredientIds = candidate.Product.Ingredients
            .Where(ingredient => ingredient.IngredientId.HasValue)
            .Select(ingredient => ingredient.IngredientId!.Value)
            .ToHashSet();
        var candidateIngredientNames = candidate.Product.Ingredients
            .Select(ingredient => RecommendationTextNormalizer.NormalizeKey(ingredient.Name))
            .ToHashSet(StringComparer.Ordinal);

        var conflicts = new List<RecommendationConflictMatch>();
        foreach (var selected in selectedList)
        {
            var selectedIngredientIds = selected.Product.Ingredients
                .Where(ingredient => ingredient.IngredientId.HasValue)
                .Select(ingredient => ingredient.IngredientId!.Value)
                .ToHashSet();
            var selectedIngredientNames = selected.Product.Ingredients
                .Select(ingredient => RecommendationTextNormalizer.NormalizeKey(ingredient.Name))
                .ToHashSet(StringComparer.Ordinal);

            foreach (var rule in rules)
            {
                if (!IsRuleMatch(rule, candidateIngredientIds, candidateIngredientNames, selectedIngredientIds, selectedIngredientNames))
                {
                    continue;
                }

                conflicts.Add(new RecommendationConflictMatch
                {
                    Rule = rule,
                    ProductA = selected,
                    ProductB = candidate
                });
            }
        }

        return conflicts;
    }

    private static bool IsRuleMatch(
        RecommendationConflictRule rule,
        ISet<Guid> candidateIngredientIds,
        ISet<string> candidateIngredientNames,
        ISet<Guid> selectedIngredientIds,
        ISet<string> selectedIngredientNames)
    {
        var directIdMatch = rule.PrimaryIngredientId.HasValue &&
                            rule.ConflictingIngredientId.HasValue &&
                            candidateIngredientIds.Contains(rule.PrimaryIngredientId.Value) &&
                            selectedIngredientIds.Contains(rule.ConflictingIngredientId.Value);

        var reverseIdMatch = rule.PrimaryIngredientId.HasValue &&
                             rule.ConflictingIngredientId.HasValue &&
                             candidateIngredientIds.Contains(rule.ConflictingIngredientId.Value) &&
                             selectedIngredientIds.Contains(rule.PrimaryIngredientId.Value);

        if (directIdMatch || reverseIdMatch)
        {
            return true;
        }

        var primaryName = RecommendationTextNormalizer.NormalizeKey(rule.PrimaryIngredient);
        var conflictingName = RecommendationTextNormalizer.NormalizeKey(rule.ConflictingIngredient);
        if (string.IsNullOrWhiteSpace(primaryName) || string.IsNullOrWhiteSpace(conflictingName))
        {
            return false;
        }

        return (candidateIngredientNames.Contains(primaryName) && selectedIngredientNames.Contains(conflictingName)) ||
               (candidateIngredientNames.Contains(conflictingName) && selectedIngredientNames.Contains(primaryName));
    }

    public int GetConflictPenalty(string severity)
    {
        return _options.ConflictSeverityPenalties.TryGetValue(severity, out var penalty)
            ? penalty
            : _options.ConflictSeverityPenalties.TryGetValue("medium", out var mediumPenalty)
                ? mediumPenalty
                : 15;
    }
}
