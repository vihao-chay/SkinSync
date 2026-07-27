using SkinSync.Services.Recommendations;
using Xunit;

namespace SkinSync.Tests;

public class ProductScoringServiceTests
{
    [Fact]
    public void ScoreProduct_PrefersBetterConcernAndSkinTypeFit()
    {
        var options = RecommendationEngineFixture.CreateOptions();
        var ingredientScoringService = new IngredientScoringService(options);
        var productScoringService = new ProductScoringService(ingredientScoringService, options);
        var profile = RecommendationEngineFixture.CreateProfile();
        var slot = RecommendationEngineFixture.CreateSlot("treatment", RecommendationRoutineTime.Morning, 3, "Serum");

        var alignedProduct = RecommendationEngineFixture.CreateProduct(
            "Niacinamide Serum",
            "Serum",
            4.8m,
            new RecommendationProductIngredient
            {
                Name = "Niacinamide",
                RiskLevel = "low"
            });

        var weakerProduct = new RecommendationProductCatalogItem
        {
            Id = Guid.NewGuid(),
            Name = "Dry Skin Cream",
            Brand = "Test Brand",
            Category = "Serum",
            Description = "Rich cream for dry skin",
            Rating = 3.8m,
            Currency = "USD",
            IsVerified = false,
            SuitableSkinTypes = ["Dry"],
            TargetConcerns = ["Dryness"],
            KeyIngredients = ["Shea Butter"],
            IngredientNames = ["Shea Butter"],
            Ingredients =
            [
                new RecommendationProductIngredient
                {
                    Name = "Shea Butter",
                    RiskLevel = "low"
                }
            ],
            HistoricalRecommendationCount = 1
        };

        var alignedScore = productScoringService.ScoreProduct(profile, slot, alignedProduct, maxPopularityCount: 10);
        var weakerScore = productScoringService.ScoreProduct(profile, slot, weakerProduct, maxPopularityCount: 10);

        Assert.True(alignedScore.RawScore > weakerScore.RawScore);
        Assert.True(alignedScore.Score > weakerScore.Score);
    }
}
