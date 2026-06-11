using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SkinSync.Data;
using SkinSync.Models.Entities;
using SkinSync.Services;
using SkinSync.Services.AI;

namespace SkinSync.Services.AIPlatform;

public interface IAiUsageService
{
    Task CheckLimitAsync(Guid userId, string featureName, CancellationToken cancellationToken);
    Task CheckFeatureEnabledAsync(Guid userId, string featureName, CancellationToken cancellationToken);
    Task CheckReportAccessAsync(Guid userId, string featureName, string reportType, CancellationToken cancellationToken);
    Task LogUsageAsync(Guid userId, string featureName, string? model, int? inputTokens, int? outputTokens, CancellationToken cancellationToken);
}

public class AiUsageService : IAiUsageService
{
    private readonly AppDbContext _dbContext;
    private readonly AiSettings _settings;
    private readonly ISubscriptionService _subscriptionService;

    public AiUsageService(AppDbContext dbContext, IOptions<AiSettings> settings, ISubscriptionService subscriptionService)
    {
        _dbContext = dbContext;
        _settings = settings.Value;
        _subscriptionService = subscriptionService;
    }

    public async Task CheckLimitAsync(Guid userId, string featureName, CancellationToken cancellationToken)
    {
        var access = await _subscriptionService.GetFeatureAccessAsync(userId, featureName, cancellationToken);
        if (!access.IsEnabled)
        {
            throw new AiFeatureException("PLAN_FEATURE_NOT_AVAILABLE", $"{featureName} is not available for the current plan.", 403);
        }

        var limit = access.IsConfigured
            ? access.MonthlyLimit
            : ResolveLegacyLimit(access.PlanCode, featureName);
        if (!limit.HasValue)
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

        if (usedCount >= limit.Value)
        {
            throw new AiFeatureException("AI_QUOTA_EXCEEDED", $"Monthly quota exceeded for {featureName}.", 429);
        }
    }

    public async Task CheckFeatureEnabledAsync(Guid userId, string featureName, CancellationToken cancellationToken)
    {
        var access = await _subscriptionService.GetFeatureAccessAsync(userId, featureName, cancellationToken);
        if (!access.IsEnabled)
        {
            throw new AiFeatureException("PLAN_FEATURE_NOT_AVAILABLE", $"{featureName} is not available for the current plan.", 403);
        }
    }

    public async Task CheckReportAccessAsync(Guid userId, string featureName, string reportType, CancellationToken cancellationToken)
    {
        var access = await _subscriptionService.GetFeatureAccessAsync(userId, featureName, cancellationToken);
        if (!access.IsEnabled)
        {
            throw new AiFeatureException("PLAN_FEATURE_NOT_AVAILABLE", $"{featureName} is not available for the current plan.", 403);
        }

        var normalizedReportType = reportType.Trim().ToLowerInvariant();
        if (access.AllowedValues.Count > 0 &&
            !access.AllowedValues.Contains(normalizedReportType, StringComparer.OrdinalIgnoreCase))
        {
            throw new AiFeatureException("REPORT_TYPE_NOT_AVAILABLE", $"{normalizedReportType} report is not available for the current plan.", 403);
        }

        await CheckLimitAsync(userId, featureName, cancellationToken);
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

    private int? ResolveLegacyLimit(string planCode, string featureName)
    {
        var limits = string.Equals(planCode, SubscriptionService.PremiumPlan, StringComparison.OrdinalIgnoreCase)
            ? _settings.Quotas.PremiumPlanMonthlyLimits
            : _settings.Quotas.FreePlanMonthlyLimits;

        return limits.TryGetValue(featureName, out var limit) && limit > 0 ? limit : null;
    }
}
