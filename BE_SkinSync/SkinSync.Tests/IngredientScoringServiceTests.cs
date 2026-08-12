using SkinSync.Services.Recommendations;
using Xunit;

namespace SkinSync.Tests;

public class IngredientScoringServiceTests
{
    [Fact]
    public void ScoreIngredients_RewardsMatchedActives_AndAppliesSensitivityPenalty()
    {
        var service = new IngredientScoringService(RecommendationEngineFixture.CreateOptions());
        var profile = RecommendationEngineFixture.CreateProfile(sensitivity: "High");
        var slot = RecommendationEngineFixture.CreateSlot("treatment", RecommendationRoutineTime.Night, 3, "Serum");
        var product = RecommendationEngineFixture.CreateProduct(
            "Targeted Serum",
            "Serum",
            4.7m,
            new RecommendationProductIngredient
            {
                Name = "Niacinamide",
                RiskLevel = "low"
            },
            new RecommendationProductIngredient
            {
                Name = "Alcohol Denat",
                RiskLevel = "high"
            });

        var result = service.ScoreIngredients(profile, slot, product);

        Assert.True(result.TotalScore > 0);
        Assert.Contains(result.Contributions, contribution => contribution.Ingredient == "Niacinamide" && contribution.Score > 0);
        Assert.True(result.SensitivityPenalty >= 20);
        Assert.Contains(result.Warnings, warning => warning.Contains("Sensitive skin caution", StringComparison.OrdinalIgnoreCase));
    }
}
