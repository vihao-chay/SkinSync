namespace SkinSync.Helpers;

public static class RoutineScheduleHelper
{
    public const string Morning = "morning";
    public const string Evening = "evening";

    public static string? NormalizeRoutineValue(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return value.Trim().ToLowerInvariant() switch
        {
            "morning" => Morning,
            "evening" => Evening,
            _ => null
        };
    }

    public static bool IsMorning(string? value) =>
        string.Equals(NormalizeRoutineValue(value), Morning, StringComparison.Ordinal);

    public static bool IsEvening(string? value) =>
        string.Equals(NormalizeRoutineValue(value), Evening, StringComparison.Ordinal);
}
