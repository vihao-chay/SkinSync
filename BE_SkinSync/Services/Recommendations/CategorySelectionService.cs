using Microsoft.Extensions.Options;
using SkinSync.Models.Configurations;

namespace SkinSync.Services.Recommendations;

public interface ICategorySelectionService
{
    IReadOnlyDictionary<string, IReadOnlyCollection<ScoredRecommendationCandidate>> SelectCandidatesBySlot(
        RecommendationCatalogSnapshot catalog,
        RecommendationProfile profile,
        IReadOnlyCollection<RecommendationRoutineSlot> slots);
}

public class CategorySelectionService : ICategorySelectionService
{
    private readonly IProductScoringService _productScoringService;
    private readonly RecommendationScoringOptions _options;

    public CategorySelectionService(
        IProductScoringService productScoringService,
        IOptions<RecommendationScoringOptions> options)
    {
        _productScoringService = productScoringService;
        _options = options.Value;
    }

    public IReadOnlyDictionary<string, IReadOnlyCollection<ScoredRecommendationCandidate>> SelectCandidatesBySlot(
        RecommendationCatalogSnapshot catalog,
        RecommendationProfile profile,
        IReadOnlyCollection<RecommendationRoutineSlot> slots)
    {
        var maxPopularityCount = catalog.Products.Count == 0
            ? 0
            : catalog.Products.Max(product => product.HistoricalRecommendationCount);

        return slots.ToDictionary(
            slot => BuildSlotKey(slot),
            slot => (IReadOnlyCollection<ScoredRecommendationCandidate>)catalog.Products
                .Where(product => slot.ProductCategories.Any(category =>
                    RecommendationTextNormalizer.NormalizeKey(category) ==
                    RecommendationTextNormalizer.NormalizeKey(product.Category)))
                .Select(product => _productScoringService.ScoreProduct(profile, slot, product, maxPopularityCount))
                .Where(candidate => candidate.Score >= (slot.Required ? _options.Weights.MinimumRoutineScore - 10 : _options.Weights.MinimumRoutineScore))
                .OrderByDescending(candidate => candidate.Score)
                .ThenByDescending(candidate => candidate.Product.Rating ?? 0m)
                .ThenBy(candidate => candidate.Product.Price ?? decimal.MaxValue)
                .ToArray(),
            StringComparer.OrdinalIgnoreCase);
    }

    public static string BuildSlotKey(RecommendationRoutineSlot slot)
        => $"{slot.RoutineTime}:{slot.Key}";
}
