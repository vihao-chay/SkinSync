using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using SkinSync.Base;
using SkinSync.Data;
using SkinSync.Models.Dtos;
using SkinSync.Models.Entities;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/app-installs")]
public class AppInstallsController : ControllerBase
{
    private readonly AppDbContext _dbContext;

    public AppInstallsController(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet("summary")]
    [AllowAnonymous]
    public async Task<ResponseEntity<AppInstallSummaryResponseDto>> Summary(CancellationToken cancellationToken)
    {
        var totalDownloads = await _dbContext.AppInstallEvents.CountAsync(cancellationToken);
        return ResponseEntity<AppInstallSummaryResponseDto>.Ok(
            new AppInstallSummaryResponseDto
            {
                TotalDownloads = totalDownloads
            });
    }

    [HttpPost("record")]
    [AllowAnonymous]
    public async Task<ResponseEntity<AppInstallRecordResponseDto>> Record(
        [FromBody] AppInstallRecordRequestDto? request,
        CancellationToken cancellationToken)
    {
        if (request is null)
        {
            return ResponseEntity<AppInstallRecordResponseDto>.Fail("Request body is required.", 400);
        }

        var installationId = request.InstallationId.Trim();
        if (string.IsNullOrWhiteSpace(installationId))
        {
            return ResponseEntity<AppInstallRecordResponseDto>.Fail("InstallationId is required.", 400);
        }

        if (installationId.Length > 80)
        {
            installationId = installationId[..80];
        }

        var now = DateTime.UtcNow;
        var existing = await _dbContext.AppInstallEvents
            .FirstOrDefaultAsync(x => x.InstallationId == installationId, cancellationToken);

        var recorded = false;
        if (existing is null)
        {
            _dbContext.AppInstallEvents.Add(new AppInstallEvent
            {
                Id = Guid.NewGuid(),
                InstallationId = installationId,
                Platform = NormalizeValue(request.Platform, "unknown", 40),
                AppVersion = NormalizeNullableValue(request.AppVersion, 40),
                FirstSeenAt = now,
                LastSeenAt = now
            });
            recorded = true;
        }
        else
        {
            existing.LastSeenAt = now;
            existing.Platform = NormalizeValue(request.Platform, existing.Platform, 40);
            existing.AppVersion = NormalizeNullableValue(request.AppVersion, 40) ?? existing.AppVersion;
        }

        try
        {
            await _dbContext.SaveChangesAsync(cancellationToken);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException { SqlState: PostgresErrorCodes.UniqueViolation })
        {
            recorded = false;
            _dbContext.ChangeTracker.Clear();
        }

        var totalDownloads = await _dbContext.AppInstallEvents.CountAsync(cancellationToken);
        return ResponseEntity<AppInstallRecordResponseDto>.Ok(
            new AppInstallRecordResponseDto
            {
                Recorded = recorded,
                TotalDownloads = totalDownloads
            },
            recorded ? "App install recorded successfully." : "App install was already recorded.");
    }

    private static string NormalizeValue(string? value, string fallback, int maxLength)
    {
        var normalized = string.IsNullOrWhiteSpace(value) ? fallback : value.Trim();
        return normalized.Length <= maxLength ? normalized : normalized[..maxLength];
    }

    private static string? NormalizeNullableValue(string? value, int maxLength)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var normalized = value.Trim();
        return normalized.Length <= maxLength ? normalized : normalized[..maxLength];
    }
}
