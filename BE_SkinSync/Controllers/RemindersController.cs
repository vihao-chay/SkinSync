using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SkinSync.Base;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Models.Dtos.Reminders;
using SkinSync.Models.Entities;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/reminders")]
[Authorize]
public class RemindersController : ControllerBase
{
    private readonly AppDbContext _dbContext;

    public RemindersController(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet]
    public async Task<ResponseEntity<IEnumerable<ReminderResponseDto>>> GetAll(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<IEnumerable<ReminderResponseDto>>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        var reminders = await _dbContext.Reminders
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderBy(x => x.RoutineType)
            .Select(x => new ReminderResponseDto
            {
                ReminderId = x.Id,
                Time = x.Time.ToString("HH:mm"),
                RoutineType = x.RoutineType,
                Frequency = x.Frequency,
                Reason = x.Reason,
                Priority = x.Priority,
                IsAdaptive = x.IsAdaptive,
                IsEnabled = x.IsEnabled
            })
            .ToListAsync(cancellationToken);

        return ResponseEntity<IEnumerable<ReminderResponseDto>>.Ok(reminders, "Láº¥y nháº¯c nhá»Ÿ thÃ nh cÃ´ng.");
    }

    [HttpPut]
    public async Task<ResponseEntity<ReminderResponseDto>> Upsert(
        [FromBody] ReminderUpsertRequestDto request,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<ReminderResponseDto>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        if (!TimeOnly.TryParse(request.Time, out var time))
        {
            return ResponseEntity<ReminderResponseDto>.Fail("Thá»i gian nháº¯c nhá»Ÿ khÃ´ng há»£p lá»‡. Vui lÃ²ng dÃ¹ng Ä‘á»‹nh dáº¡ng HH:mm.");
        }

        var routineType = NormalizeRoutineType(request.RoutineType);
        if (routineType is null)
        {
            return ResponseEntity<ReminderResponseDto>.Fail("RoutineType chá»‰ nháº­n Morning hoáº·c Evening.");
        }

        var reminder = await _dbContext.Reminders
            .FirstOrDefaultAsync(x => x.UserId == userId && x.RoutineType == routineType, cancellationToken);

        if (reminder is null)
        {
            reminder = new Reminder
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                RoutineType = routineType,
                CreatedAt = DateTime.UtcNow
            };
            _dbContext.Reminders.Add(reminder);
        }

        reminder.Time = time;
        reminder.Frequency = string.IsNullOrWhiteSpace(request.Frequency) ? reminder.Frequency : request.Frequency.Trim();
        reminder.Reason = string.IsNullOrWhiteSpace(request.Reason) ? null : request.Reason.Trim();
        reminder.Priority = NormalizePriority(request.Priority) ?? reminder.Priority;
        reminder.IsAdaptive = request.IsAdaptive ?? false;
        reminder.IsEnabled = request.IsEnabled;
        reminder.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);

        return ResponseEntity<ReminderResponseDto>.Ok(ToDto(reminder), "Cáº­p nháº­t nháº¯c nhá»Ÿ thÃ nh cÃ´ng.");
    }

    [HttpPatch("{id:guid}/toggle")]
    public async Task<ResponseEntity<ReminderResponseDto>> Toggle(Guid id, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<ReminderResponseDto>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        var reminder = await _dbContext.Reminders
            .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId, cancellationToken);
        if (reminder is null)
        {
            return ResponseEntity<ReminderResponseDto>.Fail("KhÃ´ng tÃ¬m tháº¥y nháº¯c nhá»Ÿ.", 404);
        }

        reminder.IsEnabled = !reminder.IsEnabled;
        reminder.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync(cancellationToken);

        return ResponseEntity<ReminderResponseDto>.Ok(ToDto(reminder), "Cáº­p nháº­t tráº¡ng thÃ¡i nháº¯c nhá»Ÿ thÃ nh cÃ´ng.");
    }

    private static ReminderResponseDto ToDto(Reminder reminder)
    {
        return new ReminderResponseDto
        {
            ReminderId = reminder.Id,
            Time = reminder.Time.ToString("HH:mm"),
            RoutineType = reminder.RoutineType,
            Frequency = reminder.Frequency,
            Reason = reminder.Reason,
            Priority = reminder.Priority,
            IsAdaptive = reminder.IsAdaptive,
            IsEnabled = reminder.IsEnabled
        };
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

    private static string? NormalizePriority(string? priority)
    {
        if (string.IsNullOrWhiteSpace(priority))
        {
            return null;
        }

        return priority.Trim().ToLowerInvariant() switch
        {
            "low" => "low",
            "medium" => "medium",
            "high" => "high",
            _ => null
        };
    }
}
