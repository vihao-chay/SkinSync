namespace SkinAsync.Models.Entities;

public class Product
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Brand { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string[] SuitableSkinTypes { get; set; } = Array.Empty<string>();
    public string? ImageUrl { get; set; }
    public decimal Rating { get; set; }
    public string Status { get; set; } = "active";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<RegimenItem> RegimenItems { get; set; } = new List<RegimenItem>();
}
