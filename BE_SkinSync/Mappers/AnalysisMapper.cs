using SkinSync.Models.Dtos.Analysis;
using SkinSync.Models.Entities;
using System.Text.Json;

namespace SkinSync.Mappers;

public static class AnalysisMapper
{
    public static AnalysisDetailResponseDto ToDetailDto(this AiAnalysis analysis)
    {
        var issues = analysis.AnalysisIssues
            .Select(x => new AnalysisIssueItemDto
            {
                Id = x.Id,
                IssueType = x.IssueType,
                SeverityScore = x.SeverityScore,
                ConfidenceScore = x.ConfidenceScore,
                Description = x.Description
            })
            .ToList();

        var recommendations = analysis.Recommendations
            .Select(x => new AnalysisRecommendationItemDto
            {
                Id = x.Id,
                RecommendationType = x.RecommendationType,
                Title = x.Title,
                Content = x.Content,
                Priority = x.Priority
            })
            .ToList();

        return new AnalysisDetailResponseDto
        {
            Id = analysis.Id,
            UserId = analysis.UserId,
            ImageUrl = analysis.ImageUrl,
            SkinType = DeriveSkinType(analysis),
            OverallScore = analysis.OverallScore,
            ConfidenceScore = DeriveConfidenceScore(analysis),
            SkinAge = analysis.SkinAge,
            RecoveryCapacity = analysis.RecoveryCapacity,
            UvDamage = analysis.UvDamage,
            AgingRisk = analysis.AgingRisk,
            IssuesDetected = analysis.IssuesDetected,
            RootCauses = analysis.RootCauses,
            Overview = BuildOverview(analysis, issues),
            AiModel = analysis.AiModel,
            Status = analysis.Status,
            Warnings = BuildWarnings(analysis),
            GeneratedAt = analysis.CreatedAt,
            Issues = issues,
            Recommendations = recommendations,
            CreatedAt = analysis.CreatedAt
        };
    }

    public static AnalysisHistoryItemDto ToHistoryDto(this AiAnalysis analysis)
    {
        return new AnalysisHistoryItemDto
        {
            Id = analysis.Id,
            CreatedAt = analysis.CreatedAt,
            OverallScore = analysis.OverallScore,
            SkinAge = analysis.SkinAge,
            RecoveryCapacity = analysis.RecoveryCapacity,
            UvDamage = analysis.UvDamage,
            AgingRisk = analysis.AgingRisk,
            Status = analysis.Status
        };
    }

    private static string DeriveSkinType(AiAnalysis analysis)
    {
        if (!string.IsNullOrWhiteSpace(analysis.RootCauses))
        {
            try
            {
                using var doc = JsonDocument.Parse(analysis.RootCauses);
                if (doc.RootElement.ValueKind == JsonValueKind.Object &&
                    doc.RootElement.TryGetProperty("skinType", out var skinType))
                {
                    return skinType.GetString() ?? "Unknown";
                }
            }
            catch (JsonException)
            {
            }
        }

        return "Unknown";
    }

    private static int DeriveConfidenceScore(AiAnalysis analysis)
    {
        var scores = analysis.AnalysisIssues
            .Where(x => x.ConfidenceScore.HasValue)
            .Select(x => x.ConfidenceScore!.Value)
            .ToList();

        return scores.Count == 0 ? 0 : (int)Math.Round(scores.Average());
    }

    private static string? BuildOverview(AiAnalysis analysis, IReadOnlyCollection<AnalysisIssueItemDto> issues)
    {
        if (issues.Count == 0)
        {
            return $"Skin score {analysis.OverallScore}/100 with balanced overall condition.";
        }

        var top = issues.OrderByDescending(x => x.SeverityScore).Take(2).Select(x => x.IssueType.ToLowerInvariant());
        return $"Skin score {analysis.OverallScore}/100. Key concerns detected: {string.Join(", ", top)}.";
    }

    private static IReadOnlyCollection<string> BuildWarnings(AiAnalysis analysis)
    {
        var warnings = new List<string>();
        if (analysis.OverallScore < 60)
        {
            warnings.Add("Skin condition appears stressed; keep actives gentle and consider professional advice if symptoms persist.");
        }

        return warnings;
    }
}
