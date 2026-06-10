using Microsoft.EntityFrameworkCore;
using SkinSync.Data;
using SkinSync.Mappers;
using SkinSync.Models.Dtos.AI;
using SkinSync.Models.Dtos.Ingredients;
using SkinSync.Models.Entities;

namespace SkinSync.Services.AIPlatform;

public interface IProductRoutineService
{
    Task<AiAddProductToRoutineResponseDto> AddToRoutineAsync(Guid userId, Guid productId, AiAddProductToRoutineRequestDto request, CancellationToken cancellationToken);
    Task<AiSavedProductDto> SaveIngredientProductAsync(Guid userId, AiSaveIngredientProductRequestDto request, CancellationToken cancellationToken);
}

public class ProductRoutineService : IProductRoutineService
{
    private readonly AppDbContext _dbContext;
    private readonly IIngredientConflictService _ingredientConflictService;

    public ProductRoutineService(AppDbContext dbContext, IIngredientConflictService ingredientConflictService)
    {
        _dbContext = dbContext;
        _ingredientConflictService = ingredientConflictService;
    }

    public async Task<AiAddProductToRoutineResponseDto> AddToRoutineAsync(Guid userId, Guid productId, AiAddProductToRoutineRequestDto request, CancellationToken cancellationToken)
    {
        var routineType = NormalizeRoutineType(request.RoutineType)
            ?? throw new AiFeatureException("INVALID_REQUEST", "RoutineType must be Morning or Evening.", 400);

        var regimen = await _dbContext.UserRegimens
            .Include(x => x.Items)
            .ThenInclude(x => x.Product)
            .FirstOrDefaultAsync(x => x.UserId == userId && x.IsActive, cancellationToken)
            ?? throw new AiFeatureException("ROUTINE_NOT_FOUND", "Generate a routine before adding products.", 404);

        var product = await _dbContext.Products
            .FirstOrDefaultAsync(x => x.Id == productId, cancellationToken)
            ?? throw new AiFeatureException("PRODUCT_NOT_FOUND", "Product not found.", 404);

        if (regimen.Items.Any(x => x.ProductId == productId && x.RoutineTime == routineType))
        {
            throw new AiFeatureException("DUPLICATE_PRODUCT", "This product is already in the selected routine.", 409);
        }

        var conflictProductIds = regimen.Items
            .Where(x => x.RoutineTime == routineType)
            .Select(x => x.ProductId)
            .Append(productId)
            .Distinct()
            .ToList();

        var conflictResult = await _ingredientConflictService.CheckAsync(conflictProductIds, cancellationToken);
        var warnings = conflictResult.Warnings
            .Select(MapWarning)
            .ToList();

        if (warnings.Count > 0 && !request.AllowConflicts)
        {
            return new AiAddProductToRoutineResponseDto
            {
                Added = false,
                RequiresConfirmation = true,
                Message = "This product may conflict with your current routine. Review the warnings before adding it.",
                Routine = regimen.ToCurrentRegimenDto(),
                Warnings = warnings
            };
        }

        var nextStepOrder = regimen.Items
            .Where(x => x.RoutineTime == routineType)
            .Select(x => x.StepOrder)
            .DefaultIfEmpty(0)
            .Max() + 1;

        regimen.Items.Add(new RegimenItem
        {
            Id = Guid.NewGuid(),
            RegimenId = regimen.Id,
            ProductId = product.Id,
            Product = product,
            RoutineTime = routineType,
            StepOrder = nextStepOrder,
            Instruction = product.UsageGuide,
            Frequency = "daily",
            CreatedAt = DateTime.UtcNow
        });
        regimen.IsCustom = true;
        regimen.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync(cancellationToken);

        await _dbContext.Entry(regimen)
            .Collection(x => x.Items)
            .Query()
            .Include(x => x.Product)
            .LoadAsync(cancellationToken);

        return new AiAddProductToRoutineResponseDto
        {
            Added = true,
            RequiresConfirmation = false,
            Message = warnings.Count > 0
                ? "Product added after confirming the potential conflicts."
                : "Product added to your routine successfully.",
            Routine = regimen.ToCurrentRegimenDto(),
            Warnings = warnings
        };
    }

    public async Task<AiSavedProductDto> SaveIngredientProductAsync(Guid userId, AiSaveIngredientProductRequestDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.ProductName) || string.IsNullOrWhiteSpace(request.IngredientsText))
        {
            throw new AiFeatureException("INVALID_REQUEST", "ProductName and IngredientsText are required.", 400);
        }

        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = request.ProductName.Trim(),
            Brand = "My Product",
            Category = string.IsNullOrWhiteSpace(request.Category) ? "Custom" : request.Category.Trim(),
            Description = "Saved from ingredient checker",
            Ingredient = request.IngredientsText.Trim(),
            UsageGuide = "Patch test first and add slowly into your routine.",
            Price = 0,
            Currency = "VND",
            Status = "inactive",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _dbContext.Products.Add(product);
        await _dbContext.SaveChangesAsync(cancellationToken);

        return new AiSavedProductDto
        {
            ProductId = product.Id,
            Name = product.Name,
            Brand = product.Brand,
            Category = product.Category,
            IsCustom = true
        };
    }

    private static AiRoutineConflictWarningDto MapWarning(IngredientConflictWarningDto warning)
    {
        return new AiRoutineConflictWarningDto
        {
            ProductAId = warning.ProductAId,
            ProductAName = warning.ProductAName,
            ProductBId = warning.ProductBId,
            ProductBName = warning.ProductBName,
            IngredientA = warning.IngredientA,
            IngredientB = warning.IngredientB,
            Severity = warning.Severity,
            Message = warning.Message,
            Recommendation = warning.Recommendation
        };
    }

    private static string? NormalizeRoutineType(string routineType)
    {
        if (routineType.Equals("Morning", StringComparison.OrdinalIgnoreCase))
        {
            return "Morning";
        }

        if (routineType.Equals("Evening", StringComparison.OrdinalIgnoreCase))
        {
            return "Evening";
        }

        return null;
    }
}
