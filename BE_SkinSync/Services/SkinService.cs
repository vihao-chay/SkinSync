using System.IO;
using System.Net.Http;
using System.Text;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Logging;
using SkinSync.Models.Dtos.Skin;
using SkinSync.Repositories;
using SkinSync.Services.AI;

namespace SkinSync.Services;

public class SkinService : ISkinService
{
    private readonly IAiService _aiService;
    private readonly IIngredientConflictService _ingredientConflictService;
    private readonly IProductRepository _productRepository;
    private readonly IWebHostEnvironment _environment;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly ILogger<SkinService> _logger;

    public SkinService(
        IAiService aiService,
        IIngredientConflictService ingredientConflictService,
        IProductRepository productRepository,
        IWebHostEnvironment environment,
        IHttpClientFactory httpClientFactory,
        ILogger<SkinService> logger)
    {
        _aiService = aiService;
        _ingredientConflictService = ingredientConflictService;
        _productRepository = productRepository;
        _environment = environment;
        _httpClientFactory = httpClientFactory;
        _logger = logger;
    }

    public async Task<SkinAnalyzeResponseDto> AnalyzeSkinSync(SkinAnalyzeRequestDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.ImageUrl))
        {
            throw new ArgumentException("Image URL is required.");
        }

        byte[] imageBytes;
        string contentType;

        if (request.ImageUrl.StartsWith("data:", StringComparison.OrdinalIgnoreCase))
        {
            var commaIndex = request.ImageUrl.IndexOf(',');
            if (commaIndex <= 0 || commaIndex >= request.ImageUrl.Length - 1)
            {
                throw new ArgumentException("Invalid data URL format.");
            }

            var meta = request.ImageUrl[..commaIndex];
            var dataPart = request.ImageUrl[(commaIndex + 1)..];
            var semicolonIndex = meta.IndexOf(';');
            var mimeType = semicolonIndex > 5 ? meta[5..semicolonIndex] : "image/jpeg";
            contentType = string.IsNullOrWhiteSpace(mimeType) ? "image/jpeg" : mimeType;
            imageBytes = Convert.FromBase64String(dataPart);
        }
        else if (request.ImageUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) || 
            request.ImageUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogInformation("Downloading image from remote URL: {Url}", request.ImageUrl);
            using var client = _httpClientFactory.CreateClient();
            var response = await client.GetAsync(request.ImageUrl, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                throw new HttpRequestException($"Failed to download image from remote URL. Status: {response.StatusCode}");
            }
            imageBytes = await response.Content.ReadAsByteArrayAsync(cancellationToken);
            contentType = response.Content.Headers.ContentType?.MediaType ?? GetContentTypeFromExtension(request.ImageUrl);
        }
        else
        {
            _logger.LogInformation("Resolving image from local relative path: {Path}", request.ImageUrl);
            var webRoot = _environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot");
            var cleanPath = request.ImageUrl.TrimStart('/');
            var absolutePath = Path.Combine(webRoot, cleanPath);

            if (!File.Exists(absolutePath))
            {
                throw new FileNotFoundException($"Local skin image file not found at: {absolutePath}");
            }

            imageBytes = await File.ReadAllBytesAsync(absolutePath, cancellationToken);
            contentType = GetContentTypeFromExtension(absolutePath);
        }

        return await _aiService.AnalyzeSkinSync(imageBytes, contentType, cancellationToken);
    }

    public async Task<SkinChatResponseDto> GetSkincareAdviceAsync(SkinChatRequestDto request, CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(request.Message))
        {
            throw new ArgumentException("Message cannot be empty.");
        }

        return await _aiService.GetSkincareAdviceAsync(request.Message, request.UserProfile, cancellationToken);
    }

    public async Task<SkinRoutineResponseDto> BuildRoutineAsync(SkinRoutineRequestDto request, CancellationToken cancellationToken)
    {
        // 1. Fetch Ingredient Conflict Rules from database
        var rules = await _ingredientConflictService.GetRulesAsync(cancellationToken);
        var sbRules = new StringBuilder();
        foreach (var rule in rules)
        {
            sbRules.AppendLine($"- {rule.PrimaryIngredient} conflicts with {rule.ConflictingIngredient} ({rule.Severity}). Recommended: {rule.Recommendation}");
        }

        // 2. Fetch Active Products from database
        var dbProducts = await _productRepository.GetAllAsync(cancellationToken);
        var activeProducts = dbProducts.Where(p => string.Equals(p.Status, "active", StringComparison.OrdinalIgnoreCase)).ToList();

        var sbProducts = new StringBuilder();
        foreach (var p in activeProducts)
        {
            var types = string.Join(", ", p.SuitableSkinTypes);
            sbProducts.AppendLine($"- Brand: {p.Brand}, Name: {p.Name}, Category: {p.Category}, Ingredients: {p.Ingredient}, Suitable for: [{types}], Price: {p.Price}");
        }

        // 3. Assemble instructions with rules and products context
        var systemInstructions = new StringBuilder();
        systemInstructions.AppendLine("You are an expert AI Skincare Routine Builder for SkinSync.");
        systemInstructions.AppendLine("You will design a customized morning (AM) and evening (PM) routine.");
        
        if (rules.Any())
        {
            systemInstructions.AppendLine("\n[CRITICAL: INGREDIENT CONFLICT RULES]");
            systemInstructions.AppendLine("You MUST strictly avoid pairing conflicting ingredients. If two ingredients conflict, DO NOT recommend them in the same routine (e.g. use one in AM, one in PM, or avoid one entirely).");
            systemInstructions.Append(sbRules);
        }

        if (activeProducts.Any())
        {
            systemInstructions.AppendLine("\n[AVAILABLE PRODUCTS DATABASE]");
            systemInstructions.AppendLine("Please select products from this list when possible, matching the user's budget and skin suitability. Use the exact product Name and Brand as 'product_recommendation'.");
            systemInstructions.Append(sbProducts);
        }

        systemInstructions.AppendLine("\n[OUTPUT FORMAT]");
        systemInstructions.AppendLine("You MUST return ONLY a JSON object matching this schema:");
        systemInstructions.AppendLine("{");
        systemInstructions.AppendLine("  \"routine\": {");
        systemInstructions.AppendLine("    \"morning\": [");
        systemInstructions.AppendLine("      {");
        systemInstructions.AppendLine("        \"step\": 1,");
        systemInstructions.AppendLine("        \"category\": \"Cleanser\",");
        systemInstructions.AppendLine("        \"product_recommendation\": \"Name by Brand\",");
        systemInstructions.AppendLine("        \"instructions\": \"Apply to wet skin...\",");
        systemInstructions.AppendLine("        \"active_ingredients\": [\"Glycerin\"]");
        systemInstructions.AppendLine("      }");
        systemInstructions.AppendLine("    ],");
        systemInstructions.AppendLine("    \"evening\": [...]");
        systemInstructions.AppendLine("  }");
        systemInstructions.AppendLine("}");

        return await _aiService.BuildRoutineAsync(request, systemInstructions.ToString(), cancellationToken);
    }

    private static string GetContentTypeFromExtension(string path)
    {
        var extension = Path.GetExtension(path).ToLowerInvariant();
        return extension switch
        {
            ".png" => "image/png",
            ".gif" => "image/gif",
            ".webp" => "image/webp",
            _ => "image/jpeg"
        };
    }
}
