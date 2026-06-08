namespace SkinSync.Models.Entities;

public class IngredientConflictRule
{
    public Guid Id { get; set; }
    public Guid? PrimaryIngredientId { get; set; }
    public Guid? ConflictingIngredientId { get; set; }
    public string? PrimaryIngredient { get; set; }
    public string? ConflictingIngredient { get; set; }
    public string Severity { get; set; } = "medium";
    public string Message { get; set; } = string.Empty;
    public string Recommendation { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Ingredient? PrimaryIngredientEntity { get; set; }
    public Ingredient? ConflictingIngredientEntity { get; set; }
}
