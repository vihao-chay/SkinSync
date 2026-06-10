using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SkinSync.Models.Dtos.Skin;

namespace SkinSync.Services.AI;

public class AiService : IAiService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly AiSettings _settings;
    private readonly ILogger<AiService> _logger;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    public AiService(
        IHttpClientFactory httpClientFactory,
        IOptions<AiSettings> settings,
        ILogger<AiService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _settings = settings.Value;
        _logger = logger;
    }

    public async Task<SkinAnalyzeResponseDto> AnalyzeSkinSync(
        byte[] imageBytes,
        string contentType,
        CancellationToken cancellationToken)
    {
        var base64Image = Convert.ToBase64String(imageBytes);
        var dataUrl = $"data:{contentType};base64,{base64Image}";

        var systemPrompt = 
            "You are a professional dermatologist AI assistant. " +
            "Analyze the skin image provided and return a structured JSON report. " +
            "Include 'skin_type' (Oily, Dry, Combination, Sensitive, Normal), " +
            "'acne_score' (0-100), 'oiliness_score' (0-100), 'redness_score' (0-100), " +
            "'pigmentation_score' (0-100), " +
            "and a list of 'concerns' (e.g. pores, blackheads, dry patches, wrinkles). " +
            "Return ONLY a JSON object matching this schema, without markdown backticks.";

        var requestBody = new
        {
            model = string.IsNullOrWhiteSpace(_settings.OpenAi.VisionModel) ? "gpt-4o" : _settings.OpenAi.VisionModel,
            messages = new[]
            {
                new
                {
                    role = "user",
                    content = new object[]
                    {
                        new { type = "text", text = systemPrompt },
                        new { type = "image_url", image_url = new { url = dataUrl } }
                    }
                }
            },
            response_format = new { type = "json_object" },
            max_tokens = 600
        };

        var responseJson = await CallOpenAiRawAsync(requestBody, cancellationToken);
        
        try
        {
            var result = JsonSerializer.Deserialize<SkinAnalyzeResponseDto>(responseJson, JsonOptions);
            if (result != null)
            {
                result.RawAiResponse = responseJson;
                return result;
            }
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Failed to deserialize OpenAI vision response: {Response}", responseJson);
        }

        throw new InvalidOperationException("Could not obtain structured skin analysis from AI.");
    }

    public async Task<SkinChatResponseDto> GetSkincareAdviceAsync(
        string message,
        UserSkinProfileDto? userProfile,
        CancellationToken cancellationToken)
    {
        var systemPrompt = new StringBuilder(
            "You are SkinSync's expert AI Skincare Assistant. " +
            "Answer in Vietnamese. " +
            "Only answer questions about facial skin, skincare routines, skincare ingredients, sunscreen, acne, oiliness, dryness, sensitivity, hyperpigmentation, pores, product selection, and safe non-prescription face-care habits. " +
            "If the user asks about anything outside facial skincare, politely say you only support facial skin and skincare questions, then suggest asking about their face skin concern. " +
            "Provide helpful, friendly, and non-medical skincare advice. " +
            "Do not prescribe prescription medications or provide clinical diagnoses. " +
            "Keep answers concise and practical. " +
            "If user skin information is provided, customize your advice to their profile.");

        if (userProfile != null)
        {
            systemPrompt.AppendLine($"\n[User Skin Profile]:");
            systemPrompt.AppendLine($"- Skin Type: {userProfile.SkinType}");
            if (userProfile.SkinConcerns?.Any() == true)
            {
                systemPrompt.AppendLine($"- Concerns: {string.Join(", ", userProfile.SkinConcerns)}");
            }
            if (!string.IsNullOrWhiteSpace(userProfile.MonthlyBudget))
            {
                systemPrompt.AppendLine($"- Budget Level: {userProfile.MonthlyBudget}");
            }
            if (userProfile.Age.HasValue)
            {
                systemPrompt.AppendLine($"- Age: {userProfile.Age.Value}");
            }
        }

        return await CallOpenAiChatAsync(message, systemPrompt.ToString(), cancellationToken);
    }

    public async Task<SkinRoutineResponseDto> BuildRoutineAsync(
        SkinRoutineRequestDto request,
        string systemInstructions,
        CancellationToken cancellationToken)
    {
        var prompt = $"Generate a customized AM/PM skincare routine for a user with {request.SkinType} skin. " +
                     $"Their skin concerns are: {string.Join(", ", request.Concerns)}. " +
                     $"Their budget is: {request.Budget}. " +
                     $"Ensure you avoid ingredient conflicts as detailed in the instructions. " +
                     $"You must respond in raw JSON format. Schema should contain 'routine' object with 'morning' and 'evening' arrays. " +
                     $"Each array item must have: 'step' (int), 'category' (string), 'product_recommendation' (string), 'instructions' (string), 'active_ingredients' (array of strings).";

        var requestBody = new
        {
            model = string.IsNullOrWhiteSpace(_settings.OpenAi.RoutineModel) ? "gpt-4o-mini" : _settings.OpenAi.RoutineModel,
            messages = new[]
            {
                new { role = "system", content = systemInstructions },
                new { role = "user", content = prompt }
            },
            response_format = new { type = "json_object" },
            max_tokens = 1200
        };

        var responseJson = await CallOpenAiRawAsync(requestBody, cancellationToken);

        try
        {
            var result = JsonSerializer.Deserialize<SkinRoutineResponseDto>(responseJson, JsonOptions);
            if (result != null)
            {
                result.RawAiResponse = responseJson;
                return result;
            }
        }
        catch (JsonException ex)
        {
            _logger.LogError(ex, "Failed to deserialize OpenAI routine response: {Response}", responseJson);
        }

        throw new InvalidOperationException("Could not obtain structured skincare routine from AI.");
    }

    private async Task<SkinChatResponseDto> CallOpenAiChatAsync(
        string message,
        string systemPrompt,
        CancellationToken cancellationToken)
    {
        var requestBody = new
        {
            model = string.IsNullOrWhiteSpace(_settings.OpenAi.ChatModel) ? "gpt-4o-mini" : _settings.OpenAi.ChatModel,
            messages = new[]
            {
                new { role = "system", content = systemPrompt },
                new { role = "user", content = message }
            },
            max_tokens = 800
        };

        var responseJson = await CallOpenAiRawAsync(requestBody, cancellationToken);
        using var doc = JsonDocument.Parse(responseJson);
        var reply = doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString() ?? string.Empty;

        return new SkinChatResponseDto
        {
            Response = reply,
            ProviderUsed = "OpenAI",
            ModelUsed = _settings.OpenAi.ChatModel
        };
    }

    private async Task<string> CallOpenAiRawAsync(object payload, CancellationToken cancellationToken)
    {
        return await ExecuteWithRetryAsync(async () =>
        {
            var client = _httpClientFactory.CreateClient("OpenAiClient");
            if (string.IsNullOrWhiteSpace(client.DefaultRequestHeaders.Authorization?.Parameter))
            {
                // Set Key on client dynamically if not set
                client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", _settings.OpenAi.ApiKey);
            }

            var response = await client.PostAsJsonAsync("chat/completions", payload, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                var errContent = await response.Content.ReadAsStringAsync(cancellationToken);
                _logger.LogError("OpenAI API error: {StatusCode} - {Content}", response.StatusCode, errContent);
                throw new HttpRequestException($"OpenAI API returned status code {response.StatusCode}: {errContent}");
            }

            return await response.Content.ReadAsStringAsync(cancellationToken);
        });
    }

    private async Task<T> ExecuteWithRetryAsync<T>(Func<Task<T>> action)
    {
        var attempts = 0;
        var retryCount = _settings.RetryCount > 0 ? _settings.RetryCount : 3;
        var delaySeconds = _settings.RetryDelaySeconds > 0 ? _settings.RetryDelaySeconds : 2;

        while (true)
        {
            attempts++;
            try
            {
                return await action();
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "API call attempt {Attempt} failed.", attempts);
                if (attempts >= retryCount)
                {
                    throw;
                }
                await Task.Delay(TimeSpan.FromSeconds(delaySeconds * attempts));
            }
        }
    }
}
