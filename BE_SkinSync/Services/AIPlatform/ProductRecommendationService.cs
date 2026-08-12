using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Entities;

namespace SkinSync.Services.AIPlatform;

public interface IProductRecommendationService
{
    Task<AiProductRecommendResponseDto> GetLatestAsync(Guid userId, CancellationToken cancellationToken);
    Task<AiProductRecommendResponseDto> GenerateAsync(Guid userId, AiProductRecommendationGenerateRequestDto request, CancellationToken cancellationToken);
    Task MarkProductAsAlreadyInRoutineAsync(Guid userId, Guid productId, CancellationToken cancellationToken);
}

public class ProductRecommendationService : IProductRecommendationService
{
    private static readonly CategoryDefinition[] CategoryDefinitions =
    [
        new("cleanser", "Cleanser"),
        new("toner", "Toner"),
        new("serum", "Serum"),
        new("moisturizer", "Moisturizer"),
        new("sunscreen", "Sunscreen"),
        new("treatment", "Treatment"),
        new("mask", "Mask"),
    ];

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

    public async Task<AiProductRecommendResponseDto> GetLatestAsync(Guid userId, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users
            .Include(x => x.Profile)
            .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

        var profilePayload = UserProfilePayloadHelper.Parse(user.Profile?.SkinConcerns);
        var profileSummary = BuildProfileSummary(user.Profile, profilePayload);

        var latestSession = await _dbContext.ProductRecommendationSessions
            .AsNoTracking()
            .Include(x => x.Items)
            .ThenInclude(x => x.Product)
            .OrderByDescending(x => x.GeneratedAt)
            .FirstOrDefaultAsync(x => x.UserId == userId, cancellationToken);

        if (latestSession is null)
        {
            return BuildNoSessionResponse(
                profileSummary,
                "No recommendations yet. Analyze your skin, then generate product recommendations.");
        }

        return MapSessionToResponse(latestSession, profileSummary);
    }

    public async Task<AiProductRecommendResponseDto> GenerateAsync(
        Guid userId,
        AiProductRecommendationGenerateRequestDto request,
        CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users
            .Include(x => x.Profile)
            .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

        await _aiUsageService.CheckLimitAsync(userId, "product_recommendation", cancellationToken);

        var normalizedRequest = NormalizeRequest(request);
        var profilePayload = UserProfilePayloadHelper.Parse(user.Profile?.SkinConcerns);
        var profileSummary = BuildProfileSummary(user.Profile, profilePayload);

        if (!HasEnoughProfileData(user.Profile, profilePayload))
        {
            return BuildNoSessionResponse(
                profileSummary,
                "Complete your skin profile to receive personalized product recommendations.");
        }

        var latestAnalysis = await _dbContext.SkinProgressAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.DiscardedAt == null && x.Status != "discarded")
            .OrderByDescending(x => x.CompletedAt ?? x.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        if (latestAnalysis is null)
        {
            return BuildNoSessionResponse(
                profileSummary,
                "Analyze your skin first to generate product recommendations.");
        }

        var products = await _dbContext.Products
            .AsNoTracking()
            .Include(x => x.ProductIngredients)
            .Where(x => x.IsActive)
            .ToListAsync(cancellationToken);

        if (products.Count == 0)
        {
            return BuildNoSessionResponse(
                profileSummary,
                "No verified products are available for recommendation yet.");
        }

        var regimenItems = await _dbContext.RegimenItems
            .AsNoTracking()
            .Include(x => x.Product)
            .ThenInclude(x => x.ProductIngredients)
            .Where(x => x.Regimen.UserId == userId && x.Regimen.IsActive)
            .ToListAsync(cancellationToken);

        var recentLogs = await _dbContext.DailyLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.Date)
            .Take(10)
            .ToListAsync(cancellationToken);

        var conflictRules = await _dbContext.IngredientConflictRules
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        var definitions = ResolveRequestedCategories(normalizedRequest.Category).ToList();
        var categoryPayloads = new List<GeneratedCategoryPayload>();

        foreach (var definition in definitions)
        {
            var categoryProducts = products
                .Where(x => NormalizeCategoryKey(x.Category) == definition.Key)
                .ToList();

            var scored = ScoreProducts(
                    user.Profile,
                    profilePayload,
                    normalizedRequest,
                    latestAnalysis,
                    categoryProducts,
                    regimenItems,
                    recentLogs,
                    conflictRules)
                .OrderByDescending(x => x.Score)
                .ThenBy(x => x.Product.Price ?? decimal.MaxValue)
                .ToList();

            var ranked = await RankCategoryAsync(
                user,
                normalizedRequest,
                definition,
                latestAnalysis,
                scored,
                regimenItems,
                recentLogs,
                cancellationToken);

            if (ranked.Count == 0)
            {
                continue;
            }

            categoryPayloads.Add(new GeneratedCategoryPayload(
                definition.Key,
                definition.Label,
                BuildCategoryReason(definition, user.Profile, profilePayload, latestAnalysis, recentLogs),
                ranked));
        }

        if (categoryPayloads.Count == 0)
        {
            return BuildNoSessionResponse(
                profileSummary,
                "No verified products matched your current routine and skin context.");
        }

        var session = new ProductRecommendationSession
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            SourceAnalysisId = latestAnalysis.Id,
            GeneratedAt = DateTime.UtcNow,
            ExpiresAt = DateTime.UtcNow.AddDays(14),
            Status = "completed",
            Summary = BuildSessionSummary(profilePayload, latestAnalysis, recentLogs),
            CreatedAt = DateTime.UtcNow,
        };

        var items = new List<ProductRecommendationItem>();
        foreach (var category in categoryPayloads)
        {
            foreach (var ranked in category.Items.OrderBy(x => x.Rank))
            {
                if (items.Any(x => x.ProductId == ranked.Product.Id))
                {
                    continue;
                }

                items.Add(new ProductRecommendationItem
                {
                    Id = Guid.NewGuid(),
                    SessionId = session.Id,
                    ProductId = ranked.Product.Id,
                    Category = category.Key,
                    MatchPercent = NormalizeMatchScore(ranked.Score),
                    WhyRecommended = ranked.AiReason,
                    Cautions = JsonSerializer.Serialize(ranked.Warnings),
                    Rank = ranked.Rank,
                    AlreadyInRoutine = ranked.AlreadyInRoutine,
                    CreatedAt = DateTime.UtcNow,
                });
            }
        }

        session.Items = items;
        _dbContext.ProductRecommendationSessions.Add(session);
        await _dbContext.SaveChangesAsync(cancellationToken);

        var reloadedSession = await _dbContext.ProductRecommendationSessions
            .AsNoTracking()
            .Include(x => x.Items)
            .ThenInclude(x => x.Product)
            .FirstAsync(x => x.Id == session.Id, cancellationToken);

        return MapSessionToResponse(reloadedSession, profileSummary);
    }

    public async Task MarkProductAsAlreadyInRoutineAsync(Guid userId, Guid productId, CancellationToken cancellationToken)
    {
        var latestSession = await _dbContext.ProductRecommendationSessions
            .Include(x => x.Items)
            .OrderByDescending(x => x.GeneratedAt)
            .FirstOrDefaultAsync(x => x.UserId == userId, cancellationToken);

        if (latestSession is null)
        {
            return;
        }

        var changed = false;
        foreach (var item in latestSession.Items.Where(x => x.ProductId == productId && !x.AlreadyInRoutine))
        {
            item.AlreadyInRoutine = true;
            changed = true;
        }

        if (changed)
        {
            await _dbContext.SaveChangesAsync(cancellationToken);
        }
    }

    private async Task<List<RankedProduct>> RankCategoryAsync(
        User user,
        AiProductRecommendationGenerateRequestDto request,
        CategoryDefinition definition,
        SkinProgressAnalysis latestAnalysis,
        List<ScoredProduct> scored,
        IReadOnlyCollection<RegimenItem> regimenItems,
        IReadOnlyCollection<DailyLog> recentLogs,
        CancellationToken cancellationToken)
    {
        if (scored.Count == 0)
        {
            return [];
        }

        var limited = scored
            .Take(Math.Max(request.LimitPerCategory * 2, request.LimitPerCategory))
            .ToList();

        try
        {
            var aiSelection = await RankWithAiAsync(
                user,
                request,
                definition,
                latestAnalysis,
                limited,
                regimenItems,
                recentLogs,
                cancellationToken);

            if (aiSelection.Count > 0)
            {
                return aiSelection
                    .Take(request.LimitPerCategory)
                    .ToList();
            }
        }
        catch
        {
            // Fall back to deterministic scoring if AI ranking fails.
        }

        return limited
            .Take(request.LimitPerCategory)
            .Select((item, index) => new RankedProduct(
                item.Product,
                item.Score,
                item.AlreadyInRoutine,
                item.AiReason,
                item.Warnings,
                index + 1))
            .ToList();
    }

    private async Task<List<RankedProduct>> RankWithAiAsync(
        User user,
        AiProductRecommendationGenerateRequestDto request,
        CategoryDefinition definition,
        SkinProgressAnalysis latestAnalysis,
        List<ScoredProduct> scored,
        IReadOnlyCollection<RegimenItem> regimenItems,
        IReadOnlyCollection<DailyLog> recentLogs,
        CancellationToken cancellationToken)
    {
        var concern = string.IsNullOrWhiteSpace(request.Concern)
            ? InferConcern(latestAnalysis, user.Profile) ?? "latest skin concerns"
            : request.Concern!;
        var profileJson = AiContextMapper.SerializeUserProfile(user.Profile);
        var analysisJson = AiContextMapper.SerializeAnalysis(SkinAnalysisService.GetLegacyDetailFromCanonical(latestAnalysis));
        var routineJson = JsonSerializer.Serialize(regimenItems
            .OrderBy(x => x.RoutineTime)
            .ThenBy(x => x.StepOrder)
            .Select(x => new
            {
                productId = x.ProductId,
                name = x.Product.Name,
                category = x.Product.Category,
                routineTime = x.RoutineTime,
                stepOrder = x.StepOrder
            }));
        var budgetJson = JsonSerializer.Serialize(request.BudgetRange ?? new AiBudgetRangeDto());
        var candidatesJson = AiContextMapper.SerializeProducts(scored.Select(x => new
        {
            productId = x.Product.Id,
            name = x.Product.Name,
            brand = x.Product.Brand,
            category = x.Product.Category,
            price = x.Product.Price,
            currency = x.Product.Currency,
            matchScore = NormalizeMatchScore(x.Score),
            targetConcerns = JsonListHelper.ParseStringList(x.Product.TargetConcerns),
            keyIngredients = JsonListHelper.ParseStringList(x.Product.KeyIngredients),
            alreadyInRoutine = x.AlreadyInRoutine,
            cautions = x.Warnings
        }));

        var prompt = AiPromptLibrary.BuildProductRecommendationPrompt(
            profileJson,
            analysisJson,
            routineJson,
            AiContextMapper.SerializeDailyLogs(recentLogs),
            concern,
            definition.Key,
            budgetJson,
            candidatesJson);

        var aiResult = await _openAiService.GenerateJsonAsync<AiProductRecommendAiModel>(
            AiPromptLibrary.CommonSystemPrompt,
            prompt,
            cancellationToken: cancellationToken);

        await _aiUsageService.LogUsageAsync(
            user.Id,
            "product_recommendation",
            aiResult.Model,
            aiResult.InputTokens,
            aiResult.OutputTokens,
            cancellationToken);

        var scoredById = scored.ToDictionary(x => x.Product.Id, x => x);
        return aiResult.Value.RecommendedProducts
            .Select(x => new
            {
                Item = x,
                ProductId = TryParseProductId(x.ProductId)
            })
            .Where(x => x.ProductId.HasValue && scoredById.ContainsKey(x.ProductId.Value))
            .OrderBy(x => x.Item.Rank)
            .Select(x =>
            {
                var productId = x.ProductId!.Value;
                var match = scoredById[productId];
                return new RankedProduct(
                    match.Product,
                    NormalizeMatchScore(x.Item.MatchScore > 0 ? x.Item.MatchScore : match.Score),
                    match.AlreadyInRoutine,
                    string.IsNullOrWhiteSpace(x.Item.AiReason) ? match.AiReason : x.Item.AiReason,
                    x.Item.Warnings.Count == 0 ? match.Warnings : x.Item.Warnings,
                    x.Item.Rank);
            })
            .ToList();
    }

    private static Guid? TryParseProductId(string? rawProductId)
    {
        return Guid.TryParse(rawProductId, out var productId) ? productId : null;
    }

    private static AiProductRecommendationGenerateRequestDto NormalizeRequest(AiProductRecommendationGenerateRequestDto request)
    {
        request.Category = string.IsNullOrWhiteSpace(request.Category) ? "any" : request.Category.Trim();
        request.Concern = string.IsNullOrWhiteSpace(request.Concern) ? "any" : request.Concern.Trim();
        request.LimitPerCategory = request.LimitPerCategory <= 0 ? 5 : Math.Min(request.LimitPerCategory, 8);
        return request;
    }

    private static AiProductRecommendResponseDto BuildNoSessionResponse(
        AiProductRecommendationProfileSummaryDto profileSummary,
        string message)
    {
        return new AiProductRecommendResponseDto
        {
            HasRecommendation = false,
            GeneratedAt = DateTime.UtcNow,
            Status = "missing",
            ProfileSummary = profileSummary,
            Categories = CategoryDefinitions.Select(x => new AiProductRecommendationCategoryDto
            {
                Key = x.Key,
                Label = x.Label,
                Reason = string.Empty,
                Items = Array.Empty<AiRecommendedProductDto>()
            }).ToList(),
            Products = Array.Empty<AiRecommendedProductDto>(),
            Message = message,
        };
    }

    private static AiProductRecommendResponseDto MapSessionToResponse(
        ProductRecommendationSession session,
        AiProductRecommendationProfileSummaryDto profileSummary)
    {
        var itemGroups = session.Items
            .GroupBy(x => NormalizeCategoryKey(x.Category))
            .ToDictionary(x => x.Key, x => x.OrderBy(item => item.Rank).ToList());

        var categories = CategoryDefinitions
            .Select(definition =>
            {
                itemGroups.TryGetValue(definition.Key, out var group);
                var items = (group ?? [])
                    .Select(ToDto)
                    .ToList();
                return new AiProductRecommendationCategoryDto
                {
                    Key = definition.Key,
                    Label = definition.Label,
                    Reason = string.Empty,
                    Items = items
                };
            })
            .ToList();

        return new AiProductRecommendResponseDto
        {
            HasRecommendation = true,
            SessionId = session.Id,
            SourceAnalysisId = session.SourceAnalysisId,
            ExpiresAt = session.ExpiresAt,
            Status = session.Status,
            Summary = session.Summary,
            GeneratedAt = session.GeneratedAt,
            ProfileSummary = profileSummary,
            Categories = categories,
            Products = categories.SelectMany(x => x.Items).ToList(),
            Message = null,
            Note = null,
        };
    }

    private static AiRecommendedProductDto ToDto(ProductRecommendationItem item)
    {
        var cautions = JsonListHelper.ParseStringList(item.Cautions);
        return new AiRecommendedProductDto
        {
            ProductId = item.ProductId,
            Name = item.Product.Name,
            Brand = item.Product.Brand,
            Category = item.Category,
            Price = item.Product.Price,
            Currency = item.Product.Currency,
            MatchScore = item.MatchPercent,
            MatchPercent = item.MatchPercent,
            AiReason = item.WhyRecommended,
            WhyRecommended = item.WhyRecommended,
            Warnings = cautions,
            Cautions = cautions,
            AlreadyInRoutine = item.AlreadyInRoutine,
            ImageUrl = item.Product.ImageUrl,
            Description = item.Product.Description,
            IngredientsText = item.Product.Ingredient,
            UsageGuide = item.Product.UsageGuide,
        };
    }

    private static bool HasEnoughProfileData(UserProfile? profile, UserProfilePayload payload)
    {
        if (profile == null)
        {
            return false;
        }

        return !string.IsNullOrWhiteSpace(profile.SkinType) ||
               payload.Concerns.Count > 0 ||
               payload.Goals.Count > 0 ||
               !string.IsNullOrWhiteSpace(payload.BudgetLevel);
    }

    private static AiProductRecommendationProfileSummaryDto BuildProfileSummary(
        UserProfile? profile,
        UserProfilePayload payload)
    {
        return new AiProductRecommendationProfileSummaryDto
        {
            SkinType = string.IsNullOrWhiteSpace(profile?.SkinType) ? "Not provided yet" : profile!.SkinType,
            Concerns = payload.Concerns.Count == 0 ? Array.Empty<string>() : payload.Concerns,
            Budget = string.IsNullOrWhiteSpace(payload.BudgetLevel)
                ? "Not provided yet"
                : payload.BudgetLevel!,
        };
    }

    private static string BuildSessionSummary(
        UserProfilePayload payload,
        SkinProgressAnalysis latestAnalysis,
        IReadOnlyCollection<DailyLog> recentLogs)
    {
        var concern = InferConcern(latestAnalysis, null) ?? payload.Concerns.FirstOrDefault() ?? "your latest skin condition";
        if (recentLogs.Count == 0)
        {
            return $"Recommendations generated from your latest skin analysis with focus on {concern.ToLowerInvariant()}.";
        }

        return $"Recommendations refreshed from your latest skin analysis, routine, and recent check-ins with focus on {concern.ToLowerInvariant()}.";
    }

    private static IEnumerable<CategoryDefinition> ResolveRequestedCategories(string? rawCategory)
    {
        var normalized = NormalizeCategoryKey(rawCategory);
        if (string.IsNullOrWhiteSpace(normalized) || normalized == "any")
        {
            return CategoryDefinitions;
        }

        return CategoryDefinitions.Where(x => x.Key == normalized);
    }

    private static IEnumerable<ScoredProduct> ScoreProducts(
        UserProfile? profile,
        UserProfilePayload payload,
        AiProductRecommendationGenerateRequestDto request,
        SkinProgressAnalysis latestAnalysis,
        IEnumerable<Product> products,
        IReadOnlyCollection<RegimenItem> regimenItems,
        IReadOnlyCollection<DailyLog> recentLogs,
        IReadOnlyCollection<IngredientConflictRule> conflictRules)
    {
        var concerns = payload.Concerns;
        var goals = payload.Goals.Count > 0 ? payload.Goals : payload.SkinGoals;
        var allergies = JsonListHelper.ParseStringList(profile?.Allergies);
        var sensitiveIngredients = JsonListHelper.ParseStringList(profile?.SensitiveIngredients);
        var skinType = profile?.SkinType ?? string.Empty;
        var routineProductIds = regimenItems.Select(x => x.ProductId).ToHashSet();
        var routineIngredientIds = regimenItems
            .SelectMany(x => x.Product.ProductIngredients)
            .Select(x => x.IngredientId)
            .ToHashSet();
        var budgetCap = request.BudgetRange?.Max ?? profile?.MonthlyBudget;
        var latestLog = recentLogs.FirstOrDefault();
        var inferredConcern = InferConcern(latestAnalysis, profile);

        foreach (var product in products)
        {
            var warnings = new List<string>();
            var score = 50;
            var suitableSkinTypes = JsonListHelper.ParseStringList(product.SuitableSkinTypes);
            var targetConcerns = JsonListHelper.ParseStringList(product.TargetConcerns);
            var avoidConcerns = JsonListHelper.ParseStringList(product.AvoidForConcerns);
            var keyIngredients = JsonListHelper.ParseStringList(product.KeyIngredients);
            var ingredientText = product.Ingredient ?? string.Empty;
            var normalizedCategory = NormalizeCategoryKey(product.Category);
            var alreadyInRoutine = routineProductIds.Contains(product.Id);

            if (alreadyInRoutine)
            {
                score -= 18;
                warnings.Add("Already in your current routine.");
            }

            if (suitableSkinTypes.Contains(skinType, StringComparer.OrdinalIgnoreCase))
            {
                score += 14;
            }

            if (targetConcerns.Any(c => concerns.Contains(c, StringComparer.OrdinalIgnoreCase)))
            {
                score += 16;
            }

            if (!string.IsNullOrWhiteSpace(inferredConcern) &&
                targetConcerns.Contains(inferredConcern, StringComparer.OrdinalIgnoreCase))
            {
                score += 14;
            }

            if (goals.Any(goal => product.Description?.Contains(goal, StringComparison.OrdinalIgnoreCase) == true ||
                                  keyIngredients.Any(i => goal.Contains(i, StringComparison.OrdinalIgnoreCase))))
            {
                score += 8;
            }

            if (budgetCap is decimal budget && budget > 0)
            {
                if (product.Price <= budget)
                {
                    score += 10;
                }
                else
                {
                    score -= 8;
                }
            }

            if (request.Category != "any" &&
                NormalizeCategoryKey(request.Category) == normalizedCategory)
            {
                score += 6;
            }

            if (avoidConcerns.Any(c => concerns.Contains(c, StringComparer.OrdinalIgnoreCase)))
            {
                score -= 18;
                warnings.Add("May not be ideal for one of your listed concerns.");
            }

            if (allergies.Any(c => ingredientText.Contains(c, StringComparison.OrdinalIgnoreCase)) ||
                sensitiveIngredients.Any(c => ingredientText.Contains(c, StringComparison.OrdinalIgnoreCase)))
            {
                score -= 22;
                warnings.Add("Contains ingredients that may not suit your sensitivity profile.");
            }

            if ((latestAnalysis.RednessScore >= 60 || (latestLog?.RednessLevel ?? 0) >= 3) &&
                ingredientText.Contains("acid", StringComparison.OrdinalIgnoreCase))
            {
                score -= 10;
                warnings.Add("Recent redness suggests patch testing first.");
            }

            if ((latestAnalysis.AcneScore >= 60 || (latestLog?.AcneLevel ?? 0) >= 3) &&
                normalizedCategory is "cleanser" or "treatment" or "serum")
            {
                score += 6;
            }

            if ((latestAnalysis.DrynessScore >= 55 || (latestLog?.HydrationLevel ?? 0) <= 2) &&
                normalizedCategory is "moisturizer" or "serum" or "mask")
            {
                score += 6;
            }

            var candidateIngredientIds = product.ProductIngredients
                .Select(x => x.IngredientId)
                .ToHashSet();

            if (HasIngredientConflict(candidateIngredientIds, routineIngredientIds, conflictRules))
            {
                score -= 16;
                warnings.Add("May conflict with ingredients in your current routine.");
            }

            score = Math.Clamp(score, 0, 99);

            yield return new ScoredProduct(
                product,
                score,
                alreadyInRoutine,
                BuildAiReason(product, concerns, goals, latestAnalysis, latestLog),
                warnings);
        }
    }

    private static bool HasIngredientConflict(
        HashSet<Guid> candidateIngredientIds,
        HashSet<Guid> routineIngredientIds,
        IReadOnlyCollection<IngredientConflictRule> conflictRules)
    {
        if (candidateIngredientIds.Count == 0 || routineIngredientIds.Count == 0)
        {
            return false;
        }

        return conflictRules.Any(rule =>
            rule.PrimaryIngredientId.HasValue &&
            rule.ConflictingIngredientId.HasValue &&
            ((candidateIngredientIds.Contains(rule.PrimaryIngredientId.Value) &&
              routineIngredientIds.Contains(rule.ConflictingIngredientId.Value)) ||
             (candidateIngredientIds.Contains(rule.ConflictingIngredientId.Value) &&
              routineIngredientIds.Contains(rule.PrimaryIngredientId.Value))));
    }

    private static int NormalizeMatchScore(int score) => Math.Clamp(score, 0, 99);

    private static string BuildCategoryReason(
        CategoryDefinition definition,
        UserProfile? profile,
        UserProfilePayload payload,
        SkinProgressAnalysis latestAnalysis,
        IReadOnlyCollection<DailyLog> recentLogs)
    {
        var concern = InferConcern(latestAnalysis, profile) ?? payload.Concerns.FirstOrDefault();
        var skinType = string.IsNullOrWhiteSpace(profile?.SkinType) ? "your skin" : $"{profile!.SkinType.ToLowerInvariant()} skin";
        if (concern != null)
        {
            return $"{definition.Label} picks tuned for {skinType} with extra focus on {concern.ToLowerInvariant()}.";
        }

        if (recentLogs.Count == 0)
        {
            return $"{definition.Label} picks based on your skin profile and latest analysis.";
        }

        return $"{definition.Label} picks shaped by your skin profile, active routine, latest analysis, and recent check-ins.";
    }

    private static string BuildAiReason(
        Product product,
        IReadOnlyCollection<string> concerns,
        IReadOnlyCollection<string> goals,
        SkinProgressAnalysis latestAnalysis,
        DailyLog? latestLog)
    {
        var concern = concerns.FirstOrDefault() ?? InferConcern(latestAnalysis, null);
        if (concern != null)
        {
            return $"Supports {concern.ToLowerInvariant()} care while fitting your current skin profile.";
        }

        var goal = goals.FirstOrDefault();
        if (goal != null)
        {
            return $"A strong fit for your goal to {goal.ToLowerInvariant()}.";
        }

        if ((latestAnalysis.DrynessScore >= 55 || (latestLog?.HydrationLevel ?? 0) <= 2) &&
            NormalizeCategoryKey(product.Category) is "moisturizer" or "serum" or "mask")
        {
            return "Helps support hydration based on your latest analysis and recent skin check-ins.";
        }

        return "Recommended from verified catalog data for your latest skin analysis, routine, and skin profile.";
    }

    private static string? InferConcern(SkinProgressAnalysis latestAnalysis, UserProfile? profile)
    {
        var detected = SkinProgressMapper.ParseConcernArray(latestAnalysis.DetectedConcerns);
        var concern = detected
            .OrderByDescending(x => x.Score)
            .Select(x => x.Label)
            .FirstOrDefault();

        if (!string.IsNullOrWhiteSpace(concern))
        {
            return concern;
        }

        return profile?.SkinType;
    }

    private static string NormalizeCategoryKey(string? value)
    {
        var normalized = (value ?? string.Empty).Trim().ToLowerInvariant();
        return normalized switch
        {
            "sua rua mat" => "cleanser",
            "moisturiser" => "moisturizer",
            "kem duong" => "moisturizer",
            "kem chong nang" => "sunscreen",
            "optional" => "mask",
            _ => normalized,
        };
    }

    private sealed record CategoryDefinition(string Key, string Label);

    private sealed record ScoredProduct(
        Product Product,
        int Score,
        bool AlreadyInRoutine,
        string AiReason,
        List<string> Warnings);

    private sealed record RankedProduct(
        Product Product,
        int Score,
        bool AlreadyInRoutine,
        string AiReason,
        List<string> Warnings,
        int Rank);

    private sealed record GeneratedCategoryPayload(
        string Key,
        string Label,
        string Reason,
        List<RankedProduct> Items);
}

internal sealed class AiProductRecommendAiModel
{
    public List<AiRecommendedProductAiModel> RecommendedProducts { get; set; } = [];
}

internal sealed class AiRecommendedProductAiModel
{
    public string ProductId { get; set; } = string.Empty;
    public int Rank { get; set; }
    public int MatchScore { get; set; }
    public string AiReason { get; set; } = string.Empty;
    public List<string> Warnings { get; set; } = [];
}
