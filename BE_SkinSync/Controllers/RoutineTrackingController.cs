using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SkinSync.Base;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Models.Dtos.RoutineTracking;
using SkinSync.Models.Entities;

namespace SkinSync.Controllers;

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
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("Missing authenticated user.", 401);
        }

        var response = await BuildDayResponseAsync(userId, AppClock.Today, cancellationToken);
        return ResponseEntity<RoutineTrackingTodayDto>.Ok(response, "Fetched today's routine tracking successfully.");
    }

    [HttpGet("history")]
    public async Task<ResponseEntity<IEnumerable<RoutineStepTrackingDto>>> GetHistory(
        [FromQuery] int days = 30,
        CancellationToken cancellationToken = default)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<IEnumerable<RoutineStepTrackingDto>>.Fail("Missing authenticated user.", 401);
        }

        if (days is < 1 or > 365)
        {
            return ResponseEntity<IEnumerable<RoutineStepTrackingDto>>.Fail("days must be between 1 and 365.");
        }

        var fromDate = AppClock.Today.AddDays(-(days - 1));
        var history = await _dbContext.RoutineTrackings
            .AsNoTracking()
            .Include(x => x.Step)
            .ThenInclude(x => x.Product)
            .Where(x => x.UserId == userId && x.TrackingDate >= fromDate)
            .OrderByDescending(x => x.TrackingDate)
            .ThenBy(x => x.RoutineTime)
            .ThenBy(x => x.Step.StepOrder)
            .Select(x => new RoutineStepTrackingDto
            {
                TrackingId = x.Id,
                StepId = x.StepId,
                ProductId = x.Step.ProductId,
                TrackingDate = x.TrackingDate,
                RoutineTime = x.RoutineTime,
                StepOrder = x.Step.StepOrder,
                ProductName = x.Step.Product.Name,
                Status = x.Status,
                CompletedAt = x.CompletedAt
            })
            .ToListAsync(cancellationToken);

        return ResponseEntity<IEnumerable<RoutineStepTrackingDto>>.Ok(history, "Fetched routine tracking history successfully.");
    }

    [HttpPost("steps/{stepId:guid}/complete")]
    public async Task<ResponseEntity<RoutineTrackingTodayDto>> CompleteStep(Guid stepId, CancellationToken cancellationToken)
    {
        return await UpsertStepStatusAsync(stepId, "completed", cancellationToken);
    }

    [HttpDelete("steps/{stepId:guid}/complete")]
    public async Task<ResponseEntity<RoutineTrackingTodayDto>> UncompleteStep(Guid stepId, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("Missing authenticated user.", 401);
        }

        var step = await GetOwnedActiveStepAsync(userId, stepId, cancellationToken);
        if (step is null)
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("Routine step not found.", 404);
        }

        var today = AppClock.Today;
        var tracking = await _dbContext.RoutineTrackings
            .FirstOrDefaultAsync(x => x.UserId == userId && x.StepId == stepId && x.TrackingDate == today, cancellationToken);

        if (tracking is not null)
        {
            _dbContext.RoutineTrackings.Remove(tracking);
            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        await SyncDailyLogAsync(userId, today, cancellationToken);
        var response = await BuildDayResponseAsync(userId, today, cancellationToken);
        return ResponseEntity<RoutineTrackingTodayDto>.Ok(response, "Removed step completion successfully.");
    }

    [HttpPost("routines/{routineType}/complete")]
    public async Task<ResponseEntity<RoutineTrackingTodayDto>> CompleteRoutine(
        string routineType,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("Missing authenticated user.", 401);
        }

        var normalizedType = NormalizeRoutineType(routineType);
        if (normalizedType is null)
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("routineType must be Morning or Evening.");
        }

        var regimen = await _dbContext.UserRegimens
            .Include(x => x.Items)
            .FirstOrDefaultAsync(x => x.UserId == userId && x.IsActive, cancellationToken);

        if (regimen is null)
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("No active routine found.", 404);
        }

        var today = AppClock.Today;
        var steps = UniqueRegimenItems(regimen.Items)
            .Where(x => x.RoutineTime.Equals(normalizedType, StringComparison.OrdinalIgnoreCase))
            .ToList();

        foreach (var step in steps)
        {
            var tracking = await _dbContext.RoutineTrackings
                .FirstOrDefaultAsync(x => x.UserId == userId && x.StepId == step.Id && x.TrackingDate == today, cancellationToken);

            if (tracking is null)
            {
                _dbContext.RoutineTrackings.Add(new RoutineTracking
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    StepId = step.Id,
                    TrackingDate = today,
                    RoutineTime = step.RoutineTime,
                    Status = "completed",
                    CompletedAt = DateTime.UtcNow
                });
            }
            else
            {
                tracking.RoutineTime = step.RoutineTime;
                tracking.Status = "completed";
                tracking.CompletedAt = DateTime.UtcNow;
            }
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
        await SyncDailyLogAsync(userId, today, cancellationToken);
        var response = await BuildDayResponseAsync(userId, today, cancellationToken);
        return ResponseEntity<RoutineTrackingTodayDto>.Ok(response, "Completed routine successfully.");
    }

    private async Task<ResponseEntity<RoutineTrackingTodayDto>> UpsertStepStatusAsync(Guid stepId, string status, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("Missing authenticated user.", 401);
        }

        var step = await GetOwnedActiveStepAsync(userId, stepId, cancellationToken);
        if (step is null)
        {
            return ResponseEntity<RoutineTrackingTodayDto>.Fail("Routine step not found.", 404);
        }

        var today = AppClock.Today;
        var tracking = await _dbContext.RoutineTrackings
            .FirstOrDefaultAsync(x => x.UserId == userId && x.StepId == stepId && x.TrackingDate == today, cancellationToken);

        if (tracking is null)
        {
            tracking = new RoutineTracking
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                StepId = stepId,
                TrackingDate = today,
                RoutineTime = step.RoutineTime
            };
            _dbContext.RoutineTrackings.Add(tracking);
        }

        tracking.RoutineTime = step.RoutineTime;
        tracking.Status = status;
        tracking.CompletedAt = status == "completed" ? DateTime.UtcNow : null;

        await _dbContext.SaveChangesAsync(cancellationToken);
        await SyncDailyLogAsync(userId, today, cancellationToken);
        var response = await BuildDayResponseAsync(userId, today, cancellationToken);
        return ResponseEntity<RoutineTrackingTodayDto>.Ok(response, "Updated step status successfully.");
    }

    private async Task<RegimenItem?> GetOwnedActiveStepAsync(Guid userId, Guid stepId, CancellationToken cancellationToken)
    {
        return await _dbContext.RegimenItems
            .Include(x => x.Regimen)
            .Include(x => x.Product)
            .FirstOrDefaultAsync(x => x.Id == stepId && x.Regimen.UserId == userId && x.Regimen.IsActive, cancellationToken);
    }

    private async Task<RoutineTrackingTodayDto> BuildDayResponseAsync(Guid userId, DateOnly date, CancellationToken cancellationToken)
    {
        var regimen = await _dbContext.UserRegimens
            .AsNoTracking()
            .Include(x => x.Items)
            .ThenInclude(x => x.Product)
            .FirstOrDefaultAsync(x => x.UserId == userId && x.IsActive, cancellationToken);

        if (regimen is null)
        {
            return new RoutineTrackingTodayDto { Date = date };
        }

        var trackings = await _dbContext.RoutineTrackings
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.TrackingDate == date)
            .ToListAsync(cancellationToken);

        var trackingByStep = trackings.ToDictionary(x => x.StepId, x => x);
        var steps = UniqueRegimenItems(regimen.Items)
            .OrderBy(x => x.RoutineTime)
            .ThenBy(x => x.StepOrder)
            .Select(x =>
            {
                trackingByStep.TryGetValue(x.Id, out var tracking);
                return new RoutineStepTrackingDto
                {
                    TrackingId = tracking?.Id ?? Guid.Empty,
                    StepId = x.Id,
                    ProductId = x.ProductId,
                    TrackingDate = date,
                    RoutineTime = x.RoutineTime,
                    StepOrder = x.StepOrder,
                    ProductName = x.Product.Name,
                    Status = tracking?.Status ?? "pending",
                    CompletedAt = tracking?.CompletedAt
                };
            })
            .ToList();

        var completedSteps = steps.Count(x => x.Status == "completed");
        var morningSteps = steps.Where(x => RoutineScheduleHelper.IsMorning(x.RoutineTime)).ToList();
        var eveningSteps = steps.Where(x => RoutineScheduleHelper.IsEvening(x.RoutineTime)).ToList();

        return new RoutineTrackingTodayDto
        {
            Date = date,
            TotalSteps = steps.Count,
            CompletedSteps = completedSteps,
            CompletionPercent = steps.Count == 0 ? 0 : Math.Round(completedSteps / (decimal)steps.Count * 100m, 2),
            MorningCompleted = morningSteps.Count > 0 && morningSteps.All(x => x.Status == "completed"),
            EveningCompleted = eveningSteps.Count > 0 && eveningSteps.All(x => x.Status == "completed"),
            Steps = steps
        };
    }

    private static List<RegimenItem> UniqueRegimenItems(IEnumerable<RegimenItem> items)
    {
        var seenKeys = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var unique = new List<RegimenItem>();

        foreach (var item in items.OrderBy(x => x.RoutineTime).ThenBy(x => x.StepOrder).ThenBy(x => x.CreatedAt))
        {
            var routineTime = RoutineScheduleHelper.NormalizeRoutineValue(item.RoutineTime) ?? item.RoutineTime;
            var productSignature = BuildProductSignature(item);
            var productKey = $"{routineTime}|id:{item.ProductId}";
            var signatureKey = string.IsNullOrWhiteSpace(productSignature)
                ? string.Empty
                : $"{routineTime}|sig:{productSignature}";

            if (!seenKeys.Add(productKey) ||
                (!string.IsNullOrWhiteSpace(signatureKey) && !seenKeys.Add(signatureKey)))
            {
                continue;
            }

            unique.Add(item);
        }

        return unique;
    }

    private static string BuildProductSignature(RegimenItem item)
    {
        if (item.Product is null)
        {
            return string.Empty;
        }

        var parts = new[]
        {
            NormalizeProductKeyPart(item.Product.Brand),
            NormalizeProductKeyPart(item.Product.Name),
            NormalizeProductKeyPart(item.Product.Category)
        };

        return parts.All(string.IsNullOrWhiteSpace)
            ? string.Empty
            : string.Join('|', parts);
    }

    private static string NormalizeProductKeyPart(string? value)
    {
        return string.Join(' ', (value ?? string.Empty)
            .Trim()
            .ToLowerInvariant()
            .Split(' ', StringSplitOptions.RemoveEmptyEntries));
    }

    private async Task SyncDailyLogAsync(Guid userId, DateOnly date, CancellationToken cancellationToken)
    {
        var progress = await BuildDayResponseAsync(userId, date, cancellationToken);
        var log = await _dbContext.DailyLogs.FirstOrDefaultAsync(x => x.UserId == userId && x.Date == date, cancellationToken);

        if (log is null)
        {
            log = new DailyLog
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                Date = date,
                SkinFeeling = "normal"
            };
            _dbContext.DailyLogs.Add(log);
        }

        log.MorningCompleted = progress.MorningCompleted;
        log.EveningCompleted = progress.EveningCompleted;
        log.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    private static string? NormalizeRoutineType(string routineType)
    {
        return RoutineScheduleHelper.NormalizeRoutineValue(routineType);
    }
}
