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
            Status = user.Status
        };
    }

    public static SurveyResponseDto ToSurveyDto(this UserProfile profile)
    {
        var payload = UserProfilePayloadHelper.Parse(profile.SkinConcerns);

        return new SurveyResponseDto
        {
            UserId = profile.UserId,
            SkinType = profile.SkinType,
            MonthlyBudget = profile.MonthlyBudget,
            BudgetLabel = profile.MonthlyBudget switch
            {
                null => null,
                <= 300000 => "Tiet kiem",
                <= 800000 => "Trung binh",
                _ => "Cao cap"
            },
            Concerns = payload.Concerns,
            Goals = payload.Goals,
            Allergies = payload.Allergies,
            AvoidIngredients = payload.AvoidIngredients,
            Age = profile.Age,
            BirthYear = profile.BirthYear,
            Gender = profile.Gender,
            SensitivityLevel = profile.SensitivityLevel
        };
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
            CreatedAt = user.CreatedAt
        };
    }
}
