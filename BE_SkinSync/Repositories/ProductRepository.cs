using Microsoft.EntityFrameworkCore;
using SkinSync.Base;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Models.Dtos.Products;
using SkinSync.Models.Entities;

namespace SkinSync.Repositories;

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
        var brandFilter = query.Brand?.Trim();
        var usageTimeFilter = query.UsageTime?.Trim();
        var sourceFilter = query.Source?.Trim();

        var source = _dbContext.Products.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            source = source.Where(x =>
                EF.Functions.ILike(x.Name, $"%{search}%") ||
                EF.Functions.ILike(x.Brand, $"%{search}%") ||
                EF.Functions.ILike(x.Category, $"%{search}%") ||
                (x.Ingredient != null && EF.Functions.ILike(x.Ingredient, $"%{search}%")));
        }

        if (!string.IsNullOrWhiteSpace(categoryFilter))
        {
            source = source.Where(x => x.Category == categoryFilter);
        }

        if (!string.IsNullOrWhiteSpace(brandFilter))
        {
            source = source.Where(x => EF.Functions.ILike(x.Brand, $"%{brandFilter}%"));
        }

        if (!string.IsNullOrWhiteSpace(usageTimeFilter))
        {
            source = source.Where(x => x.UsageTime == usageTimeFilter);
        }

        if (query.IsActive.HasValue)
        {
            source = source.Where(x => x.IsActive == query.IsActive.Value);
        }

        if (query.IsVerified.HasValue)
        {
            source = source.Where(x => x.IsVerified == query.IsVerified.Value);
        }

        if (!string.IsNullOrWhiteSpace(sourceFilter))
        {
            if (string.Equals(sourceFilter, "unknown", StringComparison.OrdinalIgnoreCase))
            {
                source = source.Where(x => x.Source == string.Empty);
            }
            else
            {
                source = source.Where(x => x.Source == sourceFilter);
            }
        }

        if (query.HasImage.HasValue)
        {
            source = query.HasImage.Value
                ? source.Where(x => x.ImageUrl != null && x.ImageUrl != string.Empty)
                : source.Where(x => x.ImageUrl == null || x.ImageUrl == string.Empty);
        }

        if (query.HasIngredients.HasValue)
        {
            source = query.HasIngredients.Value
                ? source.Where(x => x.Ingredient != null && x.Ingredient != string.Empty)
                : source.Where(x => x.Ingredient == null || x.Ingredient == string.Empty);
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
            ("usagetime", false) => source.OrderBy(x => x.UsageTime),
            ("usagetime", true) => source.OrderByDescending(x => x.UsageTime),
            ("isactive", false) => source.OrderBy(x => x.IsActive),
            ("isactive", true) => source.OrderByDescending(x => x.IsActive),
            ("isverified", false) => source.OrderBy(x => x.IsVerified),
            ("isverified", true) => source.OrderByDescending(x => x.IsVerified),
            ("source", false) => source.OrderBy(x => x.Source),
            ("source", true) => source.OrderByDescending(x => x.Source),
            ("updatedat", false) => source.OrderBy(x => x.UpdatedAt),
            ("updatedat", true) => source.OrderByDescending(x => x.UpdatedAt),
            ("createdat", false) => source.OrderBy(x => x.CreatedAt),
            _ => source.OrderByDescending(x => x.CreatedAt)
        };

        var normalizedSortBy = sortBy switch
        {
            "name" => "name",
            "brand" => "brand",
            "category" => "category",
            "price" => "price",
            "usagetime" => "usageTime",
            "isactive" => "isActive",
            "isverified" => "isVerified",
            "source" => "source",
            "updatedat" => "updatedAt",
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
                ["brand"] = brandFilter,
                ["usageTime"] = usageTimeFilter,
                ["isActive"] = query.IsActive?.ToString(),
                ["isVerified"] = query.IsVerified?.ToString(),
                ["source"] = sourceFilter,
                ["hasImage"] = query.HasImage?.ToString(),
                ["hasIngredients"] = query.HasIngredients?.ToString()
            },
            PageIndex = query.PageIndex,
            PageSize = query.PageSize,
            TotalRow = totalRow
        };
    }

    public async Task<AdminProductsSummaryDto> GetSummaryAsync(CancellationToken cancellationToken)
    {
        var source = _dbContext.Products.AsNoTracking();
        return new AdminProductsSummaryDto
        {
            TotalProducts = await source.CountAsync(cancellationToken),
            ActiveProducts = await source.CountAsync(x => x.IsActive, cancellationToken),
            VerifiedProducts = await source.CountAsync(x => x.IsVerified, cancellationToken),
            ProductsMissingImage = await source.CountAsync(x => x.ImageUrl == null || x.ImageUrl == string.Empty, cancellationToken),
            ProductsMissingIngredients = await source.CountAsync(x => x.Ingredient == null || x.Ingredient == string.Empty, cancellationToken)
        };
    }

    public Task<Product?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        return _dbContext.Products.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    }

    public Task<Product?> GetDetailByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        return _dbContext.Products
            .AsNoTracking()
            .Include(x => x.ProductIngredients)
            .ThenInclude(x => x.Ingredient)
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
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

    public async Task SetActiveAsync(Product product, bool isActive, CancellationToken cancellationToken)
    {
        product.IsActive = isActive;
        product.Status = ProductCatalogConstants.NormalizeStatusForActiveFlag(product.Status, isActive);
        product.UpdatedAt = DateTime.UtcNow;
        _dbContext.Products.Update(product);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }
}
