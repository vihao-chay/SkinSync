using SkinSync.Base;

namespace SkinSync.Models.Dtos.Admin;

public class AdminUsersQueryDto : PagingQuery
{
    public string? Role { get; set; }
    public string? Status { get; set; }
}
