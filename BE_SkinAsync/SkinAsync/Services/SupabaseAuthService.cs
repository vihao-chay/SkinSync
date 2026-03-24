using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace SkinAsync.Services;

public interface ISupabaseAuthService
{
    Task<SupabaseAuthResult> SignUpWithEmailPasswordAsync(string email, string password, string fullName, string phone, CancellationToken cancellationToken);
    Task<SupabaseAuthResult> SignInWithEmailPasswordAsync(string email, string password, CancellationToken cancellationToken);
    Task<SupabaseUserProfile?> GetUserByAccessTokenAsync(string accessToken, CancellationToken cancellationToken);
    string BuildGoogleOAuthUrl(string redirectTo, string? state);
}

public class SupabaseAuthService : ISupabaseAuthService
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web)
    {
        PropertyNameCaseInsensitive = true
    };

    private readonly HttpClient _httpClient;
    private readonly string _supabaseUrl;
    private readonly string _anonKey;

    public SupabaseAuthService(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _supabaseUrl = (configuration["Supabase:Url"] ?? string.Empty).TrimEnd('/');
        _anonKey = configuration["Supabase:AnonKey"] ?? string.Empty;
    }

    public async Task<SupabaseAuthResult> SignUpWithEmailPasswordAsync(string email, string password, string fullName, string phone, CancellationToken cancellationToken)
    {
        if (!HasValidConfig())
        {
            return SupabaseAuthResult.Fail("Supabase is not configured. Please set Supabase:Url and Supabase:AnonKey.");
        }

        try
        {
            var payload = new
            {
                email,
                password,
                data = new
                {
                    full_name = fullName,
                    phone
                }
            };

            var request = BuildRequest(HttpMethod.Post, $"{_supabaseUrl}/auth/v1/signup", payload);
            var response = await _httpClient.SendAsync(request, cancellationToken);
            var body = await response.Content.ReadAsStringAsync(cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                return SupabaseAuthResult.Fail(ParseError(body) ?? "Supabase sign-up failed.", (int)response.StatusCode);
            }

            var dto = JsonSerializer.Deserialize<SupabaseSessionDto>(body, JsonOptions);
            var user = dto?.User ?? ParseSignUpUserFromBody(body);
            if (user is null)
            {
                return SupabaseAuthResult.Fail("Supabase sign-up succeeded but no user profile was returned.");
            }

            return SupabaseAuthResult.Ok(user, dto?.AccessToken, dto?.RefreshToken, dto?.ExpiresIn);
        }
        catch (HttpRequestException ex)
        {
            return SupabaseAuthResult.Fail($"Cannot connect to Supabase auth service: {ex.Message}", ex.StatusCode is null ? 503 : (int)ex.StatusCode.Value);
        }
    }

    public async Task<SupabaseAuthResult> SignInWithEmailPasswordAsync(string email, string password, CancellationToken cancellationToken)
    {
        if (!HasValidConfig())
        {
            return SupabaseAuthResult.Fail("Supabase is not configured. Please set Supabase:Url and Supabase:AnonKey.");
        }

        try
        {
            var payload = new { email, password };
            var request = BuildRequest(HttpMethod.Post, $"{_supabaseUrl}/auth/v1/token?grant_type=password", payload);
            var response = await _httpClient.SendAsync(request, cancellationToken);
            var body = await response.Content.ReadAsStringAsync(cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                return SupabaseAuthResult.Fail(ParseError(body) ?? "Invalid email or password.", (int)response.StatusCode);
            }

            var dto = JsonSerializer.Deserialize<SupabaseSessionDto>(body, JsonOptions);
            if (dto?.User is null || string.IsNullOrWhiteSpace(dto.AccessToken))
            {
                return SupabaseAuthResult.Fail("Supabase login succeeded but no active session was returned.");
            }

            return SupabaseAuthResult.Ok(dto.User, dto.AccessToken, dto.RefreshToken, dto.ExpiresIn);
        }
        catch (HttpRequestException ex)
        {
            return SupabaseAuthResult.Fail($"Cannot connect to Supabase auth service: {ex.Message}", ex.StatusCode is null ? 503 : (int)ex.StatusCode.Value);
        }
    }

    public async Task<SupabaseUserProfile?> GetUserByAccessTokenAsync(string accessToken, CancellationToken cancellationToken)
    {
        if (!HasValidConfig() || string.IsNullOrWhiteSpace(accessToken))
        {
            return null;
        }

        using var request = new HttpRequestMessage(HttpMethod.Get, $"{_supabaseUrl}/auth/v1/user");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        request.Headers.TryAddWithoutValidation("apikey", _anonKey);

        var response = await _httpClient.SendAsync(request, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            return null;
        }

        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        return JsonSerializer.Deserialize<SupabaseUserProfile>(body, JsonOptions);
    }

    public string BuildGoogleOAuthUrl(string redirectTo, string? state)
    {
        if (!HasValidConfig())
        {
            return string.Empty;
        }

        var encodedRedirectTo = Uri.EscapeDataString(redirectTo);
        var url = $"{_supabaseUrl}/auth/v1/authorize?provider=google&redirect_to={encodedRedirectTo}";
        if (!string.IsNullOrWhiteSpace(state))
        {
            url += $"&state={Uri.EscapeDataString(state)}";
        }

        return url;
    }

    private bool HasValidConfig()
    {
        return !string.IsNullOrWhiteSpace(_supabaseUrl) && !string.IsNullOrWhiteSpace(_anonKey);
    }

    private HttpRequestMessage BuildRequest(HttpMethod method, string url, object payload)
    {
        var request = new HttpRequestMessage(method, url);
        request.Headers.TryAddWithoutValidation("apikey", _anonKey);
        request.Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json");
        return request;
    }

    private static string? ParseError(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return null;
        }

        try
        {
            using var doc = JsonDocument.Parse(raw);
            var root = doc.RootElement;

            if (root.TryGetProperty("msg", out var msgProp))
            {
                return msgProp.GetString();
            }

            if (root.TryGetProperty("message", out var messageProp))
            {
                return messageProp.GetString();
            }

            if (root.TryGetProperty("error_description", out var errorDescriptionProp))
            {
                return errorDescriptionProp.GetString();
            }

            if (root.TryGetProperty("error", out var errorProp))
            {
                return errorProp.GetString();
            }
        }
        catch
        {
            return null;
        }

        return null;
    }

    private static SupabaseUserProfile? ParseSignUpUserFromBody(string raw)
    {
        if (string.IsNullOrWhiteSpace(raw))
        {
            return null;
        }

        try
        {
            using var doc = JsonDocument.Parse(raw);
            var root = doc.RootElement;

            if (root.TryGetProperty("user", out var userProp) && userProp.ValueKind == JsonValueKind.Object)
            {
                return JsonSerializer.Deserialize<SupabaseUserProfile>(userProp.GetRawText(), JsonOptions);
            }

            if (root.TryGetProperty("id", out _) && root.TryGetProperty("email", out _))
            {
                return JsonSerializer.Deserialize<SupabaseUserProfile>(root.GetRawText(), JsonOptions);
            }
        }
        catch
        {
            return null;
        }

        return null;
    }
}

public sealed class SupabaseAuthResult
{
    public bool IsSuccess { get; private init; }
    public int StatusCode { get; private init; }
    public string? ErrorMessage { get; private init; }
    public SupabaseUserProfile? User { get; private init; }
    public string? AccessToken { get; private init; }
    public string? RefreshToken { get; private init; }
    public int? ExpiresIn { get; private init; }

    public static SupabaseAuthResult Ok(SupabaseUserProfile user, string? accessToken, string? refreshToken, int? expiresIn)
    {
        return new SupabaseAuthResult
        {
            IsSuccess = true,
            StatusCode = 200,
            User = user,
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresIn = expiresIn
        };
    }

    public static SupabaseAuthResult Fail(string message, int statusCode = 400)
    {
        return new SupabaseAuthResult
        {
            IsSuccess = false,
            StatusCode = statusCode,
            ErrorMessage = message
        };
    }
}

public class SupabaseSessionDto
{
    [JsonPropertyName("access_token")]
    public string? AccessToken { get; set; }

    [JsonPropertyName("refresh_token")]
    public string? RefreshToken { get; set; }

    [JsonPropertyName("expires_in")]
    public int? ExpiresIn { get; set; }

    [JsonPropertyName("user")]
    public SupabaseUserProfile? User { get; set; }
}

public class SupabaseUserProfile
{
    [JsonPropertyName("id")]
    public string Id { get; set; } = string.Empty;

    [JsonPropertyName("email")]
    public string Email { get; set; } = string.Empty;

    [JsonPropertyName("user_metadata")]
    public Dictionary<string, JsonElement>? UserMetadata { get; set; }
}
