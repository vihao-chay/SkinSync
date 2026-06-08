using SkinSync.Base;
using SkinSync.Models.Dtos.Admin;
using SkinSync.Models.Entities;

namespace SkinSync.Repositories;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken);
    Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken);
    Task<User?> GetByIdWithProfileAsync(Guid id, CancellationToken cancellationToken);
    Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken);
    Task AddAsync(User user, CancellationToken cancellationToken);
    Task UpdateAsync(User user, CancellationToken cancellationToken);
    Task UpsertProfileAsync(UserProfile profile, CancellationToken cancellationToken);
    Task<IReadOnlyCollection<User>> GetAllAsync(CancellationToken cancellationToken);
    Task<PagingResult<User>> GetPagedAsync(AdminUsersQueryDto query, CancellationToken cancellationToken);
}
