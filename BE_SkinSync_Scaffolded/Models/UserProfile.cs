using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class UserProfile
{
    public Guid UserId { get; set; }

    public string? SkinType { get; set; }

    public string? SkinConcerns { get; set; }

    public decimal? MonthlyBudget { get; set; }

    public int? Age { get; set; }

    public int? BirthYear { get; set; }

    public DateTime CreatedAt { get; set; }

    public string? Gender { get; set; }

    public int? SensitivityLevel { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public string? Allergies { get; set; }

    public string? RoutinePreference { get; set; }

    public string? SensitiveIngredients { get; set; }

    public string? SkinGoals { get; set; }

    public virtual User1 User { get; set; } = null!;
}
