using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinSync.Base;
using SkinSync.Helpers;
using SkinSync.Models.Dtos.Recommendations;
using SkinSync.Services.Recommendations;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/recommendations")]
[Authorize]
public class RecommendationsController : ControllerBase
{
    private readonly IRecommendationService _recommendationService;

    public RecommendationsController(IRecommendationService recommendationService)
    {
        _recommendationService = recommendationService;
    }

    [HttpPost]
    public async Task<ResponseEntity<RecommendationResponseDto>> GenerateRecommendations(
        [FromBody] RecommendationRequestDto request,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<RecommendationResponseDto>.Fail("Missing authenticated user.", 401);
        }

        if (request is null)
        {
            return ResponseEntity<RecommendationResponseDto>.Fail("Recommendation request is required.", 400);
        }

        if (string.IsNullOrWhiteSpace(request.SkinType))
        {
            return ResponseEntity<RecommendationResponseDto>.Fail("Skin type is required.", 400);
        }

        var recommendation = await _recommendationService.GenerateAsync(userId, request, cancellationToken);
        return ResponseEntity<RecommendationResponseDto>.Ok(
            recommendation,
            "Recommendations generated successfully from the current product catalog.");
    }
}
