using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinSync.Base;
using SkinSync.Helpers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Services.AIPlatform;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/skin-analysis")]
[Authorize]
public class SkinAnalysisController : ControllerBase
{
    private readonly ISkinAnalysisService _skinAnalysisService;

    public SkinAnalysisController(ISkinAnalysisService skinAnalysisService)
    {
        _skinAnalysisService = skinAnalysisService;
    }

    [HttpPost]
    [Consumes("multipart/form-data")]
    public async Task<ResponseEntity<AiSkinAnalysisResponseDto>> Analyze([FromForm] AiSkinAnalysisRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<AiSkinAnalysisResponseDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _skinAnalysisService.AnalyzeAsync(userId, request, cancellationToken);
            return ResponseEntity<AiSkinAnalysisResponseDto>.Ok(data, "Skin analysis completed successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<AiSkinAnalysisResponseDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpGet("{analysisId:guid}")]
    public async Task<ResponseEntity<AiSkinAnalysisResponseDto>> GetById(Guid analysisId, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<AiSkinAnalysisResponseDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _skinAnalysisService.GetAnalysisAsync(userId, analysisId, cancellationToken);
            return ResponseEntity<AiSkinAnalysisResponseDto>.Ok(data, "Skin analysis fetched successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<AiSkinAnalysisResponseDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpGet("history")]
    public async Task<ResponseEntity<IReadOnlyCollection<AiSkinAnalysisResponseDto>>> GetHistory(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<IReadOnlyCollection<AiSkinAnalysisResponseDto>>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _skinAnalysisService.GetHistoryAsync(userId, cancellationToken);
            return ResponseEntity<IReadOnlyCollection<AiSkinAnalysisResponseDto>>.Ok(data, "Skin analysis history fetched successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<IReadOnlyCollection<AiSkinAnalysisResponseDto>>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpPatch("{analysisId:guid}/discard")]
    public async Task<ResponseEntity<object>> Discard(Guid analysisId, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<object>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            await _skinAnalysisService.DiscardAsync(userId, analysisId, cancellationToken);
            return ResponseEntity<object>.Ok(null, "Skin analysis discarded successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<object>.Fail(ex.Message, ex.StatusCode);
        }
    }
}
