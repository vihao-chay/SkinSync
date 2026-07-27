using Microsoft.Extensions.Options;
using SkinSync.Models.Configurations;

namespace SkinSync.Services.Recommendations;

public interface IRoutineBuilderService
{
    RoutineBuildResult BuildRoutine(
        IReadOnlyDictionary<string, IReadOnlyCollection<ScoredRecommendationCandidate>> candidatesBySlot,
        IReadOnlyCollection<RecommendationRoutineSlot> slots,
        IReadOnlyCollection<RecommendationConflictRule> conflictRules);
}

public class RoutineBuilderService : IRoutineBuilderService
{
    private readonly IRecommendationIngredientConflictService _ingredientConflictService;
    private readonly RecommendationScoringOptions _options;

    public RoutineBuilderService(
        IRecommendationIngredientConflictService ingredientConflictService,
        IOptions<RecommendationScoringOptions> options)
    {
        _ingredientConflictService = ingredientConflictService;
        _options = options.Value;
    }

    public RoutineBuildResult BuildRoutine(
        IReadOnlyDictionary<string, IReadOnlyCollection<ScoredRecommendationCandidate>> candidatesBySlot,
        IReadOnlyCollection<RecommendationRoutineSlot> slots,
        IReadOnlyCollection<RecommendationConflictRule> conflictRules)
    {
        var warnings = new List<string>();
        var morning = BuildRoutineForTime(
            RecommendationRoutineTime.Morning,
            candidatesBySlot,
            slots,
            conflictRules,
            warnings);
        var night = BuildRoutineForTime(
            RecommendationRoutineTime.Night,
            candidatesBySlot,
            slots,
            conflictRules,
            warnings);

        warnings.AddRange(BuildAdvisories(morning, night));

        return new RoutineBuildResult
        {
            MorningRoutine = morning,
            NightRoutine = night,
            Warnings = warnings
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToArray()
        };
    }

    private IReadOnlyCollection<ScoredRecommendationCandidate> BuildRoutineForTime(
        RecommendationRoutineTime routineTime,
        IReadOnlyDictionary<string, IReadOnlyCollection<ScoredRecommendationCandidate>> candidatesBySlot,
        IReadOnlyCollection<RecommendationRoutineSlot> slots,
        IReadOnlyCollection<RecommendationConflictRule> conflictRules,
        ICollection<string> warnings)
    {
        var routine = new List<ScoredRecommendationCandidate>();
        var usedProductIds = new HashSet<Guid>();

        foreach (var slot in slots.Where(slot => slot.RoutineTime == routineTime).OrderBy(slot => slot.StepOrder))
        {
            if (!candidatesBySlot.TryGetValue(CategorySelectionService.BuildSlotKey(slot), out var slotCandidates))
            {
                if (slot.Required)
                {
                    warnings.Add($"No candidates were available for {slot.DisplayName} in the {routineTime.ToString().ToLowerInvariant()} routine.");
                }

                continue;
            }

            var selected = SelectCandidate(slotCandidates, routine, usedProductIds, conflictRules, warnings);
            if (selected is null)
            {
                if (slot.Required)
                {
                    warnings.Add($"No conflict-free {slot.DisplayName.ToLowerInvariant()} could be selected for the {routineTime.ToString().ToLowerInvariant()} routine.");
                }

                continue;
            }

            if (selected.Score < _options.Weights.MinimumRoutineScore && !slot.Required)
            {
                continue;
            }

            routine.Add(selected);
            usedProductIds.Add(selected.Product.Id);
        }

        return routine;
    }

    private ScoredRecommendationCandidate? SelectCandidate(
        IEnumerable<ScoredRecommendationCandidate> candidates,
        IReadOnlyCollection<ScoredRecommendationCandidate> selectedProducts,
        ISet<Guid> usedProductIds,
        IReadOnlyCollection<RecommendationConflictRule> conflictRules,
        ICollection<string> warnings)
    {
        foreach (var candidate in candidates)
        {
            if (usedProductIds.Contains(candidate.Product.Id))
            {
                continue;
            }

            var conflicts = _ingredientConflictService.FindConflicts(candidate, selectedProducts, conflictRules);
            if (conflicts.Count == 0)
            {
                return candidate;
            }

            foreach (var conflict in conflicts)
            {
                warnings.Add(conflict.Rule.Message);
            }
        }

        return null;
    }

    private static IReadOnlyCollection<string> BuildAdvisories(
        IEnumerable<ScoredRecommendationCandidate> morning,
        IEnumerable<ScoredRecommendationCandidate> night)
    {
        var warnings = new List<string>();
        var nightIngredients = night
            .SelectMany(candidate => candidate.Product.Ingredients)
            .Select(ingredient => ingredient.Name)
            .ToArray();

        if (nightIngredients.Any(ingredient => RecommendationTextNormalizer.MatchesAlias(ingredient, ["retinol", "retinal", "retinoid"])))
        {
            warnings.Add("Use sunscreen every morning while using retinoids at night.");
        }

        if (nightIngredients.Count(ingredient => RecommendationTextNormalizer.MatchesAlias(ingredient, ["aha", "bha", "salicylic acid", "glycolic acid", "lactic acid"])) > 1)
        {
            warnings.Add("Avoid stacking multiple exfoliating acids in the same night routine.");
        }

        if (morning.SelectMany(candidate => candidate.Product.Ingredients)
            .Any(ingredient => RecommendationTextNormalizer.MatchesAlias(ingredient.Name, ["vitamin c", "ascorbic acid"])) &&
            nightIngredients.Any(ingredient => RecommendationTextNormalizer.MatchesAlias(ingredient, ["retinol", "retinal", "retinoid"])))
        {
            warnings.Add("Vitamin C is placed in the morning and retinoids at night to avoid irritation-heavy layering.");
        }

        return warnings;
    }
}
