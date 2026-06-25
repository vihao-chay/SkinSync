using SkinSync.Models.Dtos.Products;
using SkinSync.Models.Entities;
using System.Text.Json;

namespace SkinSync.Mappers;

public static class ProductMapper
{
    public static ProductResponseDto ToDto(this Product product)
    {
        var suitableSkinTypes = ParseJsonArray(product.SuitableSkinTypes);
        var targetConcerns = ParseJsonArray(product.TargetConcerns);
        var ingredients = ExtractIngredients(product);
        var cautions = BuildCautions(product, ingredients);
        var conflicts = BuildConflicts(product, ingredients);

        return new ProductResponseDto
        {
            Id = product.Id,
            Name = product.Name,
            Brand = product.Brand,
            Category = product.Category,
            Description = product.Description,
            IngredientsText = ingredients.Count > 0
                ? string.Join(", ", ingredients)
                : product.Ingredient ?? string.Empty,
            Ingredients = ingredients,
            HowToUse = string.IsNullOrWhiteSpace(product.UsageGuide) ? null : product.UsageGuide,
            UsageTime = string.IsNullOrWhiteSpace(product.UsageTime) ? BuildUsageTime(product) : product.UsageTime,
            Price = product.Price,
            Currency = product.Currency ?? string.Empty,
            SkinTypes = suitableSkinTypes,
            SkinConcerns = targetConcerns,
            Cautions = cautions,
            Conflicts = conflicts,
            ImageUrl = product.ImageUrl,
            IsVerified = product.IsVerified,
            IsActive = product.IsActive,
            Source = product.Source ?? string.Empty,
            SourceUrl = product.SourceUrl,
            CreatedAt = product.CreatedAt,
            UpdatedAt = product.UpdatedAt
        };
    }

    public static string SerializeStringList(IEnumerable<string>? values)
    {
        if (values is null)
        {
            return "[]";
        }

        var normalized = values
            .Select(x => x?.Trim())
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Cast<string>()
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        return JsonSerializer.Serialize(normalized);
    }

    public static IReadOnlyCollection<string> ParseJsonArray(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return Array.Empty<string>();
        }

        try
        {
            return JsonSerializer.Deserialize<string[]>(value) ?? Array.Empty<string>();
        }
        catch (JsonException)
        {
            return value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        }
    }

    public static string SerializeDelimitedList(string? value, char separator = ',')
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return "[]";
        }

        var normalized = value
            .Split(separator, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(item => !string.IsNullOrWhiteSpace(item))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        return JsonSerializer.Serialize(normalized);
    }

    public static string SerializeKeyIngredients(string? ingredientText, int maxItems = 8)
    {
        if (string.IsNullOrWhiteSpace(ingredientText))
        {
            return "[]";
        }

        var normalized = ingredientText
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(item => item.Trim())
            .Where(item => !string.IsNullOrWhiteSpace(item))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(maxItems)
            .ToArray();

        return JsonSerializer.Serialize(normalized);
    }

    public static string SerializeIngredients(string? ingredientText)
    {
        if (string.IsNullOrWhiteSpace(ingredientText))
        {
            return "[]";
        }

        var normalized = ingredientText
            .Split([',', ';', '\n', '\r'], StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(item => item.Trim())
            .Where(item => !string.IsNullOrWhiteSpace(item))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        return JsonSerializer.Serialize(normalized);
    }

    private static IReadOnlyCollection<string> ExtractIngredients(Product product)
    {
        if (product.ProductIngredients.Count > 0)
        {
            return product.ProductIngredients
                .Select(x => x.Ingredient?.Name?.Trim())
                .Where(x => !string.IsNullOrWhiteSpace(x))
                .Cast<string>()
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToArray();
        }

        var parsed = ParseJsonArray(product.Ingredient);
        if (parsed.Count > 0)
        {
            return parsed;
        }

        return (product.Ingredient ?? string.Empty)
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Where(item => !string.IsNullOrWhiteSpace(item))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }

    private static IReadOnlyCollection<string> BuildCautions(Product product, IReadOnlyCollection<string> ingredients)
    {
        var cautions = new List<string>();
        var normalizedIngredientText = (product.Ingredient ?? string.Empty).ToLowerInvariant();

        if (ingredients.Any(x => x.Contains("retinol", StringComparison.OrdinalIgnoreCase)) ||
            normalizedIngredientText.Contains("retinol"))
        {
            cautions.Add("Avoid layering with other strong actives until your skin adjusts.");
        }

        if (ingredients.Any(x => x.Contains("aha", StringComparison.OrdinalIgnoreCase) ||
                                 x.Contains("bha", StringComparison.OrdinalIgnoreCase) ||
                                 x.Contains("salicylic", StringComparison.OrdinalIgnoreCase) ||
                                 x.Contains("glycolic", StringComparison.OrdinalIgnoreCase)) ||
            normalizedIngredientText.Contains("aha") ||
            normalizedIngredientText.Contains("bha") ||
            normalizedIngredientText.Contains("salicylic") ||
            normalizedIngredientText.Contains("glycolic"))
        {
            cautions.Add("Patch test first and introduce slowly if your skin is sensitive.");
        }

        if (normalizedIngredientText.Contains("fragrance"))
        {
            cautions.Add("May irritate sensitive skin.");
        }

        return cautions.Distinct(StringComparer.OrdinalIgnoreCase).ToArray();
    }

    private static IReadOnlyCollection<string> BuildConflicts(Product product, IReadOnlyCollection<string> ingredients)
    {
        var conflicts = new List<string>();
        var normalizedIngredientText = (product.Ingredient ?? string.Empty).ToLowerInvariant();

        var hasRetinoid = ingredients.Any(x => x.Contains("retinol", StringComparison.OrdinalIgnoreCase)) ||
                          normalizedIngredientText.Contains("retinol");
        var hasVitaminC = ingredients.Any(x => x.Contains("vitamin c", StringComparison.OrdinalIgnoreCase) ||
                                               x.Contains("ascorbic", StringComparison.OrdinalIgnoreCase)) ||
                          normalizedIngredientText.Contains("vitamin c") ||
                          normalizedIngredientText.Contains("ascorbic");
        var hasExfoliant = ingredients.Any(x => x.Contains("aha", StringComparison.OrdinalIgnoreCase) ||
                                                x.Contains("bha", StringComparison.OrdinalIgnoreCase) ||
                                                x.Contains("salicylic", StringComparison.OrdinalIgnoreCase) ||
                                                x.Contains("glycolic", StringComparison.OrdinalIgnoreCase)) ||
                          normalizedIngredientText.Contains("aha") ||
                          normalizedIngredientText.Contains("bha") ||
                          normalizedIngredientText.Contains("salicylic") ||
                          normalizedIngredientText.Contains("glycolic");

        if (hasRetinoid)
        {
            conflicts.Add("Avoid combining with strong exfoliants or benzoyl peroxide in the same routine.");
        }

        if (hasVitaminC)
        {
            conflicts.Add("Be careful when layering with exfoliating acids in the same routine.");
        }

        if (hasExfoliant)
        {
            conflicts.Add("Avoid pairing with retinoids in the same routine unless your skin already tolerates it.");
        }

        return conflicts.Distinct(StringComparer.OrdinalIgnoreCase).ToArray();
    }

    private static string BuildUsageTime(Product product)
    {
        var category = (product.Category ?? string.Empty).Trim().ToLowerInvariant();
        var ingredientText = (product.Ingredient ?? string.Empty).ToLowerInvariant();

        if (category.Contains("sunscreen") || ingredientText.Contains("spf"))
        {
            return "Morning";
        }

        if (ingredientText.Contains("retinol") || ingredientText.Contains("retinal"))
        {
            return "Night";
        }

        return "Both";
    }
}
