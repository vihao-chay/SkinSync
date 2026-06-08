namespace SkinSync.Models.Dtos.Progress;

public class ProgressOverviewResponseDto
{
    public int? StartScore { get; set; }
    public int? CurrentScore { get; set; }
    public decimal ImprovementPercent { get; set; }
    public int CompletedDaysLast28 { get; set; }
    public decimal CompletionRateLast28 { get; set; }
    public int CurrentStreak { get; set; }
}

public class ProgressChartPointDto
{
    public DateOnly Date { get; set; }
    public int OverallScore { get; set; }
    public int? HydrationScore { get; set; }
}

public class ProgressStreakDayDto
{
    public DateOnly Date { get; set; }
    public bool Completed { get; set; }
}

public class ProgressStreakResponseDto
{
    public int CurrentStreak { get; set; }
    public int BestStreak { get; set; }
    public IEnumerable<ProgressStreakDayDto> LastDays { get; set; } = Array.Empty<ProgressStreakDayDto>();
}

public class WeeklyCompletionResponseDto
{
    public DateOnly WeekStart { get; set; }
    public DateOnly WeekEnd { get; set; }
    public int CompletedDays { get; set; }
    public int TotalDays { get; set; }
    public decimal CompletionPercent { get; set; }
}

public class MonthlyReportResponseDto
{
    public int Year { get; set; }
    public int Month { get; set; }
    public int CompletedDays { get; set; }
    public int FullRoutineDays { get; set; }
    public int TotalTrackedDays { get; set; }
    public decimal CompletionPercent { get; set; }
    public int BestStreak { get; set; }
}
