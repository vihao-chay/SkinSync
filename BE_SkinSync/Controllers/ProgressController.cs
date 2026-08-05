using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SkinSync.Base;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Models.Dtos.Progress;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/progress")]
[Authorize]
public class ProgressController : ControllerBase
{
    private readonly AppDbContext _dbContext;

    public ProgressController(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet("overview")]
    public async Task<ResponseEntity<ProgressOverviewResponseDto>> GetOverview(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<ProgressOverviewResponseDto>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        var analyses = await _dbContext.SkinProgressAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.DiscardedAt == null && x.Status != "discarded")
            .OrderBy(x => x.CompletedAt ?? x.CreatedAt)
            .ToListAsync(cancellationToken);

        var nowDate = AppClock.Today;
        var fromDate = nowDate.AddDays(-27);

        var logs = await _dbContext.DailyLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.Date >= fromDate && x.Date <= nowDate)
            .ToListAsync(cancellationToken);

        var scoreEntries = analyses
            .Select(x => new
            {
                Analysis = x,
                HealthScore = ResolveSkinHealthScore(x)
            })
            .ToList();
        var startScore = scoreEntries.Count > 1 ? scoreEntries.First().HealthScore : (int?)null;
        var currentScore = scoreEntries.LastOrDefault()?.HealthScore;
        var completedDays = logs.Count(x => x.MorningCompleted || x.EveningCompleted);

        var overview = new ProgressOverviewResponseDto
        {
            StartScore = startScore,
            CurrentScore = currentScore,
            ImprovementPercent = CalculateImprovementPercent(startScore, currentScore),
            CompletedDaysLast28 = completedDays,
            CompletionRateLast28 = Math.Round((decimal)completedDays / 28m * 100m, 2),
            CurrentStreak = await CalculateCurrentStreakAsync(userId, cancellationToken),
            DailyTip = BuildDailyTip(currentScore, completedDays),
            ProgressInsight = BuildProgressInsight(startScore, currentScore, completedDays)
        };

        return ResponseEntity<ProgressOverviewResponseDto>.Ok(overview, "Láº¥y tá»•ng quan tiáº¿n Ä‘á»™ thÃ nh cÃ´ng.");
    }

    [HttpGet("chart")]
    public async Task<ResponseEntity<IEnumerable<ProgressChartPointDto>>> GetChart(
        [FromQuery] int days = 30,
        CancellationToken cancellationToken = default)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<IEnumerable<ProgressChartPointDto>>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        if (days is < 1 or > 365)
        {
            return ResponseEntity<IEnumerable<ProgressChartPointDto>>.Fail("days pháº£i náº±m trong khoáº£ng 1 Ä‘áº¿n 365.");
        }

        var fromDate = AppClock.Today.AddDays(-(days - 1));
        var analyses = await _dbContext.SkinProgressAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.DiscardedAt == null && x.Status != "discarded")
            .OrderBy(x => x.CompletedAt ?? x.CreatedAt)
            .ToListAsync(cancellationToken);

        var chart = analyses
            .Where(x => DateOnly.FromDateTime((x.CompletedAt ?? x.CreatedAt).AddHours(7).Date) >= fromDate)
            .Select(x => new ProgressChartPointDto
            {
                Date = DateOnly.FromDateTime((x.CompletedAt ?? x.CreatedAt).AddHours(7).Date),
                OverallScore = ResolveSkinHealthScore(x),
                HydrationScore = x.DrynessScore == 0 ? null : Math.Max(0, 100 - x.DrynessScore)
            })
            .ToList();

        return ResponseEntity<IEnumerable<ProgressChartPointDto>>.Ok(chart, "Láº¥y dá»¯ liá»‡u biá»ƒu Ä‘á»“ thÃ nh cÃ´ng.");
    }

    [HttpGet("streak")]
    public async Task<ResponseEntity<ProgressStreakResponseDto>> GetStreak(
        [FromQuery] int days = 30,
        CancellationToken cancellationToken = default)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<ProgressStreakResponseDto>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        if (days is < 1 or > 90)
        {
            return ResponseEntity<ProgressStreakResponseDto>.Fail("days pháº£i náº±m trong khoáº£ng 1 Ä‘áº¿n 90.");
        }

        var nowDate = AppClock.Today;
        var fromDate = nowDate.AddDays(-(days - 1));

        var logs = await _dbContext.DailyLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.Date >= fromDate && x.Date <= nowDate)
            .ToListAsync(cancellationToken);

        var completedMap = logs.ToDictionary(x => x.Date, x => x.MorningCompleted || x.EveningCompleted);

        var daily = new List<ProgressStreakDayDto>();
        for (var d = fromDate; d <= nowDate; d = d.AddDays(1))
        {
            daily.Add(new ProgressStreakDayDto
            {
                Date = d,
                Completed = completedMap.GetValueOrDefault(d)
            });
        }

        var result = new ProgressStreakResponseDto
        {
            CurrentStreak = await CalculateCurrentStreakAsync(userId, cancellationToken),
            BestStreak = CalculateBestStreak(daily),
            LastDays = daily
        };

        return ResponseEntity<ProgressStreakResponseDto>.Ok(result, "Láº¥y streak thÃ nh cÃ´ng.");
    }

    [HttpGet("weekly-completion")]
    public async Task<ResponseEntity<WeeklyCompletionResponseDto>> GetWeeklyCompletion(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<WeeklyCompletionResponseDto>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        var today = AppClock.Today;
        var offset = ((int)today.DayOfWeek + 6) % 7;
        var weekStart = today.AddDays(-offset);
        var weekEnd = weekStart.AddDays(6);

        var logs = await _dbContext.DailyLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.Date >= weekStart && x.Date <= weekEnd)
            .ToListAsync(cancellationToken);

        var completedDays = logs.Count(x => x.MorningCompleted || x.EveningCompleted);
        var response = new WeeklyCompletionResponseDto
        {
            WeekStart = weekStart,
            WeekEnd = weekEnd,
            CompletedDays = completedDays,
            TotalDays = 7,
            CompletionPercent = Math.Round(completedDays / 7m * 100m, 2)
        };

        return ResponseEntity<WeeklyCompletionResponseDto>.Ok(response, "Láº¥y tá»· lá»‡ hoÃ n thÃ nh tuáº§n thÃ nh cÃ´ng.");
    }

    [HttpGet("monthly-report")]
    public async Task<ResponseEntity<MonthlyReportResponseDto>> GetMonthlyReport(
        [FromQuery] int? year,
        [FromQuery] int? month,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<MonthlyReportResponseDto>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        var now = AppClock.LocalNow;
        var selectedYear = year ?? now.Year;
        var selectedMonth = month ?? now.Month;

        if (selectedMonth is < 1 or > 12)
        {
            return ResponseEntity<MonthlyReportResponseDto>.Fail("month pháº£i náº±m trong khoáº£ng 1 Ä‘áº¿n 12.");
        }

        var logs = await _dbContext.DailyLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.Date.Year == selectedYear && x.Date.Month == selectedMonth)
            .OrderBy(x => x.Date)
            .ToListAsync(cancellationToken);

        var completedDays = logs.Count(x => x.MorningCompleted || x.EveningCompleted);
        var fullRoutineDays = logs.Count(x => x.MorningCompleted && x.EveningCompleted);
        var daysInMonth = DateTime.DaysInMonth(selectedYear, selectedMonth);
        var streakDays = Enumerable.Range(1, daysInMonth)
            .Select(day =>
            {
                var date = new DateOnly(selectedYear, selectedMonth, day);
                var log = logs.FirstOrDefault(x => x.Date == date);
                return new ProgressStreakDayDto
                {
                    Date = date,
                    Completed = log is not null && (log.MorningCompleted || log.EveningCompleted)
                };
            })
            .ToList();

        var response = new MonthlyReportResponseDto
        {
            Year = selectedYear,
            Month = selectedMonth,
            CompletedDays = completedDays,
            FullRoutineDays = fullRoutineDays,
            TotalTrackedDays = logs.Count,
            CompletionPercent = Math.Round(completedDays / (decimal)daysInMonth * 100m, 2),
            BestStreak = CalculateBestStreak(streakDays)
        };

        return ResponseEntity<MonthlyReportResponseDto>.Ok(response, "Láº¥y bÃ¡o cÃ¡o thÃ¡ng thÃ nh cÃ´ng.");
    }

    private async Task<int> CalculateCurrentStreakAsync(Guid userId, CancellationToken cancellationToken)
    {
        var logs = await _dbContext.DailyLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .Select(x => new { x.Date, Completed = x.MorningCompleted || x.EveningCompleted })
            .ToListAsync(cancellationToken);

        var completedDates = logs
            .Where(x => x.Completed)
            .Select(x => x.Date)
            .ToHashSet();

        var currentDate = AppClock.Today;

        if (!completedDates.Contains(currentDate))
        {
            currentDate = currentDate.AddDays(-1);
        }

        var streak = 0;
        while (completedDates.Contains(currentDate))
        {
            streak++;
            currentDate = currentDate.AddDays(-1);
        }

        return streak;
    }

    private static int CalculateBestStreak(IEnumerable<ProgressStreakDayDto> days)
    {
        var best = 0;
        var current = 0;

        foreach (var day in days)
        {
            if (day.Completed)
            {
                current++;
                best = Math.Max(best, current);
            }
            else
            {
                current = 0;
            }
        }

        return best;
    }

    private static decimal? CalculateImprovementPercent(int? startScore, int? currentScore)
    {
        if (!startScore.HasValue || !currentScore.HasValue || startScore.Value <= 0)
        {
            return null;
        }

        var improvement = (currentScore.Value - startScore.Value) / (decimal)startScore.Value * 100m;
        return Math.Round(improvement, 2);
    }

    private static int ResolveSkinHealthScore(SkinSync.Models.Entities.SkinProgressAnalysis analysis)
    {
        var severity = analysis.OverallConcernSeverity ?? analysis.OverallScore;
        return analysis.SkinHealthScore ?? Math.Clamp(100 - severity, 0, 100);
    }

    private static string BuildDailyTip(int? currentScore, int completedDays)
    {
        if (!currentScore.HasValue)
        {
            return "Bắt đầu với lộ trình đơn giản gồm làm sạch, dưỡng ẩm và chống nắng để tạo thói quen ổn định.";
        }

        if (currentScore.Value < 65)
        {
            return "Hôm nay hãy giữ lộ trình dịu nhẹ, ưu tiên dưỡng ẩm và tránh dùng quá nhiều hoạt chất mạnh cùng lúc.";
        }

        if (completedDays < 10)
        {
            return "Da thường cải thiện nhờ sự đều đặn; hôm nay hãy cố gắng hoàn thành cả bước sáng và tối.";
        }

        return "Lộ trình của bạn đang duy trì tốt. Tiếp tục chống nắng mỗi sáng và dưỡng ẩm đều vào buổi tối.";
    }

    private static string BuildProgressInsight(int? startScore, int? currentScore, int completedDays)
    {
        if (!startScore.HasValue || !currentScore.HasValue)
        {
            return "Cần thêm ít nhất 2 lần phân tích và nhật ký hằng ngày để đánh giá xu hướng rõ hơn.";
        }

        var delta = currentScore.Value - startScore.Value;
        var trend = delta switch
        {
            > 0 => $"cải thiện {delta} điểm",
            < 0 => $"giảm {Math.Abs(delta)} điểm",
            _ => "ổn định"
        };

        return $"Trong giai đoạn theo dõi, điểm da của bạn {trend}. Bạn đã hoàn thành lộ trình trong {completedDays}/28 ngày gần đây.";
    }
}
