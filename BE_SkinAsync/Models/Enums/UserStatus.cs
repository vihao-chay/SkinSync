namespace SkinAsync.Models.Enums;

public enum UserStatus
{
    Active,
    Inactive,
    Banned
}

public static class UserStatusExtensions
{
    public static string ToDbValue(this UserStatus status)
    {
        return status.ToString().ToLowerInvariant();
    }

    public static UserStatus FromDbValue(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return UserStatus.Inactive;
        }

        return Enum.TryParse<UserStatus>(value, true, out var parsed)
            ? parsed
            : UserStatus.Inactive;
    }

    public static bool TryParseFromRequest(string? value, out UserStatus status)
    {
        status = UserStatus.Inactive;
        if (string.IsNullOrWhiteSpace(value))
        {
            return false;
        }

        return Enum.TryParse(value.Trim(), true, out status);
    }
}