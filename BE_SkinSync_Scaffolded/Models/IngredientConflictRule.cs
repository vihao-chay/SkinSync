using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class IngredientConflictRule
{
    public Guid Id { get; set; }

    public string? PrimaryIngredient { get; set; }

    public string? ConflictingIngredient { get; set; }

    public string Severity { get; set; } = null!;

    public string Message { get; set; } = null!;

    public string Recommendation { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public Guid? ConflictingIngredientId { get; set; }

    public Guid? PrimaryIngredientId { get; set; }

    public virtual Ingredient? ConflictingIngredientNavigation { get; set; }

    public virtual Ingredient? PrimaryIngredientNavigation { get; set; }
}
