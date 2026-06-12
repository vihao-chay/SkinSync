using Microsoft.EntityFrameworkCore;
using SkinSync.Data;
using SkinSync.Models.Dtos.Subscriptions;
using SkinSync.Models.Entities;
using SkinSync.Services.AIPlatform;

namespace SkinSync.Services;

public interface ISubscriptionPlanService
{
    Task<IReadOnlyCollection<SubscriptionPlanDto>> GetPlansAsync(CancellationToken cancellationToken);
    Task<CurrentSubscriptionDto> GetCurrentAsync(Guid userId, CancellationToken cancellationToken);
    Task<CurrentSubscriptionDto> SubscribeAsync(Guid userId, string planCode, CancellationToken cancellationToken);
    Task<CurrentSubscriptionDto> CancelAsync(Guid userId, CancellationToken cancellationToken);
    Task<CurrentSubscriptionDto> ChangeUserPlanAsync(Guid userId, string planCode, CancellationToken cancellationToken);
    Task<string> GetEffectivePlanTypeAsync(Guid userId, CancellationToken cancellationToken);
    Task<SubscriptionFeatureAccess> GetFeatureAccessAsync(Guid userId, string featureKey, CancellationToken cancellationToken);
    Task EnsureFeatureAvailableAsync(Guid userId, string featureKey, CancellationToken cancellationToken);
    Task EnsureReportAccessAsync(Guid userId, string? periodType, CancellationToken cancellationToken);
}

public sealed record SubscriptionFeatureAccess(
    string PlanCode,
    string FeatureKey,
    bool IsEnabled,
    bool IsUnlimited,
    int? MonthlyLimit);

public class SubscriptionPlanService : ISubscriptionPlanService
{
    private static readonly HashSet<string> PaidPlanCodes = new(StringComparer.OrdinalIgnoreCase)
    {
        "plus",
        "premium"
    };

    private static readonly HashSet<string> CountedQuotaFeatures = new(StringComparer.OrdinalIgnoreCase)
    {
        "skin_analysis",
        "skin_progress_analysis",
        "skin_progress_compare",
        "skin_progress_report",
        "ai_chat",
        "routine_generation",
        "product_recommendation",
        "ingredient_check",
        "report_generation",
        "conflict_check",
        "smart_reminder",
        "progress_entry"
    };

    private readonly AppDbContext _dbContext;

    public SubscriptionPlanService(AppDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IReadOnlyCollection<SubscriptionPlanDto>> GetPlansAsync(CancellationToken cancellationToken)
    {
        var plans = await _dbContext.SubscriptionPlans
            .AsNoTracking()
            .Include(x => x.Features)
            .Where(x => x.IsActive)
            .OrderBy(x => x.SortOrder)
            .ThenBy(x => x.Price)
            .ToListAsync(cancellationToken);

        return plans.Select(ToPlanDto).ToList();
    }

    public async Task<CurrentSubscriptionDto> GetCurrentAsync(Guid userId, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

        var now = DateTime.UtcNow;
        var activeSubscription = await _dbContext.UserSubscriptions
            .AsNoTracking()
            .Include(x => x.Plan)
            .ThenInclude(x => x.Features)
            .Where(x => x.UserId == userId && x.Status == "active" && (x.EndsAt == null || x.EndsAt > now))
            .OrderByDescending(x => x.CreatedAt)
            .FirstOrDefaultAsync(cancellationToken);

        var planCode = activeSubscription?.Plan.Code ?? NormalizePlanCode(user.PlanType);
        var plan = activeSubscription?.Plan ?? await GetPlanEntityAsync(planCode, cancellationToken);
        var planDto = ToPlanDto(plan);
        var usage = await BuildUsageAsync(userId, plan, cancellationToken);

        return new CurrentSubscriptionDto
        {
            Plan = planDto,
            Subscription = activeSubscription is null
                ? new SubscriptionStatusDto
                {
                    PlanCode = plan.Code,
                    Status = "active"
                }
                : new SubscriptionStatusDto
                {
                    SubscriptionId = activeSubscription.Id,
                    PlanCode = activeSubscription.Plan.Code,
                    Status = activeSubscription.Status,
                    StartedAt = activeSubscription.StartedAt,
                    CurrentPeriodStart = activeSubscription.StartedAt,
                    CurrentPeriodEnd = activeSubscription.EndsAt,
                    CanceledAt = activeSubscription.CancelledAt
                },
            Usage = usage
        };
    }

    public async Task<CurrentSubscriptionDto> SubscribeAsync(Guid userId, string planCode, CancellationToken cancellationToken)
    {
        var normalized = NormalizePlanCode(planCode);
        if (!PaidPlanCodes.Contains(normalized))
        {
            throw new AiFeatureException("INVALID_PLAN", "planCode must be plus or premium.");
        }

        return await ChangeUserPlanAsync(userId, normalized, cancellationToken);
    }

    public async Task<CurrentSubscriptionDto> CancelAsync(Guid userId, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

        var now = DateTime.UtcNow;
        var activeSubscriptions = await _dbContext.UserSubscriptions
            .Where(x => x.UserId == userId && x.Status == "active")
            .ToListAsync(cancellationToken);

        foreach (var subscription in activeSubscriptions)
        {
            subscription.Status = "canceled";
            subscription.CancelledAt = now;
            subscription.EndsAt = now;
            subscription.UpdatedAt = now;
        }

        user.PlanType = "free";
        user.UpdatedAt = now;
        await _dbContext.SaveChangesAsync(cancellationToken);

        return await GetCurrentAsync(userId, cancellationToken);
    }

    public async Task<CurrentSubscriptionDto> ChangeUserPlanAsync(Guid userId, string planCode, CancellationToken cancellationToken)
    {
        var normalized = NormalizePlanCode(planCode);
        if (normalized == "free")
        {
            return await CancelAsync(userId, cancellationToken);
        }

        var user = await _dbContext.Users.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);
        var plan = await GetPlanEntityAsync(normalized, cancellationToken);
        if (!plan.IsActive)
        {
            throw new AiFeatureException("PLAN_INACTIVE", "Selected plan is inactive.", 400);
        }

        var now = DateTime.UtcNow;
        var activeSubscriptions = await _dbContext.UserSubscriptions
            .Where(x => x.UserId == userId && x.Status == "active")
            .ToListAsync(cancellationToken);

        foreach (var subscription in activeSubscriptions)
        {
            subscription.Status = "canceled";
            subscription.CancelledAt = now;
            subscription.EndsAt = now;
            subscription.UpdatedAt = now;
        }

        _dbContext.UserSubscriptions.Add(new UserSubscription
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            PlanId = plan.Id,
            Status = "active",
            StartedAt = now,
            EndsAt = now.AddMonths(1),
            PricePaid = plan.Price,
            Currency = plan.Currency,
            BillingPeriod = plan.BillingPeriod,
            CreatedAt = now
        });

        user.PlanType = plan.Code;
        user.UpdatedAt = now;
        await _dbContext.SaveChangesAsync(cancellationToken);

        return await GetCurrentAsync(userId, cancellationToken);
    }

    public async Task<string> GetEffectivePlanTypeAsync(Guid userId, CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var activePlan = await _dbContext.UserSubscriptions
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.Status == "active" && (x.EndsAt == null || x.EndsAt > now))
            .OrderByDescending(x => x.CreatedAt)
            .Select(x => x.Plan.Code)
            .FirstOrDefaultAsync(cancellationToken);

        if (!string.IsNullOrWhiteSpace(activePlan))
        {
            return NormalizePlanCode(activePlan);
        }

        var planType = await _dbContext.Users
            .AsNoTracking()
            .Where(x => x.Id == userId)
            .Select(x => x.PlanType)
            .FirstOrDefaultAsync(cancellationToken);

        return NormalizePlanCode(planType);
    }

    public async Task<SubscriptionFeatureAccess> GetFeatureAccessAsync(Guid userId, string featureKey, CancellationToken cancellationToken)
    {
        var normalizedFeature = NormalizeFeatureKey(featureKey);
        var planCode = await GetEffectivePlanTypeAsync(userId, cancellationToken);
        var plan = await _dbContext.SubscriptionPlans
            .AsNoTracking()
            .Include(x => x.Features)
            .FirstOrDefaultAsync(x => x.Code == planCode, cancellationToken);

        if (plan is null)
        {
            return new SubscriptionFeatureAccess(planCode, normalizedFeature, true, true, null);
        }

        var feature = plan.Features.FirstOrDefault(x =>
            string.Equals(x.FeatureKey, normalizedFeature, StringComparison.OrdinalIgnoreCase));

        if (feature is null)
        {
            return new SubscriptionFeatureAccess(plan.Code, normalizedFeature, true, true, null);
        }

        return new SubscriptionFeatureAccess(
            plan.Code,
            normalizedFeature,
            feature.IsEnabled,
            IsUnlimitedFeature(feature),
            feature.MonthlyLimit);
    }

    public async Task EnsureFeatureAvailableAsync(Guid userId, string featureKey, CancellationToken cancellationToken)
    {
        var access = await GetFeatureAccessAsync(userId, featureKey, cancellationToken);
        if (!access.IsEnabled || (!access.IsUnlimited && access.MonthlyLimit == 0))
        {
            throw new AiFeatureException("PLAN_FEATURE_NOT_AVAILABLE", $"{featureKey} is not available on your current plan.", 403);
        }
    }

    public async Task EnsureReportAccessAsync(Guid userId, string? periodType, CancellationToken cancellationToken)
    {
        var normalized = string.IsNullOrWhiteSpace(periodType)
            ? "custom"
            : periodType.Trim().ToLowerInvariant();
        var featureKey = normalized switch
        {
            "weekly" => "report_weekly",
            "monthly" => "report_monthly",
            "custom" => "report_custom",
            _ => "report_custom"
        };

        await EnsureFeatureAvailableAsync(userId, featureKey, cancellationToken);
    }

    private async Task<IReadOnlyCollection<SubscriptionUsageDto>> BuildUsageAsync(
        Guid userId,
        SubscriptionPlan plan,
        CancellationToken cancellationToken)
    {
        var startOfMonth = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var featureKeys = plan.Features
            .Select(x => x.FeatureKey)
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();

        var usageRows = new Dictionary<string, int>(StringComparer.OrdinalIgnoreCase);
        if (featureKeys.Count > 0)
        {
            var usageList = await _dbContext.AiUsageLogs
                .AsNoTracking()
                .Where(x => x.UserId == userId && x.UsedAt >= startOfMonth && featureKeys.Contains(x.FeatureName))
                .GroupBy(x => x.FeatureName)
                .Select(x => new { FeatureName = x.Key, Count = x.Count() })
                .ToListAsync(cancellationToken);

            usageRows = usageList.ToDictionary(x => x.FeatureName, x => x.Count, StringComparer.OrdinalIgnoreCase);
        }

        return plan.Features
            .OrderBy(x => GetFeatureSortOrder(x.FeatureKey))
            .ThenBy(x => x.FeatureKey)
            .Select(feature =>
            {
                var used = usageRows.TryGetValue(feature.FeatureKey, out var count) ? count : 0;
                var isUnlimited = IsUnlimitedFeature(feature);
                var remaining = isUnlimited || feature.MonthlyLimit is null
                    ? (int?)null
                    : Math.Max(feature.MonthlyLimit.Value - used, 0);

                return new SubscriptionUsageDto
                {
                    FeatureKey = feature.FeatureKey,
                    DisplayName = feature.DisplayName,
                    Used = used,
                    MonthlyLimit = feature.MonthlyLimit,
                    Remaining = remaining,
                    IsUnlimited = isUnlimited,
                    IsEnabled = feature.IsEnabled
                };
            })
            .ToList();
    }

    private async Task<SubscriptionPlan> GetPlanEntityAsync(string planCode, CancellationToken cancellationToken)
    {
        var normalized = NormalizePlanCode(planCode);
        return await _dbContext.SubscriptionPlans
            .Include(x => x.Features)
            .FirstOrDefaultAsync(x => x.Code == normalized, cancellationToken)
            ?? throw new AiFeatureException("PLAN_NOT_FOUND", "Subscription plan not found.", 404);
    }

    private static SubscriptionPlanDto ToPlanDto(SubscriptionPlan plan)
    {
        return new SubscriptionPlanDto
        {
            Id = plan.Id,
            Code = plan.Code,
            Name = plan.Name,
            Description = plan.Description,
            PriceVnd = plan.Price,
            BillingCycle = plan.BillingPeriod,
            IsActive = plan.IsActive,
            Features = plan.Features
                .OrderBy(x => GetFeatureSortOrder(x.FeatureKey))
                .ThenBy(x => x.FeatureKey)
                .Select(x => new SubscriptionPlanFeatureDto
                {
                    FeatureKey = x.FeatureKey,
                    DisplayName = x.DisplayName,
                    MonthlyLimit = x.MonthlyLimit,
                    IsUnlimited = IsUnlimitedFeature(x),
                    IsEnabled = x.IsEnabled
                })
                .ToList()
        };
    }

    private static string NormalizePlanCode(string? value)
    {
        var normalized = value?.Trim().ToLowerInvariant();
        return normalized is "plus" or "premium" ? normalized : "free";
    }

    private static string NormalizeFeatureKey(string value) =>
        value.Trim().ToLowerInvariant();

    private static int GetFeatureSortOrder(string featureKey) => NormalizeFeatureKey(featureKey) switch
    {
        "skin_analysis" => 10,
        "ai_chat" => 20,
        "routine_generation" => 30,
        "ingredient_check" => 40,
        "conflict_check" => 50,
        "progress_entry" => 60,
        "skin_progress_compare" => 70,
        "report_weekly" => 80,
        "report_monthly" => 90,
        "report_custom" => 100,
        "export_pdf" => 110,
        _ => 999
    };

    private static bool IsUnlimitedFeature(SubscriptionPlanFeature feature) =>
        feature.IsEnabled &&
        feature.MonthlyLimit is null &&
        CountedQuotaFeatures.Contains(feature.FeatureKey);
}
