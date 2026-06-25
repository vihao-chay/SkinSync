namespace SkinSync.Services;

public class ProductImportOptions
{
    public bool ImportProductsOnStartup { get; set; }
    public string ProductCsvPath { get; set; } = Helpers.ProductCatalogConstants.ProductCsvDefaultPath;
}
