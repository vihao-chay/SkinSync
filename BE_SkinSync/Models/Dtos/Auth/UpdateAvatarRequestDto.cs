using System.ComponentModel.DataAnnotations;
using Microsoft.AspNetCore.Http;

namespace SkinSync.Models.Dtos.Auth;

public class UpdateAvatarRequestDto
{
    [Required]
    public IFormFile? Avatar { get; set; }
}
