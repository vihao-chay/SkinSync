using Microsoft.EntityFrameworkCore;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Models.Dtos.AI;

namespace SkinSync.Services.AIPlatform;

public interface IIngredientCheckService
{
    Task<AiIngredientCheckResponseDto> CheckAsync(Guid userId, AiIngredientCheckRequestDto request, CancellationToken cancellationToken);
}

public class IngredientCheckService : IIngredientCheckService
{
    private readonly AppDbContext _dbContext;
    private readonly IOpenAiService _openAiService;
    private readonly IAiUsageService _aiUsageService;

    public IngredientCheckService(
        AppDbContext dbContext,
        IOpenAiService openAiService,
        IAiUsageService aiUsageService)
    {
        _dbContext = dbContext;
        _openAiService = openAiService;
        _aiUsageService = aiUsageService;
    }

    public async Task<AiIngredientCheckResponseDto> CheckAsync(Guid userId, AiIngredientCheckRequestDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.IngredientsText))
        {
            throw new AiFeatureException("INVALID_REQUEST", "ingredientsText is required.");
        }

        var user = await _dbContext.Users.Include(x => x.Profile).FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

        await _aiUsageService.CheckLimitAsync(userId, "ingredient_check", cancellationToken);

        var ingredients = request.IngredientsText
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(x => x.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
        var profileJson = AiContextMapper.SerializeUserProfile(user.Profile);
        var aiResult = await _openAiService.GenerateJsonAsync<AiIngredientCheckResponseDto>(
            AiPromptLibrary.CommonSystemPrompt,
            AiPromptLibrary.BuildIngredientCheckPrompt(profileJson, request.ProductName, AiContextMapper.SerializeList(ingredients)),
            cancellationToken: cancellationToken);

        var allergies = JsonListHelper.ParseStringList(user.Profile?.Allergies);
        var sensitive = JsonListHelper.ParseStringList(user.Profile?.SensitiveIngredients);
        var warnings = aiResult.Value.Warnings.ToList();

        if (ingredients.Any(i => allergies.Contains(i, StringComparer.OrdinalIgnoreCase)))
        {
            warnings.Add("This product includes an ingredient listed in the user's allergy profile.");
            aiResult.Value.Suitability = "not_recommended";
        }

        if (ingredients.Any(i => sensitive.Contains(i, StringComparer.OrdinalIgnoreCase)) &&
            !string.Equals(aiResult.Value.Suitability, "not_recommended", StringComparison.OrdinalIgnoreCase))
        {
            warnings.Add("This product contains a user-sensitive ingredient. Introduce it cautiously.");
            aiResult.Value.Suitability = "caution";
        }

        aiResult.Value.Warnings = warnings.Distinct(StringComparer.OrdinalIgnoreCase).ToList();
        await _aiUsageService.LogUsageAsync(userId, "ingredient_check", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);
        return aiResult.Value;
    }
}
