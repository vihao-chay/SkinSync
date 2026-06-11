using SkinSync.Models.Dtos.Products;
using SkinSync.Models.Entities;
using System.Text.Json;

namespace SkinSync.Mappers;

public static class ProductMapper
{
    public static ProductResponseDto ToDto(this Product product)
    {
        return new ProductResponseDto
        {
            Id = product.Id,
            Name = product.Name,
            Brand = product.Brand,
            Category = product.Category,
            Description = product.Description,
            Ingredient = product.Ingredient,
            UsageGuide = product.UsageGuide,
            Price = product.Price,
            SuitableSkinTypes = product.SuitableSkinTypes,
            SuitableFor = ParseJsonArray(product.SuitableSkinTypes),
            ImageUrl = product.ImageUrl,
            Rating = product.Rating,
            Status = product.Status,
            CreatedAt = product.CreatedAt
        };
    }

    private static IReadOnlyCollection<string> ParseJsonArray(string? value)
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
}
