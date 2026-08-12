namespace SkinSync.Models.Dtos.Products;

public class ProductImportResult
{
    public int TotalRows { get; set; }
    public int Inserted { get; set; }
    public int Updated { get; set; }
    public int Skipped { get; set; }
    public int Duplicates { get; set; }
    public int InvalidRows { get; set; }
    public List<string> Errors { get; set; } = new();
}
