using System.ComponentModel.DataAnnotations;

namespace SkinSync.Models.Dtos.Auth;

public class UpdateAvatarSelectionRequestDto
{
    [Required]
    [MaxLength(500)]
    public string AvatarUrl { get; set; } = string.Empty;
}
