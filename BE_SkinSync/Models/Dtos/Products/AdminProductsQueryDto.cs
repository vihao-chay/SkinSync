using SkinSync.Base;

namespace SkinSync.Models.Dtos.Products;

public class AdminProductsQueryDto : PagingQuery
{
    public string? Category { get; set; }
    public string? Status { get; set; }
}
