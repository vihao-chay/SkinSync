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
    private static readonly SemaphoreSlim SchemaEnsureLock = new(1, 1);
    private static bool _schemaEnsured;
    private readonly AppDbContext _dbContext;

    public AppInstallsController(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    [HttpGet("summary")]
    [AllowAnonymous]
    public async Task<ResponseEntity<AppInstallSummaryResponseDto>> Summary(CancellationToken cancellationToken)
    {
        try
        {
            await EnsureSchemaAsync(cancellationToken);

            var totalDownloads = await _dbContext.AppInstallEvents.CountAsync(cancellationToken);
            return ResponseEntity<AppInstallSummaryResponseDto>.Ok(
                new AppInstallSummaryResponseDto
                {
                    TotalDownloads = totalDownloads
                });
        }
        catch (PostgresException ex) when (ex.SqlState is "42P01" or "42501")
        {
            return ResponseEntity<AppInstallSummaryResponseDto>.Ok(
                new AppInstallSummaryResponseDto
                {
                    TotalDownloads = 0
                },
                "App install summary is not initialized.");
        }
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

        await EnsureSchemaAsync(cancellationToken);

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

    private async Task EnsureSchemaAsync(CancellationToken cancellationToken)
    {
        if (_schemaEnsured)
        {
            return;
        }

        await SchemaEnsureLock.WaitAsync(cancellationToken);
        try
        {
            if (_schemaEnsured)
            {
                return;
            }

            await _dbContext.Database.ExecuteSqlRawAsync(
                """
                CREATE TABLE IF NOT EXISTS app_install_events (
                    "Id" uuid NOT NULL,
                    "InstallationId" character varying(80) NOT NULL,
                    "Platform" character varying(40) NOT NULL DEFAULT 'unknown',
                    "AppVersion" character varying(40) NULL,
                    "FirstSeenAt" timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
                    "LastSeenAt" timestamp with time zone NOT NULL DEFAULT timezone('utc', now()),
                    CONSTRAINT "PK_app_install_events" PRIMARY KEY ("Id")
                );

                CREATE INDEX IF NOT EXISTS "IX_app_install_events_FirstSeenAt"
                ON app_install_events ("FirstSeenAt");

                CREATE UNIQUE INDEX IF NOT EXISTS "IX_app_install_events_InstallationId"
                ON app_install_events ("InstallationId");
                """,
                cancellationToken);

            _schemaEnsured = true;
        }
        finally
        {
            SchemaEnsureLock.Release();
        }
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
