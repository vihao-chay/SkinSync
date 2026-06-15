using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace SkinSync.Models.Dtos.Diary;

public class DiaryCheckInRequestDto
{
    public DateOnly? Date { get; set; }
    public bool MorningCompleted { get; set; }
    public bool EveningCompleted { get; set; }
    public string? CompletedStepIdsJson { get; set; }

    [Required]
    [MaxLength(30)]
    public string SkinFeeling { get; set; } = string.Empty;

    public bool IsIrritated { get; set; }
    public string? Notes { get; set; }
    public int? AcneLevel { get; set; }
    public int? DrynessLevel { get; set; }
    public int? RednessLevel { get; set; }
    public int? IrritationLevel { get; set; }
    public int? HydrationLevel { get; set; }
    public IFormFile? Image { get; set; }
}
