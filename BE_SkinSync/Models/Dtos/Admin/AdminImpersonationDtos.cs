namespace SkinSync.Models.Dtos.Admin;

public class StartImpersonationRequestDto
{
    public Guid UserId { get; set; }
}

public class ImpersonationSessionResponseDto
{
    public string ImpersonationToken { get; set; } = string.Empty;
    public Guid OriginalAdminId { get; set; }
    public Guid EffectiveUserId { get; set; }
    public Guid ImpersonatedUserId { get; set; }
    public string ImpersonatedUserName { get; set; } = string.Empty;
    public string ImpersonatedUserEmail { get; set; } = string.Empty;
    public DateTime ExpiresAt { get; set; }
}
