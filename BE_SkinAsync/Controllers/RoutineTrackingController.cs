using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SkinAsync.Base;
using SkinAsync.Data;
using SkinAsync.Helpers;
using SkinAsync.Models.Dtos.RoutineTracking;
using SkinAsync.Models.Entities;

namespace SkinAsync.Controllers;

[ApiController]
[Route("api/routine-tracking")]
[Authorize]
public class RoutineTrackingController : ControllerBase
{
    private readonly AppDbContext _dbContext;

    public RoutineTrackingController(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet("today")]
    public async Task<ResponseEntity<RoutineTrackingTodayDto>> GetToday(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("Thiếu thông tin người dùng.", 401);
        }

        var response = await BuildTodayResponseAsync(userId, cancellationToken);
        return ResponseEntity<RoutineTrackingTodayDto>.Ok(response, "Lấy tiến độ hôm nay thành công.");
    }

    [HttpGet("history")]
    public async Task<ResponseEntity<IEnumerable<RoutineStepTrackingDto>>> GetHistory(
        [FromQuery] int days = 30,
        CancellationToken cancellationToken = default)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<IEnumerable<RoutineStepTrackingDto>>.Fail("Thiếu thông tin người dùng.", 401);
        }

        if (days is < 1 or > 365)
        {
            return ResponseEntity<IEnumerable<RoutineStepTrackingDto>>.Fail("days phải nằm trong khoảng 1 đến 365.");
        }

        var fromUtc = DateTime.UtcNow.Date.AddDays(-(days - 1));
        var history = await _dbContext.RoutineTrackings
            .AsNoTracking()
            .Include(x => x.Step)
            .ThenInclude(x => x.Product)
            .Where(x => x.UserId == userId && x.CompletedAt >= fromUtc)
            .OrderByDescending(x => x.CompletedAt)
            .Select(x => new RoutineStepTrackingDto
            {
                TrackingId = x.Id,
                StepId = x.StepId,
                ProductId = x.Step.ProductId,
                RoutineTime = x.Step.RoutineTime,
                StepOrder = x.Step.StepOrder,
                ProductName = x.Step.Product.Name,
                Status = x.Status,
                CompletedAt = x.CompletedAt
            })
            .ToListAsync(cancellationToken);

        return ResponseEntity<IEnumerable<RoutineStepTrackingDto>>.Ok(history, "Lấy lịch sử hoàn thành thành công.");
    }

    [HttpPost("steps/{stepId:guid}/complete")]
    public async Task<ResponseEntity<RoutineTrackingTodayDto>> CompleteStep(Guid stepId, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("Thiếu thông tin người dùng.", 401);
        }

        var step = await GetOwnedActiveStepAsync(userId, stepId, cancellationToken);
        if (step is null)
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("Không tìm thấy bước trong lộ trình hiện tại.", 404);
        }

        var (startUtc, endUtc) = TodayRangeUtc();
        var tracking = await _dbContext.RoutineTrackings
            .FirstOrDefaultAsync(x =>
                x.UserId == userId &&
                x.StepId == stepId &&
                x.CompletedAt >= startUtc &&
                x.CompletedAt < endUtc,
                cancellationToken);

        if (tracking is null)
        {
            _dbContext.RoutineTrackings.Add(new RoutineTracking
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                StepId = stepId,
                CompletedAt = DateTime.UtcNow,
                Status = "completed"
            });
        }
        else
        {
            tracking.Status = "completed";
            tracking.CompletedAt = DateTime.UtcNow;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
        await SyncDailyLogForRoutineAsync(userId, step.RoutineTime, cancellationToken);

        var response = await BuildTodayResponseAsync(userId, cancellationToken);
        return ResponseEntity<RoutineTrackingTodayDto>.Ok(response, "Đánh dấu bước hoàn thành thành công.");
    }

    [HttpDelete("steps/{stepId:guid}/complete")]
    public async Task<ResponseEntity<RoutineTrackingTodayDto>> UncompleteStep(Guid stepId, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("Thiếu thông tin người dùng.", 401);
        }

        var step = await GetOwnedActiveStepAsync(userId, stepId, cancellationToken);
        if (step is null)
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("Không tìm thấy bước trong lộ trình hiện tại.", 404);
        }

        var (startUtc, endUtc) = TodayRangeUtc();
        var trackings = await _dbContext.RoutineTrackings
            .Where(x =>
                x.UserId == userId &&
                x.StepId == stepId &&
                x.CompletedAt >= startUtc &&
                x.CompletedAt < endUtc)
            .ToListAsync(cancellationToken);

        _dbContext.RoutineTrackings.RemoveRange(trackings);
        await _dbContext.SaveChangesAsync(cancellationToken);
        await SyncDailyLogForRoutineAsync(userId, step.RoutineTime, cancellationToken);

        var response = await BuildTodayResponseAsync(userId, cancellationToken);
        return ResponseEntity<RoutineTrackingTodayDto>.Ok(response, "Bỏ đánh dấu bước thành công.");
    }

    [HttpPost("routines/{routineType}/complete")]
    public async Task<ResponseEntity<RoutineTrackingTodayDto>> CompleteRoutine(
        string routineType,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("Thiếu thông tin người dùng.", 401);
        }

        var normalizedType = NormalizeRoutineType(routineType);
        if (normalizedType is null)
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("routineType chỉ nhận Morning hoặc Evening.");
        }

        var regimen = await _dbContext.UserRegimens
            .Include(x => x.Items)
            .FirstOrDefaultAsync(x => x.UserId == userId && x.IsActive, cancellationToken);

        if (regimen is null)
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("Chưa có lộ trình đang hoạt động.", 404);
        }

        var steps = regimen.Items
            .Where(x => x.RoutineTime.Equals(normalizedType, StringComparison.OrdinalIgnoreCase))
            .ToList();

        if (steps.Count == 0)
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("Lộ trình này chưa có bước nào.");
        }

        var (startUtc, endUtc) = TodayRangeUtc();
        var stepIds = steps.Select(x => x.Id).ToHashSet();
        var existingStepIds = await _dbContext.RoutineTrackings
            .Where(x =>
                x.UserId == userId &&
                stepIds.Contains(x.StepId) &&
                x.CompletedAt >= startUtc &&
                x.CompletedAt < endUtc)
            .Select(x => x.StepId)
            .ToListAsync(cancellationToken);

        foreach (var step in steps.Where(x => !existingStepIds.Contains(x.Id)))
        {
            _dbContext.RoutineTrackings.Add(new RoutineTracking
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                StepId = step.Id,
                CompletedAt = DateTime.UtcNow,
                Status = "completed"
            });
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
        await SyncDailyLogForRoutineAsync(userId, normalizedType, cancellationToken);

        var response = await BuildTodayResponseAsync(userId, cancellationToken);
        return ResponseEntity<RoutineTrackingTodayDto>.Ok(response, "Đánh dấu hoàn thành toàn bộ routine thành công.");
    }

    private async Task<RegimenItem?> GetOwnedActiveStepAsync(Guid userId, Guid stepId, CancellationToken cancellationToken)
    {
        return await _dbContext.RegimenItems
            .Include(x => x.Regimen)
            .Include(x => x.Product)
            .FirstOrDefaultAsync(x => x.Id == stepId && x.Regimen.UserId == userId && x.Regimen.IsActive, cancellationToken);
    }

    private async Task<RoutineTrackingTodayDto> BuildTodayResponseAsync(Guid userId, CancellationToken cancellationToken)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);
        var (startUtc, endUtc) = TodayRangeUtc();

        var regimen = await _dbContext.UserRegimens
            .AsNoTracking()
            .Include(x => x.Items)
            .ThenInclude(x => x.Product)
            .FirstOrDefaultAsync(x => x.UserId == userId && x.IsActive, cancellationToken);

        if (regimen is null)
        {
            return new RoutineTrackingTodayDto { Date = today };
        }

        var trackings = await _dbContext.RoutineTrackings
            .AsNoTracking()
            .Where(x =>
                x.UserId == userId &&
                x.CompletedAt >= startUtc &&
                x.CompletedAt < endUtc &&
                x.Status == "completed")
            .ToListAsync(cancellationToken);

        var trackingByStep = trackings
            .GroupBy(x => x.StepId)
            .ToDictionary(x => x.Key, x => x.OrderByDescending(t => t.CompletedAt).First());

        var completedSteps = regimen.Items
            .Where(x => trackingByStep.ContainsKey(x.Id))
            .OrderBy(x => x.RoutineTime)
            .ThenBy(x => x.StepOrder)
            .Select(x =>
            {
                var tracking = trackingByStep[x.Id];
                return new RoutineStepTrackingDto
                {
                    TrackingId = tracking.Id,
                    StepId = x.Id,
                    ProductId = x.ProductId,
                    RoutineTime = x.RoutineTime,
                    StepOrder = x.StepOrder,
                    ProductName = x.Product.Name,
                    Status = tracking.Status,
                    CompletedAt = tracking.CompletedAt
                };
            })
            .ToList();

        var totalSteps = regimen.Items.Count;
        var morningSteps = regimen.Items.Where(x => x.RoutineTime == "Morning").Select(x => x.Id).ToHashSet();
        var eveningSteps = regimen.Items.Where(x => x.RoutineTime == "Evening").Select(x => x.Id).ToHashSet();
        var completedIds = trackingByStep.Keys.ToHashSet();

        return new RoutineTrackingTodayDto
        {
            Date = today,
            TotalSteps = totalSteps,
            CompletedSteps = completedSteps.Count,
            CompletionPercent = totalSteps == 0 ? 0 : Math.Round(completedSteps.Count / (decimal)totalSteps * 100m, 2),
            MorningCompleted = morningSteps.Count > 0 && morningSteps.All(completedIds.Contains),
            EveningCompleted = eveningSteps.Count > 0 && eveningSteps.All(completedIds.Contains),
            Steps = completedSteps
        };
    }

    private async Task SyncDailyLogForRoutineAsync(Guid userId, string routineType, CancellationToken cancellationToken)
    {
        var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);
        var progress = await BuildTodayResponseAsync(userId, cancellationToken);
        var log = await _dbContext.DailyLogs.FirstOrDefaultAsync(x => x.UserId == userId && x.Date == today, cancellationToken);

        if (log is null)
        {
            log = new DailyLog
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Date = today,
                SkinFeeling = "Normal"
            };
            _dbContext.DailyLogs.Add(log);
        }

        if (routineType == "Morning")
        {
            log.MorningCompleted = progress.MorningCompleted;
        }
        else
        {
            log.EveningCompleted = progress.EveningCompleted;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private static string? NormalizeRoutineType(string routineType)
    {
        if (routineType.Equals("Morning", StringComparison.OrdinalIgnoreCase))
        {
            return "Morning";
        }

        if (routineType.Equals("Evening", StringComparison.OrdinalIgnoreCase))
        {
            return "Evening";
        }

        return null;
    }

    private static (DateTime StartUtc, DateTime EndUtc) TodayRangeUtc()
    {
        var start = DateTime.UtcNow.Date;
        return (start, start.AddDays(1));
    }
}
