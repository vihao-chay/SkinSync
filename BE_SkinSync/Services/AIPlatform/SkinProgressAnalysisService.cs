using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Entities;

namespace SkinSync.Services.AIPlatform;

public interface ISkinProgressAnalysisService
{
    Task<SkinProgressAnalysisResponseDto> AnalyzeAsync(Guid userId, SkinProgressAnalyzeRequestDto request, CancellationToken cancellationToken);
}

public class SkinProgressAnalysisService : ISkinProgressAnalysisService
{
    private readonly AppDbContext _dbContext;
    private readonly IWebHostEnvironment _environment;
    private readonly IOpenAiService _openAiService;
    private readonly IAiUsageService _aiUsageService;
    private readonly ILogger<SkinProgressAnalysisService> _logger;

    public SkinProgressAnalysisService(
        AppDbContext dbContext,
        IWebHostEnvironment environment,
        IOpenAiService openAiService,
        IAiUsageService aiUsageService,
        ILogger<SkinProgressAnalysisService> logger)
    {
        _dbContext = dbContext;
        _environment = environment;
        _openAiService = openAiService;
        _aiUsageService = aiUsageService;
        _logger = logger;
    }

    public async Task<SkinProgressAnalysisResponseDto> AnalyzeAsync(Guid userId, SkinProgressAnalyzeRequestDto request, CancellationToken cancellationToken)
    {
        try
        {
            var photo = await _dbContext.SkinProgressPhotos
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.Id == request.PhotoId && x.UserId == userId, cancellationToken)
                ?? throw new AiFeatureException("PHOTO_NOT_FOUND", "Progress photo not found.", 404);

            var existing = await _dbContext.SkinProgressAnalyses
                .AsNoTracking()
                .FirstOrDefaultAsync(x => x.PhotoId == photo.Id && x.UserId == userId, cancellationToken);
            if (existing is not null)
            {
                return existing.ToDto();
            }

            var user = await _dbContext.Users
                .Include(x => x.Profile)
                .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
                ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

            var regimen = await _dbContext.UserRegimens
                .AsNoTracking()
                .Include(x => x.Items)
                .ThenInclude(x => x.Product)
                .FirstOrDefaultAsync(x => x.UserId == userId && x.IsActive, cancellationToken);

            await _aiUsageService.CheckLimitAsync(userId, "skin_progress_analysis", cancellationToken);

            var imageSource = await BuildImageSourceAsync(photo.ImageUrl, cancellationToken);
            var metadataJson = JsonSerializer.Serialize(new
            {
                photoDate = photo.PhotoDate,
                timeOfDay = photo.TimeOfDay,
                lightingCondition = photo.LightingCondition,
                faceAngle = photo.FaceAngle,
                note = photo.Note
            });
            object routineContext = regimen is null ? new { } : regimen.ToCurrentRegimenDto();

            OpenAiResult<SkinProgressAnalyzeAiModel> aiResult;
            try
            {
                aiResult = await _openAiService.AnalyzeImageAsync<SkinProgressAnalyzeAiModel>(
                    AiPromptLibrary.CommonSystemPrompt,
                    AiPromptLibrary.BuildSkinProgressAnalyzePrompt(
                        AiContextMapper.SerializeUserProfile(user.Profile),
                        JsonSerializer.Serialize(routineContext),
                        metadataJson),
                    imageSource,
                    cancellationToken: cancellationToken);
            }
            catch (Exception ex) when (ex is not AiFeatureException)
            {
                _logger.LogError(ex, "Skin progress analysis failed for user {UserId}, photo {PhotoId}.", userId, photo.Id);
                throw new AiFeatureException("AI_SERVICE_ERROR", "AI progress analysis failed.", 502, ex);
            }

            var normalized = NormalizeAiResult(aiResult.Value);
            var entity = new SkinProgressAnalysis
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                PhotoId = photo.Id,
                SkinTypeEstimate = normalized.SkinTypeEstimate,
                HydrationLevel = normalized.HydrationLevel,
                OilinessLevel = normalized.OilinessLevel,
                AcneScore = normalized.Scores.AcneScore,
                RednessScore = normalized.Scores.RednessScore,
                DarkSpotScore = normalized.Scores.DarkSpotScore,
                OilinessScore = normalized.Scores.OilinessScore,
                DrynessScore = normalized.Scores.DrynessScore,
                TextureScore = normalized.Scores.TextureScore,
                SensitivityScore = normalized.Scores.SensitivityScore,
                OverallScore = normalized.Scores.OverallScore,
                DetectedConcerns = JsonSerializer.Serialize(normalized.DetectedConcerns),
                AiSummary = normalized.AiSummary,
                Recommendations = JsonSerializer.Serialize(normalized.Recommendations),
                RiskFlags = JsonSerializer.Serialize(normalized.RiskFlags),
                RawAiResponse = aiResult.RawResponse,
                CreatedAt = DateTime.UtcNow
            };

            _dbContext.SkinProgressAnalyses.Add(entity);
            await _dbContext.SaveChangesAsync(cancellationToken);
            await _aiUsageService.LogUsageAsync(userId, "skin_progress_analysis", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);

            return entity.ToDto();
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
    }

    private async Task<string> BuildImageSourceAsync(string imageUrl, CancellationToken cancellationToken)
    {
        if (imageUrl.StartsWith("data:", StringComparison.OrdinalIgnoreCase) ||
            imageUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            imageUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            return imageUrl;
        }

        var webRoot = _environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot");
        var absolutePath = Path.Combine(webRoot, imageUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
        var bytes = await File.ReadAllBytesAsync(absolutePath, cancellationToken);
        var contentType = ImageMimeTypeHelper.ResolveForPath(absolutePath, bytes);
        return $"data:{contentType};base64,{Convert.ToBase64String(bytes)}";
    }

    private static SkinProgressAnalyzeAiModel NormalizeAiResult(SkinProgressAnalyzeAiModel input)
    {
        input.SkinTypeEstimate = NormalizeValue(input.SkinTypeEstimate, "unknown");
        input.HydrationLevel = NormalizeValue(input.HydrationLevel, "unknown");
        input.OilinessLevel = NormalizeValue(input.OilinessLevel, "unknown");
        input.Scores.AcneScore = ClampScore(input.Scores.AcneScore);
        input.Scores.RednessScore = ClampScore(input.Scores.RednessScore);
        input.Scores.DarkSpotScore = ClampScore(input.Scores.DarkSpotScore);
        input.Scores.OilinessScore = ClampScore(input.Scores.OilinessScore);
        input.Scores.DrynessScore = ClampScore(input.Scores.DrynessScore);
        input.Scores.TextureScore = ClampScore(input.Scores.TextureScore);
        input.Scores.SensitivityScore = ClampScore(input.Scores.SensitivityScore);
        input.Scores.OverallScore = ClampScore(input.Scores.OverallScore);

        foreach (var concern in input.DetectedConcerns)
        {
            concern.Concern = NormalizeValue(concern.Concern, "unknown");
            concern.Severity = NormalizeValue(concern.Severity, "low");
            concern.Score = ClampScore(concern.Score);
            concern.Confidence = Math.Clamp(concern.Confidence, 0d, 1d);
        }

        input.RiskFlags = input.RiskFlags
            .Select(x => NormalizeValue(x, "poor_image_quality"))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (string.IsNullOrWhiteSpace(input.Disclaimer))
        {
            input.Disclaimer = "AI analysis is for skincare tracking only and is not a medical diagnosis.";
        }

        return input;
    }

    private static string NormalizeValue(string? value, string fallback)
    {
        var normalized = value?.Trim().ToLowerInvariant();
        return string.IsNullOrWhiteSpace(normalized) ? fallback : normalized;
    }

    private static int ClampScore(int value) => Math.Clamp(value, 0, 100);

    private static bool IsMissingRelation(PostgresException ex) => ex.SqlState == PostgresErrorCodes.UndefinedTable;

    private static AiFeatureException BuildSchemaMissingException(PostgresException ex) =>
        new("SKIN_PROGRESS_SCHEMA_MISSING", "Skin progress tables are missing in the database. Apply the skin progress migration before using this feature.", 503, ex);
}

internal sealed class SkinProgressAnalyzeAiModel
{
    public string SkinTypeEstimate { get; set; } = "unknown";
    public string HydrationLevel { get; set; } = "unknown";
    public string OilinessLevel { get; set; } = "unknown";
    public SkinProgressScoreSetDto Scores { get; set; } = new();
    public List<SkinProgressConcernDto> DetectedConcerns { get; set; } = [];
    public string AiSummary { get; set; } = string.Empty;
    public List<string> Recommendations { get; set; } = [];
    public List<string> RiskFlags { get; set; } = [];
    public string Disclaimer { get; set; } = string.Empty;
}
