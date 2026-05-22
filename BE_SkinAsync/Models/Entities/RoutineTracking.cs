namespace SkinAsync.Models.Entities;

public class RoutineTracking
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid StepId { get; set; }
    public DateTime CompletedAt { get; set; } = DateTime.UtcNow;
    public string Status { get; set; } = "completed";

    public User User { get; set; } = null!;
    public RegimenItem Step { get; set; } = null!;
}
