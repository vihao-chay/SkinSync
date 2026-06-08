namespace SkinSync.Models.Dtos.Products;

public class ProductResponseDto
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Brand { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Ingredient { get; set; }
    public string? UsageGuide { get; set; }
    public decimal Price { get; set; }
    public string? SuitableSkinTypes { get; set; }
    public string? ImageUrl { get; set; }
    public decimal? Rating { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; }
}
