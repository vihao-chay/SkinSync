using System.ComponentModel.DataAnnotations;

namespace SkinAsync.Models.Dtos.Auth;

public class RefreshTokenRequestDto
{
    [Required]
    public string RefreshToken { get; set; } = string.Empty;
}
