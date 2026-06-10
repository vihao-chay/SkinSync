namespace SkinSync.Models.Dtos.Diary;

public class DiaryCheckInResponseDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public DateOnly Date { get; set; }
    public bool MorningCompleted { get; set; }
    public bool EveningCompleted { get; set; }
    public string? SkinFeeling { get; set; }
    public bool IsIrritated { get; set; }
    public string? Notes { get; set; }
    public int? AcneLevel { get; set; }
    public int? DrynessLevel { get; set; }
    public int? RednessLevel { get; set; }
    public int? IrritationLevel { get; set; }
    public int? HydrationLevel { get; set; }
    public string? DailyImageUrl { get; set; }
}
