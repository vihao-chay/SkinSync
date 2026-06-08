namespace SkinSync.Models.Entities;

public class ProductIngredient
{
    public Guid Id { get; set; }
    public Guid ProductId { get; set; }
    public Guid IngredientId { get; set; }
    public string? Concentration { get; set; }
    public string? Note { get; set; }

    public Product Product { get; set; } = null!;
    public Ingredient Ingredient { get; set; } = null!;
}
