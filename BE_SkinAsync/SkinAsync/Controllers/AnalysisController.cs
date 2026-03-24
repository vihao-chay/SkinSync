using Microsoft.AspNetCore.Mvc;
using SkinAsync.Base;
using SkinAsync.Helpers;
using SkinAsync.Mappers;
using SkinAsync.Models.Dtos.Analysis;
using SkinAsync.Models.Dtos;
using SkinAsync.Models.Entities;
using SkinAsync.Repositories;
using SkinAsync.Services;

namespace SkinAsync.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AnalysisController : ControllerBase
{
    private readonly IUserRepository _userRepository;
    private readonly IAnalysisRepository _analysisRepository;
    private readonly IRegimenRepository _regimenRepository;
    private readonly IProductRepository _productRepository;
    private readonly IAiAnalysisService _aiAnalysisService;
    private readonly IRegimenBuilderService _regimenBuilderService;
    private readonly IWebHostEnvironment _environment;

    public AnalysisController(
        IUserRepository userRepository,
        IAnalysisRepository analysisRepository,
        IRegimenRepository regimenRepository,
        IProductRepository productRepository,
        IAiAnalysisService aiAnalysisService,
        IRegimenBuilderService regimenBuilderService,
        IWebHostEnvironment environment)
    {
        _userRepository = userRepository;
        _analysisRepository = analysisRepository;
        _regimenRepository = regimenRepository;
        _productRepository = productRepository;
        _aiAnalysisService = aiAnalysisService;
        _regimenBuilderService = regimenBuilderService;
        _environment = environment;
    }

    [HttpPost("scan")]
    [Consumes("multipart/form-data")]
    public async Task<IActionResult> Scan([FromHeader(Name = "Id")] Guid userId, [FromForm] AnalysisScanRequestDto request, CancellationToken cancellationToken)
    {
        if (userId == Guid.Empty)
        {
            return BadRequest("Missing Id header.");
        }

        if (request.Image is null || request.Image.Length == 0)
        {
            return BadRequest("Image file is required.");
        }

        var user = await _userRepository.GetByIdWithProfileAsync(userId, cancellationToken);

        if (user is null)
        {
            return NotFound("User not found.");
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
        var aiResult = _aiAnalysisService.Analyze(storedFileName);

        var analysis = new AiAnalysis
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            ImageUrl = imageUrl,
            OverallScore = aiResult.OverallScore,
            SkinAge = aiResult.SkinAge,
            RecoveryCapacity = aiResult.RecoveryCapacity,
            UvDamage = aiResult.UvDamage,
            AgingRisk = aiResult.AgingRisk,
            IssuesDetected = aiResult.IssuesDetectedJson,
            RootCauses = aiResult.RootCauses,
            CreatedAt = DateTime.UtcNow
        };

        var skinType = user.Profile?.SkinType ?? aiResult.SuggestedSkinType;
        var products = await _productRepository.GetAllAsync(cancellationToken);

        await _analysisRepository.AddAsync(analysis, cancellationToken);
        await _regimenRepository.DeactivateAllByUserIdAsync(userId, cancellationToken);

        var newRegimen = _regimenBuilderService.BuildRegimen(userId, analysis.Id, skinType, products);
        await _regimenRepository.AddAsync(newRegimen, cancellationToken);

        return Ok(new AnalysisScanResponseDto
        {
            Analysis = analysis.ToDetailDto(),
            RegimenId = newRegimen.Id,
            StartDate = newRegimen.StartDate,
            EndDate = newRegimen.EndDate,
            IsActive = newRegimen.IsActive,
            ItemCount = newRegimen.Items.Count
        });
    }

    [HttpGet("history")]
    public async Task<ResponseEntity<PagingResult<AnalysisHistoryItemDto>>> History(
        [FromHeader(Name = "Id")] Guid userId,
        [FromQuery] AnalysisHistoryQueryDto query,
        CancellationToken cancellationToken)
    {
        if (userId == Guid.Empty)
        {
            return ResponseEntity<PagingResult<AnalysisHistoryItemDto>>.Fail("Missing Id header.");
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

    [HttpGet("{id:guid}")]
    public async Task<IActionResult> GetById(Guid id, [FromHeader(Name = "Id")] Guid userId, CancellationToken cancellationToken)
    {
        if (userId == Guid.Empty)
        {
            return BadRequest("Missing Id header.");
        }

        var analysis = await _analysisRepository.GetByIdAsync(id, cancellationToken);
        if (analysis is null || analysis.UserId != userId)
        {
            return NotFound("Analysis not found.");
        }

        return Ok(analysis.ToDetailDto());
    }
}
