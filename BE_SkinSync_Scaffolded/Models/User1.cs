using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class User1
{
    public Guid Id { get; set; }

    public string FullName { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string? Phone { get; set; }

    public string PasswordHash { get; set; } = null!;

    public string? AvatarUrl { get; set; }

    public string Role { get; set; } = null!;

    public string Status { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public string PlanType { get; set; } = null!;

    public virtual ICollection<AiChatConversation> AiChatConversations { get; set; } = new List<AiChatConversation>();

    public virtual ICollection<AiUsageLog> AiUsageLogs { get; set; } = new List<AiUsageLog>();

    public virtual ICollection<DailyLog> DailyLogs { get; set; } = new List<DailyLog>();

    public virtual ICollection<Reminder> Reminders { get; set; } = new List<Reminder>();

    public virtual ICollection<RoutineTracking> RoutineTrackings { get; set; } = new List<RoutineTracking>();

    public virtual ICollection<SkinPhotoComparison> SkinPhotoComparisons { get; set; } = new List<SkinPhotoComparison>();

    public virtual ICollection<SkinProgressAnalysis> SkinProgressAnalyses { get; set; } = new List<SkinProgressAnalysis>();

    public virtual ICollection<SkinProgressPhoto> SkinProgressPhotos { get; set; } = new List<SkinProgressPhoto>();

    public virtual ICollection<SkinProgressReport> SkinProgressReports { get; set; } = new List<SkinProgressReport>();

    public virtual UserProfile? UserProfile { get; set; }

    public virtual ICollection<UserRegimen> UserRegimen { get; set; } = new List<UserRegimen>();

    public virtual ICollection<UserSubscription> UserSubscriptions { get; set; } = new List<UserSubscription>();
}
