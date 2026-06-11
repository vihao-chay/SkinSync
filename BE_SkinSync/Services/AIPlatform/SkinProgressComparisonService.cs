using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using SkinSync.Data;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Entities;

namespace SkinSync.Services.AIPlatform;

public interface ISkinProgressComparisonService
{
    Task<SkinProgressCompareResponseDto> CompareAsync(Guid userId, SkinProgressCompareRequestDto request, CancellationToken cancellationToken);
}

public class SkinProgressComparisonService : ISkinProgressComparisonService
{
    private readonly AppDbContext _dbContext;
    private readonly ISkinProgressAnalysisService _analysisService;
    private readonly IOpenAiService _openAiService;
    private readonly IAiUsageService _aiUsageService;

    public SkinProgressComparisonService(
        AppDbContext dbContext,
        ISkinProgressAnalysisService analysisService,
        IOpenAiService openAiService,
        IAiUsageService aiUsageService)
    {
        _dbContext = dbContext;
        _analysisService = analysisService;
        _openAiService = openAiService;
        _aiUsageService = aiUsageService;
    }

    public async Task<SkinProgressCompareResponseDto> CompareAsync(Guid userId, SkinProgressCompareRequestDto request, CancellationToken cancellationToken)
    {
        try
        {
            if (request.BeforePhotoId == request.AfterPhotoId)
            {
                throw new AiFeatureException("INVALID_REQUEST", "Before and after photos must be different.");
            }

            var photos = await _dbContext.SkinProgressPhotos
                .AsNoTracking()
                .Where(x => x.UserId == userId && (x.Id == request.BeforePhotoId || x.Id == request.AfterPhotoId))
                .ToListAsync(cancellationToken);

            var beforePhoto = photos.FirstOrDefault(x => x.Id == request.BeforePhotoId)
                ?? throw new AiFeatureException("PHOTO_NOT_FOUND", "Before photo not found.", 404);
            var afterPhoto = photos.FirstOrDefault(x => x.Id == request.AfterPhotoId)
                ?? throw new AiFeatureException("PHOTO_NOT_FOUND", "After photo not found.", 404);

            var existing = await _dbContext.SkinPhotoComparisons
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.UserId == userId && x.BeforePhotoId == beforePhoto.Id && x.AfterPhotoId == afterPhoto.Id, cancellationToken);
            if (existing is not null)
            {
                return existing.ToDto(beforePhoto, afterPhoto);
            }

            await _aiUsageService.CheckLimitAsync(userId, "skin_progress_compare", cancellationToken);

            var beforeAnalysis = await EnsureAnalysisAsync(userId, beforePhoto.Id, cancellationToken);
            var afterAnalysis = await EnsureAnalysisAsync(userId, afterPhoto.Id, cancellationToken);

            var user = await _dbContext.Users
                .Include(x => x.Profile)
                .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
                ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

            var scoreChanges = BuildScoreChanges(beforeAnalysis, afterAnalysis);
            var aiResult = await _openAiService.GenerateJsonAsync<SkinProgressCompareAiModel>(
                AiPromptLibrary.CommonSystemPrompt,
                AiPromptLibrary.BuildSkinProgressComparePrompt(
                    AiContextMapper.SerializeUserProfile(user.Profile),
                    JsonSerializer.Serialize(beforeAnalysis.ToDto()),
                    JsonSerializer.Serialize(afterAnalysis.ToDto()),
                    JsonSerializer.Serialize(scoreChanges)),
                cancellationToken: cancellationToken);

            var progressStatus = NormalizeCompareStatus(aiResult.Value.ProgressStatus, scoreChanges);
            var comparison = new SkinPhotoComparison
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                BeforePhotoId = beforePhoto.Id,
                AfterPhotoId = afterPhoto.Id,
                BeforeAnalysisId = beforeAnalysis.Id,
                AfterAnalysisId = afterAnalysis.Id,
                ProgressStatus = progressStatus,
                ComparisonSummary = aiResult.Value.ComparisonSummary,
                Improvements = JsonSerializer.Serialize(aiResult.Value.Improvements),
                WorsenedAreas = JsonSerializer.Serialize(aiResult.Value.WorsenedAreas),
                StableAreas = JsonSerializer.Serialize(aiResult.Value.StableAreas),
                ScoreChanges = JsonSerializer.Serialize(scoreChanges),
                Recommendations = JsonSerializer.Serialize(aiResult.Value.Recommendations),
                ConfidenceNote = aiResult.Value.ConfidenceNote,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.SkinPhotoComparisons.Add(comparison);
            await _dbContext.SaveChangesAsync(cancellationToken);
            await _aiUsageService.LogUsageAsync(userId, "skin_progress_compare", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);

            return comparison.ToDto(beforePhoto, afterPhoto);
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
    }

    private async Task<SkinProgressAnalysis> EnsureAnalysisAsync(Guid userId, Guid photoId, CancellationToken cancellationToken)
    {
        var existing = await _dbContext.SkinProgressAnalyses
            .FirstOrDefaultAsync(x => x.UserId == userId && x.PhotoId == photoId, cancellationToken);
        if (existing is not null)
        {
            return existing;
        }

        await _analysisService.AnalyzeAsync(userId, new SkinProgressAnalyzeRequestDto { PhotoId = photoId }, cancellationToken);
        return await _dbContext.SkinProgressAnalyses
            .FirstAsync(x => x.UserId == userId && x.PhotoId == photoId, cancellationToken);
    }

    private static SkinProgressScoreChangesDto BuildScoreChanges(SkinProgressAnalysis beforeAnalysis, SkinProgressAnalysis afterAnalysis)
    {
        return new SkinProgressScoreChangesDto
        {
            AcneScoreChange = afterAnalysis.AcneScore - beforeAnalysis.AcneScore,
            RednessScoreChange = afterAnalysis.RednessScore - beforeAnalysis.RednessScore,
            DarkSpotScoreChange = afterAnalysis.DarkSpotScore - beforeAnalysis.DarkSpotScore,
            OilinessScoreChange = afterAnalysis.OilinessScore - beforeAnalysis.OilinessScore,
            DrynessScoreChange = afterAnalysis.DrynessScore - beforeAnalysis.DrynessScore,
            TextureScoreChange = afterAnalysis.TextureScore - beforeAnalysis.TextureScore,
            SensitivityScoreChange = afterAnalysis.SensitivityScore - beforeAnalysis.SensitivityScore,
            OverallScoreChange = afterAnalysis.OverallScore - beforeAnalysis.OverallScore
        };
    }

    private static string NormalizeCompareStatus(string? value, SkinProgressScoreChangesDto scoreChanges)
    {
        var normalized = value?.Trim().ToLowerInvariant();
        if (normalized is "improved" or "stable" or "worse" or "mixed" or "insufficient_data")
        {
            return normalized;
        }

        if (scoreChanges.OverallScoreChange < 0)
        {
            return "improved";
        }

        if (scoreChanges.OverallScoreChange > 0)
        {
            return "worse";
        }

        return "stable";
    }

    private static bool IsMissingRelation(PostgresException ex) => ex.SqlState == PostgresErrorCodes.UndefinedTable;

    private static AiFeatureException BuildSchemaMissingException(PostgresException ex) =>
        new("SKIN_PROGRESS_SCHEMA_MISSING", "Skin progress tables are missing in the database. Apply the skin progress migration before using this feature.", 503, ex);
}

internal sealed class SkinProgressCompareAiModel
{
    public string ProgressStatus { get; set; } = "insufficient_data";
    public string ComparisonSummary { get; set; } = string.Empty;
    public List<string> Improvements { get; set; } = [];
    public List<string> WorsenedAreas { get; set; } = [];
    public List<string> StableAreas { get; set; } = [];
    public List<string> Recommendations { get; set; } = [];
    public string? ConfidenceNote { get; set; }
}
