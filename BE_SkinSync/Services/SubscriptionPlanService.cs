using Microsoft.EntityFrameworkCore;
using SkinSync.Data;

namespace SkinSync.Services;

public interface ISubscriptionPlanService
{
    Task<string> GetEffectivePlanTypeAsync(Guid userId, CancellationToken cancellationToken);
}

public class SubscriptionPlanService : ISubscriptionPlanService
{
    private readonly AppDbContext _dbContext;

    public SubscriptionPlanService(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<string> GetEffectivePlanTypeAsync(Guid userId, CancellationToken cancellationToken)
    {
        var planType = await _dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == userId)
            .Select(x => x.PlanType)
            .FirstOrDefaultAsync(cancellationToken);

        return string.IsNullOrWhiteSpace(planType) ? "free" : planType.Trim().ToLowerInvariant();
    }
}
