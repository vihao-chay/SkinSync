using SkinSync.Base;
using SkinSync.Models.Dtos.Products;
using SkinSync.Models.Entities;

namespace SkinSync.Repositories;

public interface IProductRepository
{
	Task<IReadOnlyCollection<Product>> GetAllAsync(CancellationToken cancellationToken);
	Task<PagingResult<Product>> GetPagedAsync(AdminProductsQueryDto query, CancellationToken cancellationToken);
	Task<Product?> GetByIdAsync(Guid id, CancellationToken cancellationToken);
	Task AddAsync(Product product, CancellationToken cancellationToken);
	Task UpdateAsync(Product product, CancellationToken cancellationToken);
	Task DeleteAsync(Product product, CancellationToken cancellationToken);
}