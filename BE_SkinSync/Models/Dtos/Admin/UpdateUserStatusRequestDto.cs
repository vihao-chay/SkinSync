using System.ComponentModel.DataAnnotations;

namespace SkinSync.Models.Dtos.Admin;

public class UpdateUserStatusRequestDto
{
    [Required]
    [MaxLength(20)]
    public string Status { get; set; } = string.Empty;
}
