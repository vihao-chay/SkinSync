using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Options;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Models.Configurations;

namespace SkinSync.Services.Recommendations;

public interface IRecommendationCatalogService
{
    Task<RecommendationCatalogSnapshot> GetCatalogAsync(CancellationToken cancellationToken);
    IReadOnlyCollection<RecommendationRoutineSlot> GetRoutineSlots();
}

public class RecommendationCatalogService : IRecommendationCatalogService
{
    private const string ProductCacheKey = "recommendation-engine:products";
    private const string IngredientCacheKey = "recommendation-engine:ingredients";
    private const string CategoryCacheKey = "recommendation-engine:categories";
    private const string BrandCacheKey = "recommendation-engine:brands";
    private const string ConflictRuleCacheKey = "recommendation-engine:conflicts";

    private readonly AppDbContext _dbContext;
    private readonly IMemoryCache _memoryCache;
    private readonly RecommendationScoringOptions _options;

    public RecommendationCatalogService(
        AppDbContext dbContext,
        IMemoryCache memoryCache,
        IOptions<RecommendationScoringOptions> options)
    {
        _dbContext = dbContext;
        _memoryCache = memoryCache;
        _options = options.Value;
    }

    public async Task<RecommendationCatalogSnapshot> GetCatalogAsync(CancellationToken cancellationToken)
    {
        var ingredients = await GetIngredientsAsync(cancellationToken);
        var categories = await GetCategoriesAsync(cancellationToken);
        var brands = await GetBrandsAsync(cancellationToken);
        var conflictRules = await GetConflictRulesAsync(cancellationToken);
        var products = await GetProductsAsync(ingredients, cancellationToken);

        return new RecommendationCatalogSnapshot
        {
            Products = products,
            Ingredients = ingredients,
            ConflictRules = conflictRules,
            Categories = categories,
            Brands = brands
        };
    }

    public IReadOnlyCollection<RecommendationRoutineSlot> GetRoutineSlots()
    {
        return _options.Slots
            .Select(RecommendationRoutineSlot.FromOptions)
            .OrderBy(slot => slot.RoutineTime)
            .ThenBy(slot => slot.StepOrder)
            .ToArray();
    }

    private Task<IReadOnlyCollection<RecommendationIngredientKnowledge>> GetIngredientsAsync(CancellationToken cancellationToken)
    {
        return _memoryCache.GetOrCreateAsync(IngredientCacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(6);
            var rawIngredients = await _dbContext.Ingredients
                .AsNoTracking()
                .Select(ingredient => new IngredientProjection
                {
                    Id = ingredient.Id,
                    Name = ingredient.Name,
                    RiskLevel = ingredient.RiskLevel,
                    Description = ingredient.Description,
                    Benefits = ingredient.Benefit,
                    SuitableSkinTypes = ingredient.SuitableSkinTypes,
                    NotSuitableFor = ingredient.NotSuitableFor
                })
                .ToListAsync(cancellationToken);

            var ingredients = rawIngredients
                .Select(ingredient => new RecommendationIngredientKnowledge
                {
                    Id = ingredient.Id,
                    Name = ingredient.Name,
                    RiskLevel = ingredient.RiskLevel,
                    Description = ingredient.Description,
                    Benefits = ingredient.Benefits,
                    SuitableSkinTypes = JsonListHelper.ParseStringList(ingredient.SuitableSkinTypes),
                    NotSuitableFor = JsonListHelper.ParseStringList(ingredient.NotSuitableFor)
                })
                .ToList();

            return (IReadOnlyCollection<RecommendationIngredientKnowledge>)ingredients;
        })!;
    }

    private Task<IReadOnlyCollection<string>> GetCategoriesAsync(CancellationToken cancellationToken)
    {
        return _memoryCache.GetOrCreateAsync(CategoryCacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(6);
            var categories = await _dbContext.Products
                .AsNoTracking()
                .Where(product => product.IsActive)
                .Select(product => product.Category)
                .Distinct()
                .OrderBy(category => category)
                .ToListAsync(cancellationToken);

            return (IReadOnlyCollection<string>)categories;
        })!;
    }

    private Task<IReadOnlyCollection<string>> GetBrandsAsync(CancellationToken cancellationToken)
    {
        return _memoryCache.GetOrCreateAsync(BrandCacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(6);
            var brands = await _dbContext.Products
                .AsNoTracking()
                .Where(product => product.IsActive)
                .Select(product => product.Brand)
                .Distinct()
                .OrderBy(brand => brand)
                .ToListAsync(cancellationToken);

            return (IReadOnlyCollection<string>)brands;
        })!;
    }

    private Task<IReadOnlyCollection<RecommendationConflictRule>> GetConflictRulesAsync(CancellationToken cancellationToken)
    {
        return _memoryCache.GetOrCreateAsync(ConflictRuleCacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(6);
            var rules = await _dbContext.IngredientConflictRules
                .AsNoTracking()
                .Select(rule => new RecommendationConflictRule
                {
                    Id = rule.Id,
                    PrimaryIngredientId = rule.PrimaryIngredientId,
                    ConflictingIngredientId = rule.ConflictingIngredientId,
                    PrimaryIngredient = rule.PrimaryIngredientEntity != null ? rule.PrimaryIngredientEntity.Name : rule.PrimaryIngredient,
                    ConflictingIngredient = rule.ConflictingIngredientEntity != null ? rule.ConflictingIngredientEntity.Name : rule.ConflictingIngredient,
                    Severity = rule.Severity,
                    Message = rule.Message,
                    Recommendation = rule.Recommendation
                })
                .ToListAsync(cancellationToken);

            return (IReadOnlyCollection<RecommendationConflictRule>)rules;
        })!;
    }

    private Task<IReadOnlyCollection<RecommendationProductCatalogItem>> GetProductsAsync(
        IReadOnlyCollection<RecommendationIngredientKnowledge> ingredients,
        CancellationToken cancellationToken)
    {
        return _memoryCache.GetOrCreateAsync(ProductCacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(15);

            var rawProducts = await _dbContext.Products
                .AsNoTracking()
                .Where(product => product.IsActive && product.Status == "active")
                .Select(product => new ProductCatalogProjection
                {
                    Id = product.Id,
                    Name = product.Name,
                    Brand = product.Brand,
                    Category = product.Category,
                    Description = product.Description,
                    Price = product.Price,
                    Currency = product.Currency,
                    Rating = product.Rating,
                    ImageUrl = product.ImageUrl,
                    UsageGuide = product.UsageGuide,
                    UsageTime = product.UsageTime,
                    IsVerified = product.IsVerified,
                    SuitableSkinTypes = product.SuitableSkinTypes,
                    TargetConcerns = product.TargetConcerns,
                    AvoidConcerns = product.AvoidForConcerns,
                    KeyIngredients = product.KeyIngredients,
                    IngredientNames = product.Ingredient,
                    HistoricalRecommendationCount = product.ProductRecommendationItems.Count(),
                    ProductIngredients = product.ProductIngredients
                        .Select(link => new ProductIngredientProjection
                        {
                            IngredientId = link.IngredientId,
                            Name = link.Ingredient.Name,
                            RiskLevel = link.Ingredient.RiskLevel,
                            Description = link.Ingredient.Description,
                            Benefits = link.Ingredient.Benefit,
                            SuitableSkinTypes = link.Ingredient.SuitableSkinTypes,
                            NotSuitableFor = link.Ingredient.NotSuitableFor,
                            Concentration = link.Concentration
                        })
                        .ToList()
                })
                .ToListAsync(cancellationToken);

            var ingredientLookup = ingredients
                .GroupBy(ingredient => RecommendationTextNormalizer.NormalizeKey(ingredient.Name))
                .ToDictionary(group => group.Key, group => group.First(), StringComparer.Ordinal);

            var products = rawProducts
                .Select(product => MapProduct(product, ingredientLookup))
                .ToList();

            return (IReadOnlyCollection<RecommendationProductCatalogItem>)products;
        })!;
    }

    private static RecommendationProductCatalogItem MapProduct(
        ProductCatalogProjection product,
        IReadOnlyDictionary<string, RecommendationIngredientKnowledge> ingredientLookup)
    {
        var linkedIngredients = product.ProductIngredients
            .Select(ingredient => new RecommendationProductIngredient
            {
                IngredientId = ingredient.IngredientId,
                Name = ingredient.Name,
                RiskLevel = ingredient.RiskLevel,
                Description = ingredient.Description,
                Benefits = ingredient.Benefits,
                SuitableSkinTypes = JsonListHelper.ParseStringList(ingredient.SuitableSkinTypes),
                NotSuitableFor = JsonListHelper.ParseStringList(ingredient.NotSuitableFor),
                Concentration = ingredient.Concentration
            })
            .ToList();

        var parsedIngredientNames = JsonListHelper.ParseStringList(product.IngredientNames);
        foreach (var parsedIngredientName in parsedIngredientNames)
        {
            if (linkedIngredients.Any(existing =>
                    RecommendationTextNormalizer.NormalizeKey(existing.Name) ==
                    RecommendationTextNormalizer.NormalizeKey(parsedIngredientName)))
            {
                continue;
            }

            var normalizedName = RecommendationTextNormalizer.NormalizeKey(parsedIngredientName);
            if (ingredientLookup.TryGetValue(normalizedName, out var ingredient))
            {
                linkedIngredients.Add(new RecommendationProductIngredient
                {
                    IngredientId = ingredient.Id,
                    Name = ingredient.Name,
                    RiskLevel = ingredient.RiskLevel,
                    Description = ingredient.Description,
                    Benefits = ingredient.Benefits,
                    SuitableSkinTypes = ingredient.SuitableSkinTypes,
                    NotSuitableFor = ingredient.NotSuitableFor
                });
                continue;
            }

            linkedIngredients.Add(new RecommendationProductIngredient
            {
                Name = parsedIngredientName,
                RiskLevel = string.Empty
            });
        }

        return new RecommendationProductCatalogItem
        {
            Id = product.Id,
            Name = product.Name,
            Brand = product.Brand,
            Category = product.Category,
            Description = product.Description,
            Price = product.Price,
            Currency = product.Currency ?? string.Empty,
            Rating = product.Rating,
            ImageUrl = product.ImageUrl,
            UsageGuide = product.UsageGuide,
            UsageTime = product.UsageTime,
            IsVerified = product.IsVerified,
            SuitableSkinTypes = JsonListHelper.ParseStringList(product.SuitableSkinTypes),
            TargetConcerns = JsonListHelper.ParseStringList(product.TargetConcerns),
            AvoidConcerns = JsonListHelper.ParseStringList(product.AvoidConcerns),
            KeyIngredients = JsonListHelper.ParseStringList(product.KeyIngredients),
            IngredientNames = parsedIngredientNames,
            Ingredients = linkedIngredients,
            HistoricalRecommendationCount = product.HistoricalRecommendationCount
        };
    }

    private sealed class ProductCatalogProjection
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string? Description { get; set; }
        public decimal? Price { get; set; }
        public string? Currency { get; set; }
        public decimal? Rating { get; set; }
        public string? ImageUrl { get; set; }
        public string? UsageGuide { get; set; }
        public string? UsageTime { get; set; }
        public bool IsVerified { get; set; }
        public string? SuitableSkinTypes { get; set; }
        public string? TargetConcerns { get; set; }
        public string? AvoidConcerns { get; set; }
        public string? KeyIngredients { get; set; }
        public string? IngredientNames { get; set; }
        public int HistoricalRecommendationCount { get; set; }
        public List<ProductIngredientProjection> ProductIngredients { get; set; } = [];
    }

    private sealed class ProductIngredientProjection
    {
        public Guid IngredientId { get; set; }
        public string Name { get; set; } = string.Empty;
        public string RiskLevel { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Benefits { get; set; }
        public string? SuitableSkinTypes { get; set; }
        public string? NotSuitableFor { get; set; }
        public string? Concentration { get; set; }
    }

    private sealed class IngredientProjection
    {
        public Guid Id { get; set; }
        public string Name { get; set; } = string.Empty;
        public string RiskLevel { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string? Benefits { get; set; }
        public string? SuitableSkinTypes { get; set; }
        public string? NotSuitableFor { get; set; }
    }
}
