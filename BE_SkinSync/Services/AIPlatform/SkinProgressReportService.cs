using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using SkinSync.Data;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Entities;

namespace SkinSync.Services.AIPlatform;

public interface ISkinProgressReportService
{
    Task<SkinProgressReportResponseDto> GenerateAsync(Guid userId, SkinProgressReportGenerateRequestDto request, CancellationToken cancellationToken);
    Task<IReadOnlyCollection<SkinProgressReportSummaryDto>> GetReportsAsync(Guid userId, CancellationToken cancellationToken);
    Task<SkinProgressReportResponseDto> GetReportAsync(Guid userId, Guid reportId, CancellationToken cancellationToken);
}

public class SkinProgressReportService : ISkinProgressReportService
{
    private readonly AppDbContext _dbContext;
    private readonly IOpenAiService _openAiService;
    private readonly IAiUsageService _aiUsageService;

    public SkinProgressReportService(
        AppDbContext dbContext,
        IOpenAiService openAiService,
        IAiUsageService aiUsageService)
    {
        _dbContext = dbContext;
        _openAiService = openAiService;
        _aiUsageService = aiUsageService;
    }

    public async Task<SkinProgressReportResponseDto> GenerateAsync(Guid userId, SkinProgressReportGenerateRequestDto request, CancellationToken cancellationToken)
    {
        try
        {
            var periodType = request.PeriodType.Trim().ToLowerInvariant();
            if (periodType is not ("weekly" or "monthly" or "yearly"))
            {
                throw new AiFeatureException("INVALID_REQUEST", "periodType must be weekly, monthly, or yearly.");
            }

            if (request.PeriodEnd < request.PeriodStart)
            {
                throw new AiFeatureException("INVALID_REQUEST", "periodEnd must be on or after periodStart.");
            }

            var existing = await _dbContext.SkinProgressReports
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.UserId == userId && x.PeriodType == periodType && x.PeriodStart == request.PeriodStart && x.PeriodEnd == request.PeriodEnd, cancellationToken);
            if (existing is not null)
            {
                return existing.ToDto();
            }

            var user = await _dbContext.Users
                .Include(x => x.Profile)
                .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
                ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

            var photos = await _dbContext.SkinProgressPhotos
                .AsNoTracking()
                .Where(x => x.UserId == userId && x.PhotoDate >= request.PeriodStart && x.PhotoDate <= request.PeriodEnd)
                .OrderBy(x => x.PhotoDate)
                .ToListAsync(cancellationToken);

            var photoIds = photos.Select(x => x.Id).ToList();
            var analyses = await _dbContext.SkinProgressAnalyses
                .AsNoTracking()
                .Where(x => x.UserId == userId && photoIds.Contains(x.PhotoId))
                .OrderBy(x => x.CreatedAt)
                .ToListAsync(cancellationToken);

            if (analyses.Count < 2)
            {
                throw new AiFeatureException("INSUFFICIENT_DATA", "At least two progress analyses are required to generate a progress report.", 400);
            }

            await _aiUsageService.CheckLimitAsync(userId, "skin_progress_report", cancellationToken);

            var regimen = await _dbContext.UserRegimens
                .AsNoTracking()
                .Include(x => x.Items)
                .ThenInclude(x => x.Product)
                .FirstOrDefaultAsync(x => x.UserId == userId && x.IsActive, cancellationToken);
            var dailyLogs = await _dbContext.DailyLogs
                .AsNoTracking()
                .Where(x => x.UserId == userId && x.Date >= request.PeriodStart && x.Date <= request.PeriodEnd)
                .OrderByDescending(x => x.Date)
                .ToListAsync(cancellationToken);
            var comparisons = await _dbContext.SkinPhotoComparisons
                .AsNoTracking()
                .Where(x => x.UserId == userId && x.CreatedAt >= request.PeriodStart.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc) && x.CreatedAt <= request.PeriodEnd.ToDateTime(TimeOnly.MaxValue, DateTimeKind.Utc))
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync(cancellationToken);

            var firstAnalysis = analyses.First();
            var lastAnalysis = analyses.Last();
            var scoreChanges = new SkinProgressScoreChangesDto
            {
                AcneScoreChange = lastAnalysis.AcneScore - firstAnalysis.AcneScore,
                RednessScoreChange = lastAnalysis.RednessScore - firstAnalysis.RednessScore,
                DarkSpotScoreChange = lastAnalysis.DarkSpotScore - firstAnalysis.DarkSpotScore,
                OilinessScoreChange = lastAnalysis.OilinessScore - firstAnalysis.OilinessScore,
                DrynessScoreChange = lastAnalysis.DrynessScore - firstAnalysis.DrynessScore,
                TextureScoreChange = lastAnalysis.TextureScore - firstAnalysis.TextureScore,
                SensitivityScoreChange = lastAnalysis.SensitivityScore - firstAnalysis.SensitivityScore,
                OverallScoreChange = lastAnalysis.OverallScore - firstAnalysis.OverallScore
            };
            object routineContext = regimen is null ? new { } : regimen.ToCurrentRegimenDto();

            var aiResult = await _openAiService.GenerateJsonAsync<SkinProgressReportAiModel>(
                AiPromptLibrary.CommonSystemPrompt,
                AiPromptLibrary.BuildSkinProgressReportPrompt(
                    AiContextMapper.SerializeUserProfile(user.Profile),
                    JsonSerializer.Serialize(analyses.Select(x => x.ToDto())),
                    JsonSerializer.Serialize(comparisons.Select(x => x.ToDto())),
                    JsonSerializer.Serialize(routineContext),
                    AiContextMapper.SerializeDailyLogs(dailyLogs),
                    periodType,
                    JsonSerializer.Serialize(scoreChanges)),
                cancellationToken: cancellationToken);

            var report = new SkinProgressReport
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                PeriodType = periodType,
                PeriodStart = request.PeriodStart,
                PeriodEnd = request.PeriodEnd,
                ProgressStatus = NormalizeStatus(aiResult.Value.ProgressStatus, scoreChanges),
                Summary = aiResult.Value.Summary,
                ScoreChanges = JsonSerializer.Serialize(scoreChanges),
                MainFindings = JsonSerializer.Serialize(aiResult.Value.MainFindings),
                RoutineFeedback = aiResult.Value.RoutineFeedback,
                NextSuggestions = JsonSerializer.Serialize(aiResult.Value.NextSuggestions),
                RawAiResponse = aiResult.RawResponse,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.SkinProgressReports.Add(report);
            await _dbContext.SaveChangesAsync(cancellationToken);
            await _aiUsageService.LogUsageAsync(userId, "skin_progress_report", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);

            return report.ToDto();
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
    }

    public async Task<IReadOnlyCollection<SkinProgressReportSummaryDto>> GetReportsAsync(Guid userId, CancellationToken cancellationToken)
    {
        try
        {
            var reports = await _dbContext.SkinProgressReports
                .AsNoTracking()
                .Where(x => x.UserId == userId)
                .OrderByDescending(x => x.CreatedAt)
                .ToListAsync(cancellationToken);

            return reports.Select(x => x.ToSummaryDto()).ToList();
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
    }

    public async Task<SkinProgressReportResponseDto> GetReportAsync(Guid userId, Guid reportId, CancellationToken cancellationToken)
    {
        try
        {
            var report = await _dbContext.SkinProgressReports
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.UserId == userId && x.Id == reportId, cancellationToken)
                ?? throw new AiFeatureException("REPORT_NOT_FOUND", "Skin progress report not found.", 404);

            return report.ToDto();
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
    }

    private static string NormalizeStatus(string? value, SkinProgressScoreChangesDto scoreChanges)
    {
        var normalized = value?.Trim().ToLowerInvariant();
        if (normalized is "improved" or "stable" or "worse" or "mixed" or "insufficient_data")
        {
            return normalized;
        }

        if (scoreChanges.OverallScoreChange < 0)
        {
            return "improved";
        }

        if (scoreChanges.OverallScoreChange > 0)
        {
            return "worse";
        }

        return "stable";
    }

    private static bool IsMissingRelation(PostgresException ex) => ex.SqlState == PostgresErrorCodes.UndefinedTable;

    private static AiFeatureException BuildSchemaMissingException(PostgresException ex) =>
        new("SKIN_PROGRESS_SCHEMA_MISSING", "Skin progress tables are missing in the database. Apply the skin progress migration before using this feature.", 503, ex);
}

internal sealed class SkinProgressReportAiModel
{
    public string ProgressStatus { get; set; } = "insufficient_data";
    public string Summary { get; set; } = string.Empty;
    public List<string> MainFindings { get; set; } = [];
    public string? RoutineFeedback { get; set; }
    public List<string> NextSuggestions { get; set; } = [];
}
