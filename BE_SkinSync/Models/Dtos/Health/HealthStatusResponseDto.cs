using System.Text.Json.Serialization;

namespace SkinSync.Models.Dtos.Health;

public sealed class HealthStatusResponseDto
{
    [JsonPropertyName("status")]
    public string Status { get; set; } = string.Empty;

    [JsonPropertyName("service")]
    public string? Service { get; set; }

    [JsonPropertyName("database")]
    public string? Database { get; set; }

    [JsonPropertyName("provider")]
    public string? Provider { get; set; }

    [JsonPropertyName("error")]
    public string? Error { get; set; }

    [JsonPropertyName("timestamp")]
    public DateTime Timestamp { get; set; }
}
