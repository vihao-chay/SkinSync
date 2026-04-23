namespace SkinAsync.Models.Dtos.Users;

public class SurveyResponseDto
{
    public Guid UserId { get; set; }
    public string SkinType { get; set; } = string.Empty;
    public string[] SkinConcerns { get; set; } = Array.Empty<string>();
    public string MonthlyBudget { get; set; } = string.Empty;
    public int? Age { get; set; }
    public int? BirthYear { get; set; }
}
