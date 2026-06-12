using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class ProductIngredient
{
    public Guid Id { get; set; }

    public Guid ProductId { get; set; }

    public Guid IngredientId { get; set; }

    public string? Concentration { get; set; }

    public string? Note { get; set; }

    public virtual Ingredient Ingredient { get; set; } = null!;

    public virtual Product Product { get; set; } = null!;
}
