using System.Text.Json.Serialization;

namespace SkinSync.Models.Dtos.Skin;

public class SkinAnalyzeResponseDto
{
    [JsonPropertyName("skin_type")]
    public string SkinType { get; set; } = string.Empty;

    [JsonPropertyName("acne_score")]
    public int AcneScore { get; set; }

    [JsonPropertyName("oiliness_score")]
    public int OilinessScore { get; set; }

    [JsonPropertyName("redness_score")]
    public int RednessScore { get; set; }

    [JsonPropertyName("pigmentation_score")]
    public int PigmentationScore { get; set; }

    [JsonPropertyName("concerns")]
    public List<string> Concerns { get; set; } = new();

    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? RawAiResponse { get; set; }
}
