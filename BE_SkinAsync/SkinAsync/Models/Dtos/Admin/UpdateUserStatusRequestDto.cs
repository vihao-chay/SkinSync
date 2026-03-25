using System.ComponentModel.DataAnnotations;

namespace SkinAsync.Models.Dtos.Admin;

public class UpdateUserStatusRequestDto
{
    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = string.Empty;
}
