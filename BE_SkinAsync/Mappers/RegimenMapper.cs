using SkinAsync.Models.Dtos;
using SkinAsync.Models.Entities;

namespace SkinAsync.Mappers;

public static class RegimenMapper
{
    public static CurrentRegimenResponseDto ToCurrentRegimenDto(this UserRegimen regimen)
    {
        var morning = regimen.Items
            .Where(i => i.RoutineTime.Equals("Morning", StringComparison.OrdinalIgnoreCase))
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
                Price = i.Product.Price,
                ImageUrl = i.Product.ImageUrl,
                StepOrder = i.StepOrder
            })
            .ToList();

        var evening = regimen.Items
            .Where(i => i.RoutineTime.Equals("Evening", StringComparison.OrdinalIgnoreCase))
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
                Price = i.Product.Price,
                ImageUrl = i.Product.ImageUrl,
                StepOrder = i.StepOrder
            })
            .ToList();

        return new CurrentRegimenResponseDto
        {
            RegimenId = regimen.Id,
            Name = regimen.Name,
            StartDate = regimen.StartDate,
            EndDate = regimen.EndDate,
            IsCustom = regimen.IsCustom,
            TotalEstimatedCost = morning.Sum(x => x.Price) + evening.Sum(x => x.Price),
            Morning = morning,
            Evening = evening
        };
    }
}
