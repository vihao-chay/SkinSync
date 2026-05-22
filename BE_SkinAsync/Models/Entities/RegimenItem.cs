namespace SkinAsync.Models.Entities;

public class RegimenItem
{
    public Guid Id { get; set; }
    public Guid RegimenId { get; set; }
    public Guid ProductId { get; set; }
    public string RoutineTime { get; set; } = "Morning";
    public int StepOrder { get; set; }
    public string Instruction { get; set; } = string.Empty;

    public UserRegimen Regimen { get; set; } = null!;
    public Product Product { get; set; } = null!;
    public ICollection<RoutineTracking> Trackings { get; set; } = new List<RoutineTracking>();
}
