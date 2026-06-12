using SkinSync.Mappers;
using SkinSync.Models.Dtos.AI;

namespace SkinSync.Services.AIPlatform;

public interface IAiReportService
{
    Task<AiReportGenerateResponseDto> GenerateAsync(Guid userId, AiReportGenerateRequestDto request, CancellationToken cancellationToken);
    Task<IReadOnlyCollection<AiReportSummaryDto>> GetReportsAsync(Guid userId, CancellationToken cancellationToken);
    Task<AiReportGenerateResponseDto> GetReportAsync(Guid userId, Guid reportId, CancellationToken cancellationToken);
}

public class AiReportService : IAiReportService
{
    private readonly ISkinProgressReportService _skinProgressReportService;

    public AiReportService(ISkinProgressReportService skinProgressReportService)
    {
        _skinProgressReportService = skinProgressReportService;
    }

    public async Task<AiReportGenerateResponseDto> GenerateAsync(Guid userId, AiReportGenerateRequestDto request, CancellationToken cancellationToken)
    {
        var report = await _skinProgressReportService.GenerateAsync(
            userId,
            new SkinProgressReportGenerateRequestDto
            {
                ReportCategory = NormalizeReportCategory(request.ReportCategory),
                Source = NormalizeSource(request.Source),
                RelatedAnalysisId = request.RelatedAnalysisId,
                PeriodType = request.PeriodType,
                PeriodStart = request.PeriodStart,
                PeriodEnd = request.PeriodEnd
            },
            cancellationToken);

        return ToAiResponse(report);
    }

    public async Task<IReadOnlyCollection<AiReportSummaryDto>> GetReportsAsync(Guid userId, CancellationToken cancellationToken)
    {
        var reports = await _skinProgressReportService.GetReportsAsync(userId, cancellationToken);
        return reports.Select(ToAiSummary).ToList();
    }

    public async Task<AiReportGenerateResponseDto> GetReportAsync(Guid userId, Guid reportId, CancellationToken cancellationToken)
    {
        var report = await _skinProgressReportService.GetReportAsync(userId, reportId, cancellationToken);
        return ToAiResponse(report);
    }

    private static AiReportGenerateResponseDto ToAiResponse(SkinProgressReportResponseDto report)
    {
        return new AiReportGenerateResponseDto
        {
            ReportId = report.ReportId,
            ReportCategory = report.ReportCategory,
            Source = report.Source,
            RelatedAnalysisId = report.RelatedAnalysisId,
            PeriodType = report.PeriodType,
            PeriodStart = report.PeriodStart,
            PeriodEnd = report.PeriodEnd,
            CreatedAt = report.CreatedAt,
            Summary = report.Summary,
            ProgressEvaluation = report.ProgressStatus,
            MainFindings = report.MainFindings,
            RoutineFeedback = report.RoutineFeedback,
            ProductFeedback = report.ProductFeedback,
            NextPlan = report.NextSuggestions,
            Warnings = Array.Empty<string>()
        };
    }

    private static AiReportSummaryDto ToAiSummary(SkinProgressReportSummaryDto report)
    {
        return new AiReportSummaryDto
        {
            ReportId = report.ReportId,
            ReportCategory = report.ReportCategory,
            Source = report.Source,
            RelatedAnalysisId = report.RelatedAnalysisId,
            PeriodType = report.PeriodType,
            Summary = report.Summary,
            ProgressEvaluation = report.ProgressStatus,
            CreatedAt = report.CreatedAt
        };
    }

    private static string NormalizeReportCategory(string? value)
    {
        var normalized = value?.Trim().ToLowerInvariant();
        return normalized is "progress_timeline" or "after_analysis" or "routine_feedback" or "product_feedback" or "general_summary"
            ? normalized
            : "after_analysis";
    }

    private static string NormalizeSource(string? value)
    {
        var normalized = value?.Trim().ToLowerInvariant();
        return normalized is "dashboard" or "ai_hub" or "progress" or "onboarding" or "system"
            ? normalized
            : "system";
    }
}
