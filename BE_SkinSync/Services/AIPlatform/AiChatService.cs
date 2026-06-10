using Microsoft.EntityFrameworkCore;
using SkinSync.Data;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.AI;

namespace SkinSync.Services.AIPlatform;

public interface IAiChatService
{
    Task<AiChatResponseDto> ChatAsync(Guid userId, AiChatRequestDto request, CancellationToken cancellationToken);
}

public class AiChatService : IAiChatService
{
    private readonly AppDbContext _dbContext;
    private readonly IOpenAiService _openAiService;
    private readonly IAiUsageService _aiUsageService;

    public AiChatService(AppDbContext dbContext, IOpenAiService openAiService, IAiUsageService aiUsageService)
    {
        _dbContext = dbContext;
        _openAiService = openAiService;
        _aiUsageService = aiUsageService;
    }

    public async Task<AiChatResponseDto> ChatAsync(Guid userId, AiChatRequestDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Message))
        {
            throw new AiFeatureException("INVALID_REQUEST", "message is required.");
        }

        var user = await _dbContext.Users.Include(x => x.Profile).FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

        await _aiUsageService.CheckLimitAsync(userId, "ai_chat", cancellationToken);

        var currentRoutine = await _dbContext.UserRegimens
            .AsNoTracking()
            .Include(x => x.Items)
            .ThenInclude(x => x.Product)
            .FirstOrDefaultAsync(x => x.UserId == userId && x.IsActive, cancellationToken);
        var latestAnalysis = await _dbContext.AiAnalyses
            .AsNoTracking()
            .Include(x => x.AnalysisIssues)
            .Include(x => x.Recommendations)
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);
        var recentLogs = await _dbContext.DailyLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.Date)
            .Take(7)
            .ToListAsync(cancellationToken);

        var aiResult = await _openAiService.GenerateJsonAsync<AiChatResponseDto>(
            AiPromptLibrary.CommonSystemPrompt,
            AiPromptLibrary.BuildChatPrompt(
                AiContextMapper.SerializeUserProfile(user.Profile),
                System.Text.Json.JsonSerializer.Serialize(currentRoutine?.ToCurrentRegimenDto() ?? new object()),
                AiContextMapper.SerializeAnalysis(latestAnalysis?.ToDetailDto()),
                AiContextMapper.SerializeDailyLogs(recentLogs),
                request.Message),
            cancellationToken: cancellationToken);

        if (string.IsNullOrWhiteSpace(aiResult.Value.SafetyWarning))
        {
            aiResult.Value.SafetyWarning = "This is general skincare guidance, not medical advice.";
        }

        await _aiUsageService.LogUsageAsync(userId, "ai_chat", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);
        return aiResult.Value;
    }
}
