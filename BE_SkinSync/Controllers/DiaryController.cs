using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinSync.Base;
using SkinSync.Helpers;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.Diary;
using SkinSync.Models.Entities;
using SkinSync.Repositories;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/diary")]
[Authorize]
public class DiaryController : ControllerBase
{
    private readonly IDiaryRepository _diaryRepository;
    private readonly IWebHostEnvironment _environment;

    public DiaryController(IDiaryRepository diaryRepository, IWebHostEnvironment environment)
    {
        _diaryRepository = diaryRepository;
        _environment = environment;
    }

    [HttpGet("today")]
    public async Task<ResponseEntity<DiaryCheckInResponseDto>> GetToday(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<DiaryCheckInResponseDto>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        var date = DateOnly.FromDateTime(DateTime.UtcNow.Date);
        var log = await _diaryRepository.GetByUserAndDateAsync(id, date, cancellationToken);
        if (log is null)
        {
            return ResponseEntity<DiaryCheckInResponseDto>.Fail("ChÆ°a cÃ³ check-in hÃ´m nay.", 404);
        }

        return ResponseEntity<DiaryCheckInResponseDto>.Ok(log.ToCheckInDto(), "Láº¥y check-in hÃ´m nay thÃ nh cÃ´ng.");
    }

    [HttpGet("day")]
    public async Task<ResponseEntity<DiaryCheckInResponseDto>> GetByDate(
        [FromQuery] DateOnly date,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<DiaryCheckInResponseDto>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        var log = await _diaryRepository.GetByUserAndDateAsync(id, date, cancellationToken);
        if (log is null)
        {
            return ResponseEntity<DiaryCheckInResponseDto>.Fail("KhÃ´ng tÃ¬m tháº¥y check-in.", 404);
        }

        return ResponseEntity<DiaryCheckInResponseDto>.Ok(log.ToCheckInDto(), "Láº¥y check-in thÃ nh cÃ´ng.");
    }

    [HttpPost("check-in")]
    [Consumes("multipart/form-data")]
    public async Task<ResponseEntity<DiaryCheckInResponseDto>> CheckIn([FromForm] DiaryCheckInRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<DiaryCheckInResponseDto>.Fail("Thiáº¿u thÃ´ng tin ngÆ°á»i dÃ¹ng.", 401);
        }

        var date = request.Date ?? DateOnly.FromDateTime(DateTime.UtcNow.Date);
        var existing = await _diaryRepository.GetByUserAndDateAsync(id, date, cancellationToken);

        string? imageUrl = existing?.DailyImageUrl;
        if (request.Image is not null && request.Image.Length > 0)
        {
            var uploadDir = Path.Combine(_environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot"), "uploads", "diary");
            Directory.CreateDirectory(uploadDir);

            var extension = Path.GetExtension(request.Image.FileName);
            var fileName = $"{Guid.NewGuid():N}{extension}";
            var fullPath = Path.Combine(uploadDir, fileName);

            await using var fs = System.IO.File.Create(fullPath);
            await request.Image.CopyToAsync(fs, cancellationToken);
            imageUrl = $"/uploads/diary/{fileName}";
        }

        if (existing is null)
        {
            var payload = new DailyLogPayload
            {
                Note = request.Notes,
                AcneLevel = request.AcneLevel,
                DrynessLevel = request.DrynessLevel,
                RednessLevel = request.RednessLevel,
                IrritationLevel = request.IrritationLevel,
                HydrationLevel = request.HydrationLevel
            };

            var newLog = new DailyLog
            {
                Id = Guid.NewGuid(),
                UserId = id,
                Date = date,
                MorningCompleted = request.MorningCompleted,
                EveningCompleted = request.EveningCompleted,
                SkinFeeling = request.SkinFeeling,
                IsIrritated = request.IsIrritated,
                Notes = DailyLogPayloadHelper.Serialize(payload),
                DailyImageUrl = imageUrl
            };

            await _diaryRepository.AddAsync(newLog, cancellationToken);
            return ResponseEntity<DiaryCheckInResponseDto>.Ok(newLog.ToCheckInDto(), "Cáº­p nháº­t check-in thÃ nh cÃ´ng.");
        }

        var updatedPayload = new DailyLogPayload
        {
            Note = request.Notes,
            AcneLevel = request.AcneLevel,
            DrynessLevel = request.DrynessLevel,
            RednessLevel = request.RednessLevel,
            IrritationLevel = request.IrritationLevel,
            HydrationLevel = request.HydrationLevel
        };

        existing.MorningCompleted = request.MorningCompleted;
        existing.EveningCompleted = request.EveningCompleted;
        existing.SkinFeeling = request.SkinFeeling;
        existing.IsIrritated = request.IsIrritated;
        existing.Notes = DailyLogPayloadHelper.Serialize(updatedPayload);
        existing.DailyImageUrl = imageUrl;

        await _diaryRepository.UpdateAsync(existing, cancellationToken);
        return ResponseEntity<DiaryCheckInResponseDto>.Ok(existing.ToCheckInDto(), "Cáº­p nháº­t check-in thÃ nh cÃ´ng.");
    }

    [HttpGet("month")]
    public async Task<ResponseEntity<PagingResult<MonthlyDiaryDayDto>>> GetMonth(
        [FromQuery] DiaryMonthQueryDto query,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var id))
        {
            return ResponseEntity<PagingResult<MonthlyDiaryDayDto>>.Fail("Missing authenticated user.", 401);
        }

        var now = DateTime.UtcNow;
        var selectedYear = query.Year ?? now.Year;
        var selectedMonth = query.Month ?? now.Month;

        if (selectedMonth is < 1 or > 12)
        {
            return ResponseEntity<PagingResult<MonthlyDiaryDayDto>>.Fail("Month must be between 1 and 12.");
        }

        query.Year = selectedYear;
        query.Month = selectedMonth;

        var logs = await _diaryRepository.GetPagedByUserAndMonthAsync(id, query, cancellationToken);
        var response = new PagingResult<MonthlyDiaryDayDto>
        {
            Items = logs.Items.Select(x => x.ToMonthlyDayDto()).ToList(),
            Search = logs.Search,
            SortBy = logs.SortBy,
            SortDirection = logs.SortDirection,
            Filters = logs.Filters,
            PageIndex = logs.PageIndex,
            PageSize = logs.PageSize,
            TotalRow = logs.TotalRow
        };

        return ResponseEntity<PagingResult<MonthlyDiaryDayDto>>.Ok(response, "Fetched monthly diary successfully.");
    }
}
