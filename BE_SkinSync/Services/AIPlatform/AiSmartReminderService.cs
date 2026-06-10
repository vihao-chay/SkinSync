using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Npgsql;
using SkinSync.Data;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Entities;
using SkinSync.Services.AI;

namespace SkinSync.Services.AIPlatform;

public interface IAiSmartReminderService
{
    Task<AiReminderSuggestResponseDto> SuggestAsync(Guid userId, AiReminderSuggestRequestDto request, CancellationToken cancellationToken);
}

public class AiSmartReminderService : IAiSmartReminderService
{
    private static readonly TimeOnly MorningMin = new(5, 30);
    private static readonly TimeOnly MorningMax = new(10, 0);
    private static readonly TimeOnly EveningMin = new(18, 0);
    private static readonly TimeOnly EveningMax = new(23, 30);

    private readonly AppDbContext _dbContext;
    private readonly IOpenAiService _openAiService;
    private readonly IAiUsageService _aiUsageService;
    private readonly AiSettings _settings;

    public AiSmartReminderService(
        AppDbContext dbContext,
        IOpenAiService openAiService,
        IAiUsageService aiUsageService,
        IOptions<AiSettings> settings)
    {
        _dbContext = dbContext;
        _openAiService = openAiService;
        _aiUsageService = aiUsageService;
        _settings = settings.Value;
    }

    public async Task<AiReminderSuggestResponseDto> SuggestAsync(Guid userId, AiReminderSuggestRequestDto request, CancellationToken cancellationToken)
    {
        try
        {
            return await SuggestInternalAsync(userId, request, cancellationToken);
        }
        catch (PostgresException ex) when (ex.SqlState == PostgresErrorCodes.UndefinedTable)
        {
            throw new AiFeatureException("AI_REMINDER_SCHEMA_MISSING", "Reminder schema is missing. Apply the latest migrations before using AI reminders.", 503, ex);
        }
    }

    private async Task<AiReminderSuggestResponseDto> SuggestInternalAsync(Guid userId, AiReminderSuggestRequestDto request, CancellationToken cancellationToken)
    {
        var user = await _dbContext.Users
            .AsNoTracking()
            .Include(x => x.Profile)
            .FirstOrDefaultAsync(x => x.Id == userId, cancellationToken)
            ?? throw new AiFeatureException("USER_NOT_FOUND", "User not found.", 404);

        var activeRegimen = await _dbContext.UserRegimens
            .AsNoTracking()
            .Include(x => x.Items)
            .ThenInclude(x => x.Product)
            .FirstOrDefaultAsync(x => x.UserId == userId && x.IsActive, cancellationToken);

        if (activeRegimen is null || activeRegimen.Items.Count == 0)
        {
            throw new AiFeatureException("INSUFFICIENT_DATA", "Generate an active routine before optimizing reminders.", 400);
        }

        await _aiUsageService.CheckLimitAsync(userId, "smart_reminder", cancellationToken);

        var reminders = await _dbContext.Reminders
            .Where(x => x.UserId == userId)
            .ToListAsync(cancellationToken);

        var recentTrackings = await _dbContext.RoutineTrackings
            .AsNoTracking()
            .Include(x => x.Step)
            .Where(x => x.UserId == userId && x.CompletedAt >= DateTime.UtcNow.AddDays(-14))
            .ToListAsync(cancellationToken);

        var recentLogs = await _dbContext.DailyLogs
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.Date)
            .Take(14)
            .ToListAsync(cancellationToken);

        var recentProgress = await _dbContext.SkinProgressAnalyses
            .AsNoTracking()
            .Where(x => x.UserId == userId)
            .OrderByDescending(x => x.CreatedAt)
            .Take(3)
            .Select(x => new
            {
                x.CreatedAt,
                x.SkinTypeEstimate,
                x.HydrationLevel,
                x.OilinessLevel,
                x.OverallScore,
                x.RiskFlags,
                x.AiSummary
            })
            .ToListAsync(cancellationToken);

        var candidates = BuildCandidates(activeRegimen, reminders, recentTrackings, recentLogs);
        if (candidates.Count == 0)
        {
            throw new AiFeatureException("INSUFFICIENT_DATA", "No routine steps were found for reminder optimization.", 400);
        }

        var aiResult = await _openAiService.GenerateJsonAsync<AiReminderAiResult>(
            AiPromptLibrary.CommonSystemPrompt,
            AiPromptLibrary.BuildSmartReminderPrompt(
                AiContextMapper.SerializeUserProfile(user.Profile),
                JsonSerializer.Serialize(activeRegimen.ToCurrentRegimenDto()),
                AiContextMapper.SerializeDailyLogs(recentLogs),
                JsonSerializer.Serialize(recentProgress),
                JsonSerializer.Serialize(candidates.Select(x => new
                {
                    x.RoutineType,
                    Time = x.Time.ToString("HH:mm"),
                    x.Frequency,
                    x.Priority,
                    x.IsAdaptive,
                    x.AdherenceRate,
                    x.ContextNote
                }))),
            model: _settings.OpenAi.ReminderModel,
            cancellationToken: cancellationToken);

        var suggestions = MergeSuggestions(candidates, aiResult.Value);

        if (request.ApplySuggestions)
        {
            foreach (var suggestion in suggestions)
            {
                var reminder = reminders.FirstOrDefault(x => x.RoutineType == suggestion.RoutineType);
                if (reminder is null)
                {
                    reminder = new Reminder
                    {
                        Id = Guid.NewGuid(),
                        UserId = userId,
                        RoutineType = suggestion.RoutineType,
                        CreatedAt = DateTime.UtcNow
                    };
                    _dbContext.Reminders.Add(reminder);
                }

                reminder.Time = TimeOnly.Parse(suggestion.Time);
                reminder.Frequency = suggestion.Frequency;
                reminder.Reason = suggestion.Reason;
                reminder.Priority = suggestion.Priority;
                reminder.IsAdaptive = suggestion.IsAdaptive;
                reminder.IsEnabled = suggestion.IsEnabled;
                reminder.UpdatedAt = DateTime.UtcNow;
            }

            await _dbContext.SaveChangesAsync(cancellationToken);
        }

        await _aiUsageService.LogUsageAsync(userId, "smart_reminder", aiResult.Model, aiResult.InputTokens, aiResult.OutputTokens, cancellationToken);

        return new AiReminderSuggestResponseDto
        {
            Suggestions = suggestions,
            OverallAdvice = string.IsNullOrWhiteSpace(aiResult.Value.OverallAdvice)
                ? "Keep reminders aligned with the times you can realistically follow every day."
                : aiResult.Value.OverallAdvice.Trim()
        };
    }

    private static List<ReminderCandidate> BuildCandidates(
        UserRegimen activeRegimen,
        IReadOnlyCollection<Reminder> reminders,
        IReadOnlyCollection<RoutineTracking> recentTrackings,
        IReadOnlyCollection<DailyLog> recentLogs)
    {
        var results = new List<ReminderCandidate>();
        foreach (var routineType in new[] { "Morning", "Evening" })
        {
            var steps = activeRegimen.Items
                .Where(x => string.Equals(x.RoutineTime, routineType, StringComparison.OrdinalIgnoreCase))
                .ToList();
            if (steps.Count == 0)
            {
                continue;
            }

            var existing = reminders.FirstOrDefault(x => x.RoutineType == routineType);
            var trackingTimes = recentTrackings
                .Where(x => string.Equals(x.Step.RoutineTime, routineType, StringComparison.OrdinalIgnoreCase))
                .Select(x => TimeOnly.FromDateTime(x.CompletedAt))
                .ToList();

            var adherenceRate = CalculateAdherenceRate(recentLogs, routineType);
            var suggestedTime = ResolveSuggestedTime(routineType, existing?.Time, trackingTimes, adherenceRate);
            var isAdaptive = existing is null || existing.Time != suggestedTime || existing.IsAdaptive;
            var priority = adherenceRate < 0.45m ? "high" : adherenceRate < 0.75m ? "medium" : "low";
            var contextNote = BuildContextNote(routineType, steps.Count, adherenceRate, existing?.Time, suggestedTime);

            results.Add(new ReminderCandidate(
                routineType,
                suggestedTime,
                existing?.Frequency ?? "daily",
                priority,
                isAdaptive,
                existing?.IsEnabled ?? true,
                adherenceRate,
                contextNote));
        }

        return results;
    }

    private static decimal CalculateAdherenceRate(IReadOnlyCollection<DailyLog> recentLogs, string routineType)
    {
        if (recentLogs.Count == 0)
        {
            return 0.5m;
        }

        var completedDays = recentLogs.Count(x => string.Equals(routineType, "Morning", StringComparison.OrdinalIgnoreCase)
            ? x.MorningCompleted
            : x.EveningCompleted);

        return Math.Round((decimal)completedDays / recentLogs.Count, 2);
    }

    private static TimeOnly ResolveSuggestedTime(string routineType, TimeOnly? existingTime, IReadOnlyCollection<TimeOnly> trackingTimes, decimal adherenceRate)
    {
        var baseline = existingTime ?? (string.Equals(routineType, "Morning", StringComparison.OrdinalIgnoreCase)
            ? new TimeOnly(7, 0)
            : new TimeOnly(21, 0));

        var suggested = trackingTimes.Count >= 3
            ? RoundToQuarterHour(AverageTime(trackingTimes))
            : baseline;

        if (trackingTimes.Count < 3)
        {
            if (string.Equals(routineType, "Morning", StringComparison.OrdinalIgnoreCase) && adherenceRate < 0.45m)
            {
                suggested = baseline.Add(TimeSpan.FromMinutes(30));
            }
            else if (string.Equals(routineType, "Evening", StringComparison.OrdinalIgnoreCase) && adherenceRate < 0.45m)
            {
                suggested = baseline.Add(TimeSpan.FromMinutes(-30));
            }
        }

        return ClampTime(routineType, suggested);
    }

    private static string BuildContextNote(string routineType, int stepCount, decimal adherenceRate, TimeOnly? existingTime, TimeOnly suggestedTime)
    {
        var parts = new List<string>
        {
            $"{routineType} routine has {stepCount} step(s).",
            $"Recent adherence is {(adherenceRate * 100):0}%."
        };

        if (existingTime.HasValue)
        {
            parts.Add($"Existing reminder is {existingTime.Value:HH\\:mm}.");
        }

        parts.Add($"Backend suggests {suggestedTime:HH\\:mm}.");
        return string.Join(" ", parts);
    }

    private static List<AiReminderSuggestionDto> MergeSuggestions(List<ReminderCandidate> candidates, AiReminderAiResult aiResult)
    {
        var mappedSuggestions = (aiResult.Suggestions ?? Array.Empty<AiReminderAiSuggestion>())
            .GroupBy(x => NormalizeRoutineType(x.RoutineType))
            .Where(x => x.Key is not null)
            .ToDictionary(x => x.Key!, x => x.First(), StringComparer.OrdinalIgnoreCase);

        return candidates.Select(candidate =>
        {
            mappedSuggestions.TryGetValue(candidate.RoutineType, out var aiSuggestion);
            return new AiReminderSuggestionDto
            {
                RoutineType = candidate.RoutineType,
                Time = candidate.Time.ToString("HH:mm"),
                Frequency = candidate.Frequency,
                Reason = string.IsNullOrWhiteSpace(aiSuggestion?.Reason)
                    ? candidate.ContextNote
                    : aiSuggestion!.Reason.Trim(),
                Priority = NormalizePriority(aiSuggestion?.Priority) ?? candidate.Priority,
                IsAdaptive = candidate.IsAdaptive,
                IsEnabled = candidate.IsEnabled
            };
        }).ToList();
    }

    private static string? NormalizeRoutineType(string? routineType)
    {
        if (string.IsNullOrWhiteSpace(routineType))
        {
            return null;
        }

        return routineType.Trim().ToLowerInvariant() switch
        {
            "morning" => "Morning",
            "evening" => "Evening",
            _ => null
        };
    }

    private static string? NormalizePriority(string? priority)
    {
        if (string.IsNullOrWhiteSpace(priority))
        {
            return null;
        }

        return priority.Trim().ToLowerInvariant() switch
        {
            "low" => "low",
            "medium" => "medium",
            "high" => "high",
            _ => null
        };
    }

    private static TimeOnly AverageTime(IReadOnlyCollection<TimeOnly> times)
    {
        var averageMinutes = times.Average(x => x.Hour * 60 + x.Minute);
        return new TimeOnly((int)averageMinutes / 60, (int)Math.Round(averageMinutes % 60));
    }

    private static TimeOnly RoundToQuarterHour(TimeOnly time)
    {
        var totalMinutes = time.Hour * 60 + time.Minute;
        var roundedMinutes = (int)Math.Round(totalMinutes / 15d) * 15;
        roundedMinutes = Math.Clamp(roundedMinutes, 0, (24 * 60) - 1);
        return new TimeOnly(roundedMinutes / 60, roundedMinutes % 60);
    }

    private static TimeOnly ClampTime(string routineType, TimeOnly time)
    {
        if (string.Equals(routineType, "Morning", StringComparison.OrdinalIgnoreCase))
        {
            return time < MorningMin ? MorningMin : time > MorningMax ? MorningMax : time;
        }

        return time < EveningMin ? EveningMin : time > EveningMax ? EveningMax : time;
    }

    private sealed record ReminderCandidate(
        string RoutineType,
        TimeOnly Time,
        string Frequency,
        string Priority,
        bool IsAdaptive,
        bool IsEnabled,
        decimal AdherenceRate,
        string ContextNote);

    private sealed class AiReminderAiResult
    {
        public IReadOnlyCollection<AiReminderAiSuggestion> Suggestions { get; set; } = Array.Empty<AiReminderAiSuggestion>();
        public string OverallAdvice { get; set; } = string.Empty;
    }

    private sealed class AiReminderAiSuggestion
    {
        public string RoutineType { get; set; } = string.Empty;
        public string Reason { get; set; } = string.Empty;
        public string Priority { get; set; } = "medium";
    }
}
