namespace SkinAsync.Models.Entities;

public class User
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string Phone { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string Role { get; set; } = "user";
    public string Status { get; set; } = "inactive";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public UserProfile? Profile { get; set; }
    public ICollection<AiAnalysis> Analyses { get; set; } = new List<AiAnalysis>();
    public ICollection<UserRegimen> Regimens { get; set; } = new List<UserRegimen>();
    public ICollection<DailyLog> DailyLogs { get; set; } = new List<DailyLog>();
}
