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
            return SupabaseAuthResult.Fail("Hệ thống chưa cấu hình Supabase (Url hoặc AnonKey bị thiếu).");
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
                return SupabaseAuthResult.Fail(ParseError(body) ?? "Đăng ký thất bại.", (int)response.StatusCode);
            }

            var dto = JsonSerializer.Deserialize<SupabaseSessionDto>(body, JsonOptions);
            var user = dto?.User ?? ParseSignUpUserFromBody(body);
            if (user is null)
            {
                return SupabaseAuthResult.Fail("Đăng ký thành công nhưng không lấy được thông tin hồ sơ người dùng từ máy chủ.");
            }

            return SupabaseAuthResult.Ok(user, dto?.AccessToken, dto?.RefreshToken, dto?.ExpiresIn);
        }
        catch (HttpRequestException ex)
        {
            return SupabaseAuthResult.Fail($"Không thể kết nối đến máy chủ đăng nhập: {ex.Message}", ex.StatusCode is null ? 503 : (int)ex.StatusCode.Value);
        }
    }

    public async Task<SupabaseAuthResult> SignInWithEmailPasswordAsync(string email, string password, CancellationToken cancellationToken)
    {
        if (!HasValidConfig())
        {
            return SupabaseAuthResult.Fail("Hệ thống chưa cấu hình Supabase (Url hoặc AnonKey bị thiếu).");
        }

        try
        {
            var payload = new { email, password };
            var request = BuildRequest(HttpMethod.Post, $"{_supabaseUrl}/auth/v1/token?grant_type=password", payload);
            var response = await _httpClient.SendAsync(request, cancellationToken);
            var body = await response.Content.ReadAsStringAsync(cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                return SupabaseAuthResult.Fail(ParseError(body) ?? "Email hoặc mật khẩu không chính xác.", (int)response.StatusCode);
            }

            var dto = JsonSerializer.Deserialize<SupabaseSessionDto>(body, JsonOptions);
            if (dto?.User is null || string.IsNullOrWhiteSpace(dto.AccessToken))
            {
                return SupabaseAuthResult.Fail("Đăng nhập thành công nhưng không lấy được phiên hoạt động từ máy chủ.");
            }

            return SupabaseAuthResult.Ok(dto.User, dto.AccessToken, dto.RefreshToken, dto.ExpiresIn);
        }
        catch (HttpRequestException ex)
        {
            return SupabaseAuthResult.Fail($"Không thể kết nối đến máy chủ đăng nhập: {ex.Message}", ex.StatusCode is null ? 503 : (int)ex.StatusCode.Value);
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
            return SupabaseAuthResult.Fail("Hệ thống chưa cấu hình Supabase (Url hoặc AnonKey bị thiếu).");
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
                return SupabaseAuthResult.Fail(ParseError(body) ?? "Không thể gửi email khôi phục.", (int)response.StatusCode);
            }

            // We return a dummy user profile just to flag IsSuccess
            return SupabaseAuthResult.Ok(new SupabaseUserProfile(), null, null, null);
        }
        catch (HttpRequestException ex)
        {
            return SupabaseAuthResult.Fail($"Không thể kết nối đến máy chủ đăng nhập: {ex.Message}", ex.StatusCode is null ? 503 : (int)ex.StatusCode.Value);
        }
    }

    public async Task<SupabaseAuthResult> UpdateUserPasswordAsync(string accessToken, string newPassword, CancellationToken cancellationToken)
    {
        if (!HasValidConfig())
        {
            return SupabaseAuthResult.Fail("Hệ thống chưa cấu hình Supabase (Url hoặc AnonKey bị thiếu).");
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
                return SupabaseAuthResult.Fail(ParseError(body) ?? "Cập nhật mật khẩu thất bại.", (int)response.StatusCode);
            }

            return SupabaseAuthResult.Ok(new SupabaseUserProfile(), null, null, null);
        }
        catch (HttpRequestException ex)
        {
            return SupabaseAuthResult.Fail($"Không thể kết nối đến máy chủ đăng nhập: {ex.Message}", ex.StatusCode is null ? 503 : (int)ex.StatusCode.Value);
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
            return "Email hoặc mật khẩu không chính xác.";
            
        if (msg.Contains("user already registered"))
            return "Email này đã được đăng ký.";
            
        if (msg.Contains("password should be at least 6 characters") || msg.Contains("weak_password"))
            return "Mật khẩu phải có ít nhất 6 ký tự.";
            
        if (msg.Contains("email not confirmed"))
            return "Tài khoản chưa được xác thực email.";
            
        if (msg.Contains("rate limit"))
            return "Bạn thao tác quá nhanh, vui lòng thử lại sau.";
            
        if (msg.Contains("token expired"))
            return "Phiên đăng nhập đã hết hạn.";
            
        if (msg.Contains("connection"))
            return "Lỗi kết nối đến máy chủ đăng nhập.";
            
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
