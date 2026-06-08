using SkinSync.Models.Dtos.Analysis;
using SkinSync.Models.Entities;

namespace SkinSync.Mappers;

public static class AnalysisMapper
{
    public static AnalysisDetailResponseDto ToDetailDto(this AiAnalysis analysis)
    {
        return new AnalysisDetailResponseDto
        {
            Id = analysis.Id,
            UserId = analysis.UserId,
            ImageUrl = analysis.ImageUrl,
            OverallScore = analysis.OverallScore,
            SkinAge = analysis.SkinAge,
            RecoveryCapacity = analysis.RecoveryCapacity,
            UvDamage = analysis.UvDamage,
            AgingRisk = analysis.AgingRisk,
            IssuesDetected = analysis.IssuesDetected,
            RootCauses = analysis.RootCauses,
            AiModel = analysis.AiModel,
            Status = analysis.Status,
            Issues = analysis.AnalysisIssues
                .Select(x => new AnalysisIssueItemDto
                {
                    Id = x.Id,
                    IssueType = x.IssueType,
                    SeverityScore = x.SeverityScore,
                    ConfidenceScore = x.ConfidenceScore,
                    Description = x.Description
                })
                .ToList(),
            Recommendations = analysis.Recommendations
                .Select(x => new AnalysisRecommendationItemDto
                {
                    Id = x.Id,
                    RecommendationType = x.RecommendationType,
                    Title = x.Title,
                    Content = x.Content,
                    Priority = x.Priority
                })
                .ToList(),
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
}
