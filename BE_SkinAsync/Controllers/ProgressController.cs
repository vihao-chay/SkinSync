using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SkinAsync.Data;
using SkinAsync.Helpers;
using SkinAsync.Models.Dtos.Progress;

namespace SkinAsync.Controllers;

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
    public async Task<IActionResult> GetOverview(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return Unauthorized("Missing authenticated user.");
        }

        var analyses = await _dbContext.AiAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderBy(x => x.CreatedAt)
            .ToListAsync(cancellationToken);

        var nowDate = DateOnly.FromDateTime(DateTime.UtcNow.Date);
        var fromDate = nowDate.AddDays(-27);

        var logs = await _dbContext.DailyLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.Date >= fromDate && x.Date <= nowDate)
            .ToListAsync(cancellationToken);

        var completedDays = logs.Count(x => x.MorningCompleted || x.EveningCompleted);

        var overview = new ProgressOverviewResponseDto
        {
            StartScore = analyses.FirstOrDefault()?.OverallScore,
            CurrentScore = analyses.LastOrDefault()?.OverallScore,
            ImprovementPercent = CalculateImprovementPercent(analyses.FirstOrDefault()?.OverallScore, analyses.LastOrDefault()?.OverallScore),
            CompletedDaysLast28 = completedDays,
            CompletionRateLast28 = Math.Round((decimal)completedDays / 28m * 100m, 2),
            CurrentStreak = await CalculateCurrentStreakAsync(userId, cancellationToken)
        };

        return Ok(overview);
    }

    [HttpGet("chart")]
    public async Task<IActionResult> GetChart(
        [FromQuery] int days = 30,
        CancellationToken cancellationToken = default)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return Unauthorized("Missing authenticated user.");
        }

        if (days is < 1 or > 365)
        {
            return BadRequest("days must be between 1 and 365.");
        }

        var fromUtc = DateTime.UtcNow.Date.AddDays(-(days - 1));
        var analyses = await _dbContext.AiAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.CreatedAt >= fromUtc)
            .OrderBy(x => x.CreatedAt)
            .ToListAsync(cancellationToken);

        var chart = analyses
            .Select(x => new ProgressChartPointDto
            {
                Date = DateOnly.FromDateTime(x.CreatedAt.Date),
                OverallScore = x.OverallScore,
                HydrationScore = x.RecoveryCapacity
            })
            .ToList();

        return Ok(chart);
    }

    [HttpGet("streak")]
    public async Task<IActionResult> GetStreak(
        [FromQuery] int days = 30,
        CancellationToken cancellationToken = default)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return Unauthorized("Missing authenticated user.");
        }

        if (days is < 1 or > 90)
        {
            return BadRequest("days must be between 1 and 90.");
        }

        var nowDate = DateOnly.FromDateTime(DateTime.UtcNow.Date);
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

        return Ok(result);
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

        var currentDate = DateOnly.FromDateTime(DateTime.UtcNow.Date);

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

    private static decimal CalculateImprovementPercent(int? startScore, int? currentScore)
    {
        if (!startScore.HasValue || !currentScore.HasValue || startScore.Value <= 0)
        {
            return 0;
        }

        var improvement = (currentScore.Value - startScore.Value) / (decimal)startScore.Value * 100m;
        return Math.Round(improvement, 2);
    }
}
