using Microsoft.AspNetCore.Mvc;
using SkinAsync.Base;
using SkinAsync.Mappers;
using SkinAsync.Models.Dtos.Diary;
using SkinAsync.Models.Entities;
using SkinAsync.Repositories;

namespace SkinAsync.Controllers;

[ApiController]
[Route("api/diary")]
public class DiaryController : ControllerBase
{
    private readonly IDiaryRepository _diaryRepository;
    private readonly IWebHostEnvironment _environment;

    public DiaryController(IDiaryRepository diaryRepository, IWebHostEnvironment environment)
    {
        _diaryRepository = diaryRepository;
        _environment = environment;
    }

    [HttpPost("check-in")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> CheckIn([FromHeader(Name = "Id")] Guid id, [FromForm] DiaryCheckInRequestDto request, CancellationToken cancellationToken)
    {
        if (id == Guid.Empty)
        {
            return BadRequest("Missing Id header.");
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
            var newLog = new DailyLog
            {
                Id = Guid.NewGuid(),
                UserId = id,
                Date = date,
                MorningCompleted = request.MorningCompleted,
                EveningCompleted = request.EveningCompleted,
                SkinFeeling = request.SkinFeeling,
                IsIrritated = request.IsIrritated,
                Notes = request.Notes,
                DailyImageUrl = imageUrl
            };

            await _diaryRepository.AddAsync(newLog, cancellationToken);
            return Ok(newLog.ToCheckInDto());
        }

        existing.MorningCompleted = request.MorningCompleted;
        existing.EveningCompleted = request.EveningCompleted;
        existing.SkinFeeling = request.SkinFeeling;
        existing.IsIrritated = request.IsIrritated;
        existing.Notes = request.Notes;
        existing.DailyImageUrl = imageUrl;

        await _diaryRepository.UpdateAsync(existing, cancellationToken);
        return Ok(existing.ToCheckInDto());
    }

    [HttpGet("month")]
    public async Task<ResponseEntity<PagingResult<MonthlyDiaryDayDto>>> GetMonth(
        [FromHeader(Name = "Id")] Guid id,
        [FromQuery] DiaryMonthQueryDto query,
        CancellationToken cancellationToken)
    {
        if (id == Guid.Empty)
        {
            return ResponseEntity<PagingResult<MonthlyDiaryDayDto>>.Fail("Missing Id header.");
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
