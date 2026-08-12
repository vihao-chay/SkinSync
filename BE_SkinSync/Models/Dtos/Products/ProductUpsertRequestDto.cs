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
    public string Ingredients { get; set; } = string.Empty;
    public string? UsageTime { get; set; }
    public string? HowToUse { get; set; }
    public string Currency { get; set; } = string.Empty;

    [Range(0, 999999)]
    public decimal? Price { get; set; }

    public IReadOnlyCollection<string> SkinTypes { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> SkinConcerns { get; set; } = Array.Empty<string>();
    public string? ImageUrl { get; set; }
    public bool IsVerified { get; set; }
    public bool IsActive { get; set; } = true;
    public string Source { get; set; } = string.Empty;
    public string? SourceUrl { get; set; }
}
