namespace SkinAsync.Models.Dtos.Progress;

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
