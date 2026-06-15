namespace SkinSync.Models.Entities;

public class Product
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Brand { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Ingredient { get; set; }
    public string? KeyIngredients { get; set; }
    public string? TargetConcerns { get; set; }
    public string? AvoidForConcerns { get; set; }
    public string? UsageGuide { get; set; }
    public decimal Price { get; set; }
    public string Currency { get; set; } = "VND";
    public string? SuitableSkinTypes { get; set; }
    public string? ImageUrl { get; set; }
    public decimal? Rating { get; set; }
    public string Status { get; set; } = "active";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public ICollection<ProductIngredient> ProductIngredients { get; set; } = new List<ProductIngredient>();
    public ICollection<RegimenItem> RegimenItems { get; set; } = new List<RegimenItem>();
    public ICollection<ProductRecommendationItem> ProductRecommendationItems { get; set; } = new List<ProductRecommendationItem>();
}
