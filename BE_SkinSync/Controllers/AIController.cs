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
    private readonly ISkinAnalysisService _skinAnalysisService;
    private readonly IRoutineGenerationService _routineGenerationService;
    private readonly IProductRecommendationService _productRecommendationService;
    private readonly IIngredientCheckService _ingredientCheckService;
    private readonly IConflictCheckService _conflictCheckService;
    private readonly IAiChatService _aiChatService;
    private readonly IAiReportService _aiReportService;

    public AIController(
        ISkinAnalysisService skinAnalysisService,
        IRoutineGenerationService routineGenerationService,
        IProductRecommendationService productRecommendationService,
        IIngredientCheckService ingredientCheckService,
        IConflictCheckService conflictCheckService,
        IAiChatService aiChatService,
        IAiReportService aiReportService)
    {
        _skinAnalysisService = skinAnalysisService;
        _routineGenerationService = routineGenerationService;
        _productRecommendationService = productRecommendationService;
        _ingredientCheckService = ingredientCheckService;
        _conflictCheckService = conflictCheckService;
        _aiChatService = aiChatService;
        _aiReportService = aiReportService;
    }

    [HttpPost("skin-analysis")]
    [Consumes("multipart/form-data")]
    public async Task<AiApiResponse<AiSkinAnalysisResponseDto>> SkinAnalysis([FromForm] AiSkinAnalysisRequestDto request, CancellationToken cancellationToken)
    {
        return await ExecuteAsync(() => _skinAnalysisService.AnalyzeAsync(GetUserId(), request, cancellationToken), "Skin analysis completed successfully.");
    }

    [HttpPost("routine/generate")]
    public async Task<AiApiResponse<AiRoutineGenerateResponseDto>> GenerateRoutine([FromBody] AiRoutineGenerateRequestDto request, CancellationToken cancellationToken)
    {
        return await ExecuteAsync(() => _routineGenerationService.GenerateAsync(GetUserId(), request, cancellationToken), "Routine generated successfully.");
    }

    [HttpPost("products/recommend")]
    public async Task<AiApiResponse<AiProductRecommendResponseDto>> RecommendProducts([FromBody] AiProductRecommendRequestDto request, CancellationToken cancellationToken)
    {
        return await ExecuteAsync(() => _productRecommendationService.RecommendAsync(GetUserId(), request, cancellationToken), "Products recommended successfully.");
    }

    [HttpPost("ingredient-check")]
    public async Task<AiApiResponse<AiIngredientCheckResponseDto>> IngredientCheck([FromBody] AiIngredientCheckRequestDto request, CancellationToken cancellationToken)
    {
        return await ExecuteAsync(() => _ingredientCheckService.CheckAsync(GetUserId(), request, cancellationToken), "Ingredient check completed successfully.");
    }

    [HttpPost("routine/conflict-check")]
    public async Task<AiApiResponse<AiRoutineConflictCheckResponseDto>> ConflictCheck([FromBody] AiRoutineConflictCheckRequestDto request, CancellationToken cancellationToken)
    {
        return await ExecuteAsync(() => _conflictCheckService.CheckAsync(GetUserId(), request, cancellationToken), "Routine conflict check completed successfully.");
    }

    [HttpPost("chat")]
    public async Task<AiApiResponse<AiChatResponseDto>> Chat([FromBody] AiChatRequestDto request, CancellationToken cancellationToken)
    {
        return await ExecuteAsync(() => _aiChatService.ChatAsync(GetUserId(), request, cancellationToken), "AI chat response generated successfully.");
    }

    [HttpGet("chat/conversations")]
    public async Task<AiApiResponse<IReadOnlyCollection<AiChatConversationSummaryDto>>> GetChatConversations(CancellationToken cancellationToken)
    {
        return await ExecuteAsync(() => _aiChatService.GetConversationsAsync(GetUserId(), cancellationToken), "Chat conversations fetched successfully.");
    }

    [HttpGet("chat/conversations/{conversationId:guid}")]
    public async Task<AiApiResponse<AiChatConversationDetailDto>> GetChatConversation(Guid conversationId, CancellationToken cancellationToken)
    {
        return await ExecuteAsync(() => _aiChatService.GetConversationAsync(GetUserId(), conversationId, cancellationToken), "Chat conversation fetched successfully.");
    }

    [HttpPost("chat/conversations")]
    public async Task<AiApiResponse<AiChatConversationSummaryDto>> CreateChatConversation([FromBody] AiChatConversationCreateRequestDto request, CancellationToken cancellationToken)
    {
        return await ExecuteAsync(() => _aiChatService.CreateConversationAsync(GetUserId(), request, cancellationToken), "Chat conversation created successfully.");
    }

    [HttpPost("report/generate")]
    public async Task<AiApiResponse<AiReportGenerateResponseDto>> GenerateReport([FromBody] AiReportGenerateRequestDto request, CancellationToken cancellationToken)
    {
        return await ExecuteAsync(() => _aiReportService.GenerateAsync(GetUserId(), request, cancellationToken), "AI report generated successfully.");
    }

    [HttpGet("reports")]
    public async Task<AiApiResponse<IReadOnlyCollection<AiReportSummaryDto>>> GetReports(CancellationToken cancellationToken)
    {
        return await ExecuteAsync(() => _aiReportService.GetReportsAsync(GetUserId(), cancellationToken), "AI reports fetched successfully.");
    }

    [HttpGet("reports/{reportId:guid}")]
    public async Task<AiApiResponse<AiReportGenerateResponseDto>> GetReport(Guid reportId, CancellationToken cancellationToken)
    {
        return await ExecuteAsync(() => _aiReportService.GetReportAsync(GetUserId(), reportId, cancellationToken), "AI report fetched successfully.");
    }

    private Guid GetUserId()
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            throw new AiFeatureException("UNAUTHORIZED", "Missing authenticated user.", 401);
        }

        return userId;
    }

    private async Task<AiApiResponse<T>> ExecuteAsync<T>(Func<Task<T>> action, string successMessage)
    {
        try
        {
            var data = await action();
            return AiApiResponse<T>.Ok(data, successMessage, HttpContext.TraceIdentifier);
        }
        catch (AiFeatureException ex)
        {
            return AiApiResponse<T>.Fail(
                ex.Message,
                HttpContext.TraceIdentifier,
                ex.StatusCode,
                new AiApiError
                {
                    Code = ex.Code,
                    Detail = ex.Message
                });
        }
    }
}
