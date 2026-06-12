using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class Ingredient
{
    public Guid Id { get; set; }

    public string Name { get; set; } = null!;

    public string? Description { get; set; }

    public string? Benefit { get; set; }

    public string RiskLevel { get; set; } = null!;

    public string? SuitableSkinTypes { get; set; }

    public string? NotSuitableFor { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual ICollection<IngredientConflictRule> IngredientConflictRuleConflictingIngredientNavigations { get; set; } = new List<IngredientConflictRule>();

    public virtual ICollection<IngredientConflictRule> IngredientConflictRulePrimaryIngredientNavigations { get; set; } = new List<IngredientConflictRule>();

    public virtual ICollection<ProductIngredient> ProductIngredients { get; set; } = new List<ProductIngredient>();
}
