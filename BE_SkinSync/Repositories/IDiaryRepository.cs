using SkinSync.Base;
using SkinSync.Models.Dtos.Diary;
using SkinSync.Models.Entities;

namespace SkinSync.Repositories;

public interface IDiaryRepository
{
    Task<DailyLog?> GetByUserAndDateAsync(Guid userId, DateOnly date, CancellationToken cancellationToken);
    Task<IReadOnlyCollection<DailyLog>> GetByUserAndMonthAsync(Guid userId, int year, int month, CancellationToken cancellationToken);
    Task<PagingResult<DailyLog>> GetPagedByUserAndMonthAsync(Guid userId, DiaryMonthQueryDto query, CancellationToken cancellationToken);
    Task AddAsync(DailyLog dailyLog, CancellationToken cancellationToken);
    Task UpdateAsync(DailyLog dailyLog, CancellationToken cancellationToken);
}