namespace SkinSync.Models.Entities;

public class Reminder
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public TimeOnly Time { get; set; }
    public string RoutineType { get; set; } = "morning";
    public string Frequency { get; set; } = "daily";
    public string? Reason { get; set; }
    public string Priority { get; set; } = "medium";
    public bool IsAdaptive { get; set; }
    public bool IsEnabled { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public User User { get; set; } = null!;
}
