using System.Text.Json;
using SkinSync.Data;
using SkinSync.Models.Dtos.Recommendations;
using SkinSync.Models.Entities;

namespace SkinSync.Services.Recommendations;

public interface IRecommendationService
{
    Task<RecommendationResponseDto> GenerateAsync(Guid userId, RecommendationRequestDto request, CancellationToken cancellationToken);
}

public class RecommendationService : IRecommendationService
{
    private readonly IRecommendationCatalogService _catalogService;
    private readonly ICategorySelectionService _categorySelectionService;
    private readonly IRoutineBuilderService _routineBuilderService;
    private readonly IRecommendationReasonService _reasonService;
    private readonly AppDbContext _dbContext;

    public RecommendationService(
        IRecommendationCatalogService catalogService,
        ICategorySelectionService categorySelectionService,
        IRoutineBuilderService routineBuilderService,
        IRecommendationReasonService reasonService,
        AppDbContext dbContext)
    {
        _catalogService = catalogService;
        _categorySelectionService = categorySelectionService;
        _routineBuilderService = routineBuilderService;
        _reasonService = reasonService;
        _dbContext = dbContext;
    }

    public async Task<RecommendationResponseDto> GenerateAsync(Guid userId, RecommendationRequestDto request, CancellationToken cancellationToken)
    {
        var profile = NormalizeProfile(request);
        var catalog = await _catalogService.GetCatalogAsync(cancellationToken);
        var slots = _catalogService.GetRoutineSlots();
        var candidatesBySlot = _categorySelectionService.SelectCandidatesBySlot(catalog, profile, slots);
        var routine = _routineBuilderService.BuildRoutine(candidatesBySlot, slots, catalog.ConflictRules);

        var selectedCandidates = routine.MorningRoutine
            .Concat(routine.NightRoutine)
            .ToList();
        var highlights = _reasonService.BuildIngredientHighlights(selectedCandidates);

        var generatedAt = DateTime.UtcNow;
        var expiresAt = generatedAt.AddDays(14);
        var response = new RecommendationResponseDto
        {
            OverallCompatibilityScore = selectedCandidates.Count == 0
                ? 0
                : (int)Math.Round(selectedCandidates.Average(candidate => candidate.Score)),
            SkinSummary = new RecommendationSkinSummaryDto
            {
                SkinType = profile.SkinType,
                Concerns = profile.Concerns,
                Sensitivity = profile.Sensitivity,
                Goals = profile.Goals
            },
            MorningRoutine = MapProducts(profile, routine.MorningRoutine),
            NightRoutine = MapProducts(profile, routine.NightRoutine),
            Alternatives = MapAlternatives(profile, candidatesBySlot, slots, selectedCandidates),
            IngredientHighlights = highlights
                .Select(item => new RecommendationIngredientHighlightDto
                {
                    Ingredient = item.Ingredient,
                    Benefits = item.Benefits
                })
                .ToArray(),
            Warnings = routine.Warnings,
            GeneratedAt = generatedAt,
            ExpiresAt = expiresAt
        };

        if (selectedCandidates.Count > 0 || response.Alternatives.Any(alternative => alternative.Products.Count > 0))
        {
            response.SessionId = await SaveSessionAsync(userId, response, cancellationToken);
        }

        return response;
    }

    private async Task<Guid> SaveSessionAsync(
        Guid userId,
        RecommendationResponseDto response,
        CancellationToken cancellationToken)
    {
        var session = new ProductRecommendationSession
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            GeneratedAt = response.GeneratedAt,
            ExpiresAt = response.ExpiresAt,
            Status = "completed",
            Summary = BuildSessionSummary(response),
            CreatedAt = DateTime.UtcNow
        };

        var products = response.MorningRoutine
            .Concat(response.NightRoutine)
            .Concat(response.Alternatives.SelectMany(alternative => alternative.Products))
            .GroupBy(product => product.ProductId)
            .Select(group => group.First())
            .ToArray();

        var rankByCategory = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
        session.Items = products.Select(product =>
        {
            var category = string.IsNullOrWhiteSpace(product.Category) ? "other" : product.Category.Trim();
            rankByCategory.TryGetValue(category, out var currentRank);
            var rank = currentRank + 1;
            rankByCategory[category] = rank;

            return new ProductRecommendationItem
            {
                Id = Guid.NewGuid(),
                SessionId = session.Id,
                ProductId = product.ProductId,
                Category = category,
                MatchPercent = Math.Clamp(product.Score, 0, 100),
                WhyRecommended = string.IsNullOrWhiteSpace(product.Reason)
                    ? string.Join(" ", product.Reasons)
                    : product.Reason,
                Cautions = JsonSerializer.Serialize(product.Cautions),
                Rank = rank,
                AlreadyInRoutine = false,
                CreatedAt = DateTime.UtcNow
            };
        }).ToList();

        _dbContext.ProductRecommendationSessions.Add(session);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return session.Id;
    }

    private static string BuildSessionSummary(RecommendationResponseDto response)
    {
        var selectedCount = response.MorningRoutine.Count + response.NightRoutine.Count;
        return $"Generated {selectedCount} routine products with {response.OverallCompatibilityScore}% overall compatibility.";
    }

    private IReadOnlyCollection<RecommendationProductDto> MapProducts(
        RecommendationProfile profile,
        IEnumerable<ScoredRecommendationCandidate> candidates)
    {
        return candidates
            .OrderBy(candidate => candidate.Slot.StepOrder)
            .Select(candidate =>
            {
                var reasons = _reasonService.BuildReasons(profile, candidate);
                return new RecommendationProductDto
                {
                    ProductId = candidate.Product.Id,
                    Name = candidate.Product.Name,
                    Brand = candidate.Product.Brand,
                    Category = candidate.Product.Category,
                    RoutineTime = candidate.RoutineTime.ToString(),
                    StepOrder = candidate.Slot.StepOrder,
                    Price = candidate.Product.Price,
                    Currency = candidate.Product.Currency,
                    Rating = candidate.Product.Rating,
                    Score = candidate.Score,
                    ImageUrl = candidate.Product.ImageUrl,
                    KeyIngredients = candidate.Product.KeyIngredients.Count > 0
                        ? candidate.Product.KeyIngredients
                        : candidate.IngredientScore.MatchedIngredientNames.Take(4).ToArray(),
                    Reasons = reasons,
                    Reason = string.Join(" ", reasons),
                    Cautions = candidate.Warnings
                };
            })
            .ToArray();
    }

    private IReadOnlyCollection<RecommendationAlternativeCategoryDto> MapAlternatives(
        RecommendationProfile profile,
        IReadOnlyDictionary<string, IReadOnlyCollection<ScoredRecommendationCandidate>> candidatesBySlot,
        IReadOnlyCollection<RecommendationRoutineSlot> slots,
        IReadOnlyCollection<ScoredRecommendationCandidate> selectedCandidates)
    {
        var selectedIds = selectedCandidates.Select(candidate => candidate.Product.Id).ToHashSet();

        return slots
            .Select(slot =>
            {
                candidatesBySlot.TryGetValue(CategorySelectionService.BuildSlotKey(slot), out var candidates);
                var products = MapProducts(
                    profile,
                    (candidates ?? Array.Empty<ScoredRecommendationCandidate>())
                    .Where(candidate => !selectedIds.Contains(candidate.Product.Id))
                    .Take(slot.AlternativeLimit));

                return new RecommendationAlternativeCategoryDto
                {
                    CategoryKey = slot.Key,
                    CategoryName = slot.DisplayName,
                    RoutineTime = slot.RoutineTime.ToString(),
                    Products = products
                };
            })
            .Where(item => item.Products.Count > 0)
            .ToArray();
    }

    private static RecommendationProfile NormalizeProfile(RecommendationRequestDto request)
    {
        return new RecommendationProfile
        {
            SkinType = NormalizeSingle(request.SkinType, "Unknown"),
            Sensitivity = NormalizeSingle(request.Sensitivity, "Medium"),
            Concerns = RecommendationTextNormalizer.DistinctNormalized(request.Concerns).Select(ToDisplayCase).ToArray(),
            Goals = RecommendationTextNormalizer.DistinctNormalized(request.Goals).Select(ToDisplayCase).ToArray()
        };
    }

    private static string NormalizeSingle(string? value, string fallback)
    {
        return string.IsNullOrWhiteSpace(value)
            ? fallback
            : ToDisplayCase(value.Trim());
    }

    private static string ToDisplayCase(string value)
    {
        var normalized = RecommendationTextNormalizer.NormalizeKey(value);
        return string.Join(
            ' ',
            normalized
                .Split(' ', StringSplitOptions.RemoveEmptyEntries)
                .Select(token => char.ToUpperInvariant(token[0]) + token[1..]));
    }
}
