namespace SkinAsync.Models.Entities;

public class UserRegimen
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid AnalysisId { get; set; }
    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }
    public bool IsActive { get; set; } = true;

    public User User { get; set; } = null!;
    public AiAnalysis Analysis { get; set; } = null!;
    public ICollection<RegimenItem> Items { get; set; } = new List<RegimenItem>();
}
