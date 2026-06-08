using System.ComponentModel.DataAnnotations;

namespace SkinSync.Models.Dtos.Admin;

public class UpdateUserRoleRequestDto
{
    [Required]
    [MaxLength(20)]
    public string Role { get; set; } = string.Empty;
}
