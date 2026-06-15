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

            await _aiUsageService.CheckLimitAsync(userId, "skin_analysis", cancellationToken);

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
            if (!HasMeaningfulAnalysisSignal(normalized))
            {
                if (!normalized.RiskFlags.Contains("poor_image_quality", StringComparer.OrdinalIgnoreCase))
                {
                    normalized.RiskFlags = [.. normalized.RiskFlags, "poor_image_quality"];
                }

                entity.Status = "failed";
                entity.ErrorMessage = "AI could not confidently read visible skin details from this photo. Try a clearer, front-facing photo in even lighting.";
                entity.DetectedConcerns = JsonSerializer.Serialize(normalized.DetectedConcerns);
                entity.Recommendations = JsonSerializer.Serialize(normalized.Recommendations);
                entity.RoutineSuggestions = JsonSerializer.Serialize(normalized.RoutineSuggestions);
                entity.ProductSuggestions = JsonSerializer.Serialize(normalized.ProductSuggestions);
                entity.SafetyNotes = JsonSerializer.Serialize(normalized.SafetyNotes);
                entity.RiskFlags = JsonSerializer.Serialize(normalized.RiskFlags);
                entity.RawAiResponse = aiResult.RawResponse;
                entity.ParsedAiResponse = JsonSerializer.Serialize(normalized);
                entity.AiModel = aiResult.Model ?? "openai";
                entity.ConfidenceScore = normalized.ConfidenceScore;
                entity.CompletedAt = DateTime.UtcNow;
                await _dbContext.SaveChangesAsync(cancellationToken);
                await _aiUsageService.LogUsageAsync(userId, "skin_analysis", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);
                throw new AiFeatureException("ANALYSIS_INCONCLUSIVE", entity.ErrorMessage, 422);
            }

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
            entity.OverallScore = normalized.OverallConcernSeverity ?? 0;
            entity.OverallConcernSeverity = normalized.OverallConcernSeverity;
            entity.SkinHealthScore = normalized.SkinHealthScore;
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
            await _aiUsageService.LogUsageAsync(userId, "skin_analysis", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);

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
        NormalizeLegacyCompatibility(input);
        input.SkinTypeEstimate = NormalizeValue(input.SkinTypeEstimate, "unknown");
        input.HydrationLevel = NormalizeValue(input.HydrationLevel, "unknown");
        input.OilinessLevel = NormalizeValue(input.OilinessLevel, "unknown");
        input.Metrics.Acne = ClampScore(input.Metrics.Acne);
        input.Metrics.Redness = ClampScore(input.Metrics.Redness);
        input.Metrics.Oiliness = ClampScore(input.Metrics.Oiliness);
        input.Metrics.Dryness = ClampScore(input.Metrics.Dryness);
        input.Metrics.Moisture = ClampScore(input.Metrics.Moisture);
        input.Metrics.Texture = ClampScore(input.Metrics.Texture);
        input.Scores.AcneScore = input.Metrics.Acne;
        input.Scores.RednessScore = input.Metrics.Redness;
        input.Scores.DarkSpotScore = ClampScore(input.Scores.DarkSpotScore);
        input.Scores.OilinessScore = input.Metrics.Oiliness;
        input.Scores.DrynessScore = input.Metrics.Dryness;
        input.Scores.TextureScore = input.Metrics.Texture;
        input.Scores.SensitivityScore = ClampScore(input.Scores.SensitivityScore);

        input.OverallConcernSeverity = ResolveOverallConcernSeverity(input);
        input.SkinHealthScore = ResolveSkinHealthScore(input);
        input.Scores.OverallScore = input.OverallConcernSeverity ?? 0;

        foreach (var concern in input.DetectedConcerns)
        {
            concern.Key = NormalizeValue(string.IsNullOrWhiteSpace(concern.Key) ? concern.Concern : concern.Key, "unknown");
            concern.Concern = NormalizeValue(concern.Concern, "unknown");
            concern.Label = string.IsNullOrWhiteSpace(concern.Label)
                ? Humanize(concern.Key)
                : concern.Label.Trim();
            concern.Severity = NormalizeSeverityBand(concern.Severity, concern.Score);
            concern.Score = ClampScore(concern.Score);
            concern.Confidence = ClampConfidenceRatio(concern.Confidence);
            concern.Evidence = string.IsNullOrWhiteSpace(concern.Evidence)
                ? concern.Description.Trim()
                : concern.Evidence.Trim();
            concern.RecommendationPriority = NormalizePriority(concern.RecommendationPriority);
        }

        input.Recommendations = input.Recommendations
            .Where(x => !string.IsNullOrWhiteSpace(x.Description) || !string.IsNullOrWhiteSpace(x.Reason))
            .Select(x =>
            {
                x.Type = NormalizeValue(x.Type, "routine");
                x.Title = string.IsNullOrWhiteSpace(x.Title) ? Humanize(x.Type) : x.Title.Trim();
                x.Description = string.IsNullOrWhiteSpace(x.Description) ? x.Reason.Trim() : x.Description.Trim();
                x.Priority = NormalizePriority(x.Priority);
                return x;
            })
            .ToList();
        input.Confidence = ResolveConfidencePercent(input);
        input.ConfidenceScore = (input.Confidence ?? 0) / 100m;
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

        input.AiSummary = string.IsNullOrWhiteSpace(input.AiSummary)
            ? input.Summary.Trim()
            : input.AiSummary.Trim();
        input.Summary = input.AiSummary;
        input.SafetyNote = string.IsNullOrWhiteSpace(input.SafetyNote)
            ? "This is not a medical diagnosis. Consider a dermatologist if irritation, pain, or persistent symptoms occur."
            : input.SafetyNote.Trim();
        input.SafetyNotes = input.SafetyNotes
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x.Trim())
            .ToList();
        if (!input.SafetyNotes.Contains(input.SafetyNote, StringComparer.OrdinalIgnoreCase))
        {
            input.SafetyNotes = [input.SafetyNote, .. input.SafetyNotes];
        }

        return input;
    }

    private static bool HasMeaningfulAnalysisSignal(SkinProgressAnalyzeAiModel input)
    {
        if (input.SkinHealthScore.HasValue || input.OverallConcernSeverity.HasValue || input.Scores.OverallScore > 0)
        {
            return true;
        }

        if (input.DetectedConcerns.Any(concern =>
                concern.Score > 0 ||
                !string.IsNullOrWhiteSpace(concern.Evidence) ||
                !string.IsNullOrWhiteSpace(concern.Description)))
        {
            return true;
        }

        return BuildConcernMetricValues(input).Any(score => score > 0);
    }

    private static void NormalizeLegacyCompatibility(SkinProgressAnalyzeAiModel input)
    {
        if (input.Concerns.Count > 0 && input.DetectedConcerns.Count == 0)
        {
            input.DetectedConcerns = input.Concerns.Select(concern => new SkinProgressConcernDto
            {
                Key = concern.Key,
                Concern = concern.Key,
                Label = concern.Label,
                Severity = SeverityBandFromNumeric(concern.Severity),
                Score = concern.Severity,
                Confidence = concern.Confidence / 100d,
                Description = concern.Evidence,
                Evidence = concern.Evidence,
                RecommendationPriority = concern.RecommendationPriority
            }).ToList();
        }

        if (input.RecommendationItems.Count > 0 && input.Recommendations.Count == 0)
        {
            input.Recommendations = input.RecommendationItems.Select(item => new SkinProgressRecommendationDto
            {
                Type = "routine",
                Title = item.Title,
                Description = item.Reason,
                Reason = item.Reason,
                Priority = item.Priority
            }).ToList();
        }

        if (string.IsNullOrWhiteSpace(input.AiSummary) && !string.IsNullOrWhiteSpace(input.Summary))
        {
            input.AiSummary = input.Summary;
        }
    }

    private static int ResolveOverallConcernSeverity(SkinProgressAnalyzeAiModel input)
    {
        if (input.OverallConcernSeverity.HasValue)
        {
            return ClampScore(input.OverallConcernSeverity.Value);
        }

        if (input.SkinHealthScore.HasValue)
        {
            return Math.Clamp(100 - ClampScore(input.SkinHealthScore.Value), 0, 100);
        }

        if (input.Scores.OverallScore > 0)
        {
            return ClampScore(input.Scores.OverallScore);
        }

        if (input.DetectedConcerns.Count > 0)
        {
            return Math.Clamp(
                (int)Math.Round(input.DetectedConcerns.Average(x => Math.Max(0, x.Score))),
                0,
                100);
        }

        var metricValues = BuildConcernMetricValues(input).ToArray();
        if (metricValues.Length > 0)
        {
            return Math.Clamp((int)Math.Round(metricValues.Average()), 0, 100);
        }

        return 0;
    }

    private static int ResolveSkinHealthScore(SkinProgressAnalyzeAiModel input)
    {
        if (input.SkinHealthScore.HasValue)
        {
            return ClampScore(input.SkinHealthScore.Value);
        }

        return Math.Clamp(100 - ResolveOverallConcernSeverity(input), 0, 100);
    }

    private static int ResolveConfidencePercent(SkinProgressAnalyzeAiModel input)
    {
        if (input.Confidence.HasValue)
        {
            return ClampScore(input.Confidence.Value);
        }

        if (input.ConfidenceScore.HasValue)
        {
            var raw = input.ConfidenceScore.Value <= 1m ? input.ConfidenceScore.Value * 100m : input.ConfidenceScore.Value;
            return Math.Clamp((int)Math.Round(raw), 0, 100);
        }

        if (input.RiskFlags.Contains("poor_image_quality", StringComparer.OrdinalIgnoreCase))
        {
            return 40;
        }

        return input.DetectedConcerns.Count == 0
            ? 82
            : Math.Clamp(
                (int)Math.Round(input.DetectedConcerns.Average(x => ClampConfidenceRatio(x.Confidence) * 100d)),
                0,
                100);
    }

    private static IEnumerable<int> BuildConcernMetricValues(SkinProgressAnalyzeAiModel input)
    {
        yield return ClampScore(input.Metrics.Acne);
        yield return ClampScore(input.Metrics.Redness);
        yield return ClampScore(input.Metrics.Oiliness);
        yield return ClampScore(input.Metrics.Dryness);
        yield return ClampScore(input.Metrics.Texture);
        yield return ClampScore(input.Scores.DarkSpotScore);
        yield return ClampScore(input.Scores.SensitivityScore);
    }

    private static double ClampConfidenceRatio(double value)
    {
        var normalized = value > 1d ? value / 100d : value;
        return Math.Clamp(normalized, 0d, 1d);
    }

    private static string NormalizeSeverityBand(string? band, int score)
    {
        var normalized = NormalizeValue(band, string.Empty);
        return normalized switch
        {
            "low" or "medium" or "high" => normalized,
            _ => SeverityBandFromNumeric(score)
        };
    }

    private static string SeverityBandFromNumeric(int score) => ClampScore(score) switch
    {
        >= 67 => "high",
        >= 34 => "medium",
        _ => "low"
    };

    private static string NormalizePriority(string? priority)
    {
        var normalized = NormalizeValue(priority, "medium");
        return normalized is "low" or "medium" or "high" ? normalized : "medium";
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
        new("SKIN_PROGRESS_SCHEMA_MISSING", "Skin progress schema is outdated. Apply BE_SkinSync/sql/2026-06-11-unify-skin-analysis-progress.sql or run the latest EF migration before using this feature.", 503, ex);
}

internal sealed class SkinProgressAnalyzeAiModel
{
    public int? SkinHealthScore { get; set; }
    public int? OverallConcernSeverity { get; set; }
    [JsonConverter(typeof(NullableFlexiblePercentIntJsonConverter))]
    public int? Confidence { get; set; }
    public string SkinTypeEstimate { get; set; } = "unknown";
    public string HydrationLevel { get; set; } = "unknown";
    public string OilinessLevel { get; set; } = "unknown";
    [JsonConverter(typeof(SkinProgressMetricsJsonConverter))]
    public SkinProgressMetricsDto Metrics { get; set; } = new();
    public SkinProgressScoreSetDto Scores { get; set; } = new();
    [JsonConverter(typeof(SkinProgressConcernInputListJsonConverter))]
    public List<SkinProgressConcernInputModel> Concerns { get; set; } = [];
    [JsonConverter(typeof(SkinProgressConcernDtoListJsonConverter))]
    public List<SkinProgressConcernDto> DetectedConcerns { get; set; } = [];
    public string Summary { get; set; } = string.Empty;
    public string AiSummary { get; set; } = string.Empty;
    [JsonConverter(typeof(SkinProgressRecommendationListJsonConverter))]
    public List<SkinProgressRecommendationDto> Recommendations { get; set; } = [];
    [JsonConverter(typeof(SkinProgressRecommendationInputListJsonConverter))]
    public List<SkinProgressRecommendationInputModel> RecommendationItems { get; set; } = [];
    [JsonConverter(typeof(SkinProgressRoutineSuggestionsJsonConverter))]
    public SkinProgressRoutineSuggestionsDto RoutineSuggestions { get; set; } = new();
    [JsonConverter(typeof(SkinProgressProductSuggestionListJsonConverter))]
    public List<SkinProgressProductSuggestionDto> ProductSuggestions { get; set; } = [];
    [JsonConverter(typeof(FlexibleStringListJsonConverter))]
    public List<string> SafetyNotes { get; set; } = [];
    [JsonConverter(typeof(FlexibleStringListJsonConverter))]
    public List<string> RiskFlags { get; set; } = [];
    public string SafetyNote { get; set; } = string.Empty;
    public string Disclaimer { get; set; } = string.Empty;
    public decimal? ConfidenceScore { get; set; }
}

internal sealed class SkinProgressConcernInputModel
{
    public string Key { get; set; } = "unknown";
    public string Label { get; set; } = string.Empty;
    [JsonConverter(typeof(FlexibleSeverityIntJsonConverter))]
    public int Severity { get; set; }
    [JsonConverter(typeof(FlexiblePercentIntJsonConverter))]
    public int Confidence { get; set; }
    public string Evidence { get; set; } = string.Empty;
    public string RecommendationPriority { get; set; } = "medium";
}

internal sealed class SkinProgressRecommendationInputModel
{
    public string Title { get; set; } = string.Empty;
    public string Reason { get; set; } = string.Empty;
    public string Priority { get; set; } = "medium";
}

internal sealed class SkinProgressMetricsJsonConverter : JsonConverter<SkinProgressMetricsDto>
{
    public override SkinProgressMetricsDto Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Null)
        {
            return new SkinProgressMetricsDto();
        }

        using var document = JsonDocument.ParseValue(ref reader);
        if (document.RootElement.ValueKind != JsonValueKind.Object)
        {
            return new SkinProgressMetricsDto();
        }

        return new SkinProgressMetricsDto
        {
            Acne = JsonParsingHelpers.ParsePercent(document.RootElement, "acne"),
            Redness = JsonParsingHelpers.ParsePercent(document.RootElement, "redness"),
            Oiliness = JsonParsingHelpers.ParsePercent(document.RootElement, "oiliness"),
            Dryness = JsonParsingHelpers.ParsePercent(document.RootElement, "dryness"),
            Moisture = JsonParsingHelpers.ParsePercent(document.RootElement, "moisture"),
            Texture = JsonParsingHelpers.ParsePercent(document.RootElement, "texture")
        };
    }

    public override void Write(Utf8JsonWriter writer, SkinProgressMetricsDto value, JsonSerializerOptions options)
    {
        JsonSerializer.Serialize(writer, value, options);
    }
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
                    if (element.TryGetProperty("description", out var descriptionElement) ||
                        element.TryGetProperty("reason", out descriptionElement))
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

internal sealed class SkinProgressRecommendationInputListJsonConverter : JsonConverter<List<SkinProgressRecommendationInputModel>>
{
    public override List<SkinProgressRecommendationInputModel> Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
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

        var items = new List<SkinProgressRecommendationInputModel>();
        foreach (var element in document.RootElement.EnumerateArray())
        {
            switch (element.ValueKind)
            {
                case JsonValueKind.String:
                {
                    var reason = element.GetString()?.Trim();
                    if (!string.IsNullOrWhiteSpace(reason))
                    {
                        items.Add(new SkinProgressRecommendationInputModel
                        {
                            Title = "Recommendation",
                            Reason = reason,
                            Priority = "medium"
                        });
                    }

                    break;
                }
                case JsonValueKind.Object:
                {
                    items.Add(new SkinProgressRecommendationInputModel
                    {
                        Title = JsonParsingHelpers.GetString(element, "title") ?? "Recommendation",
                        Reason = JsonParsingHelpers.GetString(element, "reason")
                            ?? JsonParsingHelpers.GetString(element, "description")
                            ?? string.Empty,
                        Priority = JsonParsingHelpers.GetString(element, "priority") ?? "medium"
                    });
                    break;
                }
            }
        }

        return items;
    }

    public override void Write(Utf8JsonWriter writer, List<SkinProgressRecommendationInputModel> value, JsonSerializerOptions options)
    {
        JsonSerializer.Serialize(writer, value, options);
    }
}

internal sealed class SkinProgressConcernInputListJsonConverter : JsonConverter<List<SkinProgressConcernInputModel>>
{
    public override List<SkinProgressConcernInputModel> Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
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

        var items = new List<SkinProgressConcernInputModel>();
        foreach (var element in document.RootElement.EnumerateArray())
        {
            switch (element.ValueKind)
            {
                case JsonValueKind.String:
                {
                    var label = element.GetString()?.Trim();
                    if (!string.IsNullOrWhiteSpace(label))
                    {
                        items.Add(new SkinProgressConcernInputModel
                        {
                            Key = label,
                            Label = label,
                        });
                    }

                    break;
                }
                case JsonValueKind.Object:
                {
                    try
                    {
                        var dto = element.Deserialize<SkinProgressConcernInputModel>(options);
                        if (dto is not null)
                        {
                            items.Add(dto);
                            break;
                        }
                    }
                    catch (JsonException)
                    {
                    }

                    items.Add(ParseConcernObject(element));
                    break;
                }
            }
        }

        return items;
    }

    public override void Write(Utf8JsonWriter writer, List<SkinProgressConcernInputModel> value, JsonSerializerOptions options)
    {
        JsonSerializer.Serialize(writer, value, options);
    }

    private static SkinProgressConcernInputModel ParseConcernObject(JsonElement element)
    {
        var key = JsonParsingHelpers.GetString(element, "key") ?? JsonParsingHelpers.GetString(element, "concern") ?? "unknown";
        var label = JsonParsingHelpers.GetString(element, "label") ?? key;
        var recommendationPriority = JsonParsingHelpers.GetString(element, "recommendationPriority") ?? JsonParsingHelpers.GetString(element, "priority") ?? "medium";

        return new SkinProgressConcernInputModel
        {
            Key = key,
            Label = label,
            Severity = JsonParsingHelpers.ParseSeverity(element, "severity"),
            Confidence = JsonParsingHelpers.ParsePercent(element, "confidence"),
            Evidence = JsonParsingHelpers.GetString(element, "evidence") ?? JsonParsingHelpers.GetString(element, "description") ?? string.Empty,
            RecommendationPriority = recommendationPriority
        };
    }
}

internal sealed class SkinProgressConcernDtoListJsonConverter : JsonConverter<List<SkinProgressConcernDto>>
{
    public override List<SkinProgressConcernDto> Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
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

        var items = new List<SkinProgressConcernDto>();
        foreach (var element in document.RootElement.EnumerateArray())
        {
            switch (element.ValueKind)
            {
                case JsonValueKind.String:
                {
                    var label = element.GetString()?.Trim();
                    if (!string.IsNullOrWhiteSpace(label))
                    {
                        items.Add(new SkinProgressConcernDto
                        {
                            Key = label,
                            Concern = label,
                            Label = label,
                        });
                    }

                    break;
                }
                case JsonValueKind.Object:
                {
                    items.Add(new SkinProgressConcernDto
                    {
                        Key = JsonParsingHelpers.GetString(element, "key") ?? JsonParsingHelpers.GetString(element, "concern") ?? "unknown",
                        Concern = JsonParsingHelpers.GetString(element, "concern") ?? JsonParsingHelpers.GetString(element, "key") ?? "unknown",
                        Label = JsonParsingHelpers.GetString(element, "label") ?? JsonParsingHelpers.GetString(element, "concern") ?? "Unknown",
                        Severity = JsonParsingHelpers.GetString(element, "severity") ?? "low",
                        Score = JsonParsingHelpers.ParsePercent(element, "score", "severity"),
                        Confidence = JsonParsingHelpers.ParseRatio(element, "confidence"),
                        Description = JsonParsingHelpers.GetString(element, "description") ?? string.Empty,
                        Evidence = JsonParsingHelpers.GetString(element, "evidence") ?? JsonParsingHelpers.GetString(element, "description") ?? string.Empty,
                        RecommendationPriority = JsonParsingHelpers.GetString(element, "recommendationPriority") ?? JsonParsingHelpers.GetString(element, "priority") ?? "medium"
                    });
                    break;
                }
            }
        }

        return items;
    }

    public override void Write(Utf8JsonWriter writer, List<SkinProgressConcernDto> value, JsonSerializerOptions options)
    {
        JsonSerializer.Serialize(writer, value, options);
    }
}

internal sealed class SkinProgressRoutineSuggestionsJsonConverter : JsonConverter<SkinProgressRoutineSuggestionsDto>
{
    public override SkinProgressRoutineSuggestionsDto Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Null)
        {
            return new SkinProgressRoutineSuggestionsDto();
        }

        using var document = JsonDocument.ParseValue(ref reader);
        if (document.RootElement.ValueKind != JsonValueKind.Object)
        {
            return new SkinProgressRoutineSuggestionsDto();
        }

        return new SkinProgressRoutineSuggestionsDto
        {
            Morning = JsonParsingHelpers.ParseStringArray(document.RootElement, "morning"),
            Evening = JsonParsingHelpers.ParseStringArray(document.RootElement, "evening")
        };
    }

    public override void Write(Utf8JsonWriter writer, SkinProgressRoutineSuggestionsDto value, JsonSerializerOptions options)
    {
        JsonSerializer.Serialize(writer, value, options);
    }
}

internal sealed class SkinProgressProductSuggestionListJsonConverter : JsonConverter<List<SkinProgressProductSuggestionDto>>
{
    public override List<SkinProgressProductSuggestionDto> Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
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

        var items = new List<SkinProgressProductSuggestionDto>();
        foreach (var element in document.RootElement.EnumerateArray())
        {
            switch (element.ValueKind)
            {
                case JsonValueKind.String:
                {
                    var reason = element.GetString()?.Trim();
                    if (!string.IsNullOrWhiteSpace(reason))
                    {
                        items.Add(new SkinProgressProductSuggestionDto
                        {
                            Reason = reason
                        });
                    }

                    break;
                }
                case JsonValueKind.Object:
                {
                    items.Add(new SkinProgressProductSuggestionDto
                    {
                        Category = JsonParsingHelpers.GetString(element, "category") ?? string.Empty,
                        Reason = JsonParsingHelpers.GetString(element, "reason") ?? JsonParsingHelpers.GetString(element, "description") ?? string.Empty,
                        AvoidIngredients = JsonParsingHelpers.ParseStringArray(element, "avoidIngredients"),
                        PreferredIngredients = JsonParsingHelpers.ParseStringArray(element, "preferredIngredients")
                    });
                    break;
                }
            }
        }

        return items;
    }

    public override void Write(Utf8JsonWriter writer, List<SkinProgressProductSuggestionDto> value, JsonSerializerOptions options)
    {
        JsonSerializer.Serialize(writer, value, options);
    }
}

internal sealed class FlexibleStringListJsonConverter : JsonConverter<List<string>>
{
    public override List<string> Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType == JsonTokenType.Null)
        {
            return [];
        }

        using var document = JsonDocument.ParseValue(ref reader);
        return document.RootElement.ValueKind switch
        {
            JsonValueKind.Array => document.RootElement
                .EnumerateArray()
                .SelectMany(ParseStringElement)
                .ToList(),
            JsonValueKind.String => string.IsNullOrWhiteSpace(document.RootElement.GetString())
                ? []
                : [document.RootElement.GetString()!.Trim()],
            _ => []
        };
    }

    public override void Write(Utf8JsonWriter writer, List<string> value, JsonSerializerOptions options)
    {
        JsonSerializer.Serialize(writer, value, options);
    }

    private static IEnumerable<string> ParseStringElement(JsonElement element)
    {
        return element.ValueKind switch
        {
            JsonValueKind.String => string.IsNullOrWhiteSpace(element.GetString())
                ? Array.Empty<string>()
                : [element.GetString()!.Trim()],
            JsonValueKind.Number => [element.GetRawText()],
            _ => Array.Empty<string>()
        };
    }
}

internal static class JsonParsingHelpers
{
    internal static string? GetString(JsonElement element, string propertyName)
    {
        if (!element.TryGetProperty(propertyName, out var property))
        {
            return null;
        }

        return property.ValueKind switch
        {
            JsonValueKind.String => property.GetString(),
            JsonValueKind.Number => property.GetRawText(),
            JsonValueKind.True => "true",
            JsonValueKind.False => "false",
            _ => null
        };
    }

    internal static int ParseSeverity(JsonElement element, params string[] propertyNames)
    {
        foreach (var propertyName in propertyNames)
        {
            if (!element.TryGetProperty(propertyName, out var property))
            {
                continue;
            }

            switch (property.ValueKind)
            {
                case JsonValueKind.Number:
                    return Math.Clamp((int)Math.Round(property.GetDouble()), 0, 100);
                case JsonValueKind.String:
                    return FlexibleSeverityIntJsonConverter.ParseSeverityString(property.GetString());
            }
        }

        return 0;
    }

    internal static int ParsePercent(JsonElement element, params string[] propertyNames)
    {
        foreach (var propertyName in propertyNames)
        {
            if (!element.TryGetProperty(propertyName, out var property))
            {
                continue;
            }

            switch (property.ValueKind)
            {
                case JsonValueKind.Number:
                {
                    var raw = property.GetDouble();
                    return Math.Clamp((int)Math.Round(raw <= 1d ? raw * 100d : raw), 0, 100);
                }
                case JsonValueKind.String:
                {
                    var parsed = FlexiblePercentParser.TryParseFlexiblePercentString(property.GetString());
                    if (parsed.HasValue)
                    {
                        var normalized = parsed.Value <= 1d ? parsed.Value * 100d : parsed.Value;
                        return Math.Clamp((int)Math.Round(normalized), 0, 100);
                    }

                    break;
                }
                case JsonValueKind.True:
                    return 100;
                case JsonValueKind.False:
                    return 0;
            }
        }

        return 0;
    }

    internal static double ParseRatio(JsonElement element, params string[] propertyNames)
    {
        var percent = ParsePercent(element, propertyNames);
        return Math.Clamp(percent / 100d, 0d, 1d);
    }

    internal static IReadOnlyCollection<string> ParseStringArray(JsonElement element, string propertyName)
    {
        if (!element.TryGetProperty(propertyName, out var property))
        {
            return Array.Empty<string>();
        }

        return property.ValueKind switch
        {
            JsonValueKind.Array => property
                .EnumerateArray()
                .Select(item => item.ValueKind switch
                {
                    JsonValueKind.String => item.GetString(),
                    JsonValueKind.Number => item.GetRawText(),
                    _ => null
                })
                .Where(item => !string.IsNullOrWhiteSpace(item))
                .Select(item => item!.Trim())
                .ToList(),
            JsonValueKind.String => string.IsNullOrWhiteSpace(property.GetString())
                ? Array.Empty<string>()
                : [property.GetString()!.Trim()],
            _ => Array.Empty<string>()
        };
    }
}

internal sealed class FlexibleSeverityIntJsonConverter : JsonConverter<int>
{
    public override int Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        return reader.TokenType switch
        {
            JsonTokenType.Number => Math.Clamp(reader.GetInt32(), 0, 100),
            JsonTokenType.String => ParseSeverityString(reader.GetString()),
            JsonTokenType.Null => 0,
            _ => 0
        };
    }

    public override void Write(Utf8JsonWriter writer, int value, JsonSerializerOptions options)
    {
        writer.WriteNumberValue(Math.Clamp(value, 0, 100));
    }

    internal static int ParseSeverityString(string? value)
    {
        var normalized = value?.Trim();
        if (string.IsNullOrWhiteSpace(normalized))
        {
            return 0;
        }

        if (int.TryParse(normalized.TrimEnd('%').Trim(), out var numeric))
        {
            return Math.Clamp(numeric, 0, 100);
        }

        return normalized.ToLowerInvariant() switch
        {
            "high" => 85,
            "medium" => 60,
            "low" => 35,
            "none" or "unknown" or "n/a" or "na" => 0,
            _ => 0
        };
    }
}

internal sealed class FlexiblePercentIntJsonConverter : JsonConverter<int>
{
    public override int Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        return FlexiblePercentParser.ParseFlexiblePercentValue(ref reader) ?? 0;
    }

    public override void Write(Utf8JsonWriter writer, int value, JsonSerializerOptions options)
    {
        writer.WriteNumberValue(Math.Clamp(value, 0, 100));
    }
}

internal sealed class NullableFlexiblePercentIntJsonConverter : JsonConverter<int?>
{
    public override int? Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        return FlexiblePercentParser.ParseFlexiblePercentValue(ref reader);
    }

    public override void Write(Utf8JsonWriter writer, int? value, JsonSerializerOptions options)
    {
        if (!value.HasValue)
        {
            writer.WriteNullValue();
            return;
        }

        writer.WriteNumberValue(Math.Clamp(value.Value, 0, 100));
    }
}

internal static class FlexiblePercentParser
{
    internal static int? ParseFlexiblePercentValue(ref Utf8JsonReader reader)
    {
        if (reader.TokenType == JsonTokenType.Null)
        {
            return null;
        }

        double? rawValue = reader.TokenType switch
        {
            JsonTokenType.Number => reader.GetDouble(),
            JsonTokenType.String => TryParseFlexiblePercentString(reader.GetString()),
            JsonTokenType.False => 0d,
            JsonTokenType.True => 100d,
            _ => null
        };

        if (!rawValue.HasValue)
        {
            return null;
        }

        var normalized = rawValue.Value <= 1d ? rawValue.Value * 100d : rawValue.Value;
        return Math.Clamp((int)Math.Round(normalized), 0, 100);
    }

    internal static double? TryParseFlexiblePercentString(string? value)
    {
        var normalized = value?.Trim();
        if (string.IsNullOrWhiteSpace(normalized))
        {
            return null;
        }

        normalized = normalized.TrimEnd('%').Trim();
        if (normalized.Equals("unknown", StringComparison.OrdinalIgnoreCase) ||
            normalized.Equals("n/a", StringComparison.OrdinalIgnoreCase) ||
            normalized.Equals("na", StringComparison.OrdinalIgnoreCase) ||
            normalized.Equals("null", StringComparison.OrdinalIgnoreCase) ||
            normalized.Equals("none", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        return double.TryParse(normalized, out var parsed) ? parsed : null;
    }
}
