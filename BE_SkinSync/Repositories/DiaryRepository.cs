using Microsoft.EntityFrameworkCore;
using SkinSync.Base;
using SkinSync.Data;
using SkinSync.Models.Dtos.Diary;
using SkinSync.Models.Entities;

namespace SkinSync.Repositories;

public class DiaryRepository : IDiaryRepository
{
    private readonly AppDbContext _dbContext;

    public DiaryRepository(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<DailyLog?> GetByUserAndDateAsync(Guid userId, DateOnly date, CancellationToken cancellationToken)
    {
        return _dbContext.DailyLogs.FirstOrDefaultAsync(x => x.UserId == userId && x.Date == date, cancellationToken);
    }

    public async Task<IReadOnlyCollection<DailyLog>> GetByUserAndMonthAsync(Guid userId, int year, int month, CancellationToken cancellationToken)
    {
        return await _dbContext.DailyLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.Date.Year == year && x.Date.Month == month)
            .OrderBy(x => x.Date)
            .ToListAsync(cancellationToken);
    }

    public async Task<PagingResult<DailyLog>> GetPagedByUserAndMonthAsync(Guid userId, DiaryMonthQueryDto query, CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var year = query.Year ?? now.Year;
        var month = query.Month ?? now.Month;
        var search = query.Search?.Trim();
        var skinFeelingFilter = query.SkinFeeling?.Trim();

        var source = _dbContext.DailyLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.Date.Year == year && x.Date.Month == month)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            source = source.Where(x =>
                (x.SkinFeeling != null && EF.Functions.ILike(x.SkinFeeling, $"%{search}%")) ||
                (x.Notes != null && EF.Functions.ILike(x.Notes, $"%{search}%")));
        }

        if (query.IsIrritated.HasValue)
        {
            source = source.Where(x => x.IsIrritated == query.IsIrritated.Value);
        }

        if (!string.IsNullOrWhiteSpace(skinFeelingFilter))
        {
            source = source.Where(x => x.SkinFeeling == skinFeelingFilter);
        }

        var sortBy = (query.SortBy ?? "date").Trim().ToLowerInvariant();
        var isDesc = !string.Equals(query.SortDirection, "asc", StringComparison.OrdinalIgnoreCase);
        var normalizedDirection = isDesc ? "desc" : "asc";

        source = (sortBy, isDesc) switch
        {
            ("date", false) => source.OrderBy(x => x.Date),
            ("skinfeeling", false) => source.OrderBy(x => x.SkinFeeling),
            ("skinfeeling", true) => source.OrderByDescending(x => x.SkinFeeling),
            ("isirritated", false) => source.OrderBy(x => x.IsIrritated),
            ("isirritated", true) => source.OrderByDescending(x => x.IsIrritated),
            _ => source.OrderByDescending(x => x.Date)
        };

        var normalizedSortBy = sortBy switch
        {
            "skinfeeling" => "skinFeeling",
            "isirritated" => "isIrritated",
            "date" => "date",
            _ => "date"
        };

        var totalRow = await source.CountAsync(cancellationToken);
        var items = await source
            .Skip((query.PageIndex - 1) * query.PageSize)
            .Take(query.PageSize)
            .ToListAsync(cancellationToken);

        return new PagingResult<DailyLog>
        {
            Items = items,
            Search = search,
            SortBy = normalizedSortBy,
            SortDirection = normalizedDirection,
            Filters = new Dictionary<string, string?>
            {
                ["year"] = year.ToString(),
                ["month"] = month.ToString(),
                ["isIrritated"] = query.IsIrritated?.ToString(),
                ["skinFeeling"] = skinFeelingFilter
            },
            PageIndex = query.PageIndex,
            PageSize = query.PageSize,
            TotalRow = totalRow
        };
    }

    public async Task AddAsync(DailyLog dailyLog, CancellationToken cancellationToken)
    {
        _dbContext.DailyLogs.Add(dailyLog);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public async Task UpdateAsync(DailyLog dailyLog, CancellationToken cancellationToken)
    {
        _dbContext.DailyLogs.Update(dailyLog);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }
}
