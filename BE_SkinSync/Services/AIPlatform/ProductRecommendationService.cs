using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Entities;

namespace SkinSync.Services.AIPlatform;

public interface IProductRecommendationService
{
    Task<AiProductRecommendResponseDto> RecommendAsync(Guid userId, AiProductRecommendRequestDto request, CancellationToken cancellationToken);
}

public class ProductRecommendationService : IProductRecommendationService
{
    private readonly AppDbContext _dbContext;
    private readonly IOpenAiService _openAiService;
    private readonly IAiUsageService _aiUsageService;

    public ProductRecommendationService(
        AppDbContext dbContext,
        IOpenAiService openAiService,
        IAiUsageService aiUsageService)
    {
        _dbContext = dbContext;
        _openAiService = openAiService;
        _aiUsageService = aiUsageService;
    }

    public async Task<AiProductRecommendResponseDto> RecommendAsync(Guid userId, AiProductRecommendRequestDto request, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users.Include(x => x.Profile).FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

        await _aiUsageService.CheckLimitAsync(userId, "product_recommendation", cancellationToken);

        var products = await _dbContext.Products
            .AsNoTracking()
            .Where(x => x.Status == "active" &&
                        (request.Category == "any" || x.Category.ToLower() == request.Category.ToLower()))
            .ToListAsync(cancellationToken);

        var scored = ScoreProducts(user.Profile, request, products)
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.Product.Price)
            .Take(10)
            .ToList();

        var profileJson = AiContextMapper.SerializeUserProfile(user.Profile);
        var budgetJson = JsonSerializer.Serialize(request.BudgetRange ?? new AiBudgetRangeDto());
        var candidatesJson = AiContextMapper.SerializeProducts(scored.Select(x => new
        {
            productId = x.Product.Id,
            name = x.Product.Name,
            brand = x.Product.Brand,
            category = x.Product.Category,
            price = x.Product.Price,
            currency = x.Product.Currency,
            matchScore = x.Score,
            targetConcerns = JsonListHelper.ParseStringList(x.Product.TargetConcerns),
            keyIngredients = JsonListHelper.ParseStringList(x.Product.KeyIngredients)
        }));

        var aiResult = await _openAiService.GenerateJsonAsync<AiProductRecommendAiModel>(
            AiPromptLibrary.CommonSystemPrompt,
            AiPromptLibrary.BuildProductRecommendationPrompt(profileJson, request.Concern, request.Category, budgetJson, candidatesJson),
            cancellationToken: cancellationToken);

        await _aiUsageService.LogUsageAsync(userId, "product_recommendation", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);

        var scoreMap = scored.ToDictionary(x => x.Product.Id, x => x);
        var productsDto = aiResult.Value.RecommendedProducts
            .Where(x => scoreMap.ContainsKey(x.ProductId))
            .OrderBy(x => x.Rank)
            .Select(x =>
            {
                var product = scoreMap[x.ProductId].Product;
                return new AiRecommendedProductDto
                {
                    ProductId = product.Id,
                    Name = product.Name,
                    Brand = product.Brand,
                    Category = product.Category,
                    Price = product.Price,
                    Currency = product.Currency,
                    MatchScore = scoreMap[x.ProductId].Score,
                    AiReason = x.AiReason,
                    Warnings = x.Warnings
                };
            })
            .ToList();

        return new AiProductRecommendResponseDto { Products = productsDto };
    }

    private static IEnumerable<ScoredProduct> ScoreProducts(UserProfile? profile, AiProductRecommendRequestDto request, IEnumerable<Product> products)
    {
        var concerns = UserProfilePayloadHelper.Parse(profile?.SkinConcerns).Concerns;
        var allergies = JsonListHelper.ParseStringList(profile?.Allergies);
        var sensitiveIngredients = JsonListHelper.ParseStringList(profile?.SensitiveIngredients);
        var skinType = profile?.SkinType ?? "unknown";

        foreach (var product in products)
        {
            var score = 0;
            var suitableSkinTypes = JsonListHelper.ParseStringList(product.SuitableSkinTypes);
            var targetConcerns = JsonListHelper.ParseStringList(product.TargetConcerns);
            var avoidConcerns = JsonListHelper.ParseStringList(product.AvoidForConcerns);
            var keyIngredients = JsonListHelper.ParseStringList(product.KeyIngredients);
            var ingredientText = product.Ingredient ?? string.Empty;

            if (suitableSkinTypes.Contains(skinType, StringComparer.OrdinalIgnoreCase))
            {
                score += 3;
            }
            if (targetConcerns.Contains(request.Concern, StringComparer.OrdinalIgnoreCase) ||
                targetConcerns.Any(c => concerns.Contains(c, StringComparer.OrdinalIgnoreCase)))
            {
                score += 3;
            }
            if (request.BudgetRange?.Max is decimal maxBudget && product.Price <= maxBudget)
            {
                score += 2;
            }
            if (request.Category != "any" && product.Category.Equals(request.Category, StringComparison.OrdinalIgnoreCase))
            {
                score += 2;
            }
            if (keyIngredients.Count > 0)
            {
                score += 1;
            }
            if (avoidConcerns.Any(c => concerns.Contains(c, StringComparer.OrdinalIgnoreCase)))
            {
                score -= 4;
            }
            if (allergies.Any(c => ingredientText.Contains(c, StringComparison.OrdinalIgnoreCase)) ||
                sensitiveIngredients.Any(c => ingredientText.Contains(c, StringComparison.OrdinalIgnoreCase)))
            {
                score -= 5;
            }

            yield return new ScoredProduct(product, score);
        }
    }

    private sealed record ScoredProduct(Product Product, int Score);
}

internal sealed class AiProductRecommendAiModel
{
    public List<AiRecommendedProductAiModel> RecommendedProducts { get; set; } = [];
}

internal sealed class AiRecommendedProductAiModel
{
    public Guid ProductId { get; set; }
    public int Rank { get; set; }
    public int MatchScore { get; set; }
    public string AiReason { get; set; } = string.Empty;
    public List<string> Warnings { get; set; } = [];
}
