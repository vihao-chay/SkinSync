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
    Task<SkinProgressPhotoDto> UploadAnalysisPhotoAsync(Guid userId, SkinProgressPhotoUploadRequestDto request, CancellationToken cancellationToken);
    Task<IReadOnlyCollection<SkinProgressPhotoDto>> GetPhotosAsync(Guid userId, CancellationToken cancellationToken);
    Task DeletePhotoAsync(Guid userId, Guid photoId, CancellationToken cancellationToken);
    Task<SkinProgressDashboardResponseDto> GetDashboardAsync(Guid userId, SkinProgressDashboardQueryDto query, CancellationToken cancellationToken);
    Task<SkinProgressOverviewResponseDto> GetOverviewAsync(Guid userId, CancellationToken cancellationToken);
    Task<SkinProgressTimelineResponseDto> GetTimelineAsync(Guid userId, SkinProgressTimelineQueryDto query, CancellationToken cancellationToken);
    Task<SkinProgressEntryDetailDto> GetEntryDetailAsync(Guid userId, Guid entryId, CancellationToken cancellationToken);
}

public class SkinProgressService : ISkinProgressService
{
    private readonly AppDbContext _dbContext;
    private readonly IImageStorageService _imageStorageService;
    private readonly IAiUsageService _aiUsageService;

    public SkinProgressService(
        AppDbContext dbContext,
        IImageStorageService imageStorageService,
        IAiUsageService aiUsageService)
    {
        _dbContext = dbContext;
        _imageStorageService = imageStorageService;
        _aiUsageService = aiUsageService;
    }

    public async Task<SkinProgressPhotoDto> UploadPhotoAsync(Guid userId, SkinProgressPhotoUploadRequestDto request, CancellationToken cancellationToken)
    {
        return await UploadPhotoCoreAsync(userId, request, enforceProgressQuota: true, cancellationToken);
    }

    public async Task<SkinProgressPhotoDto> UploadAnalysisPhotoAsync(Guid userId, SkinProgressPhotoUploadRequestDto request, CancellationToken cancellationToken)
    {
        return await UploadPhotoCoreAsync(userId, request, enforceProgressQuota: false, cancellationToken);
    }

    private async Task<SkinProgressPhotoDto> UploadPhotoCoreAsync(
        Guid userId,
        SkinProgressPhotoUploadRequestDto request,
        bool enforceProgressQuota,
        CancellationToken cancellationToken)
    {
        try
        {
            if (request.Image is null && string.IsNullOrWhiteSpace(request.ImageUrl))
            {
                throw new AiFeatureException("INVALID_REQUEST", "Image file or imageUrl is required.");
            }

            if (enforceProgressQuota)
            {
                await _aiUsageService.CheckLimitAsync(userId, "progress_entry", cancellationToken);
            }

            var imageUrl = await _imageStorageService.StoreSkinProgressPhotoAsync(request, cancellationToken);
            var metadataJson = System.Text.Json.JsonSerializer.Serialize(new
            {
                fileName = request.Image?.FileName,
                contentType = request.Image?.ContentType,
                length = request.Image?.Length
            });
            var photo = new SkinProgressPhoto
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                ImageUrl = imageUrl,
                ThumbnailUrl = imageUrl,
                Source = NormalizeSource(request.Source),
                ImageMetadataJson = request.Image is null ? null : metadataJson,
                PhotoDate = request.PhotoDate ?? DateOnly.FromDateTime(DateTime.UtcNow.Date),
                TimeOfDay = NormalizeEnum(request.TimeOfDay, "unknown"),
                LightingCondition = NormalizeEnum(request.LightingCondition, "unknown"),
                FaceAngle = NormalizeEnum(request.FaceAngle, "unknown"),
                Note = request.Note?.Trim(),
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.SkinProgressPhotos.Add(photo);
            await _dbContext.SaveChangesAsync(cancellationToken);
            if (enforceProgressQuota)
            {
                await _aiUsageService.LogUsageAsync(userId, "progress_entry", null, null, null, cancellationToken);
            }

            return photo.ToDto();
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException pgEx && IsMissingRelation(pgEx))
        {
            throw BuildSchemaMissingException(pgEx);
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

            _imageStorageService.TryDeleteLocalFile(photo.ImageUrl);
            if (!string.Equals(photo.ThumbnailUrl, photo.ImageUrl, StringComparison.OrdinalIgnoreCase))
            {
                _imageStorageService.TryDeleteLocalFile(photo.ThumbnailUrl);
            }
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException pgEx && IsMissingRelation(pgEx))
        {
            throw BuildSchemaMissingException(pgEx);
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
                .Where(x => x.UserId == userId && photoIds.Contains(x.PhotoId) && x.DiscardedAt == null && x.Status != "discarded")
                .OrderBy(x => x.CreatedAt)
                .ToListAsync(cancellationToken);

            var beforePhoto = photos.First();
            var afterPhoto = photos.Count > 1 ? photos.Last() : null;
            var beforeAnalysis = analyses.FirstOrDefault(x => x.PhotoId == beforePhoto.Id);
            var afterAnalysis = afterPhoto is null ? null : analyses.LastOrDefault(x => x.PhotoId == afterPhoto.Id);
            var latestAnalysis = analyses.LastOrDefault();

            var latestReport = await _dbContext.SkinProgressReports
                .AsNoTracking()
                .Where(x =>
                    x.UserId == userId &&
                    x.ReportCategory == "progress_timeline" &&
                    x.PeriodType == periodType &&
                    x.PeriodStart == periodStart &&
                    x.PeriodEnd == periodEnd)
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

    public async Task<SkinProgressOverviewResponseDto> GetOverviewAsync(Guid userId, CancellationToken cancellationToken)
    {
        try
        {
            var entries = await LoadTimelineEntriesAsync(userId, null, null, cancellationToken);
            var visibleAnalyses = entries.Where(x => x.Analysis is not null).Select(x => x.Analysis!).ToList();
            var latest = visibleAnalyses.OrderByDescending(x => x.CompletedAt ?? x.CreatedAt).FirstOrDefault();
            var earliest = visibleAnalyses.OrderBy(x => x.CompletedAt ?? x.CreatedAt).FirstOrDefault();
            int? delta = latest is null || earliest is null
                ? null
                : latest.OverallScore - earliest.OverallScore;

            return new SkinProgressOverviewResponseDto
            {
                LatestScore = latest?.OverallScore,
                ScoreDelta = delta,
                LatestEntryId = latest?.PhotoId,
                TotalEntries = visibleAnalyses.Count,
                CurrentStreak = CalculatePhotoStreak(entries.Select(x => x.Photo).ToList()),
                RoutineAdherenceRate = null,
                MainConcerns = latest is null
                    ? Array.Empty<string>()
                    : SkinProgressMapper.ParseConcernArray(latest.DetectedConcerns)
                        .Select(x => x.Label)
                        .Where(x => !string.IsNullOrWhiteSpace(x))
                        .Distinct(StringComparer.OrdinalIgnoreCase)
                        .Take(4)
                        .ToList(),
                TrendSummary = BuildTrendSummary(delta),
                ChartData = entries
                    .Where(x => x.Analysis is not null)
                    .OrderBy(x => x.Analysis!.CompletedAt ?? x.Analysis!.CreatedAt)
                    .Select(x => new SkinProgressChartPointDto
                    {
                        EntryId = x.Photo.Id,
                        CreatedAt = x.Analysis!.CompletedAt ?? x.Analysis!.CreatedAt,
                        SkinScore = x.Analysis!.OverallScore,
                        AcneLevel = x.Analysis!.AcneScore,
                        RednessLevel = x.Analysis!.RednessScore,
                        DarkSpotLevel = x.Analysis!.DarkSpotScore,
                        TextureLevel = x.Analysis!.TextureScore,
                        HydrationLevel = null
                    })
                    .ToList()
            };
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
    }

    public async Task<SkinProgressTimelineResponseDto> GetTimelineAsync(Guid userId, SkinProgressTimelineQueryDto query, CancellationToken cancellationToken)
    {
        try
        {
            var entries = await LoadTimelineEntriesAsync(userId, query.FromDate, query.ToDate, cancellationToken);
            var page = Math.Max(query.Page, 1);
            var pageSize = Math.Clamp(query.PageSize, 1, 100);

            return new SkinProgressTimelineResponseDto
            {
                Items = entries
                    .OrderByDescending(x => x.Analysis?.CompletedAt ?? x.Analysis?.CreatedAt ?? x.Photo.CreatedAt)
                    .Skip((page - 1) * pageSize)
                    .Take(pageSize)
                    .Select(x => x.Photo.ToTimelineDto(x.Analysis))
                    .ToList()
            };
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
    }

    public async Task<SkinProgressEntryDetailDto> GetEntryDetailAsync(Guid userId, Guid entryId, CancellationToken cancellationToken)
    {
        try
        {
            var photo = await _dbContext.SkinProgressPhotos
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.UserId == userId && x.Id == entryId, cancellationToken)
                ?? throw new AiFeatureException("ENTRY_NOT_FOUND", "Progress entry not found.", 404);

            var analysis = await _dbContext.SkinProgressAnalyses
                .AsNoTracking()
                .Where(x => x.UserId == userId && x.PhotoId == entryId && x.DiscardedAt == null && x.Status != "discarded")
                .OrderByDescending(x => x.CompletedAt ?? x.CreatedAt)
                .FirstOrDefaultAsync(cancellationToken);

            return photo.ToEntryDetailDto(analysis);
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
    }

    private static string NormalizeEnum(string? value, string fallback)
    {
        var normalized = value?.Trim().ToLowerInvariant();
        return string.IsNullOrWhiteSpace(normalized) ? fallback : normalized;
    }

    private static string NormalizeSource(string? value)
    {
        var normalized = NormalizeEnum(value, "unknown");
        return normalized is "dashboard" or "ai_hub" or "progress" or "onboarding" ? normalized : "unknown";
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
        if (delta > 0)
        {
            return "improved";
        }

        if (delta < 0)
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

    private async Task<List<(SkinProgressPhoto Photo, SkinProgressAnalysis? Analysis)>> LoadTimelineEntriesAsync(
        Guid userId,
        DateOnly? fromDate,
        DateOnly? toDate,
        CancellationToken cancellationToken)
    {
        var photoQuery = _dbContext.SkinProgressPhotos
            .AsNoTracking()
            .Where(x => x.UserId == userId);

        if (fromDate.HasValue)
        {
            photoQuery = photoQuery.Where(x => x.PhotoDate >= fromDate.Value);
        }

        if (toDate.HasValue)
        {
            photoQuery = photoQuery.Where(x => x.PhotoDate <= toDate.Value);
        }

        var photos = await photoQuery
            .OrderByDescending(x => x.PhotoDate)
            .ThenByDescending(x => x.CreatedAt)
            .ToListAsync(cancellationToken);

        if (photos.Count == 0)
        {
            return [];
        }

        var photoIds = photos.Select(x => x.Id).ToList();
        var analyses = await _dbContext.SkinProgressAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId && photoIds.Contains(x.PhotoId) && x.DiscardedAt == null && x.Status != "discarded")
            .OrderByDescending(x => x.CompletedAt ?? x.CreatedAt)
            .ToListAsync(cancellationToken);

        var analysisByPhotoId = analyses
            .GroupBy(x => x.PhotoId)
            .ToDictionary(x => x.Key, x => x.FirstOrDefault());

        return photos
            .Select(photo => (photo, analysisByPhotoId.GetValueOrDefault(photo.Id)))
            .ToList();
    }

    private static int CalculatePhotoStreak(IReadOnlyCollection<SkinProgressPhoto> photos)
    {
        var days = photos
            .Select(x => x.PhotoDate)
            .Distinct()
            .OrderByDescending(x => x)
            .ToList();

        if (days.Count == 0)
        {
            return 0;
        }

        var streak = 1;
        for (var index = 1; index < days.Count; index++)
        {
            if (days[index - 1].DayNumber - days[index].DayNumber == 1)
            {
                streak++;
                continue;
            }

            break;
        }

        return streak;
    }

    private static string BuildTrendSummary(int? delta)
    {
        if (delta is null)
        {
            return "Add another analysis to unlock a clearer progress trend.";
        }

        if (delta > 0)
        {
            return $"Your latest skin score improved by {delta} points.";
        }

        if (delta < 0)
        {
            return $"Your latest skin score dropped by {Math.Abs(delta.Value)} points and may need extra care.";
        }

        return "Your tracked skin score is stable across recent entries.";
    }

    private static bool IsMissingRelation(PostgresException ex) =>
        ex.SqlState is PostgresErrorCodes.UndefinedTable or PostgresErrorCodes.UndefinedColumn;

    private static AiFeatureException BuildSchemaMissingException(PostgresException ex) =>
        new("SKIN_PROGRESS_SCHEMA_MISSING", "Skin progress schema is outdated. Apply BE_SkinSync/sql/2026-06-11-unify-skin-analysis-progress.sql before using this feature.", 503, ex);
}
