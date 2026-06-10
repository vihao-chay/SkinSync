using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SkinSync.Data;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Entities;

namespace SkinSync.Services.AIPlatform;

public interface IConflictCheckService
{
    Task<AiRoutineConflictCheckResponseDto> CheckAsync(Guid userId, AiRoutineConflictCheckRequestDto request, CancellationToken cancellationToken);
}

public class ConflictCheckService : IConflictCheckService
{
    private readonly AppDbContext _dbContext;
    private readonly IOpenAiService _openAiService;
    private readonly IAiUsageService _aiUsageService;

    private static readonly IReadOnlyDictionary<string, string[]> Synonyms = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase)
    {
        ["Retinol"] = ["retinol", "retinal", "retinaldehyde", "retinoid", "retinyl palmitate"],
        ["AHA"] = ["aha", "glycolic acid", "lactic acid", "mandelic acid", "alpha hydroxy acid"],
        ["BHA"] = ["bha", "salicylic acid", "beta hydroxy acid"],
        ["Benzoyl Peroxide"] = ["benzoyl peroxide", "bpo"],
        ["Vitamin C"] = ["vitamin c", "ascorbic acid", "l-ascorbic acid"]
    };

    public ConflictCheckService(
        AppDbContext dbContext,
        IOpenAiService openAiService,
        IAiUsageService aiUsageService)
    {
        _dbContext = dbContext;
        _openAiService = openAiService;
        _aiUsageService = aiUsageService;
    }

    public async Task<AiRoutineConflictCheckResponseDto> CheckAsync(Guid userId, AiRoutineConflictCheckRequestDto request, CancellationToken cancellationToken)
    {
        var regimen = await _dbContext.UserRegimens
            .Include(x => x.User)
            .ThenInclude(x => x.Profile)
            .Include(x => x.Items)
            .ThenInclude(x => x.Product)
            .FirstOrDefaultAsync(x => x.Id == request.RoutineId && x.UserId == userId, cancellationToken)
            ?? throw new AiFeatureException("ROUTINE_NOT_FOUND", "Routine not found.", 404);

        await _aiUsageService.CheckLimitAsync(userId, "conflict_check", cancellationToken);

        var rules = await _dbContext.IngredientConflictRules.AsNoTracking().ToListAsync(cancellationToken);
        var conflicts = DetectConflicts(regimen.Items, rules);
        if (conflicts.Count == 0)
        {
            await _aiUsageService.LogUsageAsync(userId, "conflict_check", null, null, null, cancellationToken);
            return new AiRoutineConflictCheckResponseDto
            {
                HasConflict = false,
                Conflicts = Array.Empty<AiConflictItemDto>(),
                OverallAdvice = "The routine looks acceptable based on current rule-based checks."
            };
        }

        var profileJson = AiContextMapper.SerializeUserProfile(regimen.User.Profile);
        var routineJson = JsonSerializer.Serialize(regimen.ToCurrentRegimenDto());
        var conflictsJson = JsonSerializer.Serialize(conflicts);
        var aiResult = await _openAiService.GenerateJsonAsync<AiRoutineConflictCheckResponseDto>(
            AiPromptLibrary.CommonSystemPrompt,
            AiPromptLibrary.BuildConflictPrompt(profileJson, routineJson, conflictsJson),
            cancellationToken: cancellationToken);

        await _aiUsageService.LogUsageAsync(userId, "conflict_check", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);
        aiResult.Value.HasConflict = aiResult.Value.Conflicts.Count > 0;
        return aiResult.Value;
    }

    private List<AiConflictItemDto> DetectConflicts(IEnumerable<RegimenItem> items, IEnumerable<IngredientConflictRule> rules)
    {
        var conflicts = new List<AiConflictItemDto>();
        var groupedByTime = items.GroupBy(x => x.RoutineTime, StringComparer.OrdinalIgnoreCase);
        foreach (var group in groupedByTime)
        {
            var list = group.ToList();
            for (var i = 0; i < list.Count; i++)
            {
                for (var j = i + 1; j < list.Count; j++)
                {
                    foreach (var rule in rules)
                    {
                        var ingredientA = rule.PrimaryIngredientEntity?.Name ?? rule.PrimaryIngredient;
                        var ingredientB = rule.ConflictingIngredientEntity?.Name ?? rule.ConflictingIngredient;
                        if (ContainsIngredient(list[i].Product.Ingredient, ingredientA) &&
                            ContainsIngredient(list[j].Product.Ingredient, ingredientB))
                        {
                            conflicts.Add(new AiConflictItemDto
                            {
                                IngredientA = ingredientA ?? string.Empty,
                                IngredientB = ingredientB ?? string.Empty,
                                Severity = NormalizeSeverity(rule.Severity),
                                Reason = rule.Message,
                                Recommendation = rule.Recommendation
                            });
                        }
                    }
                }
            }
        }

        return conflicts
            .GroupBy(x => $"{x.IngredientA}|{x.IngredientB}|{x.Severity}", StringComparer.OrdinalIgnoreCase)
            .Select(x => x.First())
            .ToList();
    }

    private static bool ContainsIngredient(string? ingredientText, string? target)
    {
        if (string.IsNullOrWhiteSpace(ingredientText) || string.IsNullOrWhiteSpace(target))
        {
            return false;
        }

        var normalized = ingredientText.ToLowerInvariant();
        var aliases = Synonyms.TryGetValue(target, out var values) ? values : new[] { target.ToLowerInvariant() };
        return aliases.Any(alias => normalized.Contains(alias, StringComparison.OrdinalIgnoreCase));
    }

    private static string NormalizeSeverity(string severity)
    {
        return severity.ToLowerInvariant() switch
        {
            "danger" => "high",
            "warning" => "medium",
            _ => severity.ToLowerInvariant() is "low" or "medium" or "high" ? severity.ToLowerInvariant() : "medium"
        };
    }
}
