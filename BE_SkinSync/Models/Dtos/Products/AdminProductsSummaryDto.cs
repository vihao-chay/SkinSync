namespace SkinSync.Models.Dtos.Products;

public class AdminProductsSummaryDto
{
    public int TotalProducts { get; set; }
    public int ActiveProducts { get; set; }
    public int VerifiedProducts { get; set; }
    public int ProductsMissingImage { get; set; }
    public int ProductsMissingIngredients { get; set; }
}
