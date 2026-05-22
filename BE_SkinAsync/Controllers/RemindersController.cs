using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SkinAsync.Base;
using SkinAsync.Data;
using SkinAsync.Helpers;
using SkinAsync.Models.Dtos.Reminders;
using SkinAsync.Models.Entities;

namespace SkinAsync.Controllers;

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
            return ResponseEntity<IEnumerable<ReminderResponseDto>>.Fail("Thiếu thông tin người dùng.", 401);
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
                IsEnabled = x.IsEnabled
            })
            .ToListAsync(cancellationToken);

        return ResponseEntity<IEnumerable<ReminderResponseDto>>.Ok(reminders, "Lấy nhắc nhở thành công.");
    }

    [HttpPut]
    public async Task<ResponseEntity<ReminderResponseDto>> Upsert(
        [FromBody] ReminderUpsertRequestDto request,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<ReminderResponseDto>.Fail("Thiếu thông tin người dùng.", 401);
        }

        if (!TimeOnly.TryParse(request.Time, out var time))
        {
            return ResponseEntity<ReminderResponseDto>.Fail("Thời gian nhắc nhở không hợp lệ. Vui lòng dùng định dạng HH:mm.");
        }

        var routineType = NormalizeRoutineType(request.RoutineType);
        if (routineType is null)
        {
            return ResponseEntity<ReminderResponseDto>.Fail("RoutineType chỉ nhận Morning hoặc Evening.");
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
        reminder.IsEnabled = request.IsEnabled;

        await _dbContext.SaveChangesAsync(cancellationToken);

        return ResponseEntity<ReminderResponseDto>.Ok(ToDto(reminder), "Cập nhật nhắc nhở thành công.");
    }

    [HttpPatch("{id:guid}/toggle")]
    public async Task<ResponseEntity<ReminderResponseDto>> Toggle(Guid id, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<ReminderResponseDto>.Fail("Thiếu thông tin người dùng.", 401);
        }

        var reminder = await _dbContext.Reminders
            .FirstOrDefaultAsync(x => x.Id == id && x.UserId == userId, cancellationToken);
        if (reminder is null)
        {
            return ResponseEntity<ReminderResponseDto>.Fail("Không tìm thấy nhắc nhở.", 404);
        }

        reminder.IsEnabled = !reminder.IsEnabled;
        await _dbContext.SaveChangesAsync(cancellationToken);

        return ResponseEntity<ReminderResponseDto>.Ok(ToDto(reminder), "Cập nhật trạng thái nhắc nhở thành công.");
    }

    private static ReminderResponseDto ToDto(Reminder reminder)
    {
        return new ReminderResponseDto
        {
            ReminderId = reminder.Id,
            Time = reminder.Time.ToString("HH:mm"),
            RoutineType = reminder.RoutineType,
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
}
