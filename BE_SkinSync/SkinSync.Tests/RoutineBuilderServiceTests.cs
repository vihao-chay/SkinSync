using SkinSync.Services.Recommendations;
using Xunit;

namespace SkinSync.Tests;

public class RoutineBuilderServiceTests
{
    [Fact]
    public void BuildRoutine_SkipsConflictingNightTreatment_AndUsesNextCandidate()
    {
        var options = RecommendationEngineFixture.CreateOptions();
        var conflictService = new RecommendationIngredientConflictService(options);
        var routineBuilder = new RoutineBuilderService(conflictService, options);

        var tonerSlot = RecommendationEngineFixture.CreateSlot("toner", RecommendationRoutineTime.Night, 2, "Exfoliant");
        var treatmentSlot = RecommendationEngineFixture.CreateSlot("treatment", RecommendationRoutineTime.Night, 3, "Serum");

        var exfoliant = BuildCandidate(
            RecommendationEngineFixture.CreateProduct(
                "AHA Toner",
                "Exfoliant",
                4.4m,
                new RecommendationProductIngredient
                {
                    Name = "Glycolic Acid",
                    RiskLevel = "medium"
                }),
            tonerSlot,
            88);

        var retinol = BuildCandidate(
            RecommendationEngineFixture.CreateProduct(
                "Retinol Serum",
                "Serum",
                4.8m,
                new RecommendationProductIngredient
                {
                    Name = "Retinol",
                    RiskLevel = "high"
                }),
            treatmentSlot,
            95);

        var niacinamide = BuildCandidate(
            RecommendationEngineFixture.CreateProduct(
                "Niacinamide Serum",
                "Serum",
                4.6m,
                new RecommendationProductIngredient
                {
                    Name = "Niacinamide",
                    RiskLevel = "low"
                }),
            treatmentSlot,
            90);

        var candidatesBySlot = new Dictionary<string, IReadOnlyCollection<ScoredRecommendationCandidate>>(StringComparer.OrdinalIgnoreCase)
        {
            [CategorySelectionService.BuildSlotKey(tonerSlot)] = [exfoliant],
            [CategorySelectionService.BuildSlotKey(treatmentSlot)] = [retinol, niacinamide]
        };

        IReadOnlyCollection<RecommendationConflictRule> conflictRules =
        [
            new RecommendationConflictRule
            {
                Id = Guid.NewGuid(),
                PrimaryIngredient = "Retinol",
                ConflictingIngredient = "Glycolic Acid",
                Severity = "high",
                Message = "Avoid using Retinol and AHA on the same night.",
                Recommendation = "Use them on alternating nights."
            }
        ];

        var result = routineBuilder.BuildRoutine(candidatesBySlot, [tonerSlot, treatmentSlot], conflictRules);

        Assert.Contains(result.NightRoutine, candidate => candidate.Product.Name == "AHA Toner");
        Assert.Contains(result.NightRoutine, candidate => candidate.Product.Name == "Niacinamide Serum");
        Assert.DoesNotContain(result.NightRoutine, candidate => candidate.Product.Name == "Retinol Serum");
        Assert.Contains(result.Warnings, warning => warning.Contains("Retinol and AHA", StringComparison.OrdinalIgnoreCase));
    }

    private static ScoredRecommendationCandidate BuildCandidate(
        RecommendationProductCatalogItem product,
        RecommendationRoutineSlot slot,
        int score)
    {
        return new ScoredRecommendationCandidate
        {
            Product = product,
            Slot = slot,
            RoutineTime = slot.RoutineTime,
            RawScore = score,
            Score = score,
            IngredientScore = new IngredientScoreResult(),
            Components = []
        };
    }
}
