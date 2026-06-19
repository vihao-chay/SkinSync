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
            Source = photo.Source,
            ImageMetadataJson = photo.ImageMetadataJson,
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

    public static SkinProgressAnalysisResponseDto ToDto(this SkinProgressAnalysis analysis, SkinProgressPhoto? photo = null)
    {
        var resolvedPhoto = photo;
        return new SkinProgressAnalysisResponseDto
        {
            AnalysisId = analysis.Id,
            PhotoId = analysis.PhotoId,
            ProgressEntryId = analysis.PhotoId,
            Status = analysis.Status,
            Source = resolvedPhoto?.Source ?? "unknown",
            ImageUrl = resolvedPhoto?.ImageUrl ?? string.Empty,
            ThumbnailUrl = resolvedPhoto?.ThumbnailUrl,
            AiModel = analysis.AiModel,
            SkinTypeEstimate = analysis.SkinTypeEstimate,
            HydrationLevel = analysis.HydrationLevel,
            OilinessLevel = analysis.OilinessLevel,
            SkinHealthScore = ResolveSkinHealthScore(analysis),
            OverallConcernSeverity = ResolveOverallConcernSeverity(analysis),
            Confidence = ResolveConfidence(analysis.ConfidenceScore),
            Metrics = BuildMetrics(analysis),
            Scores = ParseScoreSet(analysis),
            DetectedConcerns = ParseConcernArray(analysis.DetectedConcerns),
            AiSummary = analysis.AiSummary,
            Summary = analysis.AiSummary,
            Recommendations = ParseRecommendationArray(analysis.Recommendations),
            RoutineSuggestions = ParseRoutineSuggestions(analysis.RoutineSuggestions),
            ProductSuggestions = ParseProductSuggestionArray(analysis.ProductSuggestions),
            SafetyNotes = ParseStringArray(analysis.SafetyNotes),
            RiskFlags = ParseStringArray(analysis.RiskFlags),
            Disclaimer = "AI analysis is for skincare tracking only and is not a medical diagnosis.",
            SafetyNote = ResolveSafetyNote(analysis),
            ConfidenceScore = analysis.ConfidenceScore,
            ErrorMessage = analysis.ErrorMessage,
            CreatedAt = analysis.CreatedAt,
            CompletedAt = analysis.CompletedAt
        };
    }

    public static SkinProgressTimelineEntryDto ToTimelineDto(this SkinProgressPhoto photo, SkinProgressAnalysis? analysis)
    {
        return new SkinProgressTimelineEntryDto
        {
            EntryId = photo.Id,
            AnalysisId = analysis?.Id,
            PhotoId = photo.Id,
            EntryType = "analysis",
            Source = photo.Source,
            Status = analysis?.Status ?? "pending",
            ImageUrl = photo.ImageUrl,
            ThumbnailUrl = photo.ThumbnailUrl,
            SkinScore = analysis is null ? null : ResolveOverallConcernSeverity(analysis),
            AcneLevel = analysis?.AcneScore,
            RednessLevel = analysis?.RednessScore,
            DarkSpotLevel = analysis?.DarkSpotScore,
            TextureLevel = analysis?.TextureScore,
            HydrationLevel = ParseHydrationScore(analysis?.HydrationLevel),
            Summary = analysis?.AiSummary,
            MainConcerns = ParseConcernArray(analysis?.DetectedConcerns).Select(x => x.Label).Where(x => !string.IsNullOrWhiteSpace(x)).ToList(),
            CreatedAt = analysis?.CompletedAt ?? analysis?.CreatedAt ?? photo.CreatedAt
        };
    }

    public static SkinProgressEntryDetailDto ToEntryDetailDto(this SkinProgressPhoto photo, SkinProgressAnalysis? analysis)
    {
        var timeline = photo.ToTimelineDto(analysis);
        return new SkinProgressEntryDetailDto
        {
            EntryId = timeline.EntryId,
            AnalysisId = timeline.AnalysisId,
            PhotoId = timeline.PhotoId,
            EntryType = timeline.EntryType,
            Source = timeline.Source,
            Status = timeline.Status,
            ImageUrl = timeline.ImageUrl,
            ThumbnailUrl = timeline.ThumbnailUrl,
            SkinScore = timeline.SkinScore,
            AcneLevel = timeline.AcneLevel,
            RednessLevel = timeline.RednessLevel,
            DarkSpotLevel = timeline.DarkSpotLevel,
            TextureLevel = timeline.TextureLevel,
            HydrationLevel = timeline.HydrationLevel,
            Summary = timeline.Summary,
            MainConcerns = timeline.MainConcerns,
            CreatedAt = timeline.CreatedAt,
            SkinType = analysis?.SkinTypeEstimate ?? "unknown",
            OilinessLevel = analysis?.OilinessLevel ?? "unknown",
            Scores = analysis is null ? new SkinProgressScoreSetDto() : ParseScoreSet(analysis),
            DetectedConcerns = ParseConcernArray(analysis?.DetectedConcerns),
            Recommendations = ParseRecommendationArray(analysis?.Recommendations),
            RoutineSuggestions = ParseRoutineSuggestions(analysis?.RoutineSuggestions),
            ProductSuggestions = ParseProductSuggestionArray(analysis?.ProductSuggestions),
            SafetyNotes = ParseStringArray(analysis?.SafetyNotes),
            RiskFlags = ParseStringArray(analysis?.RiskFlags),
            Disclaimer = "AI analysis is for skincare tracking only and is not a medical diagnosis.",
            ConfidenceScore = analysis?.ConfidenceScore,
            Note = photo.Note
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
            ReportCategory = report.ReportCategory,
            Source = report.Source,
            RelatedAnalysisId = report.RelatedAnalysisId,
            PeriodType = report.PeriodType,
            PeriodStart = report.PeriodStart,
            PeriodEnd = report.PeriodEnd,
            ProgressStatus = report.ProgressStatus,
            Summary = report.Summary,
            ScoreChanges = ParseScoreChanges(report.ScoreChanges),
            MainFindings = ParseStringArray(report.MainFindings),
            RoutineFeedback = report.RoutineFeedback,
            ProductFeedback = report.ProductFeedback,
            NextSuggestions = ParseStringArray(report.NextSuggestions),
            CreatedAt = report.CreatedAt
        };
    }

    public static SkinProgressReportSummaryDto ToSummaryDto(this SkinProgressReport report)
    {
        return new SkinProgressReportSummaryDto
        {
            ReportId = report.Id,
            ReportCategory = report.ReportCategory,
            Source = report.Source,
            RelatedAnalysisId = report.RelatedAnalysisId,
            PeriodType = report.PeriodType,
            PeriodStart = report.PeriodStart,
            PeriodEnd = report.PeriodEnd,
            ProgressStatus = report.ProgressStatus,
            Summary = report.Summary,
            CreatedAt = report.CreatedAt
        };
    }

    public static SkinProgressScoreSetDto ParseScoreSet(SkinProgressAnalysis analysis)
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
            OverallScore = ResolveOverallConcernSeverity(analysis)
        };
    }

    private static SkinProgressMetricsDto BuildMetrics(SkinProgressAnalysis analysis)
    {
        return new SkinProgressMetricsDto
        {
            Acne = analysis.AcneScore,
            Redness = analysis.RednessScore,
            Oiliness = analysis.OilinessScore,
            Dryness = analysis.DrynessScore,
            Moisture = ResolveMoistureScore(analysis),
            Texture = analysis.TextureScore
        };
    }

    private static int ResolveSkinHealthScore(SkinProgressAnalysis analysis)
    {
        var severity = ResolveOverallConcernSeverity(analysis);
        return analysis.SkinHealthScore ?? Math.Clamp(100 - severity, 0, 100);
    }

    private static int ResolveOverallConcernSeverity(SkinProgressAnalysis analysis) =>
        analysis.OverallConcernSeverity ?? analysis.OverallScore;

    private static int ResolveConfidence(decimal? confidenceScore)
    {
        if (!confidenceScore.HasValue)
        {
            return 82;
        }

        var raw = confidenceScore.Value <= 1m ? confidenceScore.Value * 100m : confidenceScore.Value;
        return Math.Clamp((int)Math.Round(raw), 0, 100);
    }

    private static int ResolveMoistureScore(SkinProgressAnalysis analysis)
    {
        var parsed = ParseHydrationScore(analysis.HydrationLevel);
        return parsed ?? Math.Clamp(100 - analysis.DrynessScore, 0, 100);
    }

    private static string ResolveSafetyNote(SkinProgressAnalysis analysis)
    {
        return ParseStringArray(analysis.SafetyNotes).FirstOrDefault()
            ?? "This is not a medical diagnosis. Consider a dermatologist if irritation, pain, or persistent symptoms occur.";
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
            var items = JsonSerializer.Deserialize<List<SkinProgressConcernDto>>(raw) ?? [];
            foreach (var item in items)
            {
                item.Key = string.IsNullOrWhiteSpace(item.Key) ? item.Concern : item.Key;
                item.Label = string.IsNullOrWhiteSpace(item.Label) ? Humanize(item.Concern) : item.Label;
            }

            return items;
        }
        catch (JsonException)
        {
            return Array.Empty<SkinProgressConcernDto>();
        }
    }

    public static IReadOnlyCollection<SkinProgressRecommendationDto> ParseRecommendationArray(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return Array.Empty<SkinProgressRecommendationDto>();
        }

        try
        {
            return JsonSerializer.Deserialize<List<SkinProgressRecommendationDto>>(raw) ?? [];
        }
        catch (JsonException)
        {
            return ParseStringArray(raw)
                .Select((item, index) => new SkinProgressRecommendationDto
                {
                    Type = "routine",
                    Title = $"Recommendation {index + 1}",
                    Description = item,
                    Reason = item,
                    Priority = "medium"
                })
                .ToList();
        }
    }

    public static SkinProgressRoutineSuggestionsDto ParseRoutineSuggestions(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return new SkinProgressRoutineSuggestionsDto();
        }

        try
        {
            return JsonSerializer.Deserialize<SkinProgressRoutineSuggestionsDto>(raw) ?? new SkinProgressRoutineSuggestionsDto();
        }
        catch (JsonException)
        {
            return new SkinProgressRoutineSuggestionsDto();
        }
    }

    public static IReadOnlyCollection<SkinProgressProductSuggestionDto> ParseProductSuggestionArray(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return Array.Empty<SkinProgressProductSuggestionDto>();
        }

        try
        {
            return JsonSerializer.Deserialize<List<SkinProgressProductSuggestionDto>>(raw) ?? [];
        }
        catch (JsonException)
        {
            return Array.Empty<SkinProgressProductSuggestionDto>();
        }
    }

    private static int? ParseHydrationScore(string? level)
    {
        if (string.IsNullOrWhiteSpace(level))
        {
            return null;
        }

        return level.Trim().ToLowerInvariant() switch
        {
            "very_low" => 15,
            "low" => 30,
            "moderate" => 55,
            "balanced" => 70,
            "good" => 80,
            "high" => 90,
            _ => null
        };
    }

    private static string Humanize(string value)
    {
        var normalized = value.Trim().Replace('_', ' ');
        if (normalized.Length == 0)
        {
            return "Unknown";
        }

        return char.ToUpperInvariant(normalized[0]) + normalized[1..];
    }
}
