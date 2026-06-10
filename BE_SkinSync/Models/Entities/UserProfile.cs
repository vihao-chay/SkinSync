namespace SkinSync.Models.Entities;

public class UserProfile
{
    public Guid UserId { get; set; }
    public string? SkinType { get; set; }
    public string? SkinConcerns { get; set; }
    public decimal? MonthlyBudget { get; set; }
    public int? Age { get; set; }
    public int? BirthYear { get; set; }
    public string? Gender { get; set; }
    public int? SensitivityLevel { get; set; }
    public string? Allergies { get; set; }
    public string? SensitiveIngredients { get; set; }
    public string? SkinGoals { get; set; }
    public string? RoutinePreference { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public User User { get; set; } = null!;
}
