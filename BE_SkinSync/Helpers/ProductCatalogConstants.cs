namespace SkinSync.Helpers;

public static class ProductCatalogConstants
{
    public static readonly string[] AllowedCategories =
    [
        "Cleanser",
        "Toner",
        "Serum",
        "Moisturizer",
        "Sunscreen",
        "Treatment",
        "Mask",
        "Exfoliant",
        "Eye Care",
        "Oil",
        "Mist",
        "Balm",
        "Other"
    ];

    public static readonly string[] AllowedUsageTimes =
    [
        "Morning",
        "Night",
        "Both"
    ];

    public const string SourceSkinSafe = "SkinSAFE";
    public const string ProductCsvDefaultPath = "Data/Import/skinsync_skinsafe_filtered.csv";

    public static bool IsAllowedCategory(string? value)
        => AllowedCategories.Contains(value?.Trim() ?? string.Empty, StringComparer.OrdinalIgnoreCase);

    public static bool IsAllowedUsageTime(string? value)
        => string.IsNullOrWhiteSpace(value) || AllowedUsageTimes.Contains(value.Trim(), StringComparer.OrdinalIgnoreCase);

    public static string NormalizeCategory(string? value)
    {
        var match = AllowedCategories.FirstOrDefault(item => string.Equals(item, value?.Trim(), StringComparison.OrdinalIgnoreCase));
        return match ?? string.Empty;
    }

    public static string NormalizeUsageTime(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var match = AllowedUsageTimes.FirstOrDefault(item => string.Equals(item, value.Trim(), StringComparison.OrdinalIgnoreCase));
        return match ?? string.Empty;
    }

    public static bool IsValidHttpUrl(string? value)
        => Uri.TryCreate(value, UriKind.Absolute, out var uri)
           && (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps);

    public static string NormalizeStatusForActiveFlag(string currentStatus, bool isActive)
    {
        if (!isActive)
        {
            return string.Equals(currentStatus, "out_of_stock", StringComparison.OrdinalIgnoreCase)
                ? "out_of_stock"
                : "inactive";
        }

        return "active";
    }
}
