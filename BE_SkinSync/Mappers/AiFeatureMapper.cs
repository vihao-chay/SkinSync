using System.Text.Json;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Entities;

namespace SkinSync.Mappers;

public static class AiFeatureMapper
{
    public static AiChatConversationSummaryDto ToSummaryDto(this AiChatConversation conversation)
    {
        var lastMessage = conversation.Messages
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefault();

        return new AiChatConversationSummaryDto
        {
            ConversationId = conversation.Id,
            Title = conversation.Title,
            LastMessagePreview = lastMessage is null ? null : BuildPreview(lastMessage.Content),
            CreatedAt = conversation.CreatedAt,
            UpdatedAt = conversation.UpdatedAt,
            LastMessageAt = conversation.LastMessageAt
        };
    }

    public static AiChatConversationDetailDto ToDetailDto(this AiChatConversation conversation)
    {
        return new AiChatConversationDetailDto
        {
            ConversationId = conversation.Id,
            Title = conversation.Title,
            CreatedAt = conversation.CreatedAt,
            UpdatedAt = conversation.UpdatedAt,
            LastMessageAt = conversation.LastMessageAt,
            Messages = conversation.Messages
                .OrderBy(x => x.CreatedAt)
                .Select(x => new AiChatMessageDto
                {
                    Id = x.Id,
                    Role = x.Role,
                    Content = x.Content,
                    CreatedAt = x.CreatedAt
                })
                .ToList()
        };
    }

    public static AiReportGenerateResponseDto ToAiReportDto(this SkinProgressReport report)
    {
        return new AiReportGenerateResponseDto
        {
            ReportId = report.Id,
            ReportCategory = report.ReportCategory,
            Source = report.Source,
            RelatedAnalysisId = report.RelatedAnalysisId,
            PeriodType = report.PeriodType,
            PeriodStart = report.PeriodStart,
            PeriodEnd = report.PeriodEnd,
            CreatedAt = report.CreatedAt,
            Summary = report.Summary,
            ProgressEvaluation = report.ProgressStatus,
            MainFindings = ParseStringArray(report.MainFindings),
            RoutineFeedback = report.RoutineFeedback,
            ProductFeedback = report.ProductFeedback,
            NextPlan = ParseStringArray(report.NextSuggestions),
            Warnings = Array.Empty<string>()
        };
    }

    public static AiReportSummaryDto ToAiReportSummaryDto(this SkinProgressReport report)
    {
        return new AiReportSummaryDto
        {
            ReportId = report.Id,
            ReportCategory = report.ReportCategory,
            Source = report.Source,
            RelatedAnalysisId = report.RelatedAnalysisId,
            PeriodType = report.PeriodType,
            Summary = report.Summary,
            ProgressEvaluation = report.ProgressStatus,
            CreatedAt = report.CreatedAt
        };
    }

    private static string? BuildPreview(string content)
    {
        var normalized = content.Trim();
        if (normalized.Length <= 120)
        {
            return normalized;
        }

        return $"{normalized[..117]}...";
    }

    private static IReadOnlyCollection<string> ParseStringArray(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return Array.Empty<string>();
        }

        try
        {
            return JsonSerializer.Deserialize<List<string>>(raw) ?? new List<string>();
        }
        catch (JsonException)
        {
            return raw.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        }
    }
}
