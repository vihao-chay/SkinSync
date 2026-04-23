using Microsoft.EntityFrameworkCore;
using SkinAsync.Data;
using SkinAsync.Models.Entities;

namespace SkinAsync.Repositories;

public class RegimenRepository : IRegimenRepository
{
    private readonly AppDbContext _dbContext;

    public RegimenRepository(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IReadOnlyCollection<UserRegimen>> GetActiveByUserIdAsync(Guid userId, CancellationToken cancellationToken)
    {
        return await _dbContext.UserRegimens
            .Include(x => x.Items)
            .ThenInclude(x => x.Product)
            .Where(x => x.UserId == userId && x.IsActive)
            .ToListAsync(cancellationToken);
    }

    public Task<UserRegimen?> GetCurrentByUserIdAsync(Guid userId, CancellationToken cancellationToken)
    {
        return _dbContext.UserRegimens
            .AsNoTracking()
            .Include(x => x.Items)
            .ThenInclude(x => x.Product)
            .FirstOrDefaultAsync(x => x.UserId == userId && x.IsActive, cancellationToken);
    }

    public async Task AddAsync(UserRegimen regimen, CancellationToken cancellationToken)
    {
        _dbContext.UserRegimens.Add(regimen);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task DeactivateAllByUserIdAsync(Guid userId, CancellationToken cancellationToken)
    {
        var activeRegimens = await _dbContext.UserRegimens.Where(x => x.UserId == userId && x.IsActive).ToListAsync(cancellationToken);
        foreach (var regimen in activeRegimens)
        {
            regimen.IsActive = false;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
    }
}
