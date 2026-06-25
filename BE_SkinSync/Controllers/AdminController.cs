using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SkinSync.Base;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Mappers;
using SkinSync.Models.Dtos;
using SkinSync.Models.Dtos.Admin;
using SkinSync.Models.Dtos.Progress;
using SkinSync.Models.Dtos.Products;
using SkinSync.Models.Entities;
using SkinSync.Models.Dtos.Subscriptions;
using SkinSync.Models.Enums;
using SkinSync.Repositories;
using SkinSync.Services;
using SkinSync.Services.AIPlatform;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/admin")]
[Authorize(Roles = "admin")]
public class AdminController : ControllerBase
{
    private readonly AppDbContext _dbContext;
    private readonly IUserRepository _userRepository;
    private readonly IProductRepository _productRepository;
    private readonly ISubscriptionPlanService _subscriptionPlanService;
    private readonly IProductImportService _productImportService;
    private readonly ProductImportOptions _productImportOptions;
    private readonly IImpersonationService _impersonationService;
    private readonly ILogger<AdminController> _logger;

    public AdminController(
        AppDbContext dbContext,
        IUserRepository userRepository,
        IProductRepository productRepository,
        ISubscriptionPlanService subscriptionPlanService,
        IProductImportService productImportService,
        IOptions<ProductImportOptions> productImportOptions,
        IImpersonationService impersonationService,
        ILogger<AdminController> logger)
    {
        _dbContext = dbContext;
        _userRepository = userRepository;
        _productRepository = productRepository;
        _subscriptionPlanService = subscriptionPlanService;
        _productImportService = productImportService;
        _productImportOptions = productImportOptions.Value;
        _impersonationService = impersonationService;
        _logger = logger;
    }

    [HttpGet("dashboard")]
    public async Task<IActionResult> Dashboard(CancellationToken cancellationToken)
    {
        var totalUsers = await _dbContext.Users.CountAsync(cancellationToken);
        var activeUsers = await _dbContext.Users.CountAsync(x => x.Status == "active", cancellationToken);
        var totalAnalyses = await _dbContext.SkinProgressAnalyses.CountAsync(cancellationToken);

        var skinTypes = await _dbContext.UserProfiles
            .AsNoTracking()
            .GroupBy(x => x.SkinType)
            .Select(x => new { SkinType = x.Key, Count = x.Count() })
            .ToListAsync(cancellationToken);

        return Ok(new AdminDashboardResponseDto
        {
            TotalUsers = totalUsers,
            ActiveUsers = activeUsers,
            TotalAnalyses = totalAnalyses,
            SkinTypeDistribution = skinTypes.ToDictionary(x => x.SkinType ?? "unknown", x => x.Count)
        });
    }

    [HttpGet("users")]
    public async Task<ResponseEntity<PagingResult<AdminUserItemDto>>> Users([FromQuery] AdminUsersQueryDto query, CancellationToken cancellationToken)
    {
        var users = await _userRepository.GetPagedAsync(query, cancellationToken);
        var response = new PagingResult<AdminUserItemDto>
        {
            Items = users.Items.Select(x => x.ToAdminUserDto()).ToList(),
            Search = users.Search,
            SortBy = users.SortBy,
            SortDirection = users.SortDirection,
            Filters = users.Filters,
            PageIndex = users.PageIndex,
            PageSize = users.PageSize,
            TotalRow = users.TotalRow
        };

        return ResponseEntity<PagingResult<AdminUserItemDto>>.Ok(response, "Fetched users successfully.");
    }

    [HttpGet("users/{id:guid}")]
    public async Task<ResponseEntity<AdminUserDetailResponseDto>> GetUserDetail(Guid id, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users
            .AsNoTracking()
            .Include(x => x.Profile)
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);

        if (user is null)
        {
            return ResponseEntity<AdminUserDetailResponseDto>.Fail("User not found.", 404);
        }

        var latestAnalysis = await _dbContext.SkinProgressAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == id && x.Status == "completed")
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new Models.Dtos.Analysis.AnalysisDetailResponseDto
            {
                Id = x.Id,
                UserId = x.UserId,
                ImageUrl = x.Photo.ImageUrl,
                SkinType = x.SkinTypeEstimate,
                OverallScore = x.OverallScore,
                ConfidenceScore = x.ConfidenceScore.HasValue ? (int)Math.Round(x.ConfidenceScore.Value * 100) : 0,
                Overview = x.AiSummary,
                RootCauses = x.AiSummary,
                AiModel = x.AiModel,
                Status = x.Status,
                GeneratedAt = x.CompletedAt ?? x.CreatedAt,
                CreatedAt = x.CreatedAt,
                Recommendations = Array.Empty<Models.Dtos.Analysis.AnalysisRecommendationItemDto>(),
                Issues = Array.Empty<Models.Dtos.Analysis.AnalysisIssueItemDto>(),
                Warnings = Array.Empty<string>()
            })
            .FirstOrDefaultAsync(cancellationToken);

        var regimen = await _dbContext.UserRegimens
            .AsNoTracking()
            .Where(x => x.UserId == id && x.IsActive)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new CurrentRegimenResponseDto
            {
                RegimenId = x.Id,
                Name = x.Name,
                StartDate = DateOnly.FromDateTime(x.CreatedAt),
                EndDate = null,
                IsCustom = x.IsCustom,
                TotalEstimatedCost = 0,
                Morning = x.Items.Where(item => item.RoutineTime == "morning").OrderBy(item => item.StepOrder).Select(item => new RegimenProductDto
                {
                    StepId = item.Id,
                    ProductId = item.ProductId,
                    Name = item.Product.Name,
                    Brand = item.Product.Brand,
                    Category = item.Product.Category,
                    Description = item.Product.Description,
                    Ingredient = item.Product.Ingredient,
                    UsageGuide = item.Product.UsageGuide,
                    Instruction = item.Instruction,
                    Purpose = item.Product.Description,
                    Frequency = item.Frequency,
                    Caution = null,
                    Price = item.Product.Price,
                    ImageUrl = item.Product.ImageUrl,
                    StepOrder = item.StepOrder
                }).ToList(),
                Evening = x.Items.Where(item => item.RoutineTime == "evening").OrderBy(item => item.StepOrder).Select(item => new RegimenProductDto
                {
                    StepId = item.Id,
                    ProductId = item.ProductId,
                    Name = item.Product.Name,
                    Brand = item.Product.Brand,
                    Category = item.Product.Category,
                    Description = item.Product.Description,
                    Ingredient = item.Product.Ingredient,
                    UsageGuide = item.Product.UsageGuide,
                    Instruction = item.Instruction,
                    Purpose = item.Product.Description,
                    Frequency = item.Frequency,
                    Caution = null,
                    Price = item.Product.Price,
                    ImageUrl = item.Product.ImageUrl,
                    StepOrder = item.StepOrder
                }).ToList()
            })
            .FirstOrDefaultAsync(cancellationToken);

        var progressOverview = await BuildProgressOverviewAsync(id, cancellationToken);
        var subscription = await _subscriptionPlanService.GetCurrentAsync(id, cancellationToken);
        var activities = await BuildRecentActivitiesAsync(id, cancellationToken);

        return ResponseEntity<AdminUserDetailResponseDto>.Ok(new AdminUserDetailResponseDto
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            Role = user.Role,
            Status = user.Status,
            PlanType = user.PlanType,
            AvatarUrl = user.AvatarUrl,
            CreatedAt = user.CreatedAt,
            Profile = user.Profile is null ? null : new AdminUserProfileSnapshotDto
            {
                SkinType = user.Profile.SkinType,
                SkinConcerns = JsonListHelper.ParseStringList(user.Profile.SkinConcerns),
                MonthlyBudget = user.Profile.MonthlyBudget,
                Age = user.Profile.Age,
                BirthYear = user.Profile.BirthYear,
                Gender = user.Profile.Gender,
                Allergies = JsonListHelper.ParseStringList(user.Profile.Allergies),
                SensitiveIngredients = JsonListHelper.ParseStringList(user.Profile.SensitiveIngredients),
                SkinGoals = JsonListHelper.ParseStringList(user.Profile.SkinGoals),
                RoutinePreference = user.Profile.RoutinePreference,
                UpdatedAt = user.Profile.UpdatedAt
            },
            Subscription = subscription,
            ProgressOverview = progressOverview,
            CurrentRegimen = regimen,
            LatestAnalysis = latestAnalysis,
            RecentActivities = activities
        }, "Fetched user detail successfully.");
    }

    [HttpGet("products")]
    public async Task<ResponseEntity<PagedItemsDto<ProductResponseDto>>> GetProducts([FromQuery] AdminProductsQueryDto query, CancellationToken cancellationToken)
    {
        var products = await _productRepository.GetPagedAsync(query, cancellationToken);
        var response = new PagedItemsDto<ProductResponseDto>
        {
            Items = products.Items.Select(x => x.ToDto()).ToList(),
            Page = products.PageIndex,
            PageSize = products.PageSize,
            TotalItems = products.TotalRow,
            TotalPages = products.TotalPages
        };

        return ResponseEntity<PagedItemsDto<ProductResponseDto>>.Ok(response, "Fetched products successfully.");
    }

    [HttpGet("products/summary")]
    public async Task<ResponseEntity<AdminProductsSummaryDto>> GetProductSummary(CancellationToken cancellationToken)
    {
        var summary = await _productRepository.GetSummaryAsync(cancellationToken);
        return ResponseEntity<AdminProductsSummaryDto>.Ok(summary, "Fetched product summary successfully.");
    }

    [HttpGet("products/{id:guid}")]
    public async Task<ResponseEntity<ProductResponseDto>> GetProductById(Guid id, CancellationToken cancellationToken)
    {
        var product = await _productRepository.GetDetailByIdAsync(id, cancellationToken);
        return product is null
            ? ResponseEntity<ProductResponseDto>.Fail("Product not found.", 404)
            : ResponseEntity<ProductResponseDto>.Ok(product.ToDto(), "Fetched product successfully.");
    }

    [HttpPost("products")]
    public async Task<ResponseEntity<ProductResponseDto>> CreateProduct([FromBody] ProductUpsertRequestDto request, CancellationToken cancellationToken)
    {
        var validationMessage = ValidateProductRequest(request);
        if (validationMessage is not null)
        {
            return ResponseEntity<ProductResponseDto>.Fail(validationMessage, 400);
        }

        var now = DateTime.UtcNow;
        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Brand = request.Brand.Trim(),
            Category = ProductCatalogConstants.NormalizeCategory(request.Category),
            Description = request.Description?.Trim(),
            Ingredient = ProductMapper.SerializeIngredients(request.Ingredients),
            KeyIngredients = ProductMapper.SerializeKeyIngredients(request.Ingredients),
            TargetConcerns = ProductMapper.SerializeStringList(request.SkinConcerns),
            UsageGuide = request.HowToUse?.Trim(),
            UsageTime = string.IsNullOrWhiteSpace(request.UsageTime) ? null : ProductCatalogConstants.NormalizeUsageTime(request.UsageTime),
            Price = request.Price,
            Currency = string.IsNullOrWhiteSpace(request.Currency) ? string.Empty : request.Currency.Trim().ToUpperInvariant(),
            SuitableSkinTypes = ProductMapper.SerializeStringList(request.SkinTypes),
            ImageUrl = request.ImageUrl?.Trim(),
            Status = ProductCatalogConstants.NormalizeStatusForActiveFlag("active", request.IsActive),
            IsVerified = request.IsVerified,
            IsActive = request.IsActive,
            Source = string.IsNullOrWhiteSpace(request.Source) ? string.Empty : request.Source.Trim(),
            SourceUrl = string.IsNullOrWhiteSpace(request.SourceUrl) ? null : request.SourceUrl.Trim(),
            CreatedAt = now,
            UpdatedAt = now
        };

        await _productRepository.AddAsync(product, cancellationToken);
        return ResponseEntity<ProductResponseDto>.Ok(product.ToDto(), "Created product successfully.");
    }

    [HttpPut("products/{id:guid}")]
    public async Task<ResponseEntity<ProductResponseDto>> UpdateProduct(Guid id, [FromBody] ProductUpsertRequestDto request, CancellationToken cancellationToken)
    {
        var validationMessage = ValidateProductRequest(request);
        if (validationMessage is not null)
        {
            return ResponseEntity<ProductResponseDto>.Fail(validationMessage, 400);
        }

        var product = await _productRepository.GetByIdAsync(id, cancellationToken);
        if (product is null)
        {
            return ResponseEntity<ProductResponseDto>.Fail("Product not found.", 404);
        }

        product.Name = request.Name.Trim();
        product.Brand = request.Brand.Trim();
        product.Category = ProductCatalogConstants.NormalizeCategory(request.Category);
        product.Description = request.Description?.Trim();
        product.Ingredient = ProductMapper.SerializeIngredients(request.Ingredients);
        product.KeyIngredients = ProductMapper.SerializeKeyIngredients(request.Ingredients);
        product.TargetConcerns = ProductMapper.SerializeStringList(request.SkinConcerns);
        product.UsageGuide = request.HowToUse?.Trim();
        product.UsageTime = string.IsNullOrWhiteSpace(request.UsageTime) ? null : ProductCatalogConstants.NormalizeUsageTime(request.UsageTime);
        product.Price = request.Price;
        product.Currency = string.IsNullOrWhiteSpace(request.Currency) ? string.Empty : request.Currency.Trim().ToUpperInvariant();
        product.SuitableSkinTypes = ProductMapper.SerializeStringList(request.SkinTypes);
        product.ImageUrl = request.ImageUrl?.Trim();
        product.IsVerified = request.IsVerified;
        product.IsActive = request.IsActive;
        product.Source = string.IsNullOrWhiteSpace(request.Source) ? string.Empty : request.Source.Trim();
        product.SourceUrl = string.IsNullOrWhiteSpace(request.SourceUrl) ? null : request.SourceUrl.Trim();
        product.Status = ProductCatalogConstants.NormalizeStatusForActiveFlag(product.Status, request.IsActive);
        product.UpdatedAt = DateTime.UtcNow;

        await _productRepository.UpdateAsync(product, cancellationToken);
        return ResponseEntity<ProductResponseDto>.Ok(product.ToDto(), "Updated product successfully.");
    }

    [HttpPatch("products/{id:guid}/toggle-active")]
    public async Task<ResponseEntity<ProductResponseDto>> ToggleProductActive(Guid id, CancellationToken cancellationToken)
    {
        var product = await _productRepository.GetByIdAsync(id, cancellationToken);
        if (product is null)
        {
            return ResponseEntity<ProductResponseDto>.Fail("Product not found.", 404);
        }

        await _productRepository.SetActiveAsync(product, !product.IsActive, cancellationToken);
        return ResponseEntity<ProductResponseDto>.Ok(product.ToDto(), "Toggled product active state successfully.");
    }

    [HttpDelete("products/{id:guid}")]
    public async Task<ResponseEntity<object>> DeleteProduct(Guid id, CancellationToken cancellationToken)
    {
        var product = await _productRepository.GetByIdAsync(id, cancellationToken);
        if (product is null)
        {
            return ResponseEntity<object>.Fail("Product not found.", 404);
        }

        await _productRepository.SetActiveAsync(product, false, cancellationToken);
        return ResponseEntity<object>.Ok(null, "Archived product successfully.");
    }

    [HttpPost("products/import-csv")]
    public async Task<ResponseEntity<ProductImportResult>> ImportProductsFromCsv(CancellationToken cancellationToken)
    {
        var result = await _productImportService.ImportFromCsvAsync(_productImportOptions.ProductCsvPath, cancellationToken);
        return ResponseEntity<ProductImportResult>.Ok(result, $"Imported products from '{_productImportOptions.ProductCsvPath}'.");
    }

    [HttpPatch("users/{id:guid}/status")]
    public async Task<ResponseEntity<AdminUserItemDto>> UpdateUserStatus(Guid id, [FromBody] UpdateUserStatusRequestDto request, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return ResponseEntity<AdminUserItemDto>.Fail("User not found.", 404);
        }

        if (!UserStatusExtensions.TryParseFromRequest(request.Status, out var nextStatus))
        {
            return ResponseEntity<AdminUserItemDto>.Fail("Status must be one of: active, inactive, banned.", 400);
        }

        user.Status = nextStatus.ToDbValue();
        await _userRepository.UpdateAsync(user, cancellationToken);
        return ResponseEntity<AdminUserItemDto>.Ok(user.ToAdminUserDto(), "Updated user status successfully.");
    }

    [HttpPatch("users/{id:guid}/role")]
    public async Task<IActionResult> UpdateUserRole(Guid id, [FromBody] UpdateUserRoleRequestDto request, CancellationToken cancellationToken)
    {
        var user = await _userRepository.GetByIdAsync(id, cancellationToken);
        if (user is null)
        {
            return NotFound("User not found.");
        }

        var role = request.Role.Trim().ToLowerInvariant();
        if (role is not ("user" or "admin"))
        {
            return BadRequest("Role must be either 'user' or 'admin'.");
        }

        user.Role = role;
        await _userRepository.UpdateAsync(user, cancellationToken);
        return Ok(user.ToAdminUserDto());
    }

    [HttpPatch("users/{id:guid}/plan")]
    public async Task<ResponseEntity<AdminUserItemDto>> UpdateUserPlan(Guid id, [FromBody] UpdateUserPlanRequestDto request, CancellationToken cancellationToken)
    {
        try
        {
            await _subscriptionPlanService.ChangeUserPlanAsync(id, request.PlanCode, cancellationToken);
            var user = await _userRepository.GetByIdAsync(id, cancellationToken);
            return user is null
                ? ResponseEntity<AdminUserItemDto>.Fail("User not found.", 404)
                : ResponseEntity<AdminUserItemDto>.Ok(user.ToAdminUserDto(), "User plan updated successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<AdminUserItemDto>.Fail(ex.Message, ex.StatusCode);
        }
    }

    [HttpGet("ai-logs")]
    public async Task<ResponseEntity<AdminAiLogsResponseDto>> GetAiLogs([FromQuery] int take = 50, CancellationToken cancellationToken = default)
    {
        take = Math.Clamp(take, 1, 200);
        var logs = await _dbContext.AiUsageLogs
            .AsNoTracking()
            .Include(x => x.User)
            .OrderByDescending(x => x.UsedAt)
            .Take(take)
            .ToListAsync(cancellationToken);

        return ResponseEntity<AdminAiLogsResponseDto>.Ok(new AdminAiLogsResponseDto
        {
            TotalLogs = await _dbContext.AiUsageLogs.CountAsync(cancellationToken),
            DistinctUsers = await _dbContext.AiUsageLogs.Select(x => x.UserId).Distinct().CountAsync(cancellationToken),
            Items = logs.Select(x => new AdminAiUsageLogItemDto
            {
                Id = x.Id,
                UserId = x.UserId,
                UserEmail = x.User.Email,
                UserName = x.User.FullName,
                FeatureName = x.FeatureName,
                Model = x.Model,
                InputTokens = x.InputTokens,
                OutputTokens = x.OutputTokens,
                CostEstimate = x.CostEstimate,
                UsedAt = x.UsedAt
            }).ToList()
        }, "Fetched AI logs successfully.");
    }

    [HttpGet("subscriptions")]
    public async Task<ResponseEntity<AdminSubscriptionsResponseDto>> GetSubscriptions([FromQuery] int take = 100, CancellationToken cancellationToken = default)
    {
        take = Math.Clamp(take, 1, 250);
        var subscriptions = await _dbContext.UserSubscriptions
            .AsNoTracking()
            .Include(x => x.User)
            .Include(x => x.Plan)
            .OrderByDescending(x => x.CreatedAt)
            .Take(take)
            .ToListAsync(cancellationToken);

        return ResponseEntity<AdminSubscriptionsResponseDto>.Ok(new AdminSubscriptionsResponseDto
        {
            TotalSubscriptions = await _dbContext.UserSubscriptions.CountAsync(cancellationToken),
            ActiveSubscriptions = await _dbContext.UserSubscriptions.CountAsync(x => x.Status == "active", cancellationToken),
            Items = subscriptions.Select(x => new AdminSubscriptionItemDto
            {
                SubscriptionId = x.Id,
                UserId = x.UserId,
                UserEmail = x.User.Email,
                UserName = x.User.FullName,
                PlanCode = x.Plan.Code,
                PlanName = x.Plan.Name,
                Status = x.Status,
                PricePaid = x.PricePaid,
                Currency = x.Currency,
                BillingPeriod = x.BillingPeriod,
                StartedAt = x.StartedAt,
                EndsAt = x.EndsAt,
                CancelledAt = x.CancelledAt
            }).ToList()
        }, "Fetched subscriptions successfully.");
    }

    [HttpPost("impersonation/start")]
    public async Task<ResponseEntity<ImpersonationSessionResponseDto>> StartImpersonation([FromBody] StartImpersonationRequestDto request, CancellationToken cancellationToken)
    {
        if (!HttpContext.TryGetActorUserId(out var adminId))
        {
            return ResponseEntity<ImpersonationSessionResponseDto>.Fail("Missing authenticated admin.", 401);
        }

        var adminUser = await _dbContext.Users.FirstOrDefaultAsync(x => x.Id == adminId, cancellationToken);
        if (adminUser is null || !string.Equals(adminUser.Role, "admin", StringComparison.OrdinalIgnoreCase))
        {
            return ResponseEntity<ImpersonationSessionResponseDto>.Fail("Admin access is required.", 403);
        }

        var targetUser = await _dbContext.Users.FirstOrDefaultAsync(x => x.Id == request.UserId, cancellationToken);
        if (targetUser is null)
        {
            return ResponseEntity<ImpersonationSessionResponseDto>.Fail("Target user not found.", 404);
        }

        if (string.Equals(targetUser.Role, "admin", StringComparison.OrdinalIgnoreCase))
        {
            return ResponseEntity<ImpersonationSessionResponseDto>.Fail("Cannot impersonate another admin.", 400);
        }

        var session = _impersonationService.CreateSession(adminUser, targetUser);
        _logger.LogInformation("Impersonation started by admin {AdminId} for user {UserId}", adminId, targetUser.Id);
        return ResponseEntity<ImpersonationSessionResponseDto>.Ok(session, "Impersonation session started successfully.");
    }

    [HttpPost("impersonation/end")]
    public ResponseEntity<object> EndImpersonation()
    {
        if (HttpContext.TryGetActorUserId(out var adminId) &&
            HttpContext.TryGetImpersonationContext(out var context) &&
            context is not null)
        {
            _logger.LogInformation("Impersonation ended by admin {AdminId} for user {UserId}", adminId, context.ImpersonatedUserId);
        }

        return ResponseEntity<object>.Ok(null, "Impersonation session ended successfully.");
    }

    private static string? ValidateProductRequest(ProductUpsertRequestDto request)
    {
        if (string.IsNullOrWhiteSpace(request.Name) ||
            string.IsNullOrWhiteSpace(request.Brand) ||
            string.IsNullOrWhiteSpace(request.Category) ||
            string.IsNullOrWhiteSpace(request.Ingredients))
        {
            return "Name, brand, category, and ingredients are required.";
        }

        if (!ProductCatalogConstants.IsAllowedCategory(request.Category))
        {
            return "Category must be one of the supported catalog categories.";
        }

        if (!ProductCatalogConstants.IsAllowedUsageTime(request.UsageTime))
        {
            return "UsageTime must be Morning, Night, or Both.";
        }

        if (!string.IsNullOrWhiteSpace(request.ImageUrl) && !ProductCatalogConstants.IsValidHttpUrl(request.ImageUrl))
        {
            return "ImageUrl must be a valid http or https URL.";
        }

        if (!string.IsNullOrWhiteSpace(request.SourceUrl) && !ProductCatalogConstants.IsValidHttpUrl(request.SourceUrl))
        {
            return "SourceUrl must be a valid http or https URL.";
        }

        if (request.Price.HasValue && request.Price.Value < 0)
        {
            return "Price must be greater than or equal to 0.";
        }

        return null;
    }

    private async Task<ProgressOverviewResponseDto?> BuildProgressOverviewAsync(Guid userId, CancellationToken cancellationToken)
    {
        var latestAnalyses = await _dbContext.SkinProgressAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.Status == "completed")
            .OrderByDescending(x => x.CreatedAt)
            .Take(2)
            .ToListAsync(cancellationToken);

        var currentScore = latestAnalyses.FirstOrDefault()?.OverallScore;
        var startScore = latestAnalyses.Count > 1 ? latestAnalyses.Last().OverallScore : currentScore;
        var completedDays = await _dbContext.DailyLogs.CountAsync(x => x.UserId == userId && (x.MorningCompleted || x.EveningCompleted), cancellationToken);

        return new ProgressOverviewResponseDto
        {
            StartScore = startScore,
            CurrentScore = currentScore,
            ImprovementPercent = startScore.HasValue && currentScore.HasValue && startScore.Value > 0
                ? Math.Round(((decimal)(currentScore.Value - startScore.Value) / startScore.Value) * 100, 2)
                : 0,
            CompletedDaysLast28 = completedDays,
            CompletionRateLast28 = completedDays > 0 ? Math.Round((decimal)completedDays / 28 * 100, 2) : 0,
            CurrentStreak = 0,
            DailyTip = null,
            ProgressInsight = latestAnalyses.FirstOrDefault()?.AiSummary
        };
    }

    private async Task<IReadOnlyCollection<AdminUserActivityItemDto>> BuildRecentActivitiesAsync(Guid userId, CancellationToken cancellationToken)
    {
        var items = new List<AdminUserActivityItemDto>();

        var analysis = await _dbContext.SkinProgressAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new AdminUserActivityItemDto
            {
                Type = "analysis",
                Title = "Completed skin analysis",
                Description = x.AiSummary,
                OccurredAt = x.CreatedAt
            })
            .FirstOrDefaultAsync(cancellationToken);
        if (analysis is not null) items.Add(analysis);

        var diary = await _dbContext.DailyLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new AdminUserActivityItemDto
            {
                Type = "checkup",
                Title = "Submitted daily check-up",
                Description = x.SkinFeeling,
                OccurredAt = x.CreatedAt
            })
            .FirstOrDefaultAsync(cancellationToken);
        if (diary is not null) items.Add(diary);

        var chat = await _dbContext.AiChatMessages
            .AsNoTracking()
            .Where(x => x.Conversation.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => new AdminUserActivityItemDto
            {
                Type = "chat",
                Title = "AI chat activity",
                Description = x.Content.Length > 120 ? x.Content.Substring(0, 120) : x.Content,
                OccurredAt = x.CreatedAt
            })
            .FirstOrDefaultAsync(cancellationToken);
        if (chat is not null) items.Add(chat);

        return items.OrderByDescending(x => x.OccurredAt).Take(10).ToList();
    }
}
