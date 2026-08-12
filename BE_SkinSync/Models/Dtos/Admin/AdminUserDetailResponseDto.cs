using SkinSync.Models.Dtos;
using SkinSync.Models.Dtos.Analysis;
using SkinSync.Models.Dtos.Progress;
using SkinSync.Models.Dtos.Subscriptions;

namespace SkinSync.Models.Dtos.Admin;

public class AdminUserDetailResponseDto
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string Role { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string PlanType { get; set; } = "free";
    public string? AvatarUrl { get; set; }
    public DateTime CreatedAt { get; set; }
    public AdminUserProfileSnapshotDto? Profile { get; set; }
    public CurrentSubscriptionDto? Subscription { get; set; }
    public ProgressOverviewResponseDto? ProgressOverview { get; set; }
    public CurrentRegimenResponseDto? CurrentRegimen { get; set; }
    public AnalysisDetailResponseDto? LatestAnalysis { get; set; }
    public IReadOnlyCollection<AdminUserActivityItemDto> RecentActivities { get; set; } = Array.Empty<AdminUserActivityItemDto>();
}

public class AdminUserProfileSnapshotDto
{
    public string? SkinType { get; set; }
    public IReadOnlyCollection<string> SkinConcerns { get; set; } = Array.Empty<string>();
    public decimal? MonthlyBudget { get; set; }
    public int? Age { get; set; }
    public int? BirthYear { get; set; }
    public string? Gender { get; set; }
    public IReadOnlyCollection<string> Allergies { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> SensitiveIngredients { get; set; } = Array.Empty<string>();
    public IReadOnlyCollection<string> SkinGoals { get; set; } = Array.Empty<string>();
    public string? RoutinePreference { get; set; }
    public DateTime? UpdatedAt { get; set; }
}

public class AdminUserActivityItemDto
{
    public string Type { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTime OccurredAt { get; set; }
}
