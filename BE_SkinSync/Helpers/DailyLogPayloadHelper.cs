using System.Text.Json;

namespace SkinSync.Helpers;

public sealed class DailyLogPayload
{
    public string? Note { get; set; }
    public int? AcneLevel { get; set; }
    public int? DrynessLevel { get; set; }
    public int? RednessLevel { get; set; }
    public int? IrritationLevel { get; set; }
    public int? HydrationLevel { get; set; }
}

public static class DailyLogPayloadHelper
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public static DailyLogPayload Parse(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return new DailyLogPayload();
        }

        try
        {
            return JsonSerializer.Deserialize<DailyLogPayload>(value, JsonOptions) ?? new DailyLogPayload { Note = value };
        }
        catch (JsonException)
        {
            return new DailyLogPayload { Note = value };
        }
    }

    public static string Serialize(DailyLogPayload payload)
    {
        return JsonSerializer.Serialize(payload, JsonOptions);
    }
}
