using System.ComponentModel.DataAnnotations;

namespace SkinSync.Models.Dtos.Auth;

public class RefreshTokenRequestDto
{
    [Required]
    public string RefreshToken { get; set; } = string.Empty;
}
