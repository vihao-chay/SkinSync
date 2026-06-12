using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinSync.Base;
using SkinSync.Helpers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Services;
using SkinSync.Services.AIPlatform;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/skin-progress")]
[Authorize]
public class SkinProgressController : ControllerBase
{
    private readonly ISkinProgressService _skinProgressService;
    private readonly ISkinProgressComparisonService _skinProgressComparisonService;
    private readonly ISkinProgressReportService _skinProgressReportService;
    private readonly IAiUsageService _aiUsageService;
    private readonly IReportPdfService _reportPdfService;

    public SkinProgressController(
        ISkinProgressService skinProgressService,
        ISkinProgressComparisonService skinProgressComparisonService,
        ISkinProgressReportService skinProgressReportService,
        IAiUsageService aiUsageService,
        IReportPdfService reportPdfService)
    {
        _skinProgressService = skinProgressService;
        _skinProgressComparisonService = skinProgressComparisonService;
        _skinProgressReportService = skinProgressReportService;
        _aiUsageService = aiUsageService;
        _reportPdfService = reportPdfService;
    }

    [HttpPost("photos")]
    [Consumes("multipart/form-data")]
    public async Task<ResponseEntity<SkinProgressPhotoDto>> UploadPhoto([FromForm] SkinProgressPhotoUploadRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<SkinProgressPhotoDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _skinProgressService.UploadPhotoAsync(userId, request, cancellationToken);
            return ResponseEntity<SkinProgressPhotoDto>.Ok(data, "Skin progress photo uploaded successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<SkinProgressPhotoDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpGet("photos")]
    public async Task<ResponseEntity<IReadOnlyCollection<SkinProgressPhotoDto>>> GetPhotos(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<IReadOnlyCollection<SkinProgressPhotoDto>>.Fail("Missing authenticated user.", 401);
        }

        var data = await _skinProgressService.GetPhotosAsync(userId, cancellationToken);
        return ResponseEntity<IReadOnlyCollection<SkinProgressPhotoDto>>.Ok(data, "Skin progress photos fetched successfully.");
    }

    [HttpDelete("photos/{photoId:guid}")]
    public async Task<ResponseEntity<object>> DeletePhoto(Guid photoId, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<object>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            await _skinProgressService.DeletePhotoAsync(userId, photoId, cancellationToken);
            return ResponseEntity<object>.Ok(null, "Skin progress photo deleted successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<object>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpGet("dashboard")]
    public async Task<ResponseEntity<SkinProgressDashboardResponseDto>> GetDashboard([FromQuery] SkinProgressDashboardQueryDto query, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<SkinProgressDashboardResponseDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _skinProgressService.GetDashboardAsync(userId, query, cancellationToken);
            return ResponseEntity<SkinProgressDashboardResponseDto>.Ok(data, "Skin progress dashboard fetched successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<SkinProgressDashboardResponseDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpGet("overview")]
    public async Task<ResponseEntity<SkinProgressOverviewResponseDto>> GetOverview(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<SkinProgressOverviewResponseDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _skinProgressService.GetOverviewAsync(userId, cancellationToken);
            return ResponseEntity<SkinProgressOverviewResponseDto>.Ok(data, "Skin progress overview fetched successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<SkinProgressOverviewResponseDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpGet("timeline")]
    public async Task<ResponseEntity<IReadOnlyCollection<SkinProgressTimelineEntryDto>>> GetTimeline([FromQuery] SkinProgressTimelineQueryDto query, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<IReadOnlyCollection<SkinProgressTimelineEntryDto>>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _skinProgressService.GetTimelineAsync(userId, query, cancellationToken);
            return ResponseEntity<IReadOnlyCollection<SkinProgressTimelineEntryDto>>.Ok(data.Items, "Skin progress timeline fetched successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<IReadOnlyCollection<SkinProgressTimelineEntryDto>>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpGet("entries/{entryId:guid}")]
    public async Task<ResponseEntity<SkinProgressEntryDetailDto>> GetEntry(Guid entryId, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<SkinProgressEntryDetailDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _skinProgressService.GetEntryDetailAsync(userId, entryId, cancellationToken);
            return ResponseEntity<SkinProgressEntryDetailDto>.Ok(data, "Skin progress entry fetched successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<SkinProgressEntryDetailDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpPost("compare")]
    public async Task<ResponseEntity<SkinProgressCompareResponseDto>> Compare([FromBody] SkinProgressEntryCompareRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<SkinProgressCompareResponseDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _skinProgressComparisonService.CompareAsync(userId, new SkinProgressCompareRequestDto
            {
                BeforePhotoId = request.BeforeEntryId,
                AfterPhotoId = request.AfterEntryId
            }, cancellationToken);
            return ResponseEntity<SkinProgressCompareResponseDto>.Ok(data, "Skin progress comparison completed successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<SkinProgressCompareResponseDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpPost("reports/generate")]
    public async Task<ResponseEntity<SkinProgressReportResponseDto>> GenerateReport([FromBody] SkinProgressReportGenerateRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<SkinProgressReportResponseDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _skinProgressReportService.GenerateAsync(userId, request, cancellationToken);
            return ResponseEntity<SkinProgressReportResponseDto>.Ok(data, "Skin progress report generated successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<SkinProgressReportResponseDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpGet("reports")]
    public async Task<ResponseEntity<IReadOnlyCollection<SkinProgressReportSummaryDto>>> GetReports(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<IReadOnlyCollection<SkinProgressReportSummaryDto>>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _skinProgressReportService.GetReportsAsync(userId, cancellationToken);
            return ResponseEntity<IReadOnlyCollection<SkinProgressReportSummaryDto>>.Ok(data, "Skin progress reports fetched successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<IReadOnlyCollection<SkinProgressReportSummaryDto>>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpGet("reports/{reportId:guid}")]
    public async Task<ResponseEntity<SkinProgressReportResponseDto>> GetReport(Guid reportId, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<SkinProgressReportResponseDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _skinProgressReportService.GetReportAsync(userId, reportId, cancellationToken);
            return ResponseEntity<SkinProgressReportResponseDto>.Ok(data, "Skin progress report fetched successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<SkinProgressReportResponseDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpGet("reports/{reportId:guid}/export-pdf")]
    public async Task<IActionResult> ExportReportPdf(Guid reportId, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return Unauthorized(ResponseEntity<object>.Fail("Missing authenticated user.", 401));
        }

        try
        {
            await _aiUsageService.CheckFeatureEnabledAsync(userId, "export_pdf", cancellationToken);
            var report = await _skinProgressReportService.GetReportAsync(userId, reportId, cancellationToken);
            var pdf = _reportPdfService.BuildSkinProgressReportPdf(report);
            var fileName = $"skinsync-progress-report-{report.ReportId:N}.pdf";
            return File(pdf, "application/pdf", fileName);
        }
        catch (AiFeatureException ex)
        {
            return StatusCode(ex.StatusCode, ResponseEntity<object>.Fail(ex.Message, ex.StatusCode));
        }
    }
}
