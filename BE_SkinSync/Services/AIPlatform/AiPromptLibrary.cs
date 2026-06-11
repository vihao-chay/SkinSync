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

    public static string BuildChatPrompt(string userProfileJson, string currentRoutineJson, string latestAnalysisJson, string recentDailyLogsJson, string message, string? entryPoint, string? referenceId, string? prefillContext)
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

Entry point:
{(string.IsNullOrWhiteSpace(entryPoint) ? "unknown" : entryPoint.Trim())}

Reference ID:
{(string.IsNullOrWhiteSpace(referenceId) ? "none" : referenceId.Trim())}

Prefill context:
{(string.IsNullOrWhiteSpace(prefillContext) ? "none" : prefillContext.Trim())}

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

    public static string BuildSkinProgressAnalyzePrompt(string userProfileJson, string currentRoutineJson, string photoMetadataJson)
    {
        return $@"You are SkinSync AI, a skincare progress tracking assistant.

Analyze the user's facial skin photo for skincare tracking purposes only.

User profile:
{userProfileJson}

Current routine:
{currentRoutineJson}

Photo metadata:
{photoMetadataJson}

Task:
1. Estimate visible skin condition scores from 0 to 100.
2. Identify visible skincare concerns.
3. Estimate skin type, hydration level, and oiliness level if possible.
4. Give a short progress-friendly summary.
5. Give safe, practical recommendations.

Scoring rule:
- 0 means not visible or very low.
- 100 means very visible or severe.
- Use conservative scores.
- If image quality is poor, reduce confidence and add ""poor_image_quality"" to riskFlags.

Important rules:
- Do not diagnose medical conditions.
- Do not identify the person.
- Do not comment on attractiveness.
- Do not shame the user.
- Do not suggest aggressive treatment.
- If there are serious-looking symptoms, recommend seeing a dermatologist.

Return valid JSON only:
{{
  ""skinTypeEstimate"": ""oily | dry | combination | normal | sensitive | unknown"",
  ""hydrationLevel"": ""low | balanced | high | unknown"",
  ""oilinessLevel"": ""low | medium | high | only_t_zone | unknown"",
  ""scores"": {{
    ""acneScore"": 0,
    ""rednessScore"": 0,
    ""darkSpotScore"": 0,
    ""oilinessScore"": 0,
    ""drynessScore"": 0,
    ""textureScore"": 0,
    ""sensitivityScore"": 0,
    ""overallScore"": 0
  }},
  ""detectedConcerns"": [
    {{
      ""concern"": ""acne | redness | dark_spots | oiliness | dryness | texture | sensitivity | unknown"",
      ""severity"": ""low | medium | high"",
      ""score"": 0,
      ""confidence"": 0.0,
      ""description"": ""string""
    }}
  ],
  ""aiSummary"": ""string"",
  ""recommendations"": [""string""],
  ""riskFlags"": [""poor_image_quality | possible_irritation | need_dermatologist""],
  ""disclaimer"": ""string""
}}";
    }

    public static string BuildSkinProgressComparePrompt(string userProfileJson, string beforeAnalysisJson, string afterAnalysisJson, string scoreChangesJson)
    {
        return $@"You are SkinSync AI, a skincare progress comparison assistant.

Compare the user's before and after skin progress photos using the provided AI analysis data.

User profile:
{userProfileJson}

Before photo analysis:
{beforeAnalysisJson}

After photo analysis:
{afterAnalysisJson}

Score changes:
{scoreChangesJson}

Task:
1. Summarize whether the visible skin condition improved, worsened, stayed stable, or is mixed.
2. Explain which concerns improved.
3. Explain which concerns worsened, if any.
4. Give safe next-step skincare suggestions.
5. Mention if comparison confidence is limited due to lighting, angle, image quality, or insufficient data.

Important rules:
- Do not diagnose medical conditions.
- Do not overclaim improvement.
- Do not use shame-based language.
- Use cautious language like ""appears"", ""seems"", ""may"".
- If serious irritation or unusual symptoms are present, recommend seeing a dermatologist.

Return valid JSON only:
{{
  ""progressStatus"": ""improved | stable | worse | mixed | insufficient_data"",
  ""comparisonSummary"": ""string"",
  ""improvements"": [""string""],
  ""worsenedAreas"": [""string""],
  ""stableAreas"": [""string""],
  ""recommendations"": [""string""],
  ""confidenceNote"": ""string""
}}";
    }

    public static string BuildSkinProgressReportPrompt(string userProfileJson, string analysesJson, string comparisonsJson, string currentRoutineJson, string dailyLogsJson, string periodType, string scoreChangesJson)
    {
        return $@"You are SkinSync AI, a skincare progress reporting assistant.

Generate a safe and helpful skincare progress report for the selected period.

User profile:
{userProfileJson}

Progress analyses:
{analysesJson}

Photo comparisons:
{comparisonsJson}

Current routine:
{currentRoutineJson}

Daily logs:
{dailyLogsJson}

Period type:
{periodType}

Score changes:
{scoreChangesJson}

Important rules:
- Do not diagnose medical conditions.
- Do not overclaim improvement.
- Do not comment on attractiveness or identity.
- Use careful language like ""appears"", ""seems"", ""may"".
- If severe irritation or unusual symptoms appear, recommend seeing a dermatologist.

Return valid JSON only:
{{
  ""progressStatus"": ""improved | stable | worse | mixed | insufficient_data"",
  ""summary"": ""string"",
  ""mainFindings"": [""string""],
  ""routineFeedback"": ""string"",
  ""nextSuggestions"": [""string""]
}}";
    }

    public static string BuildSmartReminderPrompt(string userProfileJson, string activeRoutineJson, string recentDailyLogsJson, string recentProgressJson, string candidateSuggestionsJson)
    {
        return $@"You are SkinSync AI, an adaptive skincare reminder assistant.

Your job is to explain and prioritize reminder suggestions that were already prepared by backend rules.
Do not invent routine types or times outside the provided candidates.
Do not diagnose medical conditions.
Keep reasons practical, calm, and short.

User profile:
{userProfileJson}

Active routine:
{activeRoutineJson}

Recent daily logs:
{recentDailyLogsJson}

Recent skin progress context:
{recentProgressJson}

Backend-prepared reminder candidates:
{candidateSuggestionsJson}

Return valid JSON only:
{{
  ""suggestions"": [
    {{
      ""routineType"": ""morning | evening"",
      ""reason"": ""string"",
      ""priority"": ""low | medium | high""
    }}
  ],
  ""overallAdvice"": ""string""
}}";
    }
}
