using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace SkinAsync.Models.Dtos.Diary;

public class DiaryCheckInRequestDto
{
    public DateOnly? Date { get; set; }
    public bool MorningCompleted { get; set; }
    public bool EveningCompleted { get; set; }

    [Required]
    [MaxLength(30)]
    public string SkinFeeling { get; set; } = string.Empty;

    public bool IsIrritated { get; set; }
    public string? Notes { get; set; }
    public IFormFile? Image { get; set; }
}
