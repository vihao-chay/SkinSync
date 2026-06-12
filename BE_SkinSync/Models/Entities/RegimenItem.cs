namespace SkinSync.Models.Entities;

public class RegimenItem
{
    public Guid Id { get; set; }
    public Guid RegimenId { get; set; }
    public Guid ProductId { get; set; }
    public string RoutineTime { get; set; } = "morning";
    public int StepOrder { get; set; }
    public string? Instruction { get; set; }
    public string? Frequency { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public UserRegimen Regimen { get; set; } = null!;
    public Product Product { get; set; } = null!;
    public ICollection<RoutineTracking> Trackings { get; set; } = new List<RoutineTracking>();
}
