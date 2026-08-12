using SkinSync.Helpers;
using SkinSync.Models.Dtos;
using SkinSync.Models.Entities;

namespace SkinSync.Mappers;

public static class RegimenMapper
{
    public static CurrentRegimenResponseDto ToCurrentRegimenDto(this UserRegimen regimen)
    {
        var morning = MapSteps(regimen.Items.Where(i => RoutineScheduleHelper.IsMorning(i.RoutineTime)));
        var evening = MapSteps(regimen.Items.Where(i => RoutineScheduleHelper.IsEvening(i.RoutineTime)));

        return new CurrentRegimenResponseDto
        {
            RegimenId = regimen.Id,
            Name = regimen.Name,
            StartDate = regimen.StartDate,
            EndDate = regimen.EndDate,
            IsCustom = regimen.IsCustom,
            TotalEstimatedCost = (morning.Sum(x => x.Price) ?? 0m) + (evening.Sum(x => x.Price) ?? 0m),
            Morning = morning,
            Evening = evening
        };
    }

    private static List<RegimenProductDto> MapSteps(IEnumerable<RegimenItem> items)
    {
        return UniqueItems(items)
            .OrderBy(i => i.StepOrder)
            .Select(i => new RegimenProductDto
            {
                StepId = i.Id,
                ProductId = i.ProductId,
                Name = i.Product.Name,
                Brand = i.Product.Brand,
                Category = i.Product.Category,
                Description = i.Product.Description,
                Ingredient = i.Product.Ingredient,
                UsageGuide = i.Product.UsageGuide,
                Instruction = i.Instruction,
                Purpose = BuildPurpose(i.Product.Category),
                Frequency = string.IsNullOrWhiteSpace(i.Frequency) ? "Daily" : i.Frequency,
                Caution = BuildCaution(i.Product.Ingredient),
                Price = i.Product.Price,
                ImageUrl = i.Product.ImageUrl,
                StepOrder = i.StepOrder
            })
            .ToList();
    }

    private static List<RegimenItem> UniqueItems(IEnumerable<RegimenItem> items)
    {
        var seenProductIds = new HashSet<Guid>();
        var seenProductSignatures = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var unique = new List<RegimenItem>();

        foreach (var item in items.OrderBy(i => i.StepOrder).ThenBy(i => i.CreatedAt))
        {
            var productSignature = BuildProductSignature(item);
            if (!seenProductIds.Add(item.ProductId) ||
                (!string.IsNullOrWhiteSpace(productSignature) && !seenProductSignatures.Add(productSignature)))
            {
                continue;
            }

            unique.Add(item);
        }

        return unique;
    }

    private static string BuildProductSignature(RegimenItem item)
    {
        var parts = new[]
        {
            NormalizeProductKeyPart(item.Product.Brand),
            NormalizeProductKeyPart(item.Product.Name),
            NormalizeProductKeyPart(item.Product.Category)
        };

        return parts.All(string.IsNullOrWhiteSpace)
            ? string.Empty
            : string.Join('|', parts);
    }

    private static string NormalizeProductKeyPart(string? value)
    {
        return string.Join(' ', (value ?? string.Empty)
            .Trim()
            .ToLowerInvariant()
            .Split(' ', StringSplitOptions.RemoveEmptyEntries));
    }

    private static string BuildPurpose(string category)
    {
        return category.ToLowerInvariant() switch
        {
            "cleanser" => "Remove oil, sweat, and sunscreen buildup.",
            "toner" => "Prep skin and support hydration layering.",
            "serum" => "Target focused concerns with concentrated actives.",
            "treatment" => "Address acne, texture, or pigmentation concerns.",
            "moisturizer" => "Seal in hydration and support the skin barrier.",
            "sunscreen" => "Protect skin from UV damage during the day.",
            _ => "Support your personalized skincare routine."
        };
    }

    private static string? BuildCaution(string? ingredient)
    {
        if (string.IsNullOrWhiteSpace(ingredient))
        {
            return null;
        }

        var value = ingredient.ToLowerInvariant();
        if (value.Contains("retinol") || value.Contains("aha") || value.Contains("bha"))
        {
            return "Introduce slowly and avoid stacking with other strong exfoliating actives.";
        }

        if (value.Contains("fragrance"))
        {
            return "Monitor for irritation if your skin is sensitive.";
        }

        return null;
    }
}
