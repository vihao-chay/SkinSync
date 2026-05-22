namespace SkinAsync.Models.Entities;

public class Reminder
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public TimeOnly Time { get; set; }
    public string RoutineType { get; set; } = "Morning";
    public bool IsEnabled { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
}
