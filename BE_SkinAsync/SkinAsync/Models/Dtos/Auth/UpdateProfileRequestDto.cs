using System.ComponentModel.DataAnnotations;

namespace SkinAsync.Models.Dtos.Auth;

public class UpdateProfileRequestDto
{
    [Required]
    [MaxLength(100)]
    public string FullName { get; set; } = string.Empty;

    [MaxLength(20)]
    public string Phone { get; set; } = string.Empty;
}
