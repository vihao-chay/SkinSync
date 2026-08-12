using System.Text;

namespace SkinSync.Services.Recommendations;

public static class RecommendationTextNormalizer
{
    public static string NormalizeKey(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return string.Empty;
        }

        var builder = new StringBuilder(value.Length);
        var previousWasSpace = false;

        foreach (var character in value.Trim().ToLowerInvariant())
        {
            if (char.IsLetterOrDigit(character))
            {
                builder.Append(character);
                previousWasSpace = false;
                continue;
            }

            if (previousWasSpace)
            {
                continue;
            }

            builder.Append(' ');
            previousWasSpace = true;
        }

        return builder.ToString().Trim();
    }

    public static bool MatchesAlias(string? source, IEnumerable<string> aliases)
    {
        var normalizedSource = NormalizeKey(source);
        if (string.IsNullOrWhiteSpace(normalizedSource))
        {
            return false;
        }

        foreach (var alias in aliases)
        {
            var normalizedAlias = NormalizeKey(alias);
            if (string.IsNullOrWhiteSpace(normalizedAlias))
            {
                continue;
            }

            if (normalizedSource.Equals(normalizedAlias, StringComparison.Ordinal) ||
                normalizedSource.Contains(normalizedAlias, StringComparison.Ordinal))
            {
                return true;
            }
        }

        return false;
    }

    public static bool SequenceContains(IEnumerable<string> source, string value)
    {
        var normalizedValue = NormalizeKey(value);
        return source.Any(item => NormalizeKey(item).Equals(normalizedValue, StringComparison.Ordinal));
    }

    public static IReadOnlyCollection<string> DistinctNormalized(IEnumerable<string> values)
    {
        return values
            .Where(value => !string.IsNullOrWhiteSpace(value))
            .Select(value => value.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();
    }
}
