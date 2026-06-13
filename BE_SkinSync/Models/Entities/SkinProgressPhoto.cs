namespace SkinSync.Models.Entities;

public class SkinProgressPhoto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string ImageUrl { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public string Source { get; set; } = "unknown";
    public string? ImageMetadataJson { get; set; }
    public DateOnly PhotoDate { get; set; }
    public string TimeOfDay { get; set; } = "unknown";
    public string LightingCondition { get; set; } = "unknown";
    public string FaceAngle { get; set; } = "unknown";
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public ICollection<SkinProgressAnalysis> Analyses { get; set; } = new List<SkinProgressAnalysis>();
}
