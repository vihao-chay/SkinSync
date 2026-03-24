using Microsoft.EntityFrameworkCore;
using SkinAsync.Base;
using SkinAsync.Data;
using SkinAsync.Models.Dtos.Products;
using SkinAsync.Models.Entities;

namespace SkinAsync.Repositories;

public class ProductRepository : IProductRepository
{
    private readonly AppDbContext _dbContext;

    public ProductRepository(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IReadOnlyCollection<Product>> GetAllAsync(CancellationToken cancellationToken)
    {
        return await _dbContext.Products
            .AsNoTracking()
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync(cancellationToken);
    }

    public async Task<PagingResult<Product>> GetPagedAsync(AdminProductsQueryDto query, CancellationToken cancellationToken)
    {
        var search = query.Search?.Trim();
        var categoryFilter = query.Category?.Trim();
        var statusFilter = query.Status?.Trim();

        var source = _dbContext.Products.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            source = source.Where(x =>
                EF.Functions.ILike(x.Name, $"%{search}%") ||
                EF.Functions.ILike(x.Brand, $"%{search}%") ||
                EF.Functions.ILike(x.Category, $"%{search}%"));
        }

        if (!string.IsNullOrWhiteSpace(categoryFilter))
        {
            source = source.Where(x => x.Category == categoryFilter);
        }

        if (!string.IsNullOrWhiteSpace(statusFilter))
        {
            source = source.Where(x => x.Status == statusFilter);
        }

        var sortBy = (query.SortBy ?? "createdAt").Trim().ToLowerInvariant();
        var isDesc = !string.Equals(query.SortDirection, "asc", StringComparison.OrdinalIgnoreCase);
        var normalizedDirection = isDesc ? "desc" : "asc";

        source = (sortBy, isDesc) switch
        {
            ("name", false) => source.OrderBy(x => x.Name),
            ("name", true) => source.OrderByDescending(x => x.Name),
            ("brand", false) => source.OrderBy(x => x.Brand),
            ("brand", true) => source.OrderByDescending(x => x.Brand),
            ("category", false) => source.OrderBy(x => x.Category),
            ("category", true) => source.OrderByDescending(x => x.Category),
            ("price", false) => source.OrderBy(x => x.Price),
            ("price", true) => source.OrderByDescending(x => x.Price),
            ("rating", false) => source.OrderBy(x => x.Rating),
            ("rating", true) => source.OrderByDescending(x => x.Rating),
            ("status", false) => source.OrderBy(x => x.Status),
            ("status", true) => source.OrderByDescending(x => x.Status),
            ("createdat", false) => source.OrderBy(x => x.CreatedAt),
            _ => source.OrderByDescending(x => x.CreatedAt)
        };

        var normalizedSortBy = sortBy switch
        {
            "name" => "name",
            "brand" => "brand",
            "category" => "category",
            "price" => "price",
            "rating" => "rating",
            "status" => "status",
            "createdat" => "createdAt",
            _ => "createdAt"
        };

        var totalRow = await source.CountAsync(cancellationToken);
        var items = await source
            .Skip((query.PageIndex - 1) * query.PageSize)
            .Take(query.PageSize)
            .ToListAsync(cancellationToken);

        return new PagingResult<Product>
        {
            Items = items,
            Search = search,
            SortBy = normalizedSortBy,
            SortDirection = normalizedDirection,
            Filters = new Dictionary<string, string?>
            {
                ["category"] = categoryFilter,
                ["status"] = statusFilter
            },
            PageIndex = query.PageIndex,
            PageSize = query.PageSize,
            TotalRow = totalRow
        };
    }

    public Task<Product?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        return _dbContext.Products.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    }

    public async Task AddAsync(Product product, CancellationToken cancellationToken)
    {
        _dbContext.Products.Add(product);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task UpdateAsync(Product product, CancellationToken cancellationToken)
    {
        _dbContext.Products.Update(product);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task DeleteAsync(Product product, CancellationToken cancellationToken)
    {
        _dbContext.Products.Remove(product);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }
}
