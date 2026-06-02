using Microsoft.EntityFrameworkCore;
using SkinAsync.Data;
using SkinAsync.Models.Dtos.Ingredients;
using SkinAsync.Models.Entities;

namespace SkinAsync.Services;

public interface IIngredientConflictService
{
    Task<IReadOnlyCollection<IngredientConflictRuleDto>> GetRulesAsync(CancellationToken cancellationToken);
    Task<IngredientConflictCheckResponseDto> CheckAsync(IEnumerable<Guid> productIds, CancellationToken cancellationToken);
}

public class IngredientConflictService : IIngredientConflictService
{
    private static readonly IReadOnlyDictionary<string, string[]> IngredientAliases = new Dictionary<string, string[]>(StringComparer.OrdinalIgnoreCase)
    {
        ["Vitamin C"] = ["vitamin c", "ascorbic acid", "l-ascorbic acid", "ascorbyl glucoside", "sodium ascorbyl phosphate"],
        ["Retinol"] = ["retinol", "retinal", "retinaldehyde", "retinoid", "retinyl palmitate"],
        ["AHA"] = ["aha", "glycolic acid", "lactic acid", "mandelic acid", "alpha hydroxy acid"],
        ["BHA"] = ["bha", "salicylic acid", "beta hydroxy acid"],
        ["Benzoyl Peroxide"] = ["benzoyl peroxide", "bpo"],
        ["Copper Peptide"] = ["copper peptide", "copper peptides", "ghk-cu"],
        ["Niacinamide"] = ["niacinamide", "nicotinamide"],
    };

    private readonly AppDbContext _dbContext;

    public IngredientConflictService(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IReadOnlyCollection<IngredientConflictRuleDto>> GetRulesAsync(CancellationToken cancellationToken)
    {
        return await _dbContext.IngredientConflictRules
            .AsNoTracking()
            .OrderBy(x => x.PrimaryIngredient)
            .ThenBy(x => x.ConflictingIngredient)
            .Select(x => new IngredientConflictRuleDto
            {
                Id = x.Id,
                PrimaryIngredient = x.PrimaryIngredient,
                ConflictingIngredient = x.ConflictingIngredient,
                Severity = x.Severity,
                Message = x.Message,
                Recommendation = x.Recommendation
            })
            .ToListAsync(cancellationToken);
    }

    public async Task<IngredientConflictCheckResponseDto> CheckAsync(
        IEnumerable<Guid> productIds,
        CancellationToken cancellationToken)
    {
        var ids = productIds
            .Where(id => id != Guid.Empty)
            .Distinct()
            .ToList();

        if (ids.Count < 2)
        {
            return new IngredientConflictCheckResponseDto
            {
                ProductCount = ids.Count,
                WarningCount = 0
            };
        }

        var products = await _dbContext.Products
            .AsNoTracking()
            .Where(x => ids.Contains(x.Id))
            .ToListAsync(cancellationToken);

        var rules = await _dbContext.IngredientConflictRules
            .AsNoTracking()
            .ToListAsync(cancellationToken);

        var warnings = new List<IngredientConflictWarningDto>();
        var seen = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        for (var i = 0; i < products.Count; i++)
        {
            for (var j = i + 1; j < products.Count; j++)
            {
                foreach (var rule in rules)
                {
                    TryAddWarning(products[i], products[j], rule, warnings, seen);
                    TryAddWarning(products[j], products[i], rule, warnings, seen);
                }
            }
        }

        return new IngredientConflictCheckResponseDto
        {
            ProductCount = products.Count,
            WarningCount = warnings.Count,
            Warnings = warnings
                .OrderByDescending(x => x.Severity.Equals("danger", StringComparison.OrdinalIgnoreCase))
                .ThenBy(x => x.ProductAName)
                .ToList()
        };
    }

    private static void TryAddWarning(
        Product productA,
        Product productB,
        IngredientConflictRule rule,
        List<IngredientConflictWarningDto> warnings,
        HashSet<string> seen)
    {
        if (!ContainsIngredient(productA.Ingredient, rule.PrimaryIngredient) ||
            !ContainsIngredient(productB.Ingredient, rule.ConflictingIngredient))
        {
            return;
        }

        var orderedIds = new[] { productA.Id, productB.Id }
            .OrderBy(id => id)
            .ToArray();
        var key = $"{rule.Id}:{orderedIds[0]}:{orderedIds[1]}";
        if (!seen.Add(key))
        {
            return;
        }

        warnings.Add(new IngredientConflictWarningDto
        {
            ProductAId = productA.Id,
            ProductAName = productA.Name,
            ProductBId = productB.Id,
            ProductBName = productB.Name,
            IngredientA = rule.PrimaryIngredient,
            IngredientB = rule.ConflictingIngredient,
            Severity = rule.Severity,
            Message = rule.Message,
            Recommendation = rule.Recommendation
        });
    }

    private static bool ContainsIngredient(string ingredientText, string target)
    {
        if (string.IsNullOrWhiteSpace(ingredientText) || string.IsNullOrWhiteSpace(target))
        {
            return false;
        }

        var normalizedText = Normalize(ingredientText);
        var aliases = IngredientAliases.TryGetValue(target, out var values)
            ? values
            : new[] { target };

        return aliases.Any(alias => normalizedText.Contains(Normalize(alias), StringComparison.OrdinalIgnoreCase));
    }

    private static string Normalize(string value)
    {
        return value.Trim().ToLowerInvariant();
    }
}
