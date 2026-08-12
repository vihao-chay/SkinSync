namespace SkinSync.Helpers;

public static class AppClock
{
    private static readonly TimeSpan AppUtcOffset = TimeSpan.FromHours(7);

    public static DateTime UtcNow => DateTime.UtcNow;

    public static DateTime LocalNow => DateTime.UtcNow.Add(AppUtcOffset);

    public static DateOnly Today => DateOnly.FromDateTime(LocalNow.Date);
}
