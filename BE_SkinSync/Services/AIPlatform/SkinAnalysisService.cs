using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Entities;

namespace SkinSync.Services.AIPlatform;

public interface ISkinAnalysisService
{
    Task<AiSkinAnalysisResponseDto> AnalyzeAsync(Guid userId, AiSkinAnalysisRequestDto request, CancellationToken cancellationToken);
}

public class SkinAnalysisService : ISkinAnalysisService
{
    private readonly AppDbContext _dbContext;
    private readonly IWebHostEnvironment _environment;
    private readonly IOpenAiService _openAiService;
    private readonly IAiUsageService _aiUsageService;
    private readonly ILogger<SkinAnalysisService> _logger;

    public SkinAnalysisService(
        AppDbContext dbContext,
        IWebHostEnvironment environment,
        IOpenAiService openAiService,
        IAiUsageService aiUsageService,
        ILogger<SkinAnalysisService> logger)
    {
        _dbContext = dbContext;
        _environment = environment;
        _openAiService = openAiService;
        _aiUsageService = aiUsageService;
        _logger = logger;
    }

    public async Task<AiSkinAnalysisResponseDto> AnalyzeAsync(Guid userId, AiSkinAnalysisRequestDto request, CancellationToken cancellationToken)
    {
        if (request.Image is null && string.IsNullOrWhiteSpace(request.ImageUrl))
        {
            throw new AiFeatureException("INVALID_REQUEST", "Image file or imageUrl is required.");
        }

        var user = await _dbContext.Users
            .Include(x => x.Profile)
            .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);
        if (user is null)
        {
            throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);
        }

        await _aiUsageService.CheckLimitAsync(userId, "skin_analysis", cancellationToken);

        var storedImageUrl = await StoreImageAsync(request, cancellationToken);
        var imageSource = await BuildImageSourceAsync(request, storedImageUrl, cancellationToken);
        var profileJson = AiContextMapper.SerializeUserProfile(user.Profile);
        var onboardingJson = AiContextMapper.SerializeOnboarding(user.Profile);
        var systemPrompt = AiPromptLibrary.CommonSystemPrompt;
        var userPrompt = AiPromptLibrary.BuildSkinAnalysisPrompt(profileJson, onboardingJson, request.AdditionalNote);

        OpenAiResult<AiSkinAnalysisAiModel> aiResult;
        try
        {
            aiResult = await _openAiService.AnalyzeImageAsync<AiSkinAnalysisAiModel>(
                systemPrompt,
                userPrompt,
                imageSource,
                cancellationToken: cancellationToken);
        }
        catch (Exception ex) when (ex is not AiFeatureException)
        {
            _logger.LogError(ex, "Skin analysis failed for user {UserId}.", userId);
            throw new AiFeatureException("AI_SERVICE_ERROR", "AI analysis failed.", 502, ex);
        }

        var analysis = MapToEntity(userId, storedImageUrl, aiResult);
        _dbContext.AiAnalyses.Add(analysis);
        await _dbContext.SaveChangesAsync(cancellationToken);
        await _aiUsageService.LogUsageAsync(userId, "skin_analysis", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);

        return new AiSkinAnalysisResponseDto
        {
            AnalysisId = analysis.Id,
            SkinSummary = aiResult.Value.SkinSummary,
            DetectedConcerns = aiResult.Value.DetectedConcerns,
            Recommendations = aiResult.Value.Recommendations,
            RiskFlags = aiResult.Value.RiskFlags,
            Disclaimer = string.IsNullOrWhiteSpace(aiResult.Value.Disclaimer)
                ? "This AI analysis is for skincare guidance only and is not a medical diagnosis."
                : aiResult.Value.Disclaimer
        };
    }

    private async Task<string> StoreImageAsync(AiSkinAnalysisRequestDto request, CancellationToken cancellationToken)
    {
        if (request.Image is null)
        {
            return request.ImageUrl!.Trim();
        }

        var uploadDir = Path.Combine(_environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot"), "uploads", "analyses");
        Directory.CreateDirectory(uploadDir);
        var extension = Path.GetExtension(request.Image.FileName);
        var fileName = $"{Guid.NewGuid():N}{extension}";
        var absolutePath = Path.Combine(uploadDir, fileName);
        await using var stream = File.Create(absolutePath);
        await request.Image.CopyToAsync(stream, cancellationToken);
        return $"/uploads/analyses/{fileName}";
    }

    private async Task<string> BuildImageSourceAsync(AiSkinAnalysisRequestDto request, string storedImageUrl, CancellationToken cancellationToken)
    {
        if (request.Image is not null)
        {
            await using var stream = request.Image.OpenReadStream();
            using var memory = new MemoryStream();
            await stream.CopyToAsync(memory, cancellationToken);
            var uploadContentType = string.IsNullOrWhiteSpace(request.Image.ContentType) ? "image/jpeg" : request.Image.ContentType;
            return $"data:{uploadContentType};base64,{Convert.ToBase64String(memory.ToArray())}";
        }

        var imageUrl = request.ImageUrl!;
        if (imageUrl.StartsWith("data:", StringComparison.OrdinalIgnoreCase) ||
            imageUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            imageUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            return imageUrl;
        }

        var webRoot = _environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot");
        var absolutePath = Path.Combine(webRoot, imageUrl.TrimStart('/'));
        var bytes = await File.ReadAllBytesAsync(absolutePath, cancellationToken);
        var localContentType = Path.GetExtension(absolutePath).ToLowerInvariant() switch
        {
            ".png" => "image/png",
            ".webp" => "image/webp",
            ".gif" => "image/gif",
            _ => "image/jpeg"
        };
        return $"data:{localContentType};base64,{Convert.ToBase64String(bytes)}";
    }

    private static AiAnalysis MapToEntity(Guid userId, string imageUrl, OpenAiResult<AiSkinAnalysisAiModel> result)
    {
        var issues = result.Value.DetectedConcerns
            .Select(concern => new AiAnalysisIssue
            {
                Id = Guid.NewGuid(),
                IssueType = concern.Concern,
                SeverityScore = concern.Severity.ToLowerInvariant() switch
                {
                    "high" => 85,
                    "medium" => 60,
                    _ => 35
                },
                ConfidenceScore = (int)Math.Round(Math.Clamp(concern.Confidence, 0d, 1d) * 100d),
                Description = concern.Description
            })
            .ToList();

        var recommendations = result.Value.Recommendations
            .Select((item, index) => new AiRecommendation
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                RecommendationType = "routine",
                Title = $"Recommendation {index + 1}",
                Content = item,
                Priority = Math.Min(index + 1, 5)
            })
            .ToList();

        var overallScore = Math.Max(0, 100 - (issues.Count == 0 ? 15 : (int)issues.Average(x => x.SeverityScore)));

        return new AiAnalysis
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ImageUrl = imageUrl,
            OverallScore = overallScore,
            RecoveryCapacity = Math.Max(0, 100 - issues.Where(x => x.IssueType.Contains("dry", StringComparison.OrdinalIgnoreCase)).Select(x => x.SeverityScore).DefaultIfEmpty(25).Max()),
            UvDamage = issues.Where(x => x.IssueType.Contains("dark", StringComparison.OrdinalIgnoreCase) || x.IssueType.Contains("pig", StringComparison.OrdinalIgnoreCase)).Select(x => x.SeverityScore).DefaultIfEmpty(20).Max(),
            AgingRisk = issues.Where(x => x.IssueType.Contains("wrinkle", StringComparison.OrdinalIgnoreCase)).Select(x => x.SeverityScore).DefaultIfEmpty(20).Max(),
            IssuesDetected = JsonSerializer.Serialize(result.Value.DetectedConcerns),
            RootCauses = JsonSerializer.Serialize(new
            {
                skinSummary = result.Value.SkinSummary,
                riskFlags = result.Value.RiskFlags
            }),
            AiModel = result.Model ?? "openai",
            RawResponse = result.RawResponse,
            Status = "completed",
            CreatedAt = DateTime.UtcNow,
            AnalysisIssues = issues,
            Recommendations = recommendations
        };
    }
}

internal sealed class AiSkinAnalysisAiModel
{
    public string SkinSummary { get; set; } = string.Empty;
    public List<AiDetectedConcernDto> DetectedConcerns { get; set; } = [];
    public List<string> Recommendations { get; set; } = [];
    public List<string> RiskFlags { get; set; } = [];
    public string Disclaimer { get; set; } = string.Empty;
}
