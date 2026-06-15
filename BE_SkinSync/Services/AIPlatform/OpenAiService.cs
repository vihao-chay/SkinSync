using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Options;
using SkinSync.Services.AI;

namespace SkinSync.Services.AIPlatform;

public interface IOpenAiService
{
    Task<OpenAiResult<T>> GenerateJsonAsync<T>(string systemPrompt, string userPrompt, string? model = null, CancellationToken cancellationToken = default);
    Task<OpenAiResult<T>> AnalyzeImageAsync<T>(string systemPrompt, string userPrompt, string imageUrl, string? model = null, CancellationToken cancellationToken = default);
    Task<OpenAiResult<string>> GenerateTextAsync(string systemPrompt, string userPrompt, string? model = null, CancellationToken cancellationToken = default);
}

public sealed class OpenAiService : IOpenAiService
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        DefaultIgnoreCondition = JsonIgnoreCondition.WhenWritingNull
    };

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly AiSettings _settings;
    private readonly ILogger<OpenAiService> _logger;

    public OpenAiService(
        IHttpClientFactory httpClientFactory,
        IOptions<AiSettings> settings,
        ILogger<OpenAiService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _settings = settings.Value;
        _logger = logger;
    }

    public Task<OpenAiResult<T>> GenerateJsonAsync<T>(string systemPrompt, string userPrompt, string? model = null, CancellationToken cancellationToken = default)
    {
        var payload = new
        {
            model = ResolveModel(model, _settings.OpenAi.ChatModel),
            temperature = _settings.OpenAi.Temperature,
            response_format = new { type = "json_object" },
            messages = new object[]
            {
                new { role = "system", content = systemPrompt },
                new { role = "user", content = userPrompt }
            }
        };

        return ExecuteJsonAsync<T>(payload, cancellationToken);
    }

    public Task<OpenAiResult<T>> AnalyzeImageAsync<T>(string systemPrompt, string userPrompt, string imageUrl, string? model = null, CancellationToken cancellationToken = default)
    {
        var payload = new
        {
            model = ResolveModel(model, _settings.OpenAi.VisionModel),
            temperature = _settings.OpenAi.Temperature,
            response_format = new { type = "json_object" },
            messages = new object[]
            {
                new
                {
                    role = "system",
                    content = systemPrompt
                },
                new
                {
                    role = "user",
                    content = new object[]
                    {
                        new { type = "text", text = userPrompt },
                        new { type = "image_url", image_url = new { url = imageUrl } }
                    }
                }
            }
        };

        return ExecuteJsonAsync<T>(payload, cancellationToken);
    }

    public async Task<OpenAiResult<string>> GenerateTextAsync(string systemPrompt, string userPrompt, string? model = null, CancellationToken cancellationToken = default)
    {
        var payload = new
        {
            model = ResolveModel(model, _settings.OpenAi.ChatModel),
            temperature = _settings.OpenAi.Temperature,
            messages = new object[]
            {
                new { role = "system", content = systemPrompt },
                new { role = "user", content = userPrompt }
            }
        };

        var raw = await ExecuteRawAsync(payload, cancellationToken);
        var content = ExtractMessageContent(raw.Body);
        return new OpenAiResult<string>(content, raw.Body, raw.Model, raw.InputTokens, raw.OutputTokens);
    }

    private async Task<OpenAiResult<T>> ExecuteJsonAsync<T>(object payload, CancellationToken cancellationToken)
    {
        var raw = await ExecuteRawAsync(payload, cancellationToken);
        var content = ExtractMessageContent(raw.Body);
        try
        {
            var value = JsonSerializer.Deserialize<T>(content, JsonOptions);
            if (value is null)
            {
                throw new JsonException("OpenAI returned empty JSON content.");
            }

            return new OpenAiResult<T>(value, raw.Body, raw.Model, raw.InputTokens, raw.OutputTokens);
        }
        catch (JsonException ex)
        {
            _logger.LogError(
                ex,
                "Failed to parse OpenAI JSON response. Path: {Path}. Content preview: {ContentPreview}",
                ex.Path,
                BuildContentPreview(content));
            throw new AiFeatureException("AI_SERVICE_ERROR", "Failed to parse AI response.", 502, ex);
        }
    }

    private async Task<OpenAiRawResult> ExecuteRawAsync(object payload, CancellationToken cancellationToken)
    {
        var attempt = 0;
        while (true)
        {
            attempt++;
            try
            {
                var client = _httpClientFactory.CreateClient("OpenAiClient");
                client.Timeout = TimeSpan.FromSeconds(_settings.TimeoutSeconds > 0 ? _settings.TimeoutSeconds : 60);
                if (string.IsNullOrWhiteSpace(client.DefaultRequestHeaders.Authorization?.Parameter))
                {
                    client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _settings.OpenAi.ApiKey);
                }

                using var response = await client.PostAsJsonAsync("chat/completions", payload, cancellationToken);
                var body = await response.Content.ReadAsStringAsync(cancellationToken);
                if (!response.IsSuccessStatusCode)
                {
                    var errorSummary = ExtractErrorSummary(body);
                    _logger.LogWarning(
                        "OpenAI request failed with status {StatusCode}. Error: {ErrorSummary}",
                        response.StatusCode,
                        errorSummary);
                    throw new AiFeatureException(
                        "AI_SERVICE_ERROR",
                        $"AI service request failed: {errorSummary}",
                        502);
                }

                using var doc = JsonDocument.Parse(body);
                var model = doc.RootElement.TryGetProperty("model", out var modelElement)
                    ? modelElement.GetString()
                    : null;
                var usage = doc.RootElement.TryGetProperty("usage", out var usageElement) ? usageElement : default;
                var inputTokens = usage.ValueKind == JsonValueKind.Object && usage.TryGetProperty("prompt_tokens", out var promptTokens)
                    ? promptTokens.GetInt32()
                    : (int?)null;
                var outputTokens = usage.ValueKind == JsonValueKind.Object && usage.TryGetProperty("completion_tokens", out var completionTokens)
                    ? completionTokens.GetInt32()
                    : (int?)null;

                return new OpenAiRawResult(body, model, inputTokens, outputTokens);
            }
            catch (AiFeatureException) when (attempt < Math.Max(1, _settings.RetryCount))
            {
                await Task.Delay(TimeSpan.FromSeconds(Math.Max(1, _settings.RetryDelaySeconds) * attempt), cancellationToken);
            }
            catch (HttpRequestException ex) when (attempt < Math.Max(1, _settings.RetryCount))
            {
                _logger.LogWarning(ex, "OpenAI HTTP attempt {Attempt} failed.", attempt);
                await Task.Delay(TimeSpan.FromSeconds(Math.Max(1, _settings.RetryDelaySeconds) * attempt), cancellationToken);
            }
            catch (TaskCanceledException ex) when (!cancellationToken.IsCancellationRequested && attempt < Math.Max(1, _settings.RetryCount))
            {
                _logger.LogWarning(ex, "OpenAI timeout attempt {Attempt} failed.", attempt);
                await Task.Delay(TimeSpan.FromSeconds(Math.Max(1, _settings.RetryDelaySeconds) * attempt), cancellationToken);
            }
            catch (Exception ex) when (ex is HttpRequestException or TaskCanceledException)
            {
                _logger.LogError(ex, "OpenAI request failed.");
                throw new AiFeatureException("AI_SERVICE_ERROR", "AI service is temporarily unavailable.", 502, ex);
            }
        }
    }

    private static string ExtractMessageContent(string rawBody)
    {
        using var doc = JsonDocument.Parse(rawBody);
        return doc.RootElement
            .GetProperty("choices")[0]
            .GetProperty("message")
            .GetProperty("content")
            .GetString() ?? "{}";
    }

    private static string ExtractErrorSummary(string rawBody)
    {
        if (string.IsNullOrWhiteSpace(rawBody))
        {
            return "Empty error response.";
        }

        try
        {
            using var doc = JsonDocument.Parse(rawBody);
            if (doc.RootElement.TryGetProperty("error", out var errorElement))
            {
                var type = errorElement.TryGetProperty("type", out var typeElement)
                    ? typeElement.GetString()
                    : null;
                var code = errorElement.TryGetProperty("code", out var codeElement)
                    ? codeElement.GetString()
                    : null;
                var message = errorElement.TryGetProperty("message", out var messageElement)
                    ? messageElement.GetString()
                    : null;

                var parts = new[] { type, code, message }
                    .Where(x => !string.IsNullOrWhiteSpace(x));

                var combined = string.Join(" | ", parts);
                if (!string.IsNullOrWhiteSpace(combined))
                {
                    return combined;
                }
            }
        }
        catch (JsonException)
        {
        }

        return rawBody.Length <= 800 ? rawBody : $"{rawBody[..800]}...";
    }

    private static string ResolveModel(string? requested, string fallback)
    {
        return string.IsNullOrWhiteSpace(requested) ? fallback : requested.Trim();
    }

    private static string BuildContentPreview(string content)
    {
        if (string.IsNullOrWhiteSpace(content))
        {
            return "<empty>";
        }

        var normalized = content.Replace('\n', ' ').Replace('\r', ' ').Trim();
        return normalized.Length <= 600 ? normalized : normalized[..600];
    }
}

public sealed record OpenAiResult<T>(T Value, string RawResponse, string? Model, int? InputTokens, int? OutputTokens);

internal sealed record OpenAiRawResult(string Body, string? Model, int? InputTokens, int? OutputTokens);
