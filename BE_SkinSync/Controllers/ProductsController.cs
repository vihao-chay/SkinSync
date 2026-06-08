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
        CancellationToken cancellationToken)
    {
        var products = await _productRepository.GetAllAsync(cancellationToken);
        var source = products
            .Where(x => x.Status.Equals("active", StringComparison.OrdinalIgnoreCase))
            .AsEnumerable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            var keyword = search.Trim();
            source = source.Where(x =>
                x.Name.Contains(keyword, StringComparison.OrdinalIgnoreCase) ||
                x.Brand.Contains(keyword, StringComparison.OrdinalIgnoreCase) ||
                x.Category.Contains(keyword, StringComparison.OrdinalIgnoreCase));
        }

        if (!string.IsNullOrWhiteSpace(category))
        {
            source = source.Where(x => x.Category.Equals(category.Trim(), StringComparison.OrdinalIgnoreCase));
        }

        return ResponseEntity<IEnumerable<ProductResponseDto>>.Ok(
            source.Select(x => x.ToDto()).ToList(),
            "Láº¥y danh sÃ¡ch sáº£n pháº©m thÃ nh cÃ´ng.");
    }

    [HttpGet("{id:guid}")]
    public async Task<ResponseEntity<ProductResponseDto>> GetProduct(Guid id, CancellationToken cancellationToken)
    {
        var product = await _productRepository.GetByIdAsync(id, cancellationToken);
        if (product is null || !product.Status.Equals("active", StringComparison.OrdinalIgnoreCase))
        {
            return ResponseEntity<ProductResponseDto>.Fail("KhÃ´ng tÃ¬m tháº¥y sáº£n pháº©m.", 404);
        }

        return ResponseEntity<ProductResponseDto>.Ok(product.ToDto(), "Láº¥y chi tiáº¿t sáº£n pháº©m thÃ nh cÃ´ng.");
    }
}
