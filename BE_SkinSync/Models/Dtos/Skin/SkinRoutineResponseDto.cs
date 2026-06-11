using System.Text.Json.Serialization;

namespace SkinSync.Models.Dtos.Skin;

public class SkinRoutineResponseDto
{
    [JsonPropertyName("routine")]
    public RoutineDto Routine { get; set; } = new();

    [JsonIgnore(Condition = JsonIgnoreCondition.WhenWritingNull)]
    public string? RawAiResponse { get; set; }
}

public class RoutineDto
{
    [JsonPropertyName("morning")]
    public List<RoutineStepDto> Morning { get; set; } = new();

    [JsonPropertyName("evening")]
    public List<RoutineStepDto> Evening { get; set; } = new();
}

public class RoutineStepDto
{
    [JsonPropertyName("step")]
    public int Step { get; set; }

    [JsonPropertyName("category")]
    public string Category { get; set; } = string.Empty;

    [JsonPropertyName("product_recommendation")]
    public string ProductRecommendation { get; set; } = string.Empty;

    [JsonPropertyName("instructions")]
    public string Instructions { get; set; } = string.Empty;

    [JsonPropertyName("active_ingredients")]
    public List<string> ActiveIngredients { get; set; } = new();
}
