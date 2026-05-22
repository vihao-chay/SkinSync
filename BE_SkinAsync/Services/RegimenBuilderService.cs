using SkinAsync.Models.Entities;

namespace SkinAsync.Services;

public interface IRegimenBuilderService
{
    UserRegimen BuildRegimen(Guid userId, Guid analysisId, string skinType, IReadOnlyCollection<Product> products);
}

public class RegimenBuilderService : IRegimenBuilderService
{
    private static readonly string[] MorningCategories = ["Cleanser", "Toner", "Serum", "Sunscreen"];
    private static readonly string[] EveningCategories = ["Cleanser", "Toner", "Serum", "Moisturizer"];

    public UserRegimen BuildRegimen(Guid userId, Guid analysisId, string skinType, IReadOnlyCollection<Product> products)
    {
        var filtered = products
            .Where(p => string.Equals(p.Status, "active", StringComparison.OrdinalIgnoreCase))
            .Where(p => p.SuitableSkinTypes.Any(s => s.Equals(skinType, StringComparison.OrdinalIgnoreCase))
                || p.SuitableSkinTypes.Any(s => s.Equals("All", StringComparison.OrdinalIgnoreCase)))
            .ToList();

        var regimen = new UserRegimen
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            AnalysisId = analysisId,
            Name = "Lộ trình AI đề xuất",
            StartDate = DateOnly.FromDateTime(DateTime.UtcNow),
            EndDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(30)),
            IsActive = true,
            IsCustom = false
        };

        regimen.Items = BuildItems(regimen.Id, filtered);
        return regimen;
    }

    private static List<RegimenItem> BuildItems(Guid regimenId, List<Product> products)
    {
        var result = new List<RegimenItem>();
        result.AddRange(BuildByTime(regimenId, "Morning", MorningCategories, products));
        result.AddRange(BuildByTime(regimenId, "Evening", EveningCategories, products));
        return result;
    }

    private static IEnumerable<RegimenItem> BuildByTime(Guid regimenId, string routineTime, IEnumerable<string> categories, List<Product> products)
    {
        var step = 1;
        foreach (var category in categories)
        {
            var product = products.FirstOrDefault(p => p.Category.Equals(category, StringComparison.OrdinalIgnoreCase));
            if (product is null)
            {
                continue;
            }

            yield return new RegimenItem
            {
                Id = Guid.NewGuid(),
                RegimenId = regimenId,
                ProductId = product.Id,
                RoutineTime = routineTime,
                StepOrder = step,
                Instruction = string.IsNullOrWhiteSpace(product.UsageGuide)
                    ? $"Sử dụng theo hướng dẫn cho bước {category.ToLowerInvariant()}."
                    : product.UsageGuide
            };

            step++;
        }
    }
}
