namespace SkinAsync.Models.Entities;

public class DailyLog
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public DateOnly Date { get; set; }
    public bool MorningCompleted { get; set; }
    public bool EveningCompleted { get; set; }
    public string SkinFeeling { get; set; } = "Normal";
    public bool IsIrritated { get; set; }
    public string? Notes { get; set; }
    public string? DailyImageUrl { get; set; }

    public User User { get; set; } = null!;
}
