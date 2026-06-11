using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using SkinSync.Data;
using SkinSync.Models.Dtos.Subscriptions;
using SkinSync.Models.Entities;
using SkinSync.Services.AIPlatform;

namespace SkinSync.Services;

public interface ISubscriptionService
{
    Task<IReadOnlyCollection<SubscriptionPlanDto>> GetPlansAsync(CancellationToken cancellationToken);
    Task<CurrentSubscriptionDto> GetCurrentAsync(Guid userId, CancellationToken cancellationToken);
    Task<CurrentSubscriptionDto> SubscribeAsync(Guid userId, SubscribeRequestDto request, CancellationToken cancellationToken);
    Task<CurrentSubscriptionDto> CancelAsync(Guid userId, CancellationToken cancellationToken);
    Task<User> ChangeUserPlanAsync(Guid userId, string planCode, CancellationToken cancellationToken);
    Task<SubscriptionFeatureAccess> GetFeatureAccessAsync(Guid userId, string featureKey, CancellationToken cancellationToken);
}

public class SubscriptionService : ISubscriptionService
{
    public const string FreePlan = "free";
    public const string PlusPlan = "plus";
    public const string PremiumPlan = "premium";

    private readonly AppDbContext _dbContext;

    public SubscriptionService(AppDbContext dbContext)
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
            .ToListAsync(cancellationToken);

        return plans.Select(ToPlanDto).ToList();
    }

    public async Task<CurrentSubscriptionDto> GetCurrentAsync(Guid userId, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

        var plan = await GetPlanByCodeAsync(NormalizeStoredPlanCode(user.PlanType), cancellationToken);
        var activeSubscription = await GetActiveSubscriptionAsync(userId, cancellationToken);
        return await BuildCurrentDtoAsync(userId, plan, activeSubscription, cancellationToken);
    }

    public async Task<CurrentSubscriptionDto> SubscribeAsync(Guid userId, SubscribeRequestDto request, CancellationToken cancellationToken)
    {
        var planCode = NormalizeRequestedPlanCode(request.PlanCode);
        if (planCode == FreePlan)
        {
            throw new AiFeatureException("INVALID_PLAN", "Use cancel to return to the free plan.", 400);
        }

        var user = await ChangeUserPlanAsync(userId, planCode, cancellationToken);
        var plan = await GetPlanByCodeAsync(user.PlanType, cancellationToken);
        var activeSubscription = await GetActiveSubscriptionAsync(userId, cancellationToken);
        return await BuildCurrentDtoAsync(userId, plan, activeSubscription, cancellationToken);
    }

    public async Task<CurrentSubscriptionDto> CancelAsync(Guid userId, CancellationToken cancellationToken)
    {
        var user = await ChangeUserPlanAsync(userId, FreePlan, cancellationToken);
        var plan = await GetPlanByCodeAsync(user.PlanType, cancellationToken);
        return await BuildCurrentDtoAsync(userId, plan, null, cancellationToken);
    }

    public async Task<User> ChangeUserPlanAsync(Guid userId, string planCode, CancellationToken cancellationToken)
    {
        var normalizedPlanCode = NormalizeRequestedPlanCode(planCode);
        var plan = await GetPlanByCodeAsync(normalizedPlanCode, cancellationToken);
        var user = await _dbContext.Users.FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

        var now = DateTime.UtcNow;
        var activeSubscriptions = await _dbContext.UserSubscriptions
            .Where(x => x.UserId == userId && x.Status == "active")
            .ToListAsync(cancellationToken);

        foreach (var subscription in activeSubscriptions)
        {
            subscription.Status = "cancelled";
            subscription.EndsAt = now;
            subscription.CancelledAt = now;
            subscription.UpdatedAt = now;
        }

        user.PlanType = plan.Code;
        user.UpdatedAt = now;

        if (plan.Code != FreePlan)
        {
            _dbContext.UserSubscriptions.Add(new UserSubscription
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                PlanId = plan.Id,
                Status = "active",
                StartedAt = now,
                EndsAt = now.AddMonths(1),
                PricePaid = plan.Price,
                Currency = plan.Currency,
                BillingPeriod = plan.BillingPeriod,
                CreatedAt = now
            });
        }

        await _dbContext.SaveChangesAsync(cancellationToken);
        return user;
    }

    public async Task<SubscriptionFeatureAccess> GetFeatureAccessAsync(Guid userId, string featureKey, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

        var planCode = NormalizeStoredPlanCode(user.PlanType);
        var plan = await _dbContext.SubscriptionPlans
            .AsNoTracking()
            .Include(x => x.Features)
            .FirstOrDefaultAsync(x => x.Code == planCode && x.IsActive, cancellationToken);

        if (plan is null)
        {
            plan = await GetPlanByCodeAsync(FreePlan, cancellationToken);
            planCode = plan.Code;
        }

        var normalizedFeatureKey = featureKey.Trim().ToLowerInvariant();
        var feature = plan.Features.FirstOrDefault(x => x.FeatureKey.Equals(normalizedFeatureKey, StringComparison.OrdinalIgnoreCase));
        if (feature is null)
        {
            return new SubscriptionFeatureAccess(planCode, normalizedFeatureKey, true, null, Array.Empty<string>(), false);
        }

        return new SubscriptionFeatureAccess(
            planCode,
            feature.FeatureKey,
            feature.IsEnabled,
            feature.MonthlyLimit,
            ParseAllowedValues(feature.AllowedValues),
            true);
    }

    private async Task<SubscriptionPlan> GetPlanByCodeAsync(string planCode, CancellationToken cancellationToken)
    {
        var normalized = NormalizeRequestedPlanCode(planCode);
        return await _dbContext.SubscriptionPlans
            .Include(x => x.Features)
            .FirstOrDefaultAsync(x => x.Code == normalized && x.IsActive, cancellationToken)
            ?? throw new AiFeatureException("PLAN_NOT_FOUND", $"Subscription plan '{normalized}' was not found.", 404);
    }

    private async Task<UserSubscription?> GetActiveSubscriptionAsync(Guid userId, CancellationToken cancellationToken)
    {
        return await _dbContext.UserSubscriptions
            .AsNoTracking()
            .Include(x => x.Plan)
            .Where(x => x.UserId == userId && x.Status == "active")
            .OrderByDescending(x => x.StartedAt)
            .FirstOrDefaultAsync(cancellationToken);
    }

    private async Task<CurrentSubscriptionDto> BuildCurrentDtoAsync(
        Guid userId,
        SubscriptionPlan plan,
        UserSubscription? activeSubscription,
        CancellationToken cancellationToken)
    {
        var periodStart = new DateTime(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var periodEnd = periodStart.AddMonths(1);
        var usageCounts = await _dbContext.AiUsageLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId && x.UsedAt >= periodStart && x.UsedAt < periodEnd)
            .GroupBy(x => x.FeatureName)
            .Select(x => new { FeatureKey = x.Key, Used = x.Count() })
            .ToDictionaryAsync(x => x.FeatureKey, x => x.Used, StringComparer.OrdinalIgnoreCase, cancellationToken);

        return new CurrentSubscriptionDto
        {
            Plan = ToPlanDto(plan),
            ActiveSubscription = activeSubscription is null ? null : ToSubscriptionDto(activeSubscription),
            UsagePeriodStart = periodStart,
            UsagePeriodEnd = periodEnd.AddTicks(-1),
            Usage = plan.Features
                .OrderBy(x => x.FeatureKey)
                .Select(feature =>
                {
                    var used = usageCounts.GetValueOrDefault(feature.FeatureKey);
                    return new SubscriptionUsageDto
                    {
                        FeatureKey = feature.FeatureKey,
                        DisplayName = feature.DisplayName,
                        Used = used,
                        MonthlyLimit = feature.MonthlyLimit,
                        Remaining = feature.IsEnabled && feature.MonthlyLimit.HasValue
                            ? Math.Max(0, feature.MonthlyLimit.Value - used)
                            : feature.IsEnabled ? null : 0,
                        IsUnlimited = feature.IsEnabled && !feature.MonthlyLimit.HasValue,
                        IsEnabled = feature.IsEnabled,
                        Unit = feature.Unit,
                        AllowedValues = ParseAllowedValues(feature.AllowedValues)
                    };
                })
                .ToList()
        };
    }

    private static SubscriptionPlanDto ToPlanDto(SubscriptionPlan plan)
    {
        return new SubscriptionPlanDto
        {
            Code = plan.Code,
            Name = plan.Name,
            Description = plan.Description,
            Price = plan.Price,
            Currency = plan.Currency,
            BillingPeriod = plan.BillingPeriod,
            IsActive = plan.IsActive,
            Features = plan.Features
                .OrderBy(x => x.FeatureKey)
                .Select(ToFeatureDto)
                .ToList()
        };
    }

    private static SubscriptionPlanFeatureDto ToFeatureDto(SubscriptionPlanFeature feature)
    {
        return new SubscriptionPlanFeatureDto
        {
            FeatureKey = feature.FeatureKey,
            DisplayName = feature.DisplayName,
            MonthlyLimit = feature.MonthlyLimit,
            IsUnlimited = feature.IsEnabled && !feature.MonthlyLimit.HasValue,
            IsEnabled = feature.IsEnabled,
            Unit = feature.Unit,
            AllowedValues = ParseAllowedValues(feature.AllowedValues)
        };
    }

    private static UserSubscriptionDto ToSubscriptionDto(UserSubscription subscription)
    {
        return new UserSubscriptionDto
        {
            SubscriptionId = subscription.Id,
            PlanCode = subscription.Plan.Code,
            Status = subscription.Status,
            StartedAt = subscription.StartedAt,
            EndsAt = subscription.EndsAt,
            CancelledAt = subscription.CancelledAt
        };
    }

    private static IReadOnlyCollection<string> ParseAllowedValues(string? raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return Array.Empty<string>();
        }

        try
        {
            return JsonSerializer.Deserialize<IReadOnlyCollection<string>>(raw) ?? Array.Empty<string>();
        }
        catch (JsonException)
        {
            return Array.Empty<string>();
        }
    }

    private static string NormalizeRequestedPlanCode(string? planCode)
    {
        var normalized = planCode?.Trim().ToLowerInvariant();
        if (normalized is FreePlan or PlusPlan or PremiumPlan)
        {
            return normalized;
        }

        throw new AiFeatureException("INVALID_PLAN", "Plan must be one of: free, plus, premium.", 400);
    }

    private static string NormalizeStoredPlanCode(string? planCode)
    {
        var normalized = planCode?.Trim().ToLowerInvariant();
        return normalized is PlusPlan or PremiumPlan ? normalized : FreePlan;
    }
}

public sealed record SubscriptionFeatureAccess(
    string PlanCode,
    string FeatureKey,
    bool IsEnabled,
    int? MonthlyLimit,
    IReadOnlyCollection<string> AllowedValues,
    bool IsConfigured);
