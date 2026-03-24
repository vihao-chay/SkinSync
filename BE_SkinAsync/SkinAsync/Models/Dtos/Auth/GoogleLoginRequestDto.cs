using System.ComponentModel.DataAnnotations;

namespace SkinAsync.Models.Dtos.Auth;

public class GoogleLoginRequestDto
{
    [Required]
    public string SupabaseAccessToken { get; set; } = string.Empty;
}
