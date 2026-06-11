using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SkinSync.Base;
using SkinSync.Data;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.Admin;
using SkinSync.Models.Dtos.Products;
using SkinSync.Models.Entities;
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
    private readonly IAnalysisRepository _analysisRepository;
    private readonly IProductRepository _productRepository;
    private readonly ISubscriptionService _subscriptionService;

    public AdminController(
        AppDbContext dbContext,
        IUserRepository userRepository,
        IAnalysisRepository analysisRepository,
        IProductRepository productRepository,
        ISubscriptionService subscriptionService)
    {
        _dbContext = dbContext;
        _userRepository = userRepository;
        _analysisRepository = analysisRepository;
        _productRepository = productRepository;
        _subscriptionService = subscriptionService;
    }

    [HttpGet("dashboard")]
    public async Task<IActionResult> Dashboard(CancellationToken cancellationToken)
    {
        var totalUsers = await _dbContext.Users.CountAsync(cancellationToken);
        var activeUsers = await _dbContext.Users.CountAsync(x => x.Status == "active", cancellationToken);
        var totalAnalyses = await _analysisRepository.CountAsync(cancellationToken);

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
    public async Task<ResponseEntity<PagingResult<ProductResponseDto>>> GetProducts([FromQuery] AdminProductsQueryDto query, CancellationToken cancellationToken)
    {
        var products = await _productRepository.GetPagedAsync(query, cancellationToken);
        var response = new PagingResult<ProductResponseDto>
        {
            Items = products.Items.Select(x => x.ToDto()).ToList(),
            Search = products.Search,
            SortBy = products.SortBy,
            SortDirection = products.SortDirection,
            Filters = products.Filters,
            PageIndex = products.PageIndex,
            PageSize = products.PageSize,
            TotalRow = products.TotalRow
        };

        return ResponseEntity<PagingResult<ProductResponseDto>>.Ok(response, "Fetched products successfully.");
    }

    [HttpGet("products/{id:guid}")]
    public async Task<IActionResult> GetProductById(Guid id, CancellationToken cancellationToken)
    {
        var product = await _productRepository.GetByIdAsync(id, cancellationToken);
        return product is null ? NotFound("Product not found.") : Ok(product.ToDto());
    }

    [HttpPost("products")]
    public async Task<IActionResult> CreateProduct([FromBody] ProductUpsertRequestDto request, CancellationToken cancellationToken)
    {
        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Brand = request.Brand.Trim(),
            Category = request.Category.Trim(),
            Description = request.Description?.Trim(),
            Ingredient = request.Ingredient?.Trim(),
            UsageGuide = request.UsageGuide?.Trim(),
            Price = request.Price,
            SuitableSkinTypes = request.SuitableSkinTypes,
            ImageUrl = request.ImageUrl,
            Rating = request.Rating,
            Status = request.Status,
            CreatedAt = DateTime.UtcNow
        };

        await _productRepository.AddAsync(product, cancellationToken);
        return Ok(product.ToDto());
    }

    [HttpPut("products/{id:guid}")]
    public async Task<IActionResult> UpdateProduct(Guid id, [FromBody] ProductUpsertRequestDto request, CancellationToken cancellationToken)
    {
        var product = await _productRepository.GetByIdAsync(id, cancellationToken);
        if (product is null)
        {
            return NotFound("Product not found.");
        }

        product.Name = request.Name.Trim();
        product.Brand = request.Brand.Trim();
        product.Category = request.Category.Trim();
        product.Description = request.Description?.Trim();
        product.Ingredient = request.Ingredient?.Trim();
        product.UsageGuide = request.UsageGuide?.Trim();
        product.Price = request.Price;
        product.SuitableSkinTypes = request.SuitableSkinTypes;
        product.ImageUrl = request.ImageUrl;
        product.Rating = request.Rating;
        product.Status = request.Status;

        await _productRepository.UpdateAsync(product, cancellationToken);
        return Ok(product.ToDto());
    }

    [HttpDelete("products/{id:guid}")]
    public async Task<IActionResult> DeleteProduct(Guid id, CancellationToken cancellationToken)
    {
        var product = await _productRepository.GetByIdAsync(id, cancellationToken);
        if (product is null)
        {
            return NotFound("Product not found.");
        }

        await _productRepository.DeleteAsync(product, cancellationToken);
        return NoContent();
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
        return ResponseEntity<AdminUserItemDto>.Ok(user.ToAdminUserDto(), "Cáº­p nháº­t tráº¡ng thÃ¡i ngÆ°á»i dÃ¹ng thÃ nh cÃ´ng.");
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
            var user = await _subscriptionService.ChangeUserPlanAsync(id, request.PlanCode, cancellationToken);
            return ResponseEntity<AdminUserItemDto>.Ok(user.ToAdminUserDto(), "Updated user plan successfully.");
        }
        catch (AiFeatureException ex)
        {
            return ResponseEntity<AdminUserItemDto>.Fail(ex.Message, ex.StatusCode);
        }
    }
}
