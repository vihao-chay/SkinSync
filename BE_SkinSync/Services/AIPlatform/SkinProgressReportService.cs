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
    private static readonly HashSet<string> AllowedReportCategories = new(StringComparer.OrdinalIgnoreCase)
    {
        "progress_timeline",
        "after_analysis",
        "routine_feedback",
        "product_feedback",
        "general_summary"
    };

    private static readonly HashSet<string> AllowedSources = new(StringComparer.OrdinalIgnoreCase)
    {
        "dashboard",
        "ai_hub",
        "progress",
        "onboarding",
        "system"
    };

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
            var reportCategory = NormalizeReportCategory(request.ReportCategory);
            var source = NormalizeSource(request.Source);
            var periodType = NormalizePeriodType(request.PeriodType);

            if (reportCategory == "progress_timeline" && (!request.PeriodStart.HasValue || !request.PeriodEnd.HasValue))
            {
                throw new AiFeatureException("INVALID_REQUEST", "progress_timeline reports require periodStart and periodEnd.");
            }

            if (request.PeriodStart.HasValue && request.PeriodEnd.HasValue && request.PeriodEnd < request.PeriodStart)
            {
                throw new AiFeatureException("INVALID_REQUEST", "periodEnd must be on or after periodStart.");
            }

            if (reportCategory == "after_analysis" && request.RelatedAnalysisId is null)
            {
                throw new AiFeatureException("INVALID_REQUEST", "after_analysis reports require relatedAnalysisId.");
            }

            var existing = await _dbContext.SkinProgressReports
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    x => x.UserId == userId &&
                         x.ReportCategory == reportCategory &&
                         x.PeriodType == periodType &&
                         x.PeriodStart == request.PeriodStart &&
                         x.PeriodEnd == request.PeriodEnd &&
                         x.RelatedAnalysisId == request.RelatedAnalysisId,
                    cancellationToken);
            if (existing is not null)
            {
                return existing.ToDto();
            }

            var user = await _dbContext.Users
                .Include(x => x.Profile)
                .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
                ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

            await _aiUsageService.CheckLimitAsync(userId, reportCategory == "progress_timeline" ? "skin_progress_report" : "report_generation", cancellationToken);

            var activeRegimen = await _dbContext.UserRegimens
                .AsNoTracking()
                .Include(x => x.Items)
                .ThenInclude(x => x.Product)
                .FirstOrDefaultAsync(x => x.UserId == userId && x.IsActive, cancellationToken);

            var dailyLogs = await LoadDailyLogsAsync(userId, request.PeriodStart, request.PeriodEnd, cancellationToken);
            var context = await BuildReportContextAsync(userId, reportCategory, request, cancellationToken);

            var aiResult = await _openAiService.GenerateJsonAsync<SkinProgressReportAiModel>(
                AiPromptLibrary.CommonSystemPrompt,
                BuildPrompt(reportCategory, user, activeRegimen, dailyLogs, context),
                cancellationToken: cancellationToken);

            var report = new SkinProgressReport
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                ReportCategory = reportCategory,
                Source = source,
                RelatedAnalysisId = request.RelatedAnalysisId,
                PeriodType = periodType,
                PeriodStart = request.PeriodStart,
                PeriodEnd = request.PeriodEnd,
                ProgressStatus = NormalizeStatus(aiResult.Value.ProgressStatus, context.ScoreChanges),
                Summary = aiResult.Value.Summary,
                ScoreChanges = JsonSerializer.Serialize(context.ScoreChanges),
                MainFindings = JsonSerializer.Serialize(aiResult.Value.MainFindings),
                RoutineFeedback = aiResult.Value.RoutineFeedback,
                ProductFeedback = aiResult.Value.ProductFeedback,
                NextSuggestions = JsonSerializer.Serialize(aiResult.Value.NextSuggestions),
                RawAiResponse = aiResult.RawResponse,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.SkinProgressReports.Add(report);
            await _dbContext.SaveChangesAsync(cancellationToken);
            await _aiUsageService.LogUsageAsync(
                userId,
                reportCategory == "progress_timeline" ? "skin_progress_report" : "report_generation",
                aiResult.Model,
                aiResult.InputTokens,
                aiResult.OutputTokens,
                cancellationToken);

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

    private async Task<IReadOnlyCollection<DailyLog>> LoadDailyLogsAsync(
        Guid userId,
        DateOnly? periodStart,
        DateOnly? periodEnd,
        CancellationToken cancellationToken)
    {
        var query = _dbContext.DailyLogs.AsNoTracking().Where(x => x.UserId == userId);

        if (periodStart.HasValue)
        {
            query = query.Where(x => x.Date >= periodStart.Value);
        }

        if (periodEnd.HasValue)
        {
            query = query.Where(x => x.Date <= periodEnd.Value);
        }

        return await query
            .OrderByDescending(x => x.Date)
            .Take(31)
            .ToListAsync(cancellationToken);
    }

    private async Task<ReportContext> BuildReportContextAsync(
        Guid userId,
        string reportCategory,
        SkinProgressReportGenerateRequestDto request,
        CancellationToken cancellationToken)
    {
        if (reportCategory == "after_analysis")
        {
            var analysis = await _dbContext.SkinProgressAnalyses
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.UserId == userId && x.Id == request.RelatedAnalysisId, cancellationToken)
                ?? throw new AiFeatureException("ANALYSIS_NOT_FOUND", "Related analysis not found.", 404);

            var singleAnalysisScoreChanges = new SkinProgressScoreChangesDto();
            return new ReportContext(
                JsonSerializer.Serialize(analysis.ToDto()),
                "[]",
                singleAnalysisScoreChanges);
        }

        var analyses = await _dbContext.SkinProgressAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.DiscardedAt == null && x.Status != "discarded")
            .Where(x => !request.PeriodStart.HasValue || (x.CompletedAt ?? x.CreatedAt) >= request.PeriodStart.Value.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc))
            .Where(x => !request.PeriodEnd.HasValue || (x.CompletedAt ?? x.CreatedAt) <= request.PeriodEnd.Value.ToDateTime(TimeOnly.MaxValue, DateTimeKind.Utc))
            .OrderBy(x => x.CreatedAt)
            .ToListAsync(cancellationToken);

        if (analyses.Count == 0)
        {
            throw new AiFeatureException("INSUFFICIENT_DATA", "At least one progress analysis is required to generate a report.", 400);
        }

        var comparisons = await _dbContext.SkinPhotoComparisons
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .Where(x => !request.PeriodStart.HasValue || x.CreatedAt >= request.PeriodStart.Value.ToDateTime(TimeOnly.MinValue, DateTimeKind.Utc))
            .Where(x => !request.PeriodEnd.HasValue || x.CreatedAt <= request.PeriodEnd.Value.ToDateTime(TimeOnly.MaxValue, DateTimeKind.Utc))
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

        return new ReportContext(
            JsonSerializer.Serialize(analyses.Select(x => x.ToDto())),
            JsonSerializer.Serialize(comparisons.Select(x => x.ToDto())),
            scoreChanges);
    }

    private static string BuildPrompt(
        string reportCategory,
        User user,
        UserRegimen? activeRegimen,
        IReadOnlyCollection<DailyLog> dailyLogs,
        ReportContext context)
    {
        if (reportCategory == "after_analysis")
        {
            return AiPromptLibrary.BuildReportPrompt(
                AiContextMapper.SerializeUserProfile(user.Profile),
                context.AnalysesJson,
                JsonSerializer.Serialize(activeRegimen?.ToCurrentRegimenDto() ?? new object()),
                AiContextMapper.SerializeDailyLogs(dailyLogs),
                "after_analysis");
        }

        return AiPromptLibrary.BuildSkinProgressReportPrompt(
            AiContextMapper.SerializeUserProfile(user.Profile),
            context.AnalysesJson,
            context.ComparisonsJson,
            JsonSerializer.Serialize(activeRegimen?.ToCurrentRegimenDto() ?? new object()),
            AiContextMapper.SerializeDailyLogs(dailyLogs),
            reportCategory == "progress_timeline" ? "monthly" : reportCategory,
            JsonSerializer.Serialize(context.ScoreChanges));
    }

    private static string NormalizeReportCategory(string? value)
    {
        var normalized = value?.Trim().ToLowerInvariant();
        if (normalized is null || !AllowedReportCategories.Contains(normalized))
        {
            return "progress_timeline";
        }

        return normalized;
    }

    private static string NormalizeSource(string? value)
    {
        var normalized = value?.Trim().ToLowerInvariant();
        if (normalized is null || !AllowedSources.Contains(normalized))
        {
            return "system";
        }

        return normalized;
    }

    private static string? NormalizePeriodType(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        var normalized = value.Trim().ToLowerInvariant();
        return normalized is "weekly" or "monthly" or "yearly" ? normalized : null;
    }

    private static string NormalizeStatus(string? value, SkinProgressScoreChangesDto scoreChanges)
    {
        var normalized = value?.Trim().ToLowerInvariant();
        if (normalized is "improved" or "stable" or "worse" or "mixed" or "insufficient_data")
        {
            return normalized;
        }

        if (scoreChanges.OverallScoreChange > 0)
        {
            return "improved";
        }

        if (scoreChanges.OverallScoreChange < 0)
        {
            return "worse";
        }

        return "stable";
    }

    private static bool IsMissingRelation(PostgresException ex) =>
        ex.SqlState is PostgresErrorCodes.UndefinedTable or PostgresErrorCodes.UndefinedColumn;

    private static AiFeatureException BuildSchemaMissingException(PostgresException ex) =>
        new("SKIN_PROGRESS_SCHEMA_MISSING", "Skin progress schema is outdated. Apply the latest backend schema update before using this feature.", 503, ex);

    private sealed record ReportContext(
        string AnalysesJson,
        string ComparisonsJson,
        SkinProgressScoreChangesDto ScoreChanges);
}

internal sealed class SkinProgressReportAiModel
{
    public string ProgressStatus { get; set; } = "insufficient_data";
    public string Summary { get; set; } = string.Empty;
    public List<string> MainFindings { get; set; } = [];
    public string? RoutineFeedback { get; set; }
    public string? ProductFeedback { get; set; }
    public List<string> NextSuggestions { get; set; } = [];
}
