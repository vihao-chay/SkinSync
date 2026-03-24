using System.ComponentModel.DataAnnotations;

namespace SkinAsync.Models.Dtos.Users;

public class SurveyRequestDto
{
    [Required]
    [MaxLength(30)]
    public string SkinType { get; set; } = string.Empty;

    [Required]
    public string[] SkinConcerns { get; set; } = Array.Empty<string>();

    [Required]
    [MaxLength(30)]
    public string MonthlyBudget { get; set; } = string.Empty;

    public int? Age { get; set; }
    public int? BirthYear { get; set; }
}
