using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SkinSync.Base;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.Admin;
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

    public AdminController(
        AppDbContext dbContext,
        IUserRepository userRepository,
        IProductRepository productRepository,
        ISubscriptionPlanService subscriptionPlanService,
        IProductImportService productImportService,
        IOptions<ProductImportOptions> productImportOptions)
    {
        _dbContext = dbContext;
        _userRepository = userRepository;
        _productRepository = productRepository;
        _subscriptionPlanService = subscriptionPlanService;
        _productImportService = productImportService;
        _productImportOptions = productImportOptions.Value;
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
}
