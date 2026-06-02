namespace SkinAsync.Models.Entities;

public class IngredientConflictRule
{
    public Guid Id { get; set; }
    public string PrimaryIngredient { get; set; } = string.Empty;
    public string ConflictingIngredient { get; set; } = string.Empty;
    public string Severity { get; set; } = "warning";
    public string Message { get; set; } = string.Empty;
    public string Recommendation { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
