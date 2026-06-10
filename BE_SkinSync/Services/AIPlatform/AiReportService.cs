using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SkinSync.Data;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Entities;

namespace SkinSync.Services.AIPlatform;

public interface IAiReportService
{
    Task<AiReportGenerateResponseDto> GenerateAsync(Guid userId, AiReportGenerateRequestDto request, CancellationToken cancellationToken);
}

public class AiReportService : IAiReportService
{
    private readonly AppDbContext _dbContext;
    private readonly IOpenAiService _openAiService;
    private readonly IAiUsageService _aiUsageService;

    public AiReportService(AppDbContext dbContext, IOpenAiService openAiService, IAiUsageService aiUsageService)
    {
        _dbContext = dbContext;
        _openAiService = openAiService;
        _aiUsageService = aiUsageService;
    }

    public async Task<AiReportGenerateResponseDto> GenerateAsync(Guid userId, AiReportGenerateRequestDto request, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users.Include(x => x.Profile).FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

        await _aiUsageService.CheckLimitAsync(userId, "report_generation", cancellationToken);

        var analyses = await _dbContext.AiAnalyses
            .AsNoTracking()
            .Include(x => x.AnalysisIssues)
            .Include(x => x.Recommendations)
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .Take(request.ReportType.Equals("monthly", StringComparison.OrdinalIgnoreCase) ? 10 : 4)
            .ToListAsync(cancellationToken);
        var regimen = await _dbContext.UserRegimens
            .AsNoTracking()
            .Include(x => x.Items)
            .ThenInclude(x => x.Product)
            .FirstOrDefaultAsync(x => x.UserId == userId && x.IsActive, cancellationToken);
        var days = request.ReportType.Equals("monthly", StringComparison.OrdinalIgnoreCase) ? 30 : 7;
        var fromDate = DateOnly.FromDateTime(DateTime.UtcNow.Date.AddDays(-days));
        var dailyLogs = await _dbContext.DailyLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.Date >= fromDate)
            .OrderByDescending(x => x.Date)
            .ToListAsync(cancellationToken);

        if (analyses.Count == 0)
        {
            throw new AiFeatureException("INSUFFICIENT_DATA", "At least one analysis is required to generate a report.", 400);
        }

        var analysesJson = JsonSerializer.Serialize(analyses.Select(x => x.ToDetailDto()));
        var aiResult = await _openAiService.GenerateJsonAsync<AiReportGenerateAiModel>(
            AiPromptLibrary.CommonSystemPrompt,
            AiPromptLibrary.BuildReportPrompt(
                AiContextMapper.SerializeUserProfile(user.Profile),
                analysesJson,
                JsonSerializer.Serialize(regimen?.ToCurrentRegimenDto() ?? new object()),
                AiContextMapper.SerializeDailyLogs(dailyLogs),
                request.ReportType),
            cancellationToken: cancellationToken);

        var report = new AiReport
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ReportType = NormalizeReportType(request.ReportType),
            Summary = aiResult.Value.Summary,
            ProgressEvaluation = aiResult.Value.ProgressEvaluation,
            MainFindings = JsonSerializer.Serialize(aiResult.Value.MainFindings),
            RoutineFeedback = aiResult.Value.RoutineFeedback,
            ProductFeedback = aiResult.Value.ProductFeedback,
            NextPlan = JsonSerializer.Serialize(aiResult.Value.NextPlan),
            Warnings = JsonSerializer.Serialize(aiResult.Value.Warnings),
            RawAiResponse = aiResult.RawResponse,
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.AiReports.Add(report);
        await _dbContext.SaveChangesAsync(cancellationToken);
        await _aiUsageService.LogUsageAsync(userId, "report_generation", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);

        return new AiReportGenerateResponseDto
        {
            ReportId = report.Id,
            Summary = report.Summary,
            ProgressEvaluation = report.ProgressEvaluation,
            MainFindings = aiResult.Value.MainFindings,
            RoutineFeedback = report.RoutineFeedback,
            ProductFeedback = report.ProductFeedback,
            NextPlan = aiResult.Value.NextPlan,
            Warnings = aiResult.Value.Warnings
        };
    }

    private static string NormalizeReportType(string reportType)
    {
        var value = reportType.Trim().ToLowerInvariant();
        return value is "weekly" or "monthly" or "after_analysis" ? value : "after_analysis";
    }
}

internal sealed class AiReportGenerateAiModel
{
    public string Summary { get; set; } = string.Empty;
    public string ProgressEvaluation { get; set; } = "insufficient_data";
    public List<string> MainFindings { get; set; } = [];
    public string? RoutineFeedback { get; set; }
    public string? ProductFeedback { get; set; }
    public List<string> NextPlan { get; set; } = [];
    public List<string> Warnings { get; set; } = [];
}
