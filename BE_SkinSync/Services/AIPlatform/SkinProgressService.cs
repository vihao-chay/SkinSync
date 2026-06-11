using Microsoft.EntityFrameworkCore;
using Npgsql;
using SkinSync.Data;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Entities;

namespace SkinSync.Services.AIPlatform;

public interface ISkinProgressService
{
    Task<SkinProgressPhotoDto> UploadPhotoAsync(Guid userId, SkinProgressPhotoUploadRequestDto request, CancellationToken cancellationToken);
    Task<IReadOnlyCollection<SkinProgressPhotoDto>> GetPhotosAsync(Guid userId, CancellationToken cancellationToken);
    Task DeletePhotoAsync(Guid userId, Guid photoId, CancellationToken cancellationToken);
    Task<SkinProgressDashboardResponseDto> GetDashboardAsync(Guid userId, SkinProgressDashboardQueryDto query, CancellationToken cancellationToken);
}

public class SkinProgressService : ISkinProgressService
{
    private readonly AppDbContext _dbContext;
    private readonly IWebHostEnvironment _environment;

    public SkinProgressService(AppDbContext dbContext, IWebHostEnvironment environment)
    {
        _dbContext = dbContext;
        _environment = environment;
    }

    public async Task<SkinProgressPhotoDto> UploadPhotoAsync(Guid userId, SkinProgressPhotoUploadRequestDto request, CancellationToken cancellationToken)
    {
        try
        {
            if (request.Image is null && string.IsNullOrWhiteSpace(request.ImageUrl))
            {
                throw new AiFeatureException("INVALID_REQUEST", "Image file or imageUrl is required.");
            }

            var imageUrl = await StorePhotoAsync(request, cancellationToken);
            var photo = new SkinProgressPhoto
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                ImageUrl = imageUrl,
                ThumbnailUrl = imageUrl,
                PhotoDate = request.PhotoDate ?? DateOnly.FromDateTime(DateTime.UtcNow.Date),
                TimeOfDay = NormalizeEnum(request.TimeOfDay, "unknown"),
                LightingCondition = NormalizeEnum(request.LightingCondition, "unknown"),
                FaceAngle = NormalizeEnum(request.FaceAngle, "unknown"),
                Note = request.Note?.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.SkinProgressPhotos.Add(photo);
            await _dbContext.SaveChangesAsync(cancellationToken);
            return photo.ToDto();
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
    }

    public async Task<IReadOnlyCollection<SkinProgressPhotoDto>> GetPhotosAsync(Guid userId, CancellationToken cancellationToken)
    {
        try
        {
            var items = await _dbContext.SkinProgressPhotos
                .AsNoTracking()
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.PhotoDate)
                .ThenByDescending(x => x.CreatedAt)
                .ToListAsync(cancellationToken);

            return items.Select(x => x.ToDto()).ToList();
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
    }

    public async Task DeletePhotoAsync(Guid userId, Guid photoId, CancellationToken cancellationToken)
    {
        try
        {
            var photo = await _dbContext.SkinProgressPhotos
                .FirstOrDefaultAsync(x => x.Id == photoId && x.UserId == userId, cancellationToken)
                ?? throw new AiFeatureException("PHOTO_NOT_FOUND", "Photo not found.", 404);

            _dbContext.SkinProgressPhotos.Remove(photo);
            await _dbContext.SaveChangesAsync(cancellationToken);

            TryDeleteLocalFile(photo.ImageUrl);
            if (!string.Equals(photo.ThumbnailUrl, photo.ImageUrl, StringComparison.OrdinalIgnoreCase))
            {
                TryDeleteLocalFile(photo.ThumbnailUrl);
            }
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
    }

    public async Task<SkinProgressDashboardResponseDto> GetDashboardAsync(Guid userId, SkinProgressDashboardQueryDto query, CancellationToken cancellationToken)
    {
        try
        {
            var (periodType, periodStart, periodEnd, periodLabel) = ResolvePeriod(query);

            var photos = await _dbContext.SkinProgressPhotos
                .AsNoTracking()
                .Where(x => x.UserId == userId && x.PhotoDate >= periodStart && x.PhotoDate <= periodEnd)
                .OrderBy(x => x.PhotoDate)
                .ThenBy(x => x.CreatedAt)
                .ToListAsync(cancellationToken);

            if (photos.Count == 0)
            {
                return new SkinProgressDashboardResponseDto
                {
                    PeriodType = periodType,
                    PeriodLabel = periodLabel,
                    ProgressStatus = "insufficient_data",
                    Summary = new SkinProgressDashboardSummaryDto
                    {
                        SkinType = "Unknown",
                        Hydration = "Unknown",
                        Oiliness = "Unknown"
                    }
                };
            }

            var photoIds = photos.Select(x => x.Id).ToList();
            var analyses = await _dbContext.SkinProgressAnalyses
                .AsNoTracking()
                .Where(x => x.UserId == userId && photoIds.Contains(x.PhotoId))
                .OrderBy(x => x.CreatedAt)
                .ToListAsync(cancellationToken);

            var beforePhoto = photos.First();
            var afterPhoto = photos.Count > 1 ? photos.Last() : null;
            var beforeAnalysis = analyses.FirstOrDefault(x => x.PhotoId == beforePhoto.Id);
            var afterAnalysis = afterPhoto is null ? null : analyses.LastOrDefault(x => x.PhotoId == afterPhoto.Id);
            var latestAnalysis = analyses.LastOrDefault();

            var latestReport = await _dbContext.SkinProgressReports
                .AsNoTracking()
                .Where(x => x.UserId == userId && x.PeriodType == periodType && x.PeriodStart == periodStart && x.PeriodEnd == periodEnd)
                .OrderByDescending(x => x.CreatedAt)
                .FirstOrDefaultAsync(cancellationToken);

            return new SkinProgressDashboardResponseDto
            {
                PeriodType = periodType,
                PeriodLabel = periodLabel,
                Summary = new SkinProgressDashboardSummaryDto
                {
                    SkinType = NormalizeDisplay(latestAnalysis?.SkinTypeEstimate),
                    Hydration = NormalizeDisplay(latestAnalysis?.HydrationLevel),
                    Oiliness = NormalizeDisplay(latestAnalysis?.OilinessLevel)
                },
                ConditionScores = BuildConditionScores(analyses, beforeAnalysis, afterAnalysis),
                VisualJourney = new SkinProgressVisualJourneyDto
                {
                    BeforePhoto = beforePhoto.ToJourneyDto(),
                    AfterPhoto = afterPhoto?.ToJourneyDto()
                },
                PhotoGallery = photos
                    .OrderByDescending(x => x.PhotoDate)
                    .ThenByDescending(x => x.CreatedAt)
                    .Select(x => x.ToDto())
                    .ToList(),
                ProgressStatus = ResolveProgressStatus(beforeAnalysis, afterAnalysis),
                AiReportSummary = latestReport?.Summary
            };
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
    }

    private async Task<string> StorePhotoAsync(SkinProgressPhotoUploadRequestDto request, CancellationToken cancellationToken)
    {
        if (request.Image is null)
        {
            return request.ImageUrl!.Trim();
        }

        var uploadDir = Path.Combine(_environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot"), "uploads", "skin-progress");
        Directory.CreateDirectory(uploadDir);

        var extension = Path.GetExtension(request.Image.FileName);
        var fileName = $"{Guid.NewGuid():N}{extension}";
        var fullPath = Path.Combine(uploadDir, fileName);

        await using var stream = File.Create(fullPath);
        await request.Image.CopyToAsync(stream, cancellationToken);
        return $"/uploads/skin-progress/{fileName}";
    }

    private void TryDeleteLocalFile(string? url)
    {
        if (string.IsNullOrWhiteSpace(url) || url.StartsWith("http", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var webRoot = _environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot");
        var fullPath = Path.Combine(webRoot, url.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
        if (File.Exists(fullPath))
        {
            File.Delete(fullPath);
        }
    }

    private static string NormalizeEnum(string? value, string fallback)
    {
        var normalized = value?.Trim().ToLowerInvariant();
        return string.IsNullOrWhiteSpace(normalized) ? fallback : normalized;
    }

    private static string NormalizeDisplay(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return "Unknown";
        }

        return string.Join(" ", value
            .Split('_', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .Select(part => char.ToUpperInvariant(part[0]) + part[1..].ToLowerInvariant()));
    }

    private static IReadOnlyCollection<SkinProgressConditionScoreDto> BuildConditionScores(
        IReadOnlyCollection<SkinProgressAnalysis> analyses,
        SkinProgressAnalysis? beforeAnalysis,
        SkinProgressAnalysis? afterAnalysis)
    {
        if (analyses.Count == 0)
        {
            return Array.Empty<SkinProgressConditionScoreDto>();
        }

        var avgAcne = (int)Math.Round(analyses.Average(x => x.AcneScore));
        var avgRedness = (int)Math.Round(analyses.Average(x => x.RednessScore));
        var avgSensitivity = (int)Math.Round(analyses.Average(x => x.SensitivityScore));
        var avgTexture = (int)Math.Round(analyses.Average(x => x.TextureScore));

        return new[]
        {
            new SkinProgressConditionScoreDto
            {
                Label = "Acne",
                Score = avgAcne,
                Change = beforeAnalysis is null || afterAnalysis is null ? null : afterAnalysis.AcneScore - beforeAnalysis.AcneScore
            },
            new SkinProgressConditionScoreDto
            {
                Label = "Redness",
                Score = avgRedness,
                Change = beforeAnalysis is null || afterAnalysis is null ? null : afterAnalysis.RednessScore - beforeAnalysis.RednessScore
            },
            new SkinProgressConditionScoreDto
            {
                Label = "Sensitivity",
                Score = avgSensitivity,
                Change = beforeAnalysis is null || afterAnalysis is null ? null : afterAnalysis.SensitivityScore - beforeAnalysis.SensitivityScore
            },
            new SkinProgressConditionScoreDto
            {
                Label = "Texture",
                Score = avgTexture,
                Change = beforeAnalysis is null || afterAnalysis is null ? null : afterAnalysis.TextureScore - beforeAnalysis.TextureScore
            }
        };
    }

    private static string ResolveProgressStatus(SkinProgressAnalysis? beforeAnalysis, SkinProgressAnalysis? afterAnalysis)
    {
        if (beforeAnalysis is null || afterAnalysis is null)
        {
            return "insufficient_data";
        }

        var delta = afterAnalysis.OverallScore - beforeAnalysis.OverallScore;
        if (delta < 0)
        {
            return "improved";
        }

        if (delta > 0)
        {
            return "worse";
        }

        return "stable";
    }

    private static (string PeriodType, DateOnly PeriodStart, DateOnly PeriodEnd, string PeriodLabel) ResolvePeriod(SkinProgressDashboardQueryDto query)
    {
        var periodType = query.PeriodType.Trim().ToLowerInvariant();
        var today = DateOnly.FromDateTime(DateTime.UtcNow.Date);

        if (periodType == "weekly")
        {
            var weekStart = query.WeekStart ?? today.AddDays(-(((int)today.DayOfWeek + 6) % 7));
            var weekEnd = weekStart.AddDays(6);
            return ("weekly", weekStart, weekEnd, $"{weekStart:dd/MM/yyyy} - {weekEnd:dd/MM/yyyy}");
        }

        if (periodType == "yearly")
        {
            var year = query.Year ?? today.Year;
            var start = new DateOnly(year, 1, 1);
            var end = new DateOnly(year, 12, 31);
            return ("yearly", start, end, year.ToString());
        }

        var monthValue = string.IsNullOrWhiteSpace(query.Month)
            ? $"{today.Year:D4}-{today.Month:D2}"
            : query.Month!.Trim();
        var parts = monthValue.Split('-', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        if (parts.Length != 2 || !int.TryParse(parts[0], out var monthYear) || !int.TryParse(parts[1], out var month))
        {
            throw new AiFeatureException("INVALID_REQUEST", "Month must be in YYYY-MM format.");
        }

        var monthStart = new DateOnly(monthYear, month, 1);
        var monthEnd = new DateOnly(monthYear, month, DateTime.DaysInMonth(monthYear, month));
        return ("monthly", monthStart, monthEnd, monthStart.ToString("MMM yyyy"));
    }

    private static bool IsMissingRelation(PostgresException ex) => ex.SqlState == PostgresErrorCodes.UndefinedTable;

    private static AiFeatureException BuildSchemaMissingException(PostgresException ex) =>
        new("SKIN_PROGRESS_SCHEMA_MISSING", "Skin progress tables are missing in the database. Apply the skin progress migration before using this feature.", 503, ex);
}
