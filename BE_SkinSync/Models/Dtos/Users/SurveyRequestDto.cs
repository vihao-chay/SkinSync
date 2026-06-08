namespace SkinSync.Models.Dtos.Users;

public class SurveyRequestDto
{
    public string? SkinType { get; set; }
    public string? SkinConcerns { get; set; }
    public decimal? MonthlyBudget { get; set; }
    public int? Age { get; set; }
    public int? BirthYear { get; set; }
    public string? Gender { get; set; }
    public int? SensitivityLevel { get; set; }
}
