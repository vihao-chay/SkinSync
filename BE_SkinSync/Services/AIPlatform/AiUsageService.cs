using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SkinSync.Data;
using SkinSync.Models.Entities;
using SkinSync.Services.AI;

namespace SkinSync.Services.AIPlatform;

public interface IAiUsageService
{
    Task CheckLimitAsync(Guid userId, string featureName, CancellationToken cancellationToken);
    Task LogUsageAsync(Guid userId, string featureName, string? model, int? inputTokens, int? outputTokens, CancellationToken cancellationToken);
}

public class AiUsageService : IAiUsageService
{
    private readonly AppDbContext _dbContext;
    private readonly AiSettings _settings;

    public AiUsageService(AppDbContext dbContext, IOptions<AiSettings> settings)
    {
        _dbContext = dbContext;
        _settings = settings.Value;
    }

    public async Task CheckLimitAsync(Guid userId, string featureName, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users.AsNoTracking().FirstOrDefaultAsync(x => x.Id == userId, cancellationToken);
        if (user is null)
        {
            throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);
        }

        var limits = string.Equals(user.PlanType, "premium", StringComparison.OrdinalIgnoreCase)
            ? _settings.Quotas.PremiumPlanMonthlyLimits
            : _settings.Quotas.FreePlanMonthlyLimits;

        if (!limits.TryGetValue(featureName, out var limit) || limit <= 0)
        {
            return;
        }

        var startOfMonth = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var usedCount = await _dbContext.AiUsageLogs
            .AsNoTracking()
            .CountAsync(
                x => x.UserId == userId &&
                     x.FeatureName == featureName &&
                     x.UsedAt >= startOfMonth,
                cancellationToken);

        if (usedCount >= limit)
        {
            throw new AiFeatureException("AI_QUOTA_EXCEEDED", $"Monthly quota exceeded for {featureName}.", 429);
        }
    }

    public async Task LogUsageAsync(Guid userId, string featureName, string? model, int? inputTokens, int? outputTokens, CancellationToken cancellationToken)
    {
        _dbContext.AiUsageLogs.Add(new AiUsageLog
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            FeatureName = featureName,
            UsedAt = DateTime.UtcNow,
            Model = model,
            InputTokens = inputTokens,
            OutputTokens = outputTokens,
            CostEstimate = null
        });

        await _dbContext.SaveChangesAsync(cancellationToken);
    }
}
