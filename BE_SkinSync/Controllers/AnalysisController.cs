using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinSync.Base;
using SkinSync.Helpers;
using SkinSync.Models.Dtos;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Dtos.Analysis;
using SkinSync.Services.AIPlatform;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AnalysisController : ControllerBase
{
    private readonly ISkinAnalysisService _skinAnalysisService;

    public AnalysisController(ISkinAnalysisService skinAnalysisService)
    {
        _skinAnalysisService = skinAnalysisService;
    }

    [HttpPost("scan")]
    [Consumes("multipart/form-data")]
    public async Task<ResponseEntity<AnalysisScanResponseDto>> Scan([FromForm] AnalysisScanRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<AnalysisScanResponseDto>.Fail("Missing authenticated user.", 401);
        }

        var analysis = await _skinAnalysisService.AnalyzeAsync(
            userId,
            new AiSkinAnalysisRequestDto
            {
                Image = request.Image,
                Source = "dashboard"
            },
            cancellationToken);

        return ResponseEntity<AnalysisScanResponseDto>.Ok(new AnalysisScanResponseDto
        {
            Analysis = await BuildLegacyDetailAsync(userId, analysis.AnalysisResultId, cancellationToken)
                ?? throw new InvalidOperationException("Canonical analysis could not be mapped to legacy response."),
            RegimenId = Guid.Empty,
            StartDate = DateOnly.FromDateTime(DateTime.UtcNow.Date),
            EndDate = null,
            IsActive = false,
            ItemCount = 0
        }, "Skin analysis completed successfully.");
    }

    [HttpGet("history")]
    public async Task<ResponseEntity<PagingResult<AnalysisHistoryItemDto>>> History(
        [FromQuery] AnalysisHistoryQueryDto query,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<PagingResult<AnalysisHistoryItemDto>>.Fail("Missing authenticated user.", 401);
        }

        var items = await (_skinAnalysisService as SkinAnalysisService)!.GetLegacyHistoryAsync(userId, cancellationToken);
        var pagedItems = items
            .Skip(Math.Max(query.PageIndex - 1, 0) * query.PageSize)
            .Take(query.PageSize)
            .ToList();

        return ResponseEntity<PagingResult<AnalysisHistoryItemDto>>.Ok(new PagingResult<AnalysisHistoryItemDto>
        {
            Items = pagedItems,
            Search = query.Search,
            SortBy = query.SortBy ?? string.Empty,
            SortDirection = query.SortDirection,
            PageIndex = query.PageIndex,
            PageSize = query.PageSize,
            TotalRow = items.Count
        }, "Fetched analysis history successfully.");
    }

    [HttpGet("latest")]
    public async Task<ResponseEntity<AnalysisDetailResponseDto>> Latest(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<AnalysisDetailResponseDto>.Fail("Missing authenticated user.", 401);
        }

        var detail = await (_skinAnalysisService as SkinAnalysisService)!.GetLegacyLatestAsync(userId, cancellationToken);
        if (detail is null)
        {
            return ResponseEntity<AnalysisDetailResponseDto>.Fail("No analysis found.", 404);
        }

        return ResponseEntity<AnalysisDetailResponseDto>.Ok(detail, "Fetched latest analysis successfully.");
    }

    [HttpGet("{id:guid}")]
    public async Task<ResponseEntity<AnalysisDetailResponseDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<AnalysisDetailResponseDto>.Fail("Missing authenticated user.", 401);
        }

        var detail = await BuildLegacyDetailAsync(userId, id, cancellationToken);
        if (detail is null)
        {
            return ResponseEntity<AnalysisDetailResponseDto>.Fail("Analysis not found.", 404);
        }

        return ResponseEntity<AnalysisDetailResponseDto>.Ok(detail, "Fetched analysis successfully.");
    }

    private Task<AnalysisDetailResponseDto?> BuildLegacyDetailAsync(Guid userId, Guid analysisId, CancellationToken cancellationToken) =>
        (_skinAnalysisService as SkinAnalysisService)!.GetLegacyDetailAsync(userId, analysisId, cancellationToken);
}
