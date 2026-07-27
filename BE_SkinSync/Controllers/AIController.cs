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
    private readonly IAiChatService _aiChatService;

    public AIController(
        IProductRecommendationService productRecommendationService,
        IProductRoutineService productRoutineService,
        IAiChatService aiChatService)
    {
        _productRecommendationService = productRecommendationService;
        _productRoutineService = productRoutineService;
        _aiChatService = aiChatService;
    }

    [HttpPost("chat")]
    public async Task<ResponseEntity<AiChatResponseDto>> Chat(
        [FromBody] AiChatRequestDto request,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<AiChatResponseDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _aiChatService.ChatAsync(userId, request, cancellationToken);
            return ResponseEntity<AiChatResponseDto>.Ok(data, "AI chat reply generated successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<AiChatResponseDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpGet("chat/conversations")]
    public async Task<ResponseEntity<IReadOnlyCollection<AiChatConversationSummaryDto>>> GetChatConversations(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<IReadOnlyCollection<AiChatConversationSummaryDto>>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _aiChatService.GetConversationsAsync(userId, cancellationToken);
            return ResponseEntity<IReadOnlyCollection<AiChatConversationSummaryDto>>.Ok(data, "AI chat conversations fetched successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<IReadOnlyCollection<AiChatConversationSummaryDto>>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpPost("chat/conversations")]
    public async Task<ResponseEntity<AiChatConversationSummaryDto>> CreateChatConversation(
        [FromBody] AiChatConversationCreateRequestDto request,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<AiChatConversationSummaryDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _aiChatService.CreateConversationAsync(userId, request, cancellationToken);
            return ResponseEntity<AiChatConversationSummaryDto>.Ok(data, "AI chat conversation created successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<AiChatConversationSummaryDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpGet("chat/conversations/{conversationId:guid}")]
    public async Task<ResponseEntity<AiChatConversationDetailDto>> GetChatConversation(
        Guid conversationId,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<AiChatConversationDetailDto>.Fail("Missing authenticated user.", 401);
        }

        try
        {
            var data = await _aiChatService.GetConversationAsync(userId, conversationId, cancellationToken);
            return ResponseEntity<AiChatConversationDetailDto>.Ok(data, "AI chat conversation fetched successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<AiChatConversationDetailDto>.Fail(ex.Message, ex.StatusCode);
        }
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
