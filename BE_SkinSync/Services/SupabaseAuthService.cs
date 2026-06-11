using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace SkinSync.Services;

public interface ISupabaseAuthService
{
    Task<SupabaseAuthResult> SignUpWithEmailPasswordAsync(string email, string password, string fullName, string phone, CancellationToken cancellationToken);
    Task<SupabaseAuthResult> SignInWithEmailPasswordAsync(string email, string password, CancellationToken cancellationToken);
    Task<SupabaseUserProfile?> GetUserByAccessTokenAsync(string accessToken, CancellationToken cancellationToken);
    string BuildGoogleOAuthUrl(string redirectTo, string? state);
    Task<SupabaseAuthResult> SendResetPasswordEmailAsync(string email, string? redirectTo, CancellationToken cancellationToken);
    Task<SupabaseAuthResult> UpdateUserPasswordAsync(string accessToken, string newPassword, CancellationToken cancellationToken);
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
            return SupabaseAuthResult.Fail("Há»‡ thá»‘ng chÆ°a cáº¥u hÃ¬nh Supabase (Url hoáº·c AnonKey bá»‹ thiáº¿u).");
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
                return SupabaseAuthResult.Fail(ParseError(body) ?? "ÄÄƒng kÃ½ tháº¥t báº¡i.", (int)response.StatusCode);
            }

            var dto = JsonSerializer.Deserialize<SupabaseSessionDto>(body, JsonOptions);
            var user = dto?.User ?? ParseSignUpUserFromBody(body);
            if (user is null)
            {
                return SupabaseAuthResult.Fail("ÄÄƒng kÃ½ thÃ nh cÃ´ng nhÆ°ng khÃ´ng láº¥y Ä‘Æ°á»£c thÃ´ng tin há»“ sÆ¡ ngÆ°á»i dÃ¹ng tá»« mÃ¡y chá»§.");
            }

            return SupabaseAuthResult.Ok(user, dto?.AccessToken, dto?.RefreshToken, dto?.ExpiresIn);
        }
        catch (HttpRequestException ex)
        {
            return SupabaseAuthResult.Fail($"KhÃ´ng thá»ƒ káº¿t ná»‘i Ä‘áº¿n mÃ¡y chá»§ Ä‘Äƒng nháº­p: {ex.Message}", ex.StatusCode is null ? 503 : (int)ex.StatusCode.Value);
        }
    }

    public async Task<SupabaseAuthResult> SignInWithEmailPasswordAsync(string email, string password, CancellationToken cancellationToken)
    {
        if (!HasValidConfig())
        {
            return SupabaseAuthResult.Fail("Há»‡ thá»‘ng chÆ°a cáº¥u hÃ¬nh Supabase (Url hoáº·c AnonKey bá»‹ thiáº¿u).");
        }

        try
        {
            var payload = new { email, password };
            var request = BuildRequest(HttpMethod.Post, $"{_supabaseUrl}/auth/v1/token?grant_type=password", payload);
            var response = await _httpClient.SendAsync(request, cancellationToken);
            var body = await response.Content.ReadAsStringAsync(cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                return SupabaseAuthResult.Fail(ParseError(body) ?? "Email hoáº·c máº­t kháº©u khÃ´ng chÃ­nh xÃ¡c.", (int)response.StatusCode);
            }

            var dto = JsonSerializer.Deserialize<SupabaseSessionDto>(body, JsonOptions);
            if (dto?.User is null || string.IsNullOrWhiteSpace(dto.AccessToken))
            {
                return SupabaseAuthResult.Fail("ÄÄƒng nháº­p thÃ nh cÃ´ng nhÆ°ng khÃ´ng láº¥y Ä‘Æ°á»£c phiÃªn hoáº¡t Ä‘á»™ng tá»« mÃ¡y chá»§.");
            }

            return SupabaseAuthResult.Ok(dto.User, dto.AccessToken, dto.RefreshToken, dto.ExpiresIn);
        }
        catch (HttpRequestException ex)
        {
            return SupabaseAuthResult.Fail($"KhÃ´ng thá»ƒ káº¿t ná»‘i Ä‘áº¿n mÃ¡y chá»§ Ä‘Äƒng nháº­p: {ex.Message}", ex.StatusCode is null ? 503 : (int)ex.StatusCode.Value);
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

    public async Task<SupabaseAuthResult> SendResetPasswordEmailAsync(string email, string? redirectTo, CancellationToken cancellationToken)
    {
        if (!HasValidConfig())
        {
            return SupabaseAuthResult.Fail("Há»‡ thá»‘ng chÆ°a cáº¥u hÃ¬nh Supabase (Url hoáº·c AnonKey bá»‹ thiáº¿u).");
        }

        try
        {
            var payload = string.IsNullOrWhiteSpace(redirectTo) 
                ? (object)new { email } 
                : new { email, redirect_to = redirectTo };

            var request = BuildRequest(HttpMethod.Post, $"{_supabaseUrl}/auth/v1/recover", payload);
            var response = await _httpClient.SendAsync(request, cancellationToken);
            
            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync(cancellationToken);
                return SupabaseAuthResult.Fail(ParseError(body) ?? "KhÃ´ng thá»ƒ gá»­i email khÃ´i phá»¥c.", (int)response.StatusCode);
            }

            // We return a dummy user profile just to flag IsSuccess
            return SupabaseAuthResult.Ok(new SupabaseUserProfile(), null, null, null);
        }
        catch (HttpRequestException ex)
        {
            return SupabaseAuthResult.Fail($"KhÃ´ng thá»ƒ káº¿t ná»‘i Ä‘áº¿n mÃ¡y chá»§ Ä‘Äƒng nháº­p: {ex.Message}", ex.StatusCode is null ? 503 : (int)ex.StatusCode.Value);
        }
    }

    public async Task<SupabaseAuthResult> UpdateUserPasswordAsync(string accessToken, string newPassword, CancellationToken cancellationToken)
    {
        if (!HasValidConfig())
        {
            return SupabaseAuthResult.Fail("Há»‡ thá»‘ng chÆ°a cáº¥u hÃ¬nh Supabase (Url hoáº·c AnonKey bá»‹ thiáº¿u).");
        }

        try
        {
            var payload = new { password = newPassword };
            var request = BuildRequest(HttpMethod.Put, $"{_supabaseUrl}/auth/v1/user", payload);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
            
            var response = await _httpClient.SendAsync(request, cancellationToken);
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            
            if (!response.IsSuccessStatusCode)
            {
                return SupabaseAuthResult.Fail(ParseError(body) ?? "Cáº­p nháº­t máº­t kháº©u tháº¥t báº¡i.", (int)response.StatusCode);
            }

            return SupabaseAuthResult.Ok(new SupabaseUserProfile(), null, null, null);
        }
        catch (HttpRequestException ex)
        {
            return SupabaseAuthResult.Fail($"KhÃ´ng thá»ƒ káº¿t ná»‘i Ä‘áº¿n mÃ¡y chá»§ Ä‘Äƒng nháº­p: {ex.Message}", ex.StatusCode is null ? 503 : (int)ex.StatusCode.Value);
        }
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

        string? errorMsg = null;
        try
        {
            using var doc = JsonDocument.Parse(raw);
            var root = doc.RootElement;

            if (root.TryGetProperty("msg", out var msgProp))
            {
                errorMsg = msgProp.GetString();
            }
            else if (root.TryGetProperty("message", out var messageProp))
            {
                errorMsg = messageProp.GetString();
            }
            else if (root.TryGetProperty("error_description", out var errorDescriptionProp))
            {
                errorMsg = errorDescriptionProp.GetString();
            }
            else if (root.TryGetProperty("error", out var errorProp))
            {
                errorMsg = errorProp.GetString();
            }
        }
        catch
        {
            return null;
        }

        return string.IsNullOrWhiteSpace(errorMsg) ? null : TranslateErrorMessage(errorMsg);
    }

    private static string TranslateErrorMessage(string? englishMsg)
    {
        if (string.IsNullOrWhiteSpace(englishMsg)) return string.Empty;
        
        var msg = englishMsg.Trim().ToLowerInvariant();
        
        if (msg.Contains("invalid login credentials") || msg.Contains("invalid email or password"))
            return "Email hoáº·c máº­t kháº©u khÃ´ng chÃ­nh xÃ¡c.";
            
        if (msg.Contains("user already registered"))
            return "Email nÃ y Ä‘Ã£ Ä‘Æ°á»£c Ä‘Äƒng kÃ½.";
            
        if (msg.Contains("password should be at least 6 characters") || msg.Contains("weak_password"))
            return "Máº­t kháº©u pháº£i cÃ³ Ã­t nháº¥t 6 kÃ½ tá»±.";
            
        if (msg.Contains("email not confirmed"))
            return "TÃ i khoáº£n chÆ°a Ä‘Æ°á»£c xÃ¡c thá»±c email.";
            
        if (msg.Contains("rate limit"))
            return "Báº¡n thao tÃ¡c quÃ¡ nhanh, vui lÃ²ng thá»­ láº¡i sau.";
            
        if (msg.Contains("token expired"))
            return "PhiÃªn Ä‘Äƒng nháº­p Ä‘Ã£ háº¿t háº¡n.";
            
        if (msg.Contains("connection"))
            return "Lá»—i káº¿t ná»‘i Ä‘áº¿n mÃ¡y chá»§ Ä‘Äƒng nháº­p.";
            
        return englishMsg;
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
