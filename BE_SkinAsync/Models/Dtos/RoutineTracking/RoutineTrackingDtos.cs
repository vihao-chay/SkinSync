namespace SkinAsync.Models.Dtos.RoutineTracking;

public class RoutineStepTrackingDto
{
    public Guid TrackingId { get; set; }
    public Guid StepId { get; set; }
    public Guid ProductId { get; set; }
    public string RoutineTime { get; set; } = string.Empty;
    public int StepOrder { get; set; }
    public string ProductName { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public DateTime CompletedAt { get; set; }
}

public class RoutineTrackingTodayDto
{
    public DateOnly Date { get; set; }
    public int TotalSteps { get; set; }
    public int CompletedSteps { get; set; }
    public decimal CompletionPercent { get; set; }
    public bool MorningCompleted { get; set; }
    public bool EveningCompleted { get; set; }
    public IEnumerable<RoutineStepTrackingDto> Steps { get; set; } = Array.Empty<RoutineStepTrackingDto>();
}
