namespace SkinSync.Models.Dtos.Users;

public class SurveyRequestDto
{
    public string? DisplayName { get; set; }
    public string? DateOfBirth { get; set; }
    public string? Gender { get; set; }
    public IEnumerable<string> HealthIssues { get; set; } = Array.Empty<string>();
    public string? SkinType { get; set; }
    public string? BudgetLevel { get; set; }
    public decimal? MonthlyBudget { get; set; }
    public IEnumerable<string> Concerns { get; set; } = Array.Empty<string>();
    public string? CurrentRoutineLevel { get; set; }
    public IEnumerable<string> Goals { get; set; } = Array.Empty<string>();
    public IEnumerable<string> Allergies { get; set; } = Array.Empty<string>();
    public IEnumerable<string> AvoidIngredients { get; set; } = Array.Empty<string>();
    public IEnumerable<string> SkinGoals { get; set; } = Array.Empty<string>();
    public string? RednessWhenNewProducts { get; set; }
    public string? RednessWhenSunOrExercise { get; set; }
    public int? Age { get; set; }
    public int? BirthYear { get; set; }
    public int? SensitivityLevel { get; set; }
}
