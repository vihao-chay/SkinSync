using System.ComponentModel.DataAnnotations;

namespace SkinSync.Models.Dtos.Auth;

public class ResetPasswordRequestDto
{
    [Required]
    public string AccessToken { get; set; } = string.Empty;

    [Required]
    [MinLength(6)]
    public string NewPassword { get; set; } = string.Empty;
}
