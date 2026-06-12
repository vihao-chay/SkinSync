using SkinSync.Models.Dtos.Admin;
using SkinSync.Models.Dtos.Auth;
using SkinSync.Models.Dtos.Users;
using SkinSync.Models.Entities;
using SkinSync.Helpers;

namespace SkinSync.Mappers;

public static class UserMapper
{
    public static AuthUserResponseDto ToAuthUserDto(this User user)
    {
        return new AuthUserResponseDto
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            AvatarUrl = user.AvatarUrl,
            Role = user.Role,
            Status = user.Status,
            PlanType = user.PlanType
        };
    }

    public static SurveyResponseDto ToSurveyDto(this UserProfile profile)
    {
        var payload = UserProfilePayloadHelper.Parse(profile.SkinConcerns);

        return new SurveyResponseDto
        {
            UserId = profile.UserId,
            DisplayName = payload.DisplayName ?? string.Empty,
            DateOfBirth = payload.DateOfBirth,
            Gender = payload.Gender ?? profile.Gender,
            HealthIssues = payload.HealthIssues,
            SkinType = profile.SkinType,
            MonthlyBudget = profile.MonthlyBudget,
            BudgetLabel = payload.BudgetLevel ?? profile.MonthlyBudget switch
            {
                null => null,
                <= 300000 => "Tiet kiem",
                <= 800000 => "Trung binh",
                _ => "Cao cap"
            },
            Concerns = payload.Concerns,
            CurrentRoutineLevel = payload.CurrentRoutineLevel,
            Goals = payload.Goals,
            Allergies = payload.Allergies,
            AvoidIngredients = payload.AvoidIngredients,
            SkinGoals = payload.SkinGoals,
            RednessWhenNewProducts = payload.RednessWhenNewProducts,
            RednessWhenSunOrExercise = payload.RednessWhenSunOrExercise,
            Age = profile.Age,
            BirthYear = profile.BirthYear,
            SensitivityLevel = profile.SensitivityLevel,
            IsOnboardingCompleted = IsOnboardingCompleted(profile, payload)
        };
    }

    private static bool IsOnboardingCompleted(UserProfile profile, UserProfilePayload payload)
    {
        return !string.IsNullOrWhiteSpace(payload.DisplayName)
            && !string.IsNullOrWhiteSpace(payload.DateOfBirth)
            && !string.IsNullOrWhiteSpace(payload.Gender)
            && !string.IsNullOrWhiteSpace(profile.SkinType)
            && !string.IsNullOrWhiteSpace(payload.BudgetLevel)
            && payload.Concerns.Count > 0
            && !string.IsNullOrWhiteSpace(payload.CurrentRoutineLevel)
            && payload.SkinGoals.Count > 0;
    }

    public static AdminUserItemDto ToAdminUserDto(this User user)
    {
        return new AdminUserItemDto
        {
            Id = user.Id,
            FullName = user.FullName,
            Email = user.Email,
            Phone = user.Phone,
            Role = user.Role,
            Status = user.Status,
            PlanType = user.PlanType,
            CreatedAt = user.CreatedAt
        };
    }
}
