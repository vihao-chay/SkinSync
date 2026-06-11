using System.Text.Json;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Entities;

namespace SkinSync.Mappers;

public static class SkinProgressMapper
{
    public static SkinProgressPhotoDto ToDto(this SkinProgressPhoto photo)
    {
        return new SkinProgressPhotoDto
        {
            PhotoId = photo.Id,
            ImageUrl = photo.ImageUrl,
            ThumbnailUrl = photo.ThumbnailUrl,
            PhotoDate = photo.PhotoDate,
            TimeOfDay = photo.TimeOfDay,
            LightingCondition = photo.LightingCondition,
            FaceAngle = photo.FaceAngle,
            Note = photo.Note,
            CreatedAt = photo.CreatedAt
        };
    }

    public static SkinProgressVisualJourneyPhotoDto ToJourneyDto(this SkinProgressPhoto photo)
    {
        return new SkinProgressVisualJourneyPhotoDto
        {
            PhotoId = photo.Id,
            ImageUrl = photo.ImageUrl,
            ThumbnailUrl = photo.ThumbnailUrl,
            Date = photo.PhotoDate
        };
    }

    public static SkinProgressAnalysisResponseDto ToDto(this SkinProgressAnalysis analysis)
    {
        return new SkinProgressAnalysisResponseDto
        {
            AnalysisId = analysis.Id,
            PhotoId = analysis.PhotoId,
            SkinTypeEstimate = analysis.SkinTypeEstimate,
            HydrationLevel = analysis.HydrationLevel,
            OilinessLevel = analysis.OilinessLevel,
            Scores = ParseScoreChanges(analysis),
            DetectedConcerns = ParseConcernArray(analysis.DetectedConcerns),
            AiSummary = analysis.AiSummary,
            Recommendations = ParseStringArray(analysis.Recommendations),
            RiskFlags = ParseStringArray(analysis.RiskFlags),
            Disclaimer = "AI analysis is for skincare tracking only and is not a medical diagnosis.",
            CreatedAt = analysis.CreatedAt
        };
    }

    public static SkinProgressCompareResponseDto ToDto(
        this SkinPhotoComparison comparison,
        SkinProgressPhoto? beforePhoto = null,
        SkinProgressPhoto? afterPhoto = null)
    {
        return new SkinProgressCompareResponseDto
        {
            ComparisonId = comparison.Id,
            ProgressStatus = comparison.ProgressStatus,
            ComparisonSummary = comparison.ComparisonSummary,
            ScoreChanges = ParseScoreChanges(comparison.ScoreChanges),
            Improvements = ParseStringArray(comparison.Improvements),
            WorsenedAreas = ParseStringArray(comparison.WorsenedAreas),
            StableAreas = ParseStringArray(comparison.StableAreas),
            Recommendations = ParseStringArray(comparison.Recommendations),
            ConfidenceNote = comparison.ConfidenceNote,
            BeforePhoto = beforePhoto?.ToJourneyDto(),
            AfterPhoto = afterPhoto?.ToJourneyDto()
        };
    }

    public static SkinProgressReportResponseDto ToDto(this SkinProgressReport report)
    {
        return new SkinProgressReportResponseDto
        {
            ReportId = report.Id,
            PeriodType = report.PeriodType,
            PeriodStart = report.PeriodStart,
            PeriodEnd = report.PeriodEnd,
            ProgressStatus = report.ProgressStatus,
            Summary = report.Summary,
            ScoreChanges = ParseScoreChanges(report.ScoreChanges),
            MainFindings = ParseStringArray(report.MainFindings),
            RoutineFeedback = report.RoutineFeedback,
            NextSuggestions = ParseStringArray(report.NextSuggestions),
            CreatedAt = report.CreatedAt
        };
    }

    public static SkinProgressReportSummaryDto ToSummaryDto(this SkinProgressReport report)
    {
        return new SkinProgressReportSummaryDto
        {
            ReportId = report.Id,
            PeriodType = report.PeriodType,
            PeriodStart = report.PeriodStart,
            PeriodEnd = report.PeriodEnd,
            ProgressStatus = report.ProgressStatus,
            Summary = report.Summary,
            CreatedAt = report.CreatedAt
        };
    }

    public static SkinProgressScoreSetDto ParseScoreChanges(SkinProgressAnalysis analysis)
    {
        return new SkinProgressScoreSetDto
        {
            AcneScore = analysis.AcneScore,
            RednessScore = analysis.RednessScore,
            DarkSpotScore = analysis.DarkSpotScore,
            OilinessScore = analysis.OilinessScore,
            DrynessScore = analysis.DrynessScore,
            TextureScore = analysis.TextureScore,
            SensitivityScore = analysis.SensitivityScore,
            OverallScore = analysis.OverallScore
        };
    }

    public static SkinProgressScoreChangesDto ParseScoreChanges(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return new SkinProgressScoreChangesDto();
        }

        try
        {
            return JsonSerializer.Deserialize<SkinProgressScoreChangesDto>(raw) ?? new SkinProgressScoreChangesDto();
        }
        catch (JsonException)
        {
            return new SkinProgressScoreChangesDto();
        }
    }

    public static IReadOnlyCollection<string> ParseStringArray(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return Array.Empty<string>();
        }

        try
        {
            return JsonSerializer.Deserialize<List<string>>(raw) ?? [];
        }
        catch (JsonException)
        {
            return raw.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        }
    }

    public static IReadOnlyCollection<SkinProgressConcernDto> ParseConcernArray(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return Array.Empty<SkinProgressConcernDto>();
        }

        try
        {
            return JsonSerializer.Deserialize<List<SkinProgressConcernDto>>(raw) ?? [];
        }
        catch (JsonException)
        {
            return Array.Empty<SkinProgressConcernDto>();
        }
    }
}
