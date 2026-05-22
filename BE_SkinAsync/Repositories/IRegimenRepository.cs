using SkinAsync.Models.Entities;

namespace SkinAsync.Repositories;

public interface IRegimenRepository
{
    Task<IReadOnlyCollection<UserRegimen>> GetActiveByUserIdAsync(Guid userId, CancellationToken cancellationToken);
    Task<UserRegimen?> GetCurrentByUserIdAsync(Guid userId, CancellationToken cancellationToken);
    Task<UserRegimen?> GetByIdForUserAsync(Guid regimenId, Guid userId, CancellationToken cancellationToken);
    Task AddAsync(UserRegimen regimen, CancellationToken cancellationToken);
    Task UpdateAsync(UserRegimen regimen, CancellationToken cancellationToken);
    Task DeleteAsync(UserRegimen regimen, CancellationToken cancellationToken);
    Task DeactivateAllByUserIdAsync(Guid userId, CancellationToken cancellationToken);
}
