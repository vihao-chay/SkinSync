using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class Product
{
    public Guid Id { get; set; }

    public string Name { get; set; } = null!;

    public string Brand { get; set; } = null!;

    public string Category { get; set; } = null!;

    public decimal Price { get; set; }

    public string? SuitableSkinTypes { get; set; }

    public string? ImageUrl { get; set; }

    public decimal? Rating { get; set; }

    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public string? Description { get; set; }

    public string? Ingredient { get; set; }

    public string? UsageGuide { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public string? AvoidForConcerns { get; set; }

    public string Currency { get; set; } = null!;

    public string? KeyIngredients { get; set; }

    public string? TargetConcerns { get; set; }

    public virtual ICollection<ProductIngredient> ProductIngredients { get; set; } = new List<ProductIngredient>();

    public virtual ICollection<RegimenItem> RegimenItems { get; set; } = new List<RegimenItem>();
}
