using SkinSync.Models.Dtos.Products;
using SkinSync.Models.Entities;
using System.Text.Json;

namespace SkinSync.Mappers;

public static class ProductMapper
{
    public static ProductResponseDto ToDto(this Product product)
    {
        var suitableSkinTypes = ParseJsonArray(product.SuitableSkinTypes);
        var keyIngredients = ParseJsonArray(product.KeyIngredients);
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
            Ingredient = product.Ingredient,
            Ingredients = ingredients,
            UsageGuide = product.UsageGuide,
            HowToUse = product.UsageGuide,
            UsageTime = BuildUsageTime(product),
            Price = product.Price,
            Currency = string.IsNullOrWhiteSpace(product.Currency) ? "VND" : product.Currency,
            SuitableSkinTypes = suitableSkinTypes,
            SuitableFor = suitableSkinTypes,
            SkinConcerns = targetConcerns,
            KeyIngredients = keyIngredients,
            Cautions = cautions,
            Conflicts = conflicts,
            ImageUrl = product.ImageUrl,
            Rating = product.Rating,
            Status = product.Status,
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

        return ParseJsonArray(product.Ingredient);
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
            return "Evening";
        }

        return "Morning or Evening";
    }
}
