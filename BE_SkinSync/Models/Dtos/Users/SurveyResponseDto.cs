namespace SkinSync.Models.Dtos.Users;

public class SurveyResponseDto
{
    public Guid UserId { get; set; }
    public string? SkinType { get; set; }
    public decimal? MonthlyBudget { get; set; }
    public string? BudgetLabel { get; set; }
    public IReadOnlyCollection<string> Concerns { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Goals { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> Allergies { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> AvoidIngredients { get; set; } = Array.Empty<string>();
    public int? Age { get; set; }
    public int? BirthYear { get; set; }
    public string? Gender { get; set; }
    public int? SensitivityLevel { get; set; }
}
