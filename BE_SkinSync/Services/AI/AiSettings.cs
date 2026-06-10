namespace SkinSync.Services.AI;

public class AiSettings
{
    public OpenAiSettings OpenAi { get; set; } = new();
    public int RetryCount { get; set; } = 3;
    public int RetryDelaySeconds { get; set; } = 2;
    public int TimeoutSeconds { get; set; } = 60;
    public AiQuotaSettings Quotas { get; set; } = new();
}

public class OpenAiSettings
{
    public string ApiKey { get; set; } = string.Empty;
    public string BaseUrl { get; set; } = "https://api.openai.com/v1";
    public string VisionModel { get; set; } = "gpt-4o";
    public string ChatModel { get; set; } = "gpt-4o-mini";
    public string RoutineModel { get; set; } = "gpt-4o-mini";
    public string ProductModel { get; set; } = "gpt-4o-mini";
    public string IngredientModel { get; set; } = "gpt-4o-mini";
    public string ReportModel { get; set; } = "gpt-4o-mini";
    public string ConflictModel { get; set; } = "gpt-4o-mini";
    public double Temperature { get; set; } = 0.2d;
}

public class AiQuotaSettings
{
    public Dictionary<string, int> FreePlanMonthlyLimits { get; set; } = new(StringComparer.OrdinalIgnoreCase)
    {
        ["skin_analysis"] = 3,
        ["skin_progress_analysis"] = 12,
        ["skin_progress_compare"] = 12,
        ["skin_progress_report"] = 4,
        ["ai_chat"] = 20,
        ["routine_generation"] = 1,
        ["product_recommendation"] = 10,
        ["ingredient_check"] = 10,
        ["report_generation"] = 1,
        ["conflict_check"] = 5
    };

    public Dictionary<string, int> PremiumPlanMonthlyLimits { get; set; } = new(StringComparer.OrdinalIgnoreCase)
    {
        ["skin_analysis"] = 1000,
        ["skin_progress_analysis"] = 1000,
        ["skin_progress_compare"] = 1000,
        ["skin_progress_report"] = 200,
        ["ai_chat"] = 1000,
        ["routine_generation"] = 100,
        ["product_recommendation"] = 1000,
        ["ingredient_check"] = 1000,
        ["report_generation"] = 100,
        ["conflict_check"] = 100
    };
}
