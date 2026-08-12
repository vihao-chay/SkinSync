using System.Globalization;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Microsoft.VisualBasic.FileIO;
using SkinSync.Data;
using SkinSync.Helpers;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.Products;
using SkinSync.Models.Entities;

namespace SkinSync.Services;

public interface IProductImportService
{
    Task<ProductImportResult> ImportFromCsvAsync(string filePath, CancellationToken cancellationToken);
}

public class ProductImportService : IProductImportService
{
    private static readonly string[] RequiredColumns =
    [
        "name",
        "brand",
        "category",
        "image_url",
        "ingredients",
        "is_verified",
        "is_active",
        "source",
        "source_url"
    ];

    private readonly AppDbContext _dbContext;
    private readonly ILogger<ProductImportService> _logger;
    private readonly ProductImportOptions _options;

    public ProductImportService(
        AppDbContext dbContext,
        ILogger<ProductImportService> logger,
        IOptions<ProductImportOptions> options)
    {
        _dbContext = dbContext;
        _logger = logger;
        _options = options.Value;
    }

    public async Task<ProductImportResult> ImportFromCsvAsync(string filePath, CancellationToken cancellationToken)
    {
        var resolvedPath = ResolvePath(filePath);
        if (!File.Exists(resolvedPath))
        {
            throw new FileNotFoundException($"Product CSV file not found at '{resolvedPath}'.", resolvedPath);
        }

        var result = new ProductImportResult();
        var errors = result.Errors;
        var rows = ReadCsvRows(resolvedPath, errors);
        var header = rows.FirstOrDefault();
        if (header is null)
        {
            errors.Add("CSV file is empty.");
            return result;
        }

        var normalizedHeader = header
            .Select((name, index) => new { Name = NormalizeColumn(name), Index = index })
            .ToDictionary(item => item.Name, item => item.Index, StringComparer.OrdinalIgnoreCase);

        var missingColumns = RequiredColumns.Where(column => !normalizedHeader.ContainsKey(column)).ToList();
        if (missingColumns.Count > 0)
        {
            errors.Add($"Missing required columns: {string.Join(", ", missingColumns)}");
            return result;
        }

        var dataRows = rows.Skip(1).ToList();
        result.TotalRows = dataRows.Count;

        var existingProducts = await _dbContext.Products.ToListAsync(cancellationToken);
        var existingLookup = existingProducts
            .GroupBy(product => BuildNormalizedKey(product.Name, product.Brand))
            .ToDictionary(group => group.Key, group => group.First(), StringComparer.Ordinal);

        var seenInFile = new HashSet<string>(StringComparer.Ordinal);

        foreach (var fields in dataRows)
        {
            cancellationToken.ThrowIfCancellationRequested();

            var row = ReadRow(fields, normalizedHeader);
            var normalizedKey = BuildNormalizedKey(row.Name, row.Brand);

            if (string.IsNullOrWhiteSpace(row.Name) ||
                string.IsNullOrWhiteSpace(row.Brand) ||
                string.IsNullOrWhiteSpace(row.Category) ||
                string.IsNullOrWhiteSpace(row.Ingredients) ||
                string.IsNullOrWhiteSpace(row.ImageUrl))
            {
                result.Skipped++;
                result.InvalidRows++;
                errors.Add($"Skipped row with missing required value: '{row.Name}' / '{row.Brand}'.");
                continue;
            }

            if (!ProductCatalogConstants.IsValidHttpUrl(row.ImageUrl))
            {
                result.Skipped++;
                result.InvalidRows++;
                errors.Add($"Skipped row with invalid image_url: '{row.Name}' / '{row.ImageUrl}'.");
                continue;
            }

            if (!string.IsNullOrWhiteSpace(row.SourceUrl) && !ProductCatalogConstants.IsValidHttpUrl(row.SourceUrl))
            {
                result.Skipped++;
                result.InvalidRows++;
                errors.Add($"Skipped row with invalid source_url: '{row.Name}' / '{row.SourceUrl}'.");
                continue;
            }

            row.Category = ProductCatalogConstants.NormalizeCategory(row.Category);
            if (string.IsNullOrWhiteSpace(row.Category))
            {
                result.Skipped++;
                result.InvalidRows++;
                errors.Add($"Skipped row with invalid category: '{row.Name}'.");
                continue;
            }

            if (!string.IsNullOrWhiteSpace(row.UsageTime))
            {
                row.UsageTime = ProductCatalogConstants.NormalizeUsageTime(row.UsageTime);
                if (string.IsNullOrWhiteSpace(row.UsageTime))
                {
                    result.Skipped++;
                    result.InvalidRows++;
                    errors.Add($"Skipped row with invalid usage_time: '{row.Name}'.");
                    continue;
                }
            }

            if (!seenInFile.Add(normalizedKey))
            {
                result.Duplicates++;
                result.Skipped++;
                continue;
            }

            if (!existingLookup.TryGetValue(normalizedKey, out var existing))
            {
                var product = CreateNewProduct(row);
                _dbContext.Products.Add(product);
                existingLookup[normalizedKey] = product;
                result.Inserted++;
                continue;
            }

            if (ApplyImportUpdates(existing, row))
            {
                existing.UpdatedAt = DateTime.UtcNow;
                result.Updated++;
            }
            else
            {
                result.Skipped++;
            }
        }

        await _dbContext.SaveChangesAsync(cancellationToken);

        _logger.LogInformation(
            "Product CSV import finished. TotalRows={TotalRows}, Inserted={Inserted}, Updated={Updated}, Skipped={Skipped}, Duplicates={Duplicates}, InvalidRows={InvalidRows}",
            result.TotalRows,
            result.Inserted,
            result.Updated,
            result.Skipped,
            result.Duplicates,
            result.InvalidRows);

        return result;
    }

    private string ResolvePath(string? filePath)
    {
        var path = string.IsNullOrWhiteSpace(filePath) ? _options.ProductCsvPath : filePath.Trim();
        return Path.IsPathRooted(path)
            ? path
            : Path.GetFullPath(path, Directory.GetCurrentDirectory());
    }

    private static List<string[]> ReadCsvRows(string path, List<string> errors)
    {
        var rows = new List<string[]>();
        using var parser = new TextFieldParser(path);
        parser.TextFieldType = FieldType.Delimited;
        parser.SetDelimiters(",");
        parser.HasFieldsEnclosedInQuotes = true;
        parser.TrimWhiteSpace = false;

        while (!parser.EndOfData)
        {
            try
            {
                rows.Add(parser.ReadFields() ?? []);
            }
            catch (MalformedLineException ex)
            {
                errors.Add($"Malformed CSV line {ex.LineNumber}: {ex.Message}");
            }
        }

        return rows;
    }

    private static string NormalizeColumn(string value)
        => value.Trim().ToLowerInvariant();

    private static string BuildNormalizedKey(string name, string brand)
        => $"{NormalizeForKey(name)}||{NormalizeForKey(brand)}";

    private static string NormalizeForKey(string value)
        => string.Join(" ", value.Trim().ToLowerInvariant().Split(' ', StringSplitOptions.RemoveEmptyEntries));

    private static ImportedProductRow ReadRow(string[] fields, IReadOnlyDictionary<string, int> header)
    {
        string GetValue(string columnName)
        {
            return header.TryGetValue(columnName, out var index) && index < fields.Length
                ? fields[index].Trim()
                : string.Empty;
        }

        var skinTypes = ProductMapper.SerializeDelimitedList(GetValue("skin_types"), ';');
        var skinConcerns = ProductMapper.SerializeDelimitedList(GetValue("skin_concerns"), ';');
        var price = TryParseNullableDecimal(GetValue("price"));

        return new ImportedProductRow
        {
            Name = GetValue("name"),
            Brand = GetValue("brand"),
            Category = GetValue("category"),
            Description = GetValue("description"),
            ImageUrl = GetValue("image_url"),
            Price = price,
            Currency = GetValue("currency"),
            SkinTypes = skinTypes,
            SkinConcerns = skinConcerns,
            UsageTime = GetValue("usage_time"),
            HowToUse = GetValue("how_to_use"),
            Ingredients = GetValue("ingredients"),
            IsVerified = TryParseBoolean(GetValue("is_verified")),
            IsActive = TryParseBoolean(GetValue("is_active")),
            Source = GetValue("source"),
            SourceUrl = GetValue("source_url")
        };
    }

    private static Product CreateNewProduct(ImportedProductRow row)
    {
        var now = DateTime.UtcNow;
        var status = ProductCatalogConstants.NormalizeStatusForActiveFlag("active", row.IsActive);
        return new Product
        {
            Id = Guid.NewGuid(),
            Name = row.Name,
            Brand = row.Brand,
            Category = row.Category,
            Description = NullIfEmpty(row.Description),
            Ingredient = ProductMapper.SerializeIngredients(row.Ingredients),
            KeyIngredients = ProductMapper.SerializeKeyIngredients(row.Ingredients),
            TargetConcerns = row.SkinConcerns,
            UsageGuide = NullIfEmpty(row.HowToUse),
            UsageTime = NullIfEmpty(row.UsageTime),
            Price = row.Price,
            Currency = row.Currency,
            SuitableSkinTypes = row.SkinTypes,
            ImageUrl = row.ImageUrl,
            Status = status,
            IsVerified = row.IsVerified,
            IsActive = row.IsActive,
            Source = string.IsNullOrWhiteSpace(row.Source) ? ProductCatalogConstants.SourceSkinSafe : row.Source,
            SourceUrl = NullIfEmpty(row.SourceUrl),
            CreatedAt = now,
            UpdatedAt = now
        };
    }

    private static bool ApplyImportUpdates(Product product, ImportedProductRow row)
    {
        var changed = false;

        changed |= UpdateIfBetter(
            product.Description,
            row.Description,
            updated => product.Description = updated,
            preferLonger: true);
        changed |= UpdateIfBetter(
            product.ImageUrl,
            row.ImageUrl,
            updated => product.ImageUrl = updated);
        changed |= UpdateIfBetter(
            product.UsageGuide,
            row.HowToUse,
            updated => product.UsageGuide = updated,
            preferLonger: true);
        changed |= UpdateIfBetter(
            product.UsageTime,
            row.UsageTime,
            updated => product.UsageTime = updated);
        changed |= UpdateIfBetter(
            product.SourceUrl,
            row.SourceUrl,
            updated => product.SourceUrl = updated);
        changed |= UpdateIfBetter(
            product.Source,
            row.Source,
            updated => product.Source = updated);
        changed |= UpdateIfBetter(
            product.Ingredient,
            ProductMapper.SerializeIngredients(row.Ingredients),
            updated => product.Ingredient = updated,
            preferLonger: true);
        changed |= UpdateIfBetter(
            product.SuitableSkinTypes,
            row.SkinTypes,
            updated => product.SuitableSkinTypes = updated,
            preferLonger: true);
        changed |= UpdateIfBetter(
            product.TargetConcerns,
            row.SkinConcerns,
            updated => product.TargetConcerns = updated,
            preferLonger: true);
        changed |= UpdateIfBetter(
            product.KeyIngredients,
            ProductMapper.SerializeKeyIngredients(row.Ingredients),
            updated => product.KeyIngredients = updated,
            preferLonger: true);

        if (string.IsNullOrWhiteSpace(product.Category) && !string.IsNullOrWhiteSpace(row.Category))
        {
            product.Category = row.Category;
            changed = true;
        }

        if (!product.Price.HasValue && row.Price.HasValue)
        {
            product.Price = row.Price;
            changed = true;
        }

        if (string.IsNullOrWhiteSpace(product.Currency) && !string.IsNullOrWhiteSpace(row.Currency))
        {
            product.Currency = row.Currency;
            changed = true;
        }

        if (product.IsVerified != row.IsVerified)
        {
            product.IsVerified = row.IsVerified;
            changed = true;
        }

        if (product.IsActive != row.IsActive)
        {
            product.IsActive = row.IsActive;
            product.Status = ProductCatalogConstants.NormalizeStatusForActiveFlag(product.Status, row.IsActive);
            changed = true;
        }

        return changed;
    }

    private static bool UpdateIfBetter(
        string? currentValue,
        string? incomingValue,
        Action<string> apply,
        bool preferLonger = false)
    {
        var normalizedIncoming = NullIfEmpty(incomingValue);
        if (string.IsNullOrWhiteSpace(normalizedIncoming))
        {
            return false;
        }

        if (string.IsNullOrWhiteSpace(currentValue))
        {
            apply(normalizedIncoming);
            return true;
        }

        if (preferLonger && normalizedIncoming!.Length > currentValue!.Length)
        {
            apply(normalizedIncoming);
            return true;
        }

        return false;
    }

    private static string? NullIfEmpty(string? value)
        => string.IsNullOrWhiteSpace(value) ? null : value.Trim();

    private static bool TryParseBoolean(string value)
        => bool.TryParse(value, out var parsed) && parsed;

    private static decimal? TryParseNullableDecimal(string value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return decimal.TryParse(value, NumberStyles.Number, CultureInfo.InvariantCulture, out var parsed)
            ? parsed
            : null;
    }

    private sealed class ImportedProductRow
    {
        public string Name { get; set; } = string.Empty;
        public string Brand { get; set; } = string.Empty;
        public string Category { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public string ImageUrl { get; set; } = string.Empty;
        public decimal? Price { get; set; }
        public string Currency { get; set; } = string.Empty;
        public string SkinTypes { get; set; } = "[]";
        public string SkinConcerns { get; set; } = "[]";
        public string UsageTime { get; set; } = string.Empty;
        public string HowToUse { get; set; } = string.Empty;
        public string Ingredients { get; set; } = string.Empty;
        public bool IsVerified { get; set; }
        public bool IsActive { get; set; }
        public string Source { get; set; } = string.Empty;
        public string SourceUrl { get; set; } = string.Empty;
    }
}
