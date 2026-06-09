namespace SkinSync.Models.Dtos.Users;

public class SurveyRequestDto
{
    public string? SkinType { get; set; }
    public decimal? MonthlyBudget { get; set; }
    public string? BudgetLabel { get; set; }
    public IEnumerable<string> Concerns { get; set; } = Array.Empty<string>();
    public IEnumerable<string> Goals { get; set; } = Array.Empty<string>();
    public IEnumerable<string> Allergies { get; set; } = Array.Empty<string>();
    public IEnumerable<string> AvoidIngredients { get; set; } = Array.Empty<string>();
    public int? Age { get; set; }
    public int? BirthYear { get; set; }
    public string? Gender { get; set; }
    public int? SensitivityLevel { get; set; }
}
