using SkinAsync.Base;

namespace SkinAsync.Models.Dtos.Admin;

public class AdminUsersQueryDto : PagingQuery
{
    public string? Role { get; set; }
    public string? Status { get; set; }
}
