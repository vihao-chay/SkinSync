namespace SkinAsync.Models.Entities;

public class UserRegimen
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid? AnalysisId { get; set; }
    public string Name { get; set; } = "Lộ trình chăm sóc da";
    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsCustom { get; set; }

    public User User { get; set; } = null!;
    public AiAnalysis? Analysis { get; set; }
    public ICollection<RegimenItem> Items { get; set; } = new List<RegimenItem>();
}
