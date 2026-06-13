using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinSync.Base;
using SkinSync.Helpers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Services.AIPlatform;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/ai")]
[Authorize]
public class AIController : ControllerBase
{
    private readonly IProductRecommendationService _productRecommendationService;
    private readonly IProductRoutineService _productRoutineService;

    public AIController(
        IProductRecommendationService productRecommendationService,
        IProductRoutineService productRoutineService)
    {
        _productRecommendationService = productRecommendationService;
        _productRoutineService = productRoutineService;
    }

    [HttpGet("products/recommendations/latest")]
    public async Task<ResponseEntity<AiProductRecommendResponseDto>> GetLatestProductRecommendations(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<AiProductRecommendResponseDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _productRecommendationService.GetLatestAsync(userId, cancellationToken);
            return ResponseEntity<AiProductRecommendResponseDto>.Ok(data, "Latest product recommendation session fetched successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<AiProductRecommendResponseDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpPost("products/recommendations/generate")]
    public async Task<ResponseEntity<AiProductRecommendResponseDto>> GenerateProductRecommendations(
        [FromBody] AiProductRecommendationGenerateRequestDto? request,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<AiProductRecommendResponseDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _productRecommendationService.GenerateAsync(
                userId,
                request ?? new AiProductRecommendationGenerateRequestDto(),
                cancellationToken);
            return ResponseEntity<AiProductRecommendResponseDto>.Ok(data, "Product recommendation session generated successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<AiProductRecommendResponseDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpPost("products/{productId:guid}/add-to-routine")]
    public async Task<ResponseEntity<AiAddProductToRoutineResponseDto>> AddProductToRoutine(
        Guid productId,
        [FromBody] AiAddProductToRoutineRequestDto request,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<AiAddProductToRoutineResponseDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _productRoutineService.AddToRoutineAsync(userId, productId, request, cancellationToken);
            return ResponseEntity<AiAddProductToRoutineResponseDto>.Ok(data, data.Message);
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<AiAddProductToRoutineResponseDto>.Fail(ex.Message, ex.StatusCode);
        }
    }
}
