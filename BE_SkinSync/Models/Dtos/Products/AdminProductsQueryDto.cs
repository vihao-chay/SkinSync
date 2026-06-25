using SkinSync.Base;

namespace SkinSync.Models.Dtos.Products;

public class AdminProductsQueryDto : PagingQuery
{
    public string? Category { get; set; }
    public string? Brand { get; set; }
    public string? UsageTime { get; set; }
    public bool? IsActive { get; set; }
    public bool? IsVerified { get; set; }
    public string? Source { get; set; }
    public bool? HasImage { get; set; }
    public bool? HasIngredients { get; set; }
}
