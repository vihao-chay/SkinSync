namespace SkinSync.Models.Dtos.Users;

public class SurveyRequestDto
{
    public string? DisplayName { get; set; }
    public string? DateOfBirth { get; set; }
    public string? Gender { get; set; }
    public List<string> HealthIssues { get; set; } = [];
    public string? SkinType { get; set; }
    public decimal? MonthlyBudget { get; set; }
    public string? BudgetLevel { get; set; }
    public List<string> Concerns { get; set; } = [];
    public string? CurrentRoutineLevel { get; set; }
    public List<string> Goals { get; set; } = [];
    public List<string> Allergies { get; set; } = [];
    public List<string> AvoidIngredients { get; set; } = [];
    public List<string> SkinGoals { get; set; } = [];
    public string? RednessWhenNewProducts { get; set; }
    public string? RednessWhenSunOrExercise { get; set; }
    public int? Age { get; set; }
    public int? BirthYear { get; set; }
    public int? SensitivityLevel { get; set; }
}
