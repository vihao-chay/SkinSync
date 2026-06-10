using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Mappers;
using SkinSync.Models.Dtos;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Dtos.Analysis;
using SkinSync.Models.Entities;

namespace SkinSync.Services.AIPlatform;

public interface IRoutineGenerationService
{
    Task<AiRoutineGenerateResponseDto> GenerateAsync(Guid userId, AiRoutineGenerateRequestDto request, CancellationToken cancellationToken);
}

public class RoutineGenerationService : IRoutineGenerationService
{
    private readonly AppDbContext _dbContext;
    private readonly IOpenAiService _openAiService;
    private readonly IAiUsageService _aiUsageService;
    private readonly ILogger<RoutineGenerationService> _logger;

    public RoutineGenerationService(
        AppDbContext dbContext,
        IOpenAiService openAiService,
        IAiUsageService aiUsageService,
        ILogger<RoutineGenerationService> logger)
    {
        _dbContext = dbContext;
        _openAiService = openAiService;
        _aiUsageService = aiUsageService;
        _logger = logger;
    }

    public async Task<AiRoutineGenerateResponseDto> GenerateAsync(Guid userId, AiRoutineGenerateRequestDto request, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users.Include(x => x.Profile).FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

        var latestAnalysis = await _dbContext.AiAnalyses
            .AsNoTracking()
            .Include(x => x.AnalysisIssues)
            .Include(x => x.Recommendations)
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);
        if (latestAnalysis is null)
        {
            throw new AiFeatureException("ANALYSIS_REQUIRED", "Latest analysis is required before generating a routine.", 400);
        }

        await _aiUsageService.CheckLimitAsync(userId, "routine_generation", cancellationToken);

        var candidates = await _dbContext.Products
            .AsNoTracking()
            .Where(x => x.Status == "active")
            .ToListAsync(cancellationToken);

        var preference = NormalizeRoutinePreference(request.RoutinePreference, user.Profile?.RoutinePreference);
        var scoredCandidates = ScoreProducts(user.Profile, request.BudgetRange, candidates, latestAnalysis.ToDetailDto())
            .Take(20)
            .ToList();
        if (scoredCandidates.Count == 0)
        {
            throw new AiFeatureException("NO_PRODUCTS", "No suitable products found for routine generation.", 400);
        }

        var profileJson = AiContextMapper.SerializeUserProfile(user.Profile);
        var analysisJson = AiContextMapper.SerializeAnalysis(latestAnalysis.ToDetailDto());
        var productsJson = AiContextMapper.SerializeProducts(scoredCandidates.Select(x => new
        {
            productId = x.Product.Id,
            name = x.Product.Name,
            brand = x.Product.Brand,
            category = x.Product.Category,
            price = x.Product.Price,
            currency = x.Product.Currency,
            suitableSkinTypes = JsonListHelper.ParseStringList(x.Product.SuitableSkinTypes),
            targetConcerns = JsonListHelper.ParseStringList(x.Product.TargetConcerns),
            keyIngredients = JsonListHelper.ParseStringList(x.Product.KeyIngredients),
            usageGuide = x.Product.UsageGuide,
            matchScore = x.Score
        }));
        var budgetJson = JsonSerializer.Serialize(request.BudgetRange ?? new AiBudgetRangeDto());
        var userPrompt = AiPromptLibrary.BuildRoutinePrompt(profileJson, analysisJson, productsJson, budgetJson, preference);

        OpenAiResult<AiRoutineAiModel> aiResult;
        try
        {
            aiResult = await _openAiService.GenerateJsonAsync<AiRoutineAiModel>(
                AiPromptLibrary.CommonSystemPrompt,
                userPrompt,
                model: null,
                cancellationToken: cancellationToken);
        }
        catch (Exception ex) when (ex is not AiFeatureException)
        {
            _logger.LogError(ex, "Routine generation failed for user {UserId}.", userId);
            throw new AiFeatureException("AI_SERVICE_ERROR", "Routine generation failed.", 502, ex);
        }

        var allowedProductIds = scoredCandidates.Select(x => x.Product.Id).ToHashSet();
        ValidateRoutineProducts(aiResult.Value, allowedProductIds);

        var regimen = BuildRegimen(userId, latestAnalysis.Id, aiResult.Value, scoredCandidates.Select(x => x.Product).ToDictionary(x => x.Id));
        await DeactivateCurrentRegimens(userId, cancellationToken);
        _dbContext.UserRegimens.Add(regimen);
        await _dbContext.SaveChangesAsync(cancellationToken);
        await _aiUsageService.LogUsageAsync(userId, "routine_generation", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);

        var warnings = aiResult.Value.Morning.Concat(aiResult.Value.Night)
            .Select(x => x.Warning)
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x!)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        return new AiRoutineGenerateResponseDto
        {
            RoutineId = regimen.Id,
            RoutineName = regimen.Name,
            Morning = MapSteps(aiResult.Value.Morning, scoredCandidates),
            Night = MapSteps(aiResult.Value.Night, scoredCandidates),
            Warnings = warnings,
            MissingCategories = aiResult.Value.MissingCategories,
            OverallAdvice = aiResult.Value.OverallAdvice
        };
    }

    private static string NormalizeRoutinePreference(string? requestValue, string? profileValue)
    {
        var value = (requestValue ?? profileValue ?? "balanced").Trim().ToLowerInvariant();
        return value is "simple" or "balanced" or "advanced" ? value : "balanced";
    }

    private static List<ScoredProduct> ScoreProducts(UserProfile? profile, AiBudgetRangeDto? budget, IEnumerable<Product> products, AnalysisDetailResponseDto analysis)
    {
        var concerns = UserProfilePayloadHelper.Parse(profile?.SkinConcerns).Concerns;
        var allergies = JsonListHelper.ParseStringList(profile?.Allergies);
        var sensitiveIngredients = JsonListHelper.ParseStringList(profile?.SensitiveIngredients);
        var skinType = profile?.SkinType ?? "unknown";

        return products
            .Select(product =>
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

                if (targetConcerns.Any(concern => concerns.Contains(concern, StringComparer.OrdinalIgnoreCase)))
                {
                    score += 3;
                }

                if (budget?.Max is decimal maxBudget && product.Price <= maxBudget)
                {
                    score += 2;
                }

                if (keyIngredients.Any())
                {
                    score += 1;
                }

                if (avoidConcerns.Any(concern => concerns.Contains(concern, StringComparer.OrdinalIgnoreCase)))
                {
                    score -= 4;
                }

                if (allergies.Any(allergy => ingredientText.Contains(allergy, StringComparison.OrdinalIgnoreCase)) ||
                    sensitiveIngredients.Any(item => ingredientText.Contains(item, StringComparison.OrdinalIgnoreCase)))
                {
                    score -= 5;
                }

                if (string.Equals(skinType, "sensitive", StringComparison.OrdinalIgnoreCase) &&
                    ingredientText.Contains("fragrance", StringComparison.OrdinalIgnoreCase))
                {
                    score -= 2;
                }

                score += analysis.Issues.Count(issue => targetConcerns.Contains(issue.IssueType, StringComparer.OrdinalIgnoreCase));
                return new ScoredProduct(product, score);
            })
            .Where(x => x.Score > -3)
            .OrderByDescending(x => x.Score)
            .ThenBy(x => x.Product.Price)
            .ToList();
    }

    private static void ValidateRoutineProducts(AiRoutineAiModel model, HashSet<Guid> allowedProductIds)
    {
        var allProductIds = model.Morning.Concat(model.Night).Select(x => x.ProductId).Where(x => x != Guid.Empty).ToList();
        if (allProductIds.Count == 0)
        {
            throw new AiFeatureException("AI_SERVICE_ERROR", "AI did not return any routine steps.", 502);
        }

        if (allProductIds.Any(id => !allowedProductIds.Contains(id)))
        {
            throw new AiFeatureException("AI_SERVICE_ERROR", "AI returned products outside the candidate list.", 502);
        }
    }

    private static UserRegimen BuildRegimen(Guid userId, Guid analysisId, AiRoutineAiModel model, Dictionary<Guid, Product> products)
    {
        var regimenId = Guid.NewGuid();
        var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);
        var regimen = new UserRegimen
        {
            Id = regimenId,
            UserId = userId,
            AnalysisId = analysisId,
            Name = string.IsNullOrWhiteSpace(model.RoutineName) ? "AI generated routine" : model.RoutineName.Trim(),
            StartDate = today,
            EndDate = today.AddDays(30),
            IsActive = true,
            IsCustom = false,
            Source = "ai"
        };

        regimen.Items = model.Morning
            .Select(step => BuildRegimenItem(regimenId, "Morning", step, products[step.ProductId]))
            .Concat(model.Night.Select(step => BuildRegimenItem(regimenId, "Evening", step, products[step.ProductId])))
            .ToList();

        return regimen;
    }

    private static RegimenItem BuildRegimenItem(Guid regimenId, string routineTime, AiRoutineStepAiModel step, Product product)
    {
        return new RegimenItem
        {
            Id = Guid.NewGuid(),
            RegimenId = regimenId,
            ProductId = step.ProductId,
            Product = product,
            RoutineTime = routineTime,
            StepOrder = step.StepOrder,
            Frequency = step.Frequency,
            Instruction = string.IsNullOrWhiteSpace(step.Instruction) ? product.UsageGuide : step.Instruction
        };
    }

    private async Task DeactivateCurrentRegimens(Guid userId, CancellationToken cancellationToken)
    {
        var current = await _dbContext.UserRegimens.Where(x => x.UserId == userId && x.IsActive).ToListAsync(cancellationToken);
        foreach (var regimen in current)
        {
            regimen.IsActive = false;
            regimen.UpdatedAt = DateTime.UtcNow;
        }
    }

    private static IReadOnlyCollection<AiRoutineStepDto> MapSteps(IEnumerable<AiRoutineStepAiModel> steps, IEnumerable<ScoredProduct> scoredProducts)
    {
        var map = scoredProducts.ToDictionary(x => x.Product.Id, x => x.Product);
        return steps.Select(step =>
        {
            var product = map[step.ProductId];
            return new AiRoutineStepDto
            {
                StepOrder = step.StepOrder,
                StepName = step.StepName,
                ProductId = step.ProductId,
                ProductName = product.Name,
                Frequency = step.Frequency,
                Instruction = step.Instruction,
                AiReason = step.AiReason,
                Warning = step.Warning
            };
        }).ToList();
    }

    private sealed record ScoredProduct(Product Product, int Score);
}

internal sealed class AiRoutineAiModel
{
    public string RoutineName { get; set; } = string.Empty;
    public List<AiRoutineStepAiModel> Morning { get; set; } = [];
    public List<AiRoutineStepAiModel> Night { get; set; } = [];
    public List<string> MissingCategories { get; set; } = [];
    public string? OverallAdvice { get; set; }
}

internal sealed class AiRoutineStepAiModel
{
    public int StepOrder { get; set; }
    public string StepName { get; set; } = string.Empty;
    public Guid ProductId { get; set; }
    public string Frequency { get; set; } = "daily";
    public string Instruction { get; set; } = string.Empty;
    public string AiReason { get; set; } = string.Empty;
    public string? Warning { get; set; }
}
