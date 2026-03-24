using SkinAsync.Models.Dtos.Admin;
using SkinAsync.Models.Dtos.Auth;
using SkinAsync.Models.Dtos.Users;
using SkinAsync.Models.Entities;

namespace SkinAsync.Mappers;

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
            Role = user.Role,
            Status = user.Status
        };
    }

    public static SurveyResponseDto ToSurveyDto(this UserProfile profile)
    {
        return new SurveyResponseDto
        {
            UserId = profile.UserId,
            SkinType = profile.SkinType,
            SkinConcerns = profile.SkinConcerns,
            MonthlyBudget = profile.MonthlyBudget,
            Age = profile.Age,
            BirthYear = profile.BirthYear
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
