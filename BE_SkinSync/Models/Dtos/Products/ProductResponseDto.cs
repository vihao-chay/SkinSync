namespace SkinSync.Models.Dtos.Products;

public class ProductResponseDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Brand { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string IngredientsText { get; set; } = string.Empty;
    public IReadOnlyCollection<string> Ingredients { get; set; } = Array.Empty<string>();
    public string? HowToUse { get; set; }
    public string? UsageTime { get; set; }
    public decimal? Price { get; set; }
    public string Currency { get; set; } = string.Empty;
    public IReadOnlyCollection<string> SkinTypes { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> SkinConcerns { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Cautions { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Conflicts { get; set; } = Array.Empty<string>();
    public string? ImageUrl { get; set; }
    public bool IsVerified { get; set; }
    public bool IsActive { get; set; }
    public string Source { get; set; } = string.Empty;
    public string? SourceUrl { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? UpdatedAt { get; set; }
}
