namespace SkinSync.Models.Entities;

public class RoutineTracking
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid StepId { get; set; }
    public DateOnly TrackingDate { get; set; } = DateOnly.FromDateTime(DateTime.UtcNow.Date);
    public string RoutineTime { get; set; } = "morning";
    public DateTime? CompletedAt { get; set; }
    public string Status { get; set; } = "completed";
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public RegimenItem Step { get; set; } = null!;
}
