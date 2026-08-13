namespace SkinSync.Models.Entities;

public class AppInstallEvent
{
    public Guid Id { get; set; }
    public string InstallationId { get; set; } = string.Empty;
    public string Platform { get; set; } = "unknown";
    public string? AppVersion { get; set; }
    public DateTime FirstSeenAt { get; set; } = DateTime.UtcNow;
    public DateTime LastSeenAt { get; set; } = DateTime.UtcNow;
}
