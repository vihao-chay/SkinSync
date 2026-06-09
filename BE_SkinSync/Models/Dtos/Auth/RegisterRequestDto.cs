using System.ComponentModel.DataAnnotations;

namespace SkinSync.Models.Dtos.Auth;

public class RegisterRequestDto
{
    [MaxLength(120)]
    public string? FullName { get; set; }

    [Required]
    [EmailAddress]
    [MaxLength(255)]
    public string Email { get; set; } = string.Empty;

    [MaxLength(30)]
    public string Phone { get; set; } = string.Empty;

    [Required]
    [MinLength(8)]
    public string Password { get; set; } = string.Empty;
}
