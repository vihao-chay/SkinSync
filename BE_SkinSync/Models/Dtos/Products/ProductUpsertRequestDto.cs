using System.ComponentModel.DataAnnotations;

namespace SkinSync.Models.Dtos.Products;

public class ProductUpsertRequestDto
{
    [Required]
    [MaxLength(255)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [MaxLength(150)]
    public string Brand { get; set; } = string.Empty;

    [Required]
    [MaxLength(50)]
    public string Category { get; set; } = string.Empty;

    public string? Description { get; set; }
    public string? Ingredient { get; set; }
    public string? UsageGuide { get; set; }
    public string Currency { get; set; } = "VND";

    [Range(0, 999999)]
    public decimal Price { get; set; }

    public IReadOnlyCollection<string> SuitableSkinTypes { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> SkinConcerns { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> KeyIngredients { get; set; } = Array.Empty<string>();
    public string? ImageUrl { get; set; }

    [Range(0, 5)]
    public decimal? Rating { get; set; }

    [MaxLength(20)]
    public string Status { get; set; } = "active";
}
