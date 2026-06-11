using Microsoft.EntityFrameworkCore;
using SkinSync.Data;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Dtos.Analysis;
using SkinSync.Models.Entities;

namespace SkinSync.Services.AIPlatform;

public interface ISkinAnalysisService
{
    Task<AiSkinAnalysisResponseDto> AnalyzeAsync(Guid userId, AiSkinAnalysisRequestDto request, CancellationToken cancellationToken);
    Task<AiSkinAnalysisResponseDto> GetAnalysisAsync(Guid userId, Guid analysisId, CancellationToken cancellationToken);
    Task<IReadOnlyCollection<AiSkinAnalysisResponseDto>> GetHistoryAsync(Guid userId, CancellationToken cancellationToken);
    Task DiscardAsync(Guid userId, Guid analysisId, CancellationToken cancellationToken);
}

public class SkinAnalysisService : ISkinAnalysisService
{
    private readonly AppDbContext _dbContext;
    private readonly ISkinProgressService _skinProgressService;
    private readonly ISkinProgressAnalysisService _skinProgressAnalysisService;

    public SkinAnalysisService(
        AppDbContext dbContext,
        ISkinProgressService skinProgressService,
        ISkinProgressAnalysisService skinProgressAnalysisService)
    {
        _dbContext = dbContext;
        _skinProgressService = skinProgressService;
        _skinProgressAnalysisService = skinProgressAnalysisService;
    }

    public async Task<AiSkinAnalysisResponseDto> AnalyzeAsync(Guid userId, AiSkinAnalysisRequestDto request, CancellationToken cancellationToken)
    {
        if (request.Image is null && string.IsNullOrWhiteSpace(request.ImageUrl))
        {
            throw new AiFeatureException("INVALID_REQUEST", "Image file or imageUrl is required.");
        }

        var photo = await _skinProgressService.UploadPhotoAsync(userId, new SkinProgressPhotoUploadRequestDto
        {
            Image = request.Image,
            ImageUrl = request.ImageUrl,
            Source = request.Source,
            PhotoDate = DateOnly.FromDateTime(DateTime.UtcNow.Date),
            TimeOfDay = ResolveTimeOfDay(DateTime.UtcNow),
            LightingCondition = "unknown",
            FaceAngle = "front",
            Note = request.AdditionalNote
        }, cancellationToken);

        var analysis = await _skinProgressAnalysisService.AnalyzeAsync(
            userId,
            new SkinProgressAnalyzeRequestDto { PhotoId = photo.PhotoId },
            cancellationToken);

        return ToAiResponse(analysis);
    }

    public async Task<AiSkinAnalysisResponseDto> GetAnalysisAsync(Guid userId, Guid analysisId, CancellationToken cancellationToken)
    {
        var data = await _dbContext.SkinProgressAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.Id == analysisId && x.DiscardedAt == null && x.Status != "discarded")
            .Join(
                _dbContext.SkinProgressPhotos.AsNoTracking(),
                analysis => analysis.PhotoId,
                photo => photo.Id,
                (analysis, photo) => new { Analysis = analysis, Photo = photo })
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new AiFeatureException("ANALYSIS_NOT_FOUND", "Skin analysis not found.", 404);

        return ToAiResponse(data.Analysis.ToDto(data.Photo));
    }

    public async Task<IReadOnlyCollection<AiSkinAnalysisResponseDto>> GetHistoryAsync(Guid userId, CancellationToken cancellationToken)
    {
        var items = await _dbContext.SkinProgressAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.DiscardedAt == null && x.Status != "discarded")
            .Join(
                _dbContext.SkinProgressPhotos.AsNoTracking(),
                analysis => analysis.PhotoId,
                photo => photo.Id,
                (analysis, photo) => new { Analysis = analysis, Photo = photo })
            .OrderByDescending(x => x.Analysis.CompletedAt ?? x.Analysis.CreatedAt)
            .ToListAsync(cancellationToken);

        return items.Select(x => ToAiResponse(x.Analysis.ToDto(x.Photo))).ToList();
    }

    public async Task DiscardAsync(Guid userId, Guid analysisId, CancellationToken cancellationToken)
    {
        var analysis = await _dbContext.SkinProgressAnalyses
            .FirstOrDefaultAsync(x => x.UserId == userId && x.Id == analysisId, cancellationToken)
            ?? throw new AiFeatureException("ANALYSIS_NOT_FOUND", "Skin analysis not found.", 404);

        analysis.Status = "discarded";
        analysis.DiscardedAt = DateTime.UtcNow;
        analysis.ErrorMessage = null;

        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<AnalysisDetailResponseDto?> GetLegacyLatestAsync(Guid userId, CancellationToken cancellationToken)
    {
        var latest = await _dbContext.SkinProgressAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.DiscardedAt == null && x.Status != "discarded")
            .Join(
                _dbContext.SkinProgressPhotos.AsNoTracking(),
                analysis => analysis.PhotoId,
                photo => photo.Id,
                (analysis, photo) => new { Analysis = analysis, Photo = photo })
            .OrderByDescending(x => x.Analysis.CompletedAt ?? x.Analysis.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        return latest is null ? null : ToLegacyDetailDto(latest.Analysis, latest.Photo);
    }

    public async Task<IReadOnlyCollection<AnalysisHistoryItemDto>> GetLegacyHistoryAsync(Guid userId, CancellationToken cancellationToken)
    {
        var items = await _dbContext.SkinProgressAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.DiscardedAt == null && x.Status != "discarded")
            .OrderByDescending(x => x.CompletedAt ?? x.CreatedAt)
            .Select(x => new AnalysisHistoryItemDto
            {
                Id = x.Id,
                CreatedAt = x.CompletedAt ?? x.CreatedAt,
                OverallScore = x.OverallScore,
                SkinAge = null,
                RecoveryCapacity = null,
                UvDamage = null,
                AgingRisk = null,
                Status = x.Status
            })
            .ToListAsync(cancellationToken);

        return items;
    }

    public async Task<AnalysisDetailResponseDto?> GetLegacyDetailAsync(Guid userId, Guid analysisId, CancellationToken cancellationToken)
    {
        var data = await _dbContext.SkinProgressAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.Id == analysisId && x.DiscardedAt == null && x.Status != "discarded")
            .Join(
                _dbContext.SkinProgressPhotos.AsNoTracking(),
                analysis => analysis.PhotoId,
                photo => photo.Id,
                (analysis, photo) => new { Analysis = analysis, Photo = photo })
            .FirstOrDefaultAsync(cancellationToken);

        return data is null ? null : ToLegacyDetailDto(data.Analysis, data.Photo);
    }

    private static AiSkinAnalysisResponseDto ToAiResponse(SkinProgressAnalysisResponseDto analysis)
    {
        return new AiSkinAnalysisResponseDto
        {
            AnalysisSessionId = analysis.AnalysisId,
            AnalysisResultId = analysis.AnalysisId,
            ProgressEntryId = analysis.ProgressEntryId,
            PhotoId = analysis.PhotoId,
            Status = analysis.Status,
            Source = analysis.Source,
            ImageUrl = analysis.ImageUrl,
            ThumbnailUrl = analysis.ThumbnailUrl,
            AiModel = analysis.AiModel,
            SkinScore = analysis.Scores.OverallScore,
            SkinType = analysis.SkinTypeEstimate,
            OilinessLevel = analysis.Scores.OilinessScore,
            DrynessLevel = analysis.Scores.DrynessScore,
            AcneLevel = analysis.Scores.AcneScore,
            RednessLevel = analysis.Scores.RednessScore,
            DarkSpotLevel = analysis.Scores.DarkSpotScore,
            TextureLevel = analysis.Scores.TextureScore,
            PoreLevel = analysis.Scores.OilinessScore,
            WrinkleLevel = analysis.Scores.TextureScore,
            SensitivityLevel = analysis.Scores.SensitivityScore,
            HydrationLevel = analysis.Scores.DrynessScore,
            SkinSummary = analysis.AiSummary,
            DetectedConcerns = analysis.DetectedConcerns.Select(concern => new AiDetectedConcernDto
            {
                Concern = concern.Concern,
                Severity = concern.Severity,
                Confidence = concern.Confidence,
                Description = concern.Description
            }).ToList(),
            Recommendations = analysis.Recommendations,
            RoutineSuggestions = analysis.RoutineSuggestions,
            ProductSuggestions = analysis.ProductSuggestions,
            SafetyNotes = analysis.SafetyNotes,
            RiskFlags = analysis.RiskFlags,
            Disclaimer = analysis.Disclaimer,
            ConfidenceScore = analysis.ConfidenceScore,
            ErrorMessage = analysis.ErrorMessage,
            CreatedAt = analysis.CreatedAt,
            CompletedAt = analysis.CompletedAt
        };
    }

    private static AnalysisDetailResponseDto ToLegacyDetailDto(SkinProgressAnalysis analysis, SkinProgressPhoto photo)
    {
        var concerns = SkinProgressMapper.ParseConcernArray(analysis.DetectedConcerns);
        var recommendations = SkinProgressMapper.ParseRecommendationArray(analysis.Recommendations);

        return new AnalysisDetailResponseDto
        {
            Id = analysis.Id,
            UserId = analysis.UserId,
            ImageUrl = photo.ImageUrl,
            SkinType = analysis.SkinTypeEstimate,
            OverallScore = analysis.OverallScore,
            ConfidenceScore = (int)Math.Round((analysis.ConfidenceScore ?? 0.8m) * 100m),
            SkinAge = null,
            RecoveryCapacity = analysis.DrynessScore == 0 ? null : Math.Max(0, 100 - analysis.DrynessScore),
            UvDamage = analysis.DarkSpotScore,
            AgingRisk = analysis.TextureScore,
            IssuesDetected = analysis.DetectedConcerns,
            RootCauses = analysis.ParsedAiResponse,
            Overview = string.IsNullOrWhiteSpace(analysis.AiSummary)
                ? $"Skin score {analysis.OverallScore}/100."
                : analysis.AiSummary,
            AiModel = analysis.AiModel,
            Status = analysis.Status,
            Disclaimer = "AI output is for skincare guidance only and does not replace medical diagnosis.",
            Warnings = SkinProgressMapper.ParseStringArray(analysis.RiskFlags),
            GeneratedAt = analysis.CompletedAt ?? analysis.CreatedAt,
            CreatedAt = analysis.CreatedAt,
            Issues = concerns.Select((concern, index) => new AnalysisIssueItemDto
            {
                Id = Guid.NewGuid(),
                IssueType = concern.Label,
                SeverityScore = concern.Score,
                ConfidenceScore = (int)Math.Round(concern.Confidence * 100),
                Description = concern.Description
            }).ToList(),
            Recommendations = recommendations.Select((item, index) => new AnalysisRecommendationItemDto
            {
                Id = Guid.NewGuid(),
                RecommendationType = item.Type,
                Title = item.Title,
                Content = item.Description,
                Priority = item.Priority.ToLowerInvariant() switch
                {
                    "high" => 1,
                    "medium" => 2,
                    _ => 3
                }
            }).ToList()
        };
    }

    public static AnalysisDetailResponseDto GetLegacyDetailFromCanonical(SkinProgressAnalysis analysis)
    {
        var photo = new SkinProgressPhoto
        {
            Id = analysis.PhotoId,
            UserId = analysis.UserId,
            ImageUrl = string.Empty,
            ThumbnailUrl = null,
            Source = "unknown",
            PhotoDate = DateOnly.FromDateTime((analysis.CompletedAt ?? analysis.CreatedAt).Date),
            TimeOfDay = "unknown",
            LightingCondition = "unknown",
            FaceAngle = "unknown",
            CreatedAt = analysis.CreatedAt
        };

        return ToLegacyDetailDto(analysis, photo);
    }

    private static string ResolveTimeOfDay(DateTime value)
    {
        if (value.Hour < 12)
        {
            return "morning";
        }

        if (value.Hour < 18)
        {
            return "afternoon";
        }

        return "night";
    }
}
