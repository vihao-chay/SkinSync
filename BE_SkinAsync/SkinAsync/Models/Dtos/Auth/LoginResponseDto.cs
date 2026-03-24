namespace SkinAsync.Models.Dtos.Auth;

public class LoginResponseDto
{
    public string TokenType { get; set; } = "Bearer";
    public string AccessToken { get; set; } = string.Empty;
    public string RefreshToken { get; set; } = string.Empty;
    public DateTime AccessTokenExpiresAtUtc { get; set; }
    public DateTime RefreshTokenExpiresAtUtc { get; set; }
    public AuthUserResponseDto User { get; set; } = new();
}
