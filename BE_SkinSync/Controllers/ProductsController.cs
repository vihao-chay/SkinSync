using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinSync.Base;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.Products;
using SkinSync.Repositories;

namespace SkinSync.Controllers;

[ApiController]
[Route("api/products")]
[Authorize]
public class ProductsController : ControllerBase
{
    private readonly IProductRepository _productRepository;

    public ProductsController(IProductRepository productRepository)
    {
        _productRepository = productRepository;
    }

    [HttpGet]
    public async Task<ResponseEntity<IEnumerable<ProductResponseDto>>> GetProducts(
        [FromQuery] string? search,
        [FromQuery] string? category,
        [FromQuery] string? skinConcern,
        [FromQuery] string? usageTime,
        CancellationToken cancellationToken,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var products = await _productRepository.GetAllAsync(cancellationToken);
        var source = products
            .Where(x => x.IsActive)
            .AsEnumerable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var keyword = search.Trim();
            source = source.Where(x =>
                x.Name.Contains(keyword, StringComparison.OrdinalIgnoreCase) ||
                x.Brand.Contains(keyword, StringComparison.OrdinalIgnoreCase) ||
                x.Category.Contains(keyword, StringComparison.OrdinalIgnoreCase) ||
                (x.Ingredient?.Contains(keyword, StringComparison.OrdinalIgnoreCase) ?? false));
        }

        if (!string.IsNullOrWhiteSpace(category))
        {
            source = source.Where(x => x.Category.Equals(category.Trim(), StringComparison.OrdinalIgnoreCase));
        }

        if (!string.IsNullOrWhiteSpace(skinConcern))
        {
            source = source.Where(x => ProductMapper.ParseJsonArray(x.TargetConcerns)
                .Contains(skinConcern.Trim(), StringComparer.OrdinalIgnoreCase));
        }

        if (!string.IsNullOrWhiteSpace(usageTime))
        {
            source = source.Where(x => string.Equals(x.UsageTime, usageTime.Trim(), StringComparison.OrdinalIgnoreCase));
        }

        page = page < 1 ? 1 : page;
        pageSize = pageSize <= 0 ? 20 : Math.Min(pageSize, 100);
        return ResponseEntity<IEnumerable<ProductResponseDto>>.Ok(
            source.Skip((page - 1) * pageSize).Take(pageSize).Select(x => x.ToDto()).ToList(),
            "Fetched products successfully.");
    }

    [HttpGet("{id:guid}")]
    public async Task<ResponseEntity<ProductResponseDto>> GetProduct(Guid id, CancellationToken cancellationToken)
    {
        var product = await _productRepository.GetDetailByIdAsync(id, cancellationToken);
        if (product is null || !product.IsActive)
        {
            return ResponseEntity<ProductResponseDto>.Fail("Product not found.", 404);
        }

        return ResponseEntity<ProductResponseDto>.Ok(product.ToDto(), "Fetched product detail successfully.");
    }
}
