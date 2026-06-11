namespace SkinSync.Models.Entities;

public class Ingredient
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Benefit { get; set; }
    public string RiskLevel { get; set; } = "low";
    public string? SuitableSkinTypes { get; set; }
    public string? NotSuitableFor { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<ProductIngredient> ProductIngredients { get; set; } = new List<ProductIngredient>();
    public ICollection<IngredientConflictRule> PrimaryConflictRules { get; set; } = new List<IngredientConflictRule>();
    public ICollection<IngredientConflictRule> ConflictingConflictRules { get; set; } = new List<IngredientConflictRule>();
}
