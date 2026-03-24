using SkinAsync.Models.Dtos.Analysis;
using SkinAsync.Models.Entities;

namespace SkinAsync.Mappers;

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
            AgingRisk = analysis.AgingRisk
        };
    }
}
