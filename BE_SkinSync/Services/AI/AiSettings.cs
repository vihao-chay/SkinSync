namespace SkinSync.Services.AI;

public class AiSettings
{
    public OpenAiSettings OpenAi { get; set; } = new();
    public int RetryCount { get; set; } = 3;
    public int RetryDelaySeconds { get; set; } = 2;
}

public class OpenAiSettings
{
    public string ApiKey { get; set; } = string.Empty;
    public string BaseUrl { get; set; } = "https://api.openai.com/v1";
    public string VisionModel { get; set; } = "gpt-4o";
    public string ChatModel { get; set; } = "gpt-4o-mini";
    public string RoutineModel { get; set; } = "gpt-4o-mini";
}
