namespace SkinSync.Models.Dtos.Products;

public class ProductResponseDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Brand { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Ingredient { get; set; }
    public IReadOnlyCollection<string> Ingredients { get; set; } = Array.Empty<string>();
    public string? UsageGuide { get; set; }
    public string? HowToUse { get; set; }
    public string? UsageTime { get; set; }
    public decimal Price { get; set; }
    public string Currency { get; set; } = "VND";
    public IReadOnlyCollection<string> SuitableSkinTypes { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> SuitableFor { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> SkinConcerns { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> KeyIngredients { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Cautions { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Conflicts { get; set; } = Array.Empty<string>();
    public string? ImageUrl { get; set; }
    public decimal? Rating { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
