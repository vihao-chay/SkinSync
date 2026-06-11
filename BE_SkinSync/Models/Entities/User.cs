namespace SkinSync.Models.Entities;

public class User
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string PasswordHash { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string Role { get; set; } = "user";
    public string Status { get; set; } = "active";
    public string PlanType { get; set; } = "free";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedAt { get; set; }

    public UserProfile? Profile { get; set; }
    public ICollection<UserRegimen> Regimens { get; set; } = new List<UserRegimen>();
    public ICollection<DailyLog> DailyLogs { get; set; } = new List<DailyLog>();
    public ICollection<RoutineTracking> RoutineTrackings { get; set; } = new List<RoutineTracking>();
    public ICollection<Reminder> Reminders { get; set; } = new List<Reminder>();
    public ICollection<AiUsageLog> AiUsageLogs { get; set; } = new List<AiUsageLog>();
    public ICollection<AiChatConversation> AiChatConversations { get; set; } = new List<AiChatConversation>();
    public ICollection<SkinProgressPhoto> SkinProgressPhotos { get; set; } = new List<SkinProgressPhoto>();
    public ICollection<SkinProgressAnalysis> SkinProgressAnalyses { get; set; } = new List<SkinProgressAnalysis>();
    public ICollection<SkinPhotoComparison> SkinPhotoComparisons { get; set; } = new List<SkinPhotoComparison>();
    public ICollection<SkinProgressReport> SkinProgressReports { get; set; } = new List<SkinProgressReport>();
}
