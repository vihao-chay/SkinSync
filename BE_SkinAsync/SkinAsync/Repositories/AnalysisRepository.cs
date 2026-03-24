using Microsoft.EntityFrameworkCore;
using SkinAsync.Base;
using SkinAsync.Data;
using SkinAsync.Models.Dtos.Analysis;
using SkinAsync.Models.Entities;

namespace SkinAsync.Repositories;

public class AnalysisRepository : IAnalysisRepository
{
    private readonly AppDbContext _dbContext;

    public AnalysisRepository(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task AddAsync(AiAnalysis analysis, CancellationToken cancellationToken)
    {
        _dbContext.AiAnalyses.Add(analysis);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public Task<AiAnalysis?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        return _dbContext.AiAnalyses.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
    }

    public async Task<IReadOnlyCollection<AiAnalysis>> GetHistoryByUserIdAsync(Guid userId, CancellationToken cancellationToken)
    {
        return await _dbContext.AiAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .ToListAsync(cancellationToken);
    }

    public async Task<PagingResult<AiAnalysis>> GetPagedHistoryByUserIdAsync(Guid userId, AnalysisHistoryQueryDto query, CancellationToken cancellationToken)
    {
        var search = query.Search?.Trim();
        var source = _dbContext.AiAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(search))
        {
            source = source.Where(x =>
                EF.Functions.ILike(x.RootCauses, $"%{search}%") ||
                EF.Functions.ILike(x.IssuesDetected, $"%{search}%"));
        }

        if (query.MinOverallScore.HasValue)
        {
            source = source.Where(x => x.OverallScore >= query.MinOverallScore.Value);
        }

        if (query.MaxOverallScore.HasValue)
        {
            source = source.Where(x => x.OverallScore <= query.MaxOverallScore.Value);
        }

        if (query.FromDate.HasValue)
        {
            source = source.Where(x => x.CreatedAt >= query.FromDate.Value);
        }

        if (query.ToDate.HasValue)
        {
            source = source.Where(x => x.CreatedAt <= query.ToDate.Value);
        }

        var sortBy = (query.SortBy ?? "createdAt").Trim().ToLowerInvariant();
        var isDesc = !string.Equals(query.SortDirection, "asc", StringComparison.OrdinalIgnoreCase);
        var normalizedDirection = isDesc ? "desc" : "asc";

        source = (sortBy, isDesc) switch
        {
            ("overallscore", false) => source.OrderBy(x => x.OverallScore),
            ("overallscore", true) => source.OrderByDescending(x => x.OverallScore),
            ("skinage", false) => source.OrderBy(x => x.SkinAge),
            ("skinage", true) => source.OrderByDescending(x => x.SkinAge),
            ("recoverycapacity", false) => source.OrderBy(x => x.RecoveryCapacity),
            ("recoverycapacity", true) => source.OrderByDescending(x => x.RecoveryCapacity),
            ("uvdamage", false) => source.OrderBy(x => x.UvDamage),
            ("uvdamage", true) => source.OrderByDescending(x => x.UvDamage),
            ("agingrisk", false) => source.OrderBy(x => x.AgingRisk),
            ("agingrisk", true) => source.OrderByDescending(x => x.AgingRisk),
            ("createdat", false) => source.OrderBy(x => x.CreatedAt),
            _ => source.OrderByDescending(x => x.CreatedAt)
        };

        var normalizedSortBy = sortBy switch
        {
            "overallscore" => "overallScore",
            "skinage" => "skinAge",
            "recoverycapacity" => "recoveryCapacity",
            "uvdamage" => "uvDamage",
            "agingrisk" => "agingRisk",
            "createdat" => "createdAt",
            _ => "createdAt"
        };

        var totalRow = await source.CountAsync(cancellationToken);
        var items = await source
            .Skip((query.PageIndex - 1) * query.PageSize)
            .Take(query.PageSize)
            .ToListAsync(cancellationToken);

        return new PagingResult<AiAnalysis>
        {
            Items = items,
            Search = search,
            SortBy = normalizedSortBy,
            SortDirection = normalizedDirection,
            Filters = new Dictionary<string, string?>
            {
                ["minOverallScore"] = query.MinOverallScore?.ToString(),
                ["maxOverallScore"] = query.MaxOverallScore?.ToString(),
                ["fromDate"] = query.FromDate?.ToString("O"),
                ["toDate"] = query.ToDate?.ToString("O")
            },
            PageIndex = query.PageIndex,
            PageSize = query.PageSize,
            TotalRow = totalRow
        };
    }

    public Task<int> CountAsync(CancellationToken cancellationToken)
    {
        return _dbContext.AiAnalyses.CountAsync(cancellationToken);
    }
}
