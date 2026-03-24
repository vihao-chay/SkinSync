using Microsoft.EntityFrameworkCore;
using SkinAsync.Base;
using SkinAsync.Data;
using SkinAsync.Models.Dtos.Admin;
using SkinAsync.Models.Entities;

namespace SkinAsync.Repositories;

public class UserRepository : IUserRepository
{
    private readonly AppDbContext _dbContext;

    public UserRepository(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<User?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        return _dbContext.Users.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    }

    public Task<User?> GetByEmailAsync(string email, CancellationToken cancellationToken)
    {
        return _dbContext.Users.FirstOrDefaultAsync(x => x.Email == email, cancellationToken);
    }

    public Task<User?> GetByIdWithProfileAsync(Guid id, CancellationToken cancellationToken)
    {
        return _dbContext.Users.Include(x => x.Profile).FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    }

    public Task<bool> EmailExistsAsync(string email, CancellationToken cancellationToken)
    {
        return _dbContext.Users.AnyAsync(x => x.Email == email, cancellationToken);
    }

    public async Task AddAsync(User user, CancellationToken cancellationToken)
    {
        _dbContext.Users.Add(user);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task UpdateAsync(User user, CancellationToken cancellationToken)
    {
        _dbContext.Users.Update(user);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task UpsertProfileAsync(UserProfile profile, CancellationToken cancellationToken)
    {
        var existing = await _dbContext.UserProfiles.FirstOrDefaultAsync(x => x.UserId == profile.UserId, cancellationToken);
        if (existing is null)
        {
            _dbContext.UserProfiles.Add(profile);
        }
        else
        {
            existing.SkinType = profile.SkinType;
            existing.SkinConcerns = profile.SkinConcerns;
            existing.MonthlyBudget = profile.MonthlyBudget;
            existing.Age = profile.Age;
            existing.BirthYear = profile.BirthYear;
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<User>> GetAllAsync(CancellationToken cancellationToken)
    {
        return await _dbContext.Users
            .AsNoTracking()
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync(cancellationToken);
    }

    public async Task<PagingResult<User>> GetPagedAsync(AdminUsersQueryDto query, CancellationToken cancellationToken)
    {
        var search = query.Search?.Trim();
        var roleFilter = query.Role?.Trim();
        var statusFilter = query.Status?.Trim();

        var source = _dbContext.Users.AsNoTracking().AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            source = source.Where(x =>
                EF.Functions.ILike(x.FullName, $"%{search}%") ||
                EF.Functions.ILike(x.Email, $"%{search}%") ||
                EF.Functions.ILike(x.Phone, $"%{search}%"));
        }

        if (!string.IsNullOrWhiteSpace(roleFilter))
        {
            source = source.Where(x => x.Role == roleFilter);
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
            ("fullname", false) => source.OrderBy(x => x.FullName),
            ("fullname", true) => source.OrderByDescending(x => x.FullName),
            ("email", false) => source.OrderBy(x => x.Email),
            ("email", true) => source.OrderByDescending(x => x.Email),
            ("role", false) => source.OrderBy(x => x.Role),
            ("role", true) => source.OrderByDescending(x => x.Role),
            ("status", false) => source.OrderBy(x => x.Status),
            ("status", true) => source.OrderByDescending(x => x.Status),
            ("createdat", false) => source.OrderBy(x => x.CreatedAt),
            _ => source.OrderByDescending(x => x.CreatedAt)
        };

        var normalizedSortBy = sortBy switch
        {
            "fullname" => "fullName",
            "email" => "email",
            "role" => "role",
            "status" => "status",
            "createdat" => "createdAt",
            _ => "createdAt"
        };

        var totalRow = await source.CountAsync(cancellationToken);
        var items = await source
            .Skip((query.PageIndex - 1) * query.PageSize)
            .Take(query.PageSize)
            .ToListAsync(cancellationToken);

        return new PagingResult<User>
        {
            Items = items,
            Search = search,
            SortBy = normalizedSortBy,
            SortDirection = normalizedDirection,
            Filters = new Dictionary<string, string?>
            {
                ["role"] = roleFilter,
                ["status"] = statusFilter
            },
            PageIndex = query.PageIndex,
            PageSize = query.PageSize,
            TotalRow = totalRow
        };
    }
}
