using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
using Npgsql;
using SkinSync.Data;
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
    private readonly IImageStorageService _imageStorageService;
    private readonly IOpenAiService _openAiService;
    private readonly IAiUsageService _aiUsageService;
    private readonly ILogger<SkinProgressAnalysisService> _logger;

    public SkinProgressAnalysisService(
        AppDbContext dbContext,
        IImageStorageService imageStorageService,
        IOpenAiService openAiService,
        IAiUsageService aiUsageService,
        ILogger<SkinProgressAnalysisService> logger)
    {
        _dbContext = dbContext;
        _imageStorageService = imageStorageService;
        _openAiService = openAiService;
        _aiUsageService = aiUsageService;
        _logger = logger;
    }

    public async Task<SkinProgressAnalysisResponseDto> AnalyzeAsync(Guid userId, SkinProgressAnalyzeRequestDto request, CancellationToken cancellationToken)
    {
        try
        {
            var photo = await _dbContext.SkinProgressPhotos
                .FirstOrDefaultAsync(x => x.Id == request.PhotoId && x.UserId == userId, cancellationToken)
                ?? throw new AiFeatureException("PHOTO_NOT_FOUND", "Progress photo not found.", 404);

            var existing = await _dbContext.SkinProgressAnalyses
                .FirstOrDefaultAsync(x => x.PhotoId == photo.Id && x.UserId == userId, cancellationToken);
            if (existing is not null && existing.DiscardedAt == null && existing.Status == "completed")
            {
                return existing.ToDto(photo);
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

            var entity = existing ?? new SkinProgressAnalysis
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                PhotoId = photo.Id,
                CreatedAt = DateTime.UtcNow
            };

            entity.Status = "processing";
            entity.ErrorMessage = null;
            entity.DiscardedAt = null;
            entity.RawAiResponse = "{}";
            entity.ParsedAiResponse = null;
            entity.CompletedAt = null;

            if (existing is null)
            {
                _dbContext.SkinProgressAnalyses.Add(entity);
            }

            await _dbContext.SaveChangesAsync(cancellationToken);

            var imageSource = await _imageStorageService.BuildImageSourceAsync(photo.ImageUrl, cancellationToken);
            var metadataJson = string.IsNullOrWhiteSpace(photo.ImageMetadataJson)
                ? JsonSerializer.Serialize(new
                {
                    photoDate = photo.PhotoDate,
                    timeOfDay = photo.TimeOfDay,
                    lightingCondition = photo.LightingCondition,
                    faceAngle = photo.FaceAngle,
                    note = photo.Note
                })
                : photo.ImageMetadataJson;
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
                entity.Status = "failed";
                entity.ErrorMessage = "AI progress analysis failed.";
                entity.CompletedAt = DateTime.UtcNow;
                await _dbContext.SaveChangesAsync(cancellationToken);
                throw new AiFeatureException("AI_SERVICE_ERROR", "AI progress analysis failed.", 502, ex);
            }

            var normalized = NormalizeAiResult(aiResult.Value);
            entity.SkinTypeEstimate = normalized.SkinTypeEstimate;
            entity.HydrationLevel = normalized.HydrationLevel;
            entity.OilinessLevel = normalized.OilinessLevel;
            entity.AcneScore = normalized.Scores.AcneScore;
            entity.RednessScore = normalized.Scores.RednessScore;
            entity.DarkSpotScore = normalized.Scores.DarkSpotScore;
            entity.OilinessScore = normalized.Scores.OilinessScore;
            entity.DrynessScore = normalized.Scores.DrynessScore;
            entity.TextureScore = normalized.Scores.TextureScore;
            entity.SensitivityScore = normalized.Scores.SensitivityScore;
            entity.OverallScore = normalized.Scores.OverallScore;
            entity.DetectedConcerns = JsonSerializer.Serialize(normalized.DetectedConcerns);
            entity.AiSummary = normalized.AiSummary;
            entity.Recommendations = JsonSerializer.Serialize(normalized.Recommendations);
            entity.RoutineSuggestions = JsonSerializer.Serialize(normalized.RoutineSuggestions);
            entity.ProductSuggestions = JsonSerializer.Serialize(normalized.ProductSuggestions);
            entity.SafetyNotes = JsonSerializer.Serialize(normalized.SafetyNotes);
            entity.RiskFlags = JsonSerializer.Serialize(normalized.RiskFlags);
            entity.RawAiResponse = aiResult.RawResponse;
            entity.ParsedAiResponse = JsonSerializer.Serialize(normalized);
            entity.AiModel = aiResult.Model ?? "openai";
            entity.ConfidenceScore = normalized.ConfidenceScore;
            entity.Status = "completed";
            entity.ErrorMessage = null;
            entity.CompletedAt = DateTime.UtcNow;
            await _dbContext.SaveChangesAsync(cancellationToken);
            await _aiUsageService.LogUsageAsync(userId, "skin_progress_analysis", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);

            return entity.ToDto(photo);
        }
        catch (PostgresException ex) when (IsMissingRelation(ex))
        {
            throw BuildSchemaMissingException(ex);
        }
        catch (DbUpdateException ex) when (ex.InnerException is PostgresException pgEx && IsMissingRelation(pgEx))
        {
            throw BuildSchemaMissingException(pgEx);
        }
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
            concern.Label = string.IsNullOrWhiteSpace(concern.Label)
                ? Humanize(concern.Concern)
                : concern.Label.Trim();
            concern.Severity = NormalizeValue(concern.Severity, "low");
            concern.Score = ClampScore(concern.Score);
            concern.Confidence = Math.Clamp(concern.Confidence, 0d, 1d);
        }

        input.Recommendations = input.Recommendations
            .Where(x => !string.IsNullOrWhiteSpace(x.Description))
            .Select(x =>
            {
                x.Type = NormalizeValue(x.Type, "routine");
                x.Title = string.IsNullOrWhiteSpace(x.Title) ? Humanize(x.Type) : x.Title.Trim();
                x.Priority = NormalizeValue(x.Priority, "medium");
                return x;
            })
            .ToList();
        input.ConfidenceScore = input.ConfidenceScore is null
            ? 0.82m
            : Math.Clamp(input.ConfidenceScore.Value, 0m, 1m);
        input.RiskFlags = input.RiskFlags
            .Select(x => NormalizeValue(x, "poor_image_quality"))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
        input.SafetyNotes = input.SafetyNotes
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x.Trim())
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

    private static string Humanize(string value)
    {
        var normalized = value.Trim().Replace('_', ' ');
        if (normalized.Length == 0)
        {
            return "Unknown";
        }

        return char.ToUpperInvariant(normalized[0]) + normalized[1..];
    }

    private static bool IsMissingRelation(PostgresException ex) =>
        ex.SqlState is PostgresErrorCodes.UndefinedTable or PostgresErrorCodes.UndefinedColumn;

    private static AiFeatureException BuildSchemaMissingException(PostgresException ex) =>
        new("SKIN_PROGRESS_SCHEMA_MISSING", "Skin progress schema is outdated. Apply BE_SkinSync/sql/2026-06-11-unify-skin-analysis-progress.sql before using this feature.", 503, ex);
}

internal sealed class SkinProgressAnalyzeAiModel
{
    public string SkinTypeEstimate { get; set; } = "unknown";
    public string HydrationLevel { get; set; } = "unknown";
    public string OilinessLevel { get; set; } = "unknown";
    public SkinProgressScoreSetDto Scores { get; set; } = new();
    public List<SkinProgressConcernDto> DetectedConcerns { get; set; } = [];
    public string AiSummary { get; set; } = string.Empty;
    [JsonConverter(typeof(SkinProgressRecommendationListJsonConverter))]
    public List<SkinProgressRecommendationDto> Recommendations { get; set; } = [];
    public SkinProgressRoutineSuggestionsDto RoutineSuggestions { get; set; } = new();
    public List<SkinProgressProductSuggestionDto> ProductSuggestions { get; set; } = [];
    public List<string> SafetyNotes { get; set; } = [];
    public List<string> RiskFlags { get; set; } = [];
    public string Disclaimer { get; set; } = string.Empty;
    public decimal? ConfidenceScore { get; set; }
}

internal sealed class SkinProgressRecommendationListJsonConverter : JsonConverter<List<SkinProgressRecommendationDto>>
{
    public override List<SkinProgressRecommendationDto> Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Null)
        {
            return [];
        }

        using var document = JsonDocument.ParseValue(ref reader);
        if (document.RootElement.ValueKind != JsonValueKind.Array)
        {
            return [];
        }

        var items = new List<SkinProgressRecommendationDto>();
        var index = 0;
        foreach (var element in document.RootElement.EnumerateArray())
        {
            index++;
            if (element.ValueKind == JsonValueKind.String)
            {
                var description = element.GetString();
                if (!string.IsNullOrWhiteSpace(description))
                {
                    items.Add(new SkinProgressRecommendationDto
                    {
                        Type = "routine",
                        Title = $"Recommendation {index}",
                        Description = description.Trim(),
                        Priority = "medium"
                    });
                }

                continue;
            }

            if (element.ValueKind == JsonValueKind.Object)
            {
                try
                {
                    var dto = element.Deserialize<SkinProgressRecommendationDto>(options);
                    if (dto is not null)
                    {
                        items.Add(dto);
                    }
                }
                catch (JsonException)
                {
                    if (element.TryGetProperty("description", out var descriptionElement))
                    {
                        var description = descriptionElement.GetString();
                        if (!string.IsNullOrWhiteSpace(description))
                        {
                            items.Add(new SkinProgressRecommendationDto
                            {
                                Type = element.TryGetProperty("type", out var typeElement) && !string.IsNullOrWhiteSpace(typeElement.GetString())
                                    ? typeElement.GetString()!.Trim()
                                    : "routine",
                                Title = element.TryGetProperty("title", out var titleElement) && !string.IsNullOrWhiteSpace(titleElement.GetString())
                                    ? titleElement.GetString()!.Trim()
                                    : $"Recommendation {index}",
                                Description = description.Trim(),
                                Priority = element.TryGetProperty("priority", out var priorityElement) && !string.IsNullOrWhiteSpace(priorityElement.GetString())
                                    ? priorityElement.GetString()!.Trim()
                                    : "medium"
                            });
                        }
                    }
                }
            }
        }

        return items;
    }

    public override void Write(Utf8JsonWriter writer, List<SkinProgressRecommendationDto> value, JsonSerializerOptions options)
    {
        JsonSerializer.Serialize(writer, value, options);
    }
}
