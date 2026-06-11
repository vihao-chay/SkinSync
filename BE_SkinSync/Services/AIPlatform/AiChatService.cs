using System.Text;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SkinSync.Data;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Entities;

namespace SkinSync.Services.AIPlatform;

public interface IAiChatService
{
    Task<AiChatResponseDto> ChatAsync(Guid userId, AiChatRequestDto request, CancellationToken cancellationToken);
    Task<IReadOnlyCollection<AiChatConversationSummaryDto>> GetConversationsAsync(Guid userId, CancellationToken cancellationToken);
    Task<AiChatConversationDetailDto> GetConversationAsync(Guid userId, Guid conversationId, CancellationToken cancellationToken);
    Task<AiChatConversationSummaryDto> CreateConversationAsync(Guid userId, AiChatConversationCreateRequestDto request, CancellationToken cancellationToken);
}

public class AiChatService : IAiChatService
{
    private const int ContextMessageLimit = 20;

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

        var conversation = await GetOrCreateConversationAsync(userId, request, cancellationToken);
        var recentMessages = await _dbContext.AiChatMessages
            .AsNoTracking()
            .Where(x => x.ConversationId == conversation.Id)
            .OrderByDescending(x => x.CreatedAt)
            .Take(ContextMessageLimit)
            .OrderBy(x => x.CreatedAt)
            .ToListAsync(cancellationToken);

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

        var userMessage = new AiChatMessage
        {
            Id = Guid.NewGuid(),
            ConversationId = conversation.Id,
            Role = "user",
            Content = request.Message.Trim(),
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.AiChatMessages.Add(userMessage);

        var aiResult = await _openAiService.GenerateJsonAsync<AiChatAiModel>(
            AiPromptLibrary.CommonSystemPrompt,
            AiPromptLibrary.BuildChatPrompt(
                AiContextMapper.SerializeUserProfile(user.Profile),
                JsonSerializer.Serialize(currentRoutine?.ToCurrentRegimenDto() ?? new object()),
                AiContextMapper.SerializeAnalysis(latestAnalysis?.ToDetailDto()),
                AiContextMapper.SerializeDailyLogs(recentLogs),
                BuildConversationContext(recentMessages, request.Message),
                request.EntryPoint,
                request.ReferenceId,
                request.PrefillContext),
            cancellationToken: cancellationToken);

        if (string.IsNullOrWhiteSpace(aiResult.Value.SafetyWarning))
        {
            aiResult.Value.SafetyWarning = "This is general skincare guidance, not medical advice.";
        }

        var assistantMessage = new AiChatMessage
        {
            Id = Guid.NewGuid(),
            ConversationId = conversation.Id,
            Role = "assistant",
            Content = aiResult.Value.Reply.Trim(),
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.AiChatMessages.Add(assistantMessage);

        if (string.IsNullOrWhiteSpace(conversation.Title) || string.Equals(conversation.Title, "New chat", StringComparison.Ordinal))
        {
            conversation.Title = BuildTitleFromMessage(request.Message);
        }

        conversation.UpdatedAt = DateTime.UtcNow;
        conversation.LastMessageAt = assistantMessage.CreatedAt;

        await _dbContext.SaveChangesAsync(cancellationToken);
        await _aiUsageService.LogUsageAsync(userId, "ai_chat", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);

        return new AiChatResponseDto
        {
            ConversationId = conversation.Id,
            Reply = aiResult.Value.Reply,
            NeedMoreInfo = aiResult.Value.NeedMoreInfo,
            MissingInfoQuestions = aiResult.Value.MissingInfoQuestions,
            SafetyWarning = aiResult.Value.SafetyWarning,
            SuggestedActions = MapSuggestedActions(aiResult.Value.SuggestedActions, request.ReferenceId)
        };
    }

    public async Task<IReadOnlyCollection<AiChatConversationSummaryDto>> GetConversationsAsync(Guid userId, CancellationToken cancellationToken)
    {
        var conversations = await _dbContext.AiChatConversations
            .AsNoTracking()
            .Include(x => x.Messages)
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.LastMessageAt)
            .ToListAsync(cancellationToken);

        return conversations.Select(x => x.ToSummaryDto()).ToList();
    }

    public async Task<AiChatConversationDetailDto> GetConversationAsync(Guid userId, Guid conversationId, CancellationToken cancellationToken)
    {
        var conversation = await _dbContext.AiChatConversations
            .AsNoTracking()
            .Include(x => x.Messages.OrderBy(m => m.CreatedAt))
            .FirstOrDefaultAsync(x => x.Id == conversationId && x.UserId == userId, cancellationToken)
            ?? throw new AiFeatureException("CONVERSATION_NOT_FOUND", "Conversation not found.", 404);

        return conversation.ToDetailDto();
    }

    public async Task<AiChatConversationSummaryDto> CreateConversationAsync(Guid userId, AiChatConversationCreateRequestDto request, CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var conversation = new AiChatConversation
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Title = string.IsNullOrWhiteSpace(request.Title) ? "New chat" : request.Title.Trim(),
            CreatedAt = now,
            UpdatedAt = now,
            LastMessageAt = now
        };

        _dbContext.AiChatConversations.Add(conversation);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return conversation.ToSummaryDto();
    }

    private async Task<AiChatConversation> GetOrCreateConversationAsync(Guid userId, AiChatRequestDto request, CancellationToken cancellationToken)
    {
        if (request.ConversationId.HasValue)
        {
            return await _dbContext.AiChatConversations
                .FirstOrDefaultAsync(x => x.Id == request.ConversationId.Value && x.UserId == userId, cancellationToken)
                ?? throw new AiFeatureException("CONVERSATION_NOT_FOUND", "Conversation not found.", 404);
        }

        var now = DateTime.UtcNow;
        var conversation = new AiChatConversation
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Title = BuildTitleFromMessage(request.Message),
            CreatedAt = now,
            UpdatedAt = now,
            LastMessageAt = now
        };

        _dbContext.AiChatConversations.Add(conversation);
        await _dbContext.SaveChangesAsync(cancellationToken);
        return conversation;
    }

    private static string BuildConversationContext(IReadOnlyCollection<AiChatMessage> recentMessages, string latestMessage)
    {
        var builder = new StringBuilder();
        if (recentMessages.Count > 0)
        {
            builder.AppendLine("Conversation history:");
            foreach (var message in recentMessages)
            {
                builder.Append(message.Role);
                builder.Append(": ");
                builder.AppendLine(message.Content);
            }
            builder.AppendLine();
        }

        builder.AppendLine("Latest user message:");
        builder.Append(latestMessage.Trim());
        return builder.ToString();
    }

    private static string BuildTitleFromMessage(string message)
    {
        var normalized = message.Trim().ReplaceLineEndings(" ");
        if (normalized.Length <= 60)
        {
            return normalized;
        }

        return $"{normalized[..57].TrimEnd()}...";
    }

    private static IReadOnlyCollection<AiSuggestedActionDto> MapSuggestedActions(IEnumerable<string>? actions, string? referenceId)
    {
        var mapped = new List<AiSuggestedActionDto>();
        foreach (var action in actions ?? Array.Empty<string>())
        {
            var normalized = action.Trim();
            if (string.IsNullOrWhiteSpace(normalized))
            {
                continue;
            }

            if (normalized.Contains("scan", StringComparison.OrdinalIgnoreCase) ||
                normalized.Contains("analysis", StringComparison.OrdinalIgnoreCase))
            {
                mapped.Add(new AiSuggestedActionDto { Type = "scan_skin", Label = "Open skin scan", Route = "/upload", ReferenceId = referenceId });
                continue;
            }

            if (normalized.Contains("routine", StringComparison.OrdinalIgnoreCase))
            {
                mapped.Add(new AiSuggestedActionDto { Type = "open_routine", Label = "Open routine", Route = "/routine", ReferenceId = referenceId });
                continue;
            }

            if (normalized.Contains("ingredient", StringComparison.OrdinalIgnoreCase))
            {
                mapped.Add(new AiSuggestedActionDto { Type = "check_ingredients", Label = "Check ingredients", Route = "/ai/ingredient-check", ReferenceId = referenceId });
                continue;
            }

            if (normalized.Contains("product", StringComparison.OrdinalIgnoreCase))
            {
                mapped.Add(new AiSuggestedActionDto { Type = "view_products", Label = "View products", Route = "/products", ReferenceId = referenceId });
                continue;
            }

            if (normalized.Contains("report", StringComparison.OrdinalIgnoreCase))
            {
                mapped.Add(new AiSuggestedActionDto { Type = "open_reports", Label = "Open reports", Route = "/ai/reports", ReferenceId = referenceId });
                continue;
            }

            if (normalized.Contains("progress", StringComparison.OrdinalIgnoreCase))
            {
                mapped.Add(new AiSuggestedActionDto { Type = "open_progress", Label = "Open progress", Route = "/progress", ReferenceId = referenceId });
                continue;
            }
        }

        return mapped
            .GroupBy(x => $"{x.Type}|{x.Route}|{x.ReferenceId}", StringComparer.OrdinalIgnoreCase)
            .Select(x => x.First())
            .ToList();
    }
}

internal sealed class AiChatAiModel
{
    public string Reply { get; set; } = string.Empty;
    public List<string> SuggestedActions { get; set; } = [];
    public bool NeedMoreInfo { get; set; }
    public List<string> MissingInfoQuestions { get; set; } = [];
    public string SafetyWarning { get; set; } = string.Empty;
}
