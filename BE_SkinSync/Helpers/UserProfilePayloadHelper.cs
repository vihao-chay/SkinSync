using System.Text.Json;

namespace SkinSync.Helpers;

public sealed class UserProfilePayload
{
    public List<string> Concerns { get; set; } = [];
    public List<string> Goals { get; set; } = [];
    public List<string> Allergies { get; set; } = [];
    public List<string> AvoidIngredients { get; set; } = [];
}

public static class UserProfilePayloadHelper
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static UserProfilePayload Parse(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return new UserProfilePayload();
        }

        try
        {
            if (value.TrimStart().StartsWith("[", StringComparison.Ordinal))
            {
                var concerns = JsonSerializer.Deserialize<List<string>>(value, JsonOptions) ?? [];
                return new UserProfilePayload { Concerns = concerns };
            }

            return JsonSerializer.Deserialize<UserProfilePayload>(value, JsonOptions) ?? new UserProfilePayload();
        }
        catch (JsonException)
        {
            return new UserProfilePayload
            {
                Concerns = value
                    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                    .ToList()
            };
        }
    }

    public static string Serialize(UserProfilePayload payload)
    {
        return JsonSerializer.Serialize(payload, JsonOptions);
    }
}
