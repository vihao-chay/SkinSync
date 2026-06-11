namespace SkinSync.Models.Dtos.Ingredients;

public class IngredientConflictRuleDto
{
    public Guid Id { get; set; }
    public string PrimaryIngredient { get; set; } = string.Empty;
    public string ConflictingIngredient { get; set; } = string.Empty;
    public string Severity { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Recommendation { get; set; } = string.Empty;
}

public class IngredientConflictCheckRequestDto
{
    public IEnumerable<Guid> ProductIds { get; set; } = Array.Empty<Guid>();
}

public class IngredientConflictWarningDto
{
    public Guid ProductAId { get; set; }
    public string ProductAName { get; set; } = string.Empty;
    public Guid ProductBId { get; set; }
    public string ProductBName { get; set; } = string.Empty;
    public string IngredientA { get; set; } = string.Empty;
    public string IngredientB { get; set; } = string.Empty;
    public string Severity { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string Recommendation { get; set; } = string.Empty;
}

public class IngredientConflictCheckResponseDto
{
    public int ProductCount { get; set; }
    public int WarningCount { get; set; }
    public IEnumerable<IngredientConflictWarningDto> Warnings { get; set; } = Array.Empty<IngredientConflictWarningDto>();
}
