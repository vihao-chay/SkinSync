using System.ComponentModel.DataAnnotations;

namespace SkinSync.Models.Dtos.Auth;

public class ForgotPasswordRequestDto
{
    [Required]
    [EmailAddress]
    public string Email { get; set; } = string.Empty;

    public string? RedirectTo { get; set; }
}
