using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinSync.Base;
using SkinSync.Helpers;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.Analysis;
using SkinSync.Models.Dtos;
using SkinSync.Models.Dtos.Skin;
using SkinSync.Models.Entities;
using SkinSync.Repositories;
using SkinSync.Services;
using SkinSync.Services.AIPlatform;
using System.Text.Json;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AnalysisController : ControllerBase
{
    private readonly IUserRepository _userRepository;
    private readonly IAnalysisRepository _analysisRepository;
    private readonly IRegimenRepository _regimenRepository;
    private readonly IProductRepository _productRepository;
    private readonly IAiAnalysisService _aiAnalysisService;
    private readonly IRegimenBuilderService _regimenBuilderService;
    private readonly ISkinService _skinService;
    private readonly IAiUsageService _aiUsageService;
    private readonly IWebHostEnvironment _environment;

    public AnalysisController(
        IUserRepository userRepository,
        IAnalysisRepository analysisRepository,
        IRegimenRepository regimenRepository,
        IProductRepository productRepository,
        IAiAnalysisService aiAnalysisService,
        IRegimenBuilderService regimenBuilderService,
        ISkinService skinService,
        IAiUsageService aiUsageService,
        IWebHostEnvironment environment)
    {
        _userRepository = userRepository;
        _analysisRepository = analysisRepository;
        _regimenRepository = regimenRepository;
        _productRepository = productRepository;
        _aiAnalysisService = aiAnalysisService;
        _regimenBuilderService = regimenBuilderService;
        _skinService = skinService;
        _aiUsageService = aiUsageService;
        _environment = environment;
    }

    [HttpPost("scan")]
    [Consumes("multipart/form-data")]
    public async Task<ResponseEntity<AnalysisScanResponseDto>> Scan([FromForm] AnalysisScanRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<AnalysisScanResponseDto>.Fail("Missing authenticated user.", 401);
        }

        if (request.Image is null || request.Image.Length == 0)
        {
            return ResponseEntity<AnalysisScanResponseDto>.Fail("Image file is required.", 400);
        }

        var user = await _userRepository.GetByIdWithProfileAsync(userId, cancellationToken);

        if (user is null)
        {
            return ResponseEntity<AnalysisScanResponseDto>.Fail("User not found.", 404);
        }

        try
        {
            await _aiUsageService.CheckLimitAsync(userId, "skin_analysis", cancellationToken);
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<AnalysisScanResponseDto>.Fail(ex.Message, ex.StatusCode);
        }

        var uploadDir = Path.Combine(_environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot"), "uploads", "analyses");
        Directory.CreateDirectory(uploadDir);

        var extension = Path.GetExtension(request.Image.FileName);
        var storedFileName = $"{Guid.NewGuid():N}{extension}";
        var fullPath = Path.Combine(uploadDir, storedFileName);

        await using (var fs = System.IO.File.Create(fullPath))
        {
            await request.Image.CopyToAsync(fs, cancellationToken);
        }

        var imageUrl = $"/uploads/analyses/{storedFileName}";
        var analysis = await BuildAnalysisAsync(userId, user.Profile, imageUrl, storedFileName, cancellationToken);

        var products = await _productRepository.GetAllAsync(cancellationToken);

        await _analysisRepository.AddAsync(analysis, cancellationToken);
        await _regimenRepository.DeactivateAllByUserIdAsync(userId, cancellationToken);

        var newRegimen = await BuildRegimenFromAnalysisAsync(userId, user.Profile, analysis, products, cancellationToken)
            ?? _regimenBuilderService.BuildRegimen(userId, analysis.Id, user.Profile?.SkinType ?? "normal", products);
        await _regimenRepository.AddAsync(newRegimen, cancellationToken);
        await _aiUsageService.LogUsageAsync(userId, "skin_analysis", analysis.AiModel, null, null, cancellationToken);

        return ResponseEntity<AnalysisScanResponseDto>.Ok(new AnalysisScanResponseDto
        {
            Analysis = analysis.ToDetailDto(),
            RegimenId = newRegimen.Id,
            StartDate = newRegimen.StartDate,
            EndDate = newRegimen.EndDate,
            IsActive = newRegimen.IsActive,
            ItemCount = newRegimen.Items.Count
        }, "Skin analysis completed successfully.");
    }

    [HttpGet("history")]
    public async Task<ResponseEntity<PagingResult<AnalysisHistoryItemDto>>> History(
        [FromQuery] AnalysisHistoryQueryDto query,
        CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<PagingResult<AnalysisHistoryItemDto>>.Fail("Missing authenticated user.", 401);
        }

        var history = await _analysisRepository.GetPagedHistoryByUserIdAsync(userId, query, cancellationToken);
        var response = new PagingResult<AnalysisHistoryItemDto>
        {
            Items = history.Items.Select(x => x.ToHistoryDto()).ToList(),
            Search = history.Search,
            SortBy = history.SortBy,
            SortDirection = history.SortDirection,
            Filters = history.Filters,
            PageIndex = history.PageIndex,
            PageSize = history.PageSize,
            TotalRow = history.TotalRow
        };

        return ResponseEntity<PagingResult<AnalysisHistoryItemDto>>.Ok(response, "Fetched analysis history successfully.");
    }

    [HttpGet("latest")]
    public async Task<ResponseEntity<AnalysisDetailResponseDto>> Latest(CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<AnalysisDetailResponseDto>.Fail("Missing authenticated user.", 401);
        }

        var analysis = await _analysisRepository.GetLatestByUserIdAsync(userId, cancellationToken);
        if (analysis is null)
        {
            return ResponseEntity<AnalysisDetailResponseDto>.Fail("No analysis found.", 404);
        }

        return ResponseEntity<AnalysisDetailResponseDto>.Ok(analysis.ToDetailDto(), "Fetched latest analysis successfully.");
    }

    [HttpGet("{id:guid}")]
    public async Task<ResponseEntity<AnalysisDetailResponseDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetUserId(out var userId))
        {
            return ResponseEntity<AnalysisDetailResponseDto>.Fail("Missing authenticated user.", 401);
        }

        var analysis = await _analysisRepository.GetByIdAsync(id, cancellationToken);
        if (analysis is null || analysis.UserId != userId)
        {
            return ResponseEntity<AnalysisDetailResponseDto>.Fail("Analysis not found.", 404);
        }

        return ResponseEntity<AnalysisDetailResponseDto>.Ok(analysis.ToDetailDto(), "Fetched analysis successfully.");
    }

    private async Task<AiAnalysis> BuildAnalysisAsync(
        Guid userId,
        UserProfile? profile,
        string imageUrl,
        string storedFileName,
        CancellationToken cancellationToken)
    {
        try
        {
            var ai = await _skinService.AnalyzeSkinSync(new SkinAnalyzeRequestDto
            {
                ImageUrl = imageUrl
            }, cancellationToken);

            var overallScore = CalculateOverallScore(ai);
            var analysis = new AiAnalysis
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                ImageUrl = imageUrl,
                OverallScore = overallScore,
                SkinAge = InferSkinAge(profile?.Age, overallScore),
                RecoveryCapacity = ClampScore(100 - ai.DrynessEquivalent()),
                UvDamage = ClampScore((ai.PigmentationScore + ai.RednessScore) / 2),
                AgingRisk = ClampScore((100 - overallScore) + ai.PigmentationScore / 3),
                IssuesDetected = JsonSerializer.Serialize(new
                {
                    acne = ai.AcneScore,
                    oiliness = ai.OilinessScore,
                    redness = ai.RednessScore,
                    pigmentation = ai.PigmentationScore,
                    concerns = ai.Concerns
                }),
                RootCauses = JsonSerializer.Serialize(new
                {
                    skinType = ai.SkinType,
                    concerns = ai.Concerns
                }),
                AiModel = "openai-vision",
                RawResponse = ai.RawAiResponse,
                Status = "completed",
                CreatedAt = DateTime.UtcNow,
                AnalysisIssues = BuildIssues(ai),
                Recommendations = BuildRecommendations(userId, ai)
            };

            return analysis;
        }
        catch
        {
            var fallback = _aiAnalysisService.Analyze(storedFileName);
            return new AiAnalysis
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                ImageUrl = imageUrl,
                OverallScore = fallback.OverallScore,
                SkinAge = fallback.SkinAge,
                RecoveryCapacity = fallback.RecoveryCapacity,
                UvDamage = fallback.UvDamage,
                AgingRisk = fallback.AgingRisk,
                IssuesDetected = fallback.IssuesDetectedJson,
                RootCauses = JsonSerializer.Serialize(new { skinType = fallback.SuggestedSkinType, notes = fallback.RootCausesJson }),
                AiModel = fallback.AiModel,
                RawResponse = fallback.RawResponseJson,
                Status = "completed",
                CreatedAt = DateTime.UtcNow
            };
        }
    }

    private async Task<UserRegimen?> BuildRegimenFromAnalysisAsync(
        Guid userId,
        UserProfile? profile,
        AiAnalysis analysis,
        IReadOnlyCollection<Product> products,
        CancellationToken cancellationToken)
    {
        try
        {
            var payload = UserProfilePayloadHelper.Parse(profile?.SkinConcerns);
            var routine = await _skinService.BuildRoutineAsync(new SkinRoutineRequestDto
            {
                SkinType = profile?.SkinType ?? "combination",
                Concerns = payload.Concerns,
                Budget = profile?.MonthlyBudget?.ToString("0") ?? "medium"
            }, cancellationToken);

            var regimen = new UserRegimen
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                AnalysisId = analysis.Id,
                Name = "AI generated routine",
                StartDate = DateOnly.FromDateTime(DateTime.UtcNow),
                EndDate = DateOnly.FromDateTime(DateTime.UtcNow.AddDays(30)),
                IsActive = true,
                IsCustom = false,
                Source = "ai"
            };

            regimen.Items = [
                ..BuildRoutineItems(regimen.Id, "Morning", routine.Routine.Morning, products),
                ..BuildRoutineItems(regimen.Id, "Evening", routine.Routine.Evening, products)
            ];

            return regimen.Items.Count == 0 ? null : regimen;
        }
        catch
        {
            return null;
        }
    }

    private static List<AiAnalysisIssue> BuildIssues(SkinAnalyzeResponseDto ai)
    {
        var issues = new List<AiAnalysisIssue>();

        void AddIssue(string issueType, int severity, string description)
        {
            if (severity <= 0)
            {
                return;
            }

            issues.Add(new AiAnalysisIssue
            {
                Id = Guid.NewGuid(),
                IssueType = issueType,
                SeverityScore = ClampScore(severity),
                ConfidenceScore = 80,
                Description = description
            });
        }

        AddIssue("Acne", ai.AcneScore, "Monitor breakouts and keep exfoliation gentle.");
        AddIssue("Oiliness", ai.OilinessScore, "Balance cleansing without stripping the skin barrier.");
        AddIssue("Redness", ai.RednessScore, "Reduce irritation triggers and prioritize soothing ingredients.");
        AddIssue("Pigmentation", ai.PigmentationScore, "Support tone-evening care with sunscreen consistency.");

        foreach (var concern in ai.Concerns.Where(x => !string.IsNullOrWhiteSpace(x)).Distinct(StringComparer.OrdinalIgnoreCase))
        {
            if (issues.Any(x => x.IssueType.Equals(concern, StringComparison.OrdinalIgnoreCase)))
            {
                continue;
            }

            issues.Add(new AiAnalysisIssue
            {
                Id = Guid.NewGuid(),
                IssueType = concern,
                SeverityScore = 65,
                ConfidenceScore = 75,
                Description = $"AI flagged {concern.ToLowerInvariant()} as an area to watch."
            });
        }

        return issues;
    }

    private static List<AiRecommendation> BuildRecommendations(Guid userId, SkinAnalyzeResponseDto ai)
    {
        var items = new List<string>
        {
            "Use sunscreen every morning to limit UV-related worsening.",
            ai.RednessScore >= 60 ? "Keep the routine soothing and avoid over-exfoliating." : "Maintain a balanced barrier-supporting routine.",
            ai.AcneScore >= 60 ? "Introduce acne treatments gradually and avoid stacking too many strong actives." : "Keep hydration steady to maintain barrier balance."
        };

        return items
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Select((content, index) => new AiRecommendation
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                RecommendationType = index == 0 ? "routine" : "lifestyle",
                Title = $"Recommendation {index + 1}",
                Content = content,
                Priority = index + 1
            })
            .ToList();
    }

    private static IEnumerable<RegimenItem> BuildRoutineItems(
        Guid regimenId,
        string routineTime,
        IEnumerable<RoutineStepDto> steps,
        IReadOnlyCollection<Product> products)
    {
        foreach (var step in steps.OrderBy(x => x.Step))
        {
            var product = MatchProduct(step, products);
            if (product is null)
            {
                continue;
            }

            yield return new RegimenItem
            {
                Id = Guid.NewGuid(),
                RegimenId = regimenId,
                ProductId = product.Id,
                Product = product,
                RoutineTime = routineTime,
                StepOrder = step.Step,
                Instruction = step.Instructions,
                Frequency = "Daily"
            };
        }
    }

    private static Product? MatchProduct(RoutineStepDto step, IReadOnlyCollection<Product> products)
    {
        var active = products.Where(x => x.Status.Equals("active", StringComparison.OrdinalIgnoreCase)).ToList();
        var recommendation = step.ProductRecommendation.Trim();

        return active.FirstOrDefault(x => recommendation.Contains(x.Name, StringComparison.OrdinalIgnoreCase))
            ?? active.FirstOrDefault(x => x.Category.Equals(step.Category, StringComparison.OrdinalIgnoreCase))
            ?? active.FirstOrDefault();
    }

    private static int CalculateOverallScore(SkinAnalyzeResponseDto ai)
    {
        var penalty = (ai.AcneScore + ai.OilinessScore + ai.RednessScore + ai.PigmentationScore) / 4;
        return ClampScore(100 - penalty);
    }

    private static int ClampScore(int value) => Math.Max(0, Math.Min(100, value));

    private static int? InferSkinAge(int? profileAge, int overallScore)
    {
        return profileAge.HasValue ? Math.Max(16, profileAge.Value + (100 - overallScore) / 10) : null;
    }
}

internal static class AnalysisSkinResponseExtensions
{
    public static int DrynessEquivalent(this SkinAnalyzeResponseDto response)
    {
        return Clamp(100 - response.OilinessScore);
    }

    private static int Clamp(int value) => Math.Max(0, Math.Min(100, value));
}
