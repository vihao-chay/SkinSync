using System.Text.Json;
using SkinSync.Helpers;
using SkinSync.Models.Dtos.Analysis;
using SkinSync.Models.Entities;

namespace SkinSync.Services.AIPlatform;

internal static class AiContextMapper
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static string SerializeUserProfile(UserProfile? profile)
    {
        if (profile is null)
        {
            return "{}";
        }

        var payload = UserProfilePayloadHelper.Parse(profile.SkinConcerns);
        var body = new
        {
            skinType = profile.SkinType ?? "unknown",
            concerns = payload.Concerns,
            allergies = JsonListHelper.ParseStringList(profile.Allergies).DefaultIfEmpty().ToArray(),
            sensitiveIngredients = JsonListHelper.ParseStringList(profile.SensitiveIngredients).DefaultIfEmpty().ToArray(),
            skinGoals = JsonListHelper.ParseStringList(profile.SkinGoals).DefaultIfEmpty().ToArray(),
            monthlyBudget = profile.MonthlyBudget,
            gender = profile.Gender ?? payload.Gender,
            age = profile.Age,
            sensitivityLevel = profile.SensitivityLevel,
            routinePreference = profile.RoutinePreference ?? payload.CurrentRoutineLevel
        };

        return JsonSerializer.Serialize(body, JsonOptions);
    }

    public static string SerializeOnboarding(UserProfile? profile)
    {
        var payload = UserProfilePayloadHelper.Parse(profile?.SkinConcerns);
        var body = new
        {
            displayName = payload.DisplayName,
            concerns = payload.Concerns,
            goals = payload.Goals,
            allergies = payload.Allergies,
            avoidIngredients = payload.AvoidIngredients,
            skinGoals = payload.SkinGoals,
            budgetLevel = payload.BudgetLevel,
            routineLevel = payload.CurrentRoutineLevel,
            rednessWhenNewProducts = payload.RednessWhenNewProducts,
            rednessWhenSunOrExercise = payload.RednessWhenSunOrExercise
        };
        return JsonSerializer.Serialize(body, JsonOptions);
    }

    public static string SerializeAnalysis(AnalysisDetailResponseDto? analysis)
    {
        return JsonSerializer.Serialize(analysis ?? new AnalysisDetailResponseDto(), JsonOptions);
    }

    public static string SerializeProducts(IEnumerable<object> products)
    {
        return JsonSerializer.Serialize(products, JsonOptions);
    }

    public static string SerializeDailyLogs(IEnumerable<DailyLog> logs)
    {
        var body = logs.Select(x => new
        {
            date = x.Date,
            skinFeeling = x.SkinFeeling,
            irritated = x.IsIrritated,
            notes = x.Notes,
            morningCompleted = x.MorningCompleted,
            eveningCompleted = x.EveningCompleted
        });

        return JsonSerializer.Serialize(body, JsonOptions);
    }

    public static string SerializeList(IEnumerable<string> items)
    {
        return JsonSerializer.Serialize(items, JsonOptions);
    }
}
