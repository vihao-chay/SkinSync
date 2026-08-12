using SkinSync.Base;
using SkinSync.Models.Dtos.Products;
using SkinSync.Models.Entities;

namespace SkinSync.Repositories;

public interface IProductRepository
{
	Task<IReadOnlyCollection<Product>> GetAllAsync(CancellationToken cancellationToken);
	Task<PagingResult<Product>> GetPagedAsync(AdminProductsQueryDto query, CancellationToken cancellationToken);
	Task<AdminProductsSummaryDto> GetSummaryAsync(CancellationToken cancellationToken);
	Task<Product?> GetByIdAsync(Guid id, CancellationToken cancellationToken);
	Task<Product?> GetDetailByIdAsync(Guid id, CancellationToken cancellationToken);
	Task AddAsync(Product product, CancellationToken cancellationToken);
	Task UpdateAsync(Product product, CancellationToken cancellationToken);
	Task SetActiveAsync(Product product, bool isActive, CancellationToken cancellationToken);
}
