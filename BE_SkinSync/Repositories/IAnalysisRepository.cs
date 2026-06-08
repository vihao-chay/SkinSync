using SkinSync.Base;
using SkinSync.Models.Dtos.Analysis;
using SkinSync.Models.Entities;

namespace SkinSync.Repositories;

public interface IAnalysisRepository
{
    Task AddAsync(AiAnalysis analysis, CancellationToken cancellationToken);
    Task<AiAnalysis?> GetByIdAsync(Guid id, CancellationToken cancellationToken);
    Task<AiAnalysis?> GetLatestByUserIdAsync(Guid userId, CancellationToken cancellationToken);
    Task<IReadOnlyCollection<AiAnalysis>> GetHistoryByUserIdAsync(Guid userId, CancellationToken cancellationToken);
    Task<PagingResult<AiAnalysis>> GetPagedHistoryByUserIdAsync(Guid userId, AnalysisHistoryQueryDto query, CancellationToken cancellationToken);
    Task<int> CountAsync(CancellationToken cancellationToken);
}
