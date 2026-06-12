namespace SkinSync.Models.Entities;

public class UserRegimen
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid? SourceAnalysisId { get; set; }
    public string Name { get; set; } = "Skin care routine";
    public DateOnly StartDate { get; set; }
    public DateOnly? EndDate { get; set; }
    public bool IsActive { get; set; } = true;
    public bool IsCustom { get; set; }
    public string Source { get; set; } = "ai";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public User User { get; set; } = null!;
    public SkinProgressAnalysis? SourceAnalysis { get; set; }
    public ICollection<RegimenItem> Items { get; set; } = new List<RegimenItem>();
}
