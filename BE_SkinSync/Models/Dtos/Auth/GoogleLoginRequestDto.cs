using System.ComponentModel.DataAnnotations;

namespace SkinSync.Models.Dtos.Auth;

public class GoogleLoginRequestDto
{
    [Required]
    public string SupabaseAccessToken { get; set; } = string.Empty;
}
