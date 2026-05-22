using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using SkinAsync.Base;
using SkinAsync.Mappers;
using SkinAsync.Models.Dtos.Products;
using SkinAsync.Repositories;

namespace SkinAsync.Controllers;

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
            "Lấy danh sách sản phẩm thành công.");
    }

    [HttpGet("{id:guid}")]
    public async Task<ResponseEntity<ProductResponseDto>> GetProduct(Guid id, CancellationToken cancellationToken)
    {
        var product = await _productRepository.GetByIdAsync(id, cancellationToken);
        if (product is null || !product.Status.Equals("active", StringComparison.OrdinalIgnoreCase))
        {
            return ResponseEntity<ProductResponseDto>.Fail("Không tìm thấy sản phẩm.", 404);
        }

        return ResponseEntity<ProductResponseDto>.Ok(product.ToDto(), "Lấy chi tiết sản phẩm thành công.");
    }
}
