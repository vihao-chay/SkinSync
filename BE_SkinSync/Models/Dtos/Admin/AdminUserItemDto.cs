namespace SkinSync.Models.Dtos.Admin;

public class AdminUserItemDto
{
    public Guid Id { get; set; }
    public string FullName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string Role { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public string PlanType { get; set; } = "free";
    public DateTime CreatedAt { get; set; }
}
