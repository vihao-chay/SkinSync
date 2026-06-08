using SkinSync.Models.Dtos.Products;
using SkinSync.Models.Entities;

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
            ImageUrl = product.ImageUrl,
            Rating = product.Rating,
            Status = product.Status,
            CreatedAt = product.CreatedAt
        };
    }
}
