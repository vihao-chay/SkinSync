using System.Text;

namespace SkinSync.Services.AIPlatform;

public static class AiPromptLibrary
{
    public const string CommonSystemPrompt =
        """
        You are SkinSync AI, a skincare assistant inside the SkinSync application.
        Your role is to provide practical skincare guidance based on the user's context.
        Do not diagnose medical conditions or replace a dermatologist.
        Do not comment on attractiveness or identity.
        If symptoms seem severe, recommend seeing a dermatologist.
        Keep answers practical, safe, and concise.
        Return valid JSON only when JSON is requested.
        """;

    public static string BuildSkinAnalysisPrompt(string userProfileJson, string onboardingJson, string? userNote)
    {
        return $@"Analyze the user's facial skin image and skincare profile.

User profile:
{userProfileJson}

Onboarding answers:
{onboardingJson}

User note:
{(string.IsNullOrWhiteSpace(userNote) ? "No additional note." : userNote.Trim())}

Return JSON:
{{
  ""skinSummary"": ""string"",
  ""detectedConcerns"": [
    {{
      ""concern"": ""acne | dark_spots | dryness | oiliness | large_pores | redness | uneven_tone | sensitivity | unknown"",
      ""severity"": ""low | medium | high"",
      ""confidence"": 0.0,
      ""description"": ""string""
    }}
  ],
  ""recommendations"": [""string""],
  ""riskFlags"": [""possible_irritation | severe_acne | need_dermatologist | poor_image_quality""],
  ""disclaimer"": ""string""
}}";
    }

    public static string BuildRoutinePrompt(string userProfileJson, string latestAnalysisJson, string filteredProductsJson, string budgetJson, string routinePreference)
    {
        return $@"Create a personalized skincare routine for this user.

User profile:
{userProfileJson}

Latest AI skin analysis:
{latestAnalysisJson}

Available products:
{filteredProductsJson}

User budget:
{budgetJson}

Routine preference:
{routinePreference}

Use only available products and return JSON:
{{
  ""routineName"": ""string"",
  ""morning"": [
    {{
      ""stepOrder"": 1,
      ""stepName"": ""string"",
      ""productId"": ""uuid"",
      ""frequency"": ""daily | 2-3_times_per_week | weekly | as_needed"",
      ""instruction"": ""string"",
      ""aiReason"": ""string"",
      ""warning"": ""string""
    }}
  ],
  ""night"": [
    {{
      ""stepOrder"": 1,
      ""stepName"": ""string"",
      ""productId"": ""uuid"",
      ""frequency"": ""daily | 2-3_times_per_week | weekly | as_needed"",
      ""instruction"": ""string"",
      ""aiReason"": ""string"",
      ""warning"": ""string""
    }}
  ],
  ""missingCategories"": [""string""],
  ""overallAdvice"": ""string""
}}";
    }

    public static string BuildProductRecommendationPrompt(string userProfileJson, string concern, string category, string budgetJson, string candidatesJson)
    {
        return $@"Recommend skincare products for this user.

User profile:
{userProfileJson}

User concern:
{concern}

Product category requested:
{category}

Budget:
{budgetJson}

Candidate products:
{candidatesJson}

Return JSON:
{{
  ""recommendedProducts"": [
    {{
      ""productId"": ""uuid"",
      ""rank"": 1,
      ""matchScore"": 0,
      ""aiReason"": ""string"",
      ""warnings"": [""string""]
    }}
  ]
}}";
    }

    public static string BuildIngredientCheckPrompt(string userProfileJson, string productName, string ingredientsJson)
    {
        return $@"Evaluate this skincare product ingredient list for the user.

User profile:
{userProfileJson}

Product name:
{productName}

Ingredients:
{ingredientsJson}

Return JSON:
{{
  ""suitability"": ""suitable | caution | not_recommended"",
  ""beneficialIngredients"": [
    {{
      ""ingredient"": ""string"",
      ""reason"": ""string""
    }}
  ],
  ""cautionIngredients"": [
    {{
      ""ingredient"": ""string"",
      ""reason"": ""string""
    }}
  ],
  ""overallExplanation"": ""string"",
  ""usageSuggestion"": ""string"",
  ""warnings"": [""string""]
}}";
    }

    public static string BuildConflictPrompt(string userProfileJson, string routineJson, string conflictsJson)
    {
        return $@"Check ingredient conflicts in the user's skincare routine.

User profile:
{userProfileJson}

Routine:
{routineJson}

Detected rule-based conflicts:
{conflictsJson}

Return JSON:
{{
  ""hasConflict"": true,
  ""conflicts"": [
    {{
      ""ingredientA"": ""string"",
      ""ingredientB"": ""string"",
      ""severity"": ""low | medium | high"",
      ""reason"": ""string"",
      ""recommendation"": ""string""
    }}
  ],
  ""overallAdvice"": ""string""
}}";
    }

    public static string BuildChatPrompt(string userProfileJson, string currentRoutineJson, string latestAnalysisJson, string recentDailyLogsJson, string message)
    {
        return $@"You are SkinSync AI Chatbot.

User profile:
{userProfileJson}

Current routine:
{currentRoutineJson}

Latest skin analysis:
{latestAnalysisJson}

Recent daily logs:
{recentDailyLogsJson}

User message:
{message}

Return JSON:
{{
  ""reply"": ""string"",
  ""suggestedActions"": [""string""],
  ""needMoreInfo"": true,
  ""missingInfoQuestions"": [""string""],
  ""safetyWarning"": ""string""
}}";
    }

    public static string BuildReportPrompt(string userProfileJson, string aiAnalysesJson, string currentRoutineJson, string dailyLogsJson, string reportType)
    {
        return $@"Generate a skincare progress report for the user.

User profile:
{userProfileJson}

Previous AI analyses:
{aiAnalysesJson}

Current routine:
{currentRoutineJson}

Daily logs:
{dailyLogsJson}

Report type:
{reportType}

Return JSON:
{{
  ""summary"": ""string"",
  ""progressEvaluation"": ""improved | stable | worse | insufficient_data"",
  ""mainFindings"": [""string""],
  ""routineFeedback"": ""string"",
  ""productFeedback"": ""string"",
  ""nextPlan"": [""string""],
  ""warnings"": [""string""]
}}";
    }
}
