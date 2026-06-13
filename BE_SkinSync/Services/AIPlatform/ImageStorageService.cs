using SkinSync.Helpers;
using SkinSync.Models.Dtos.AI;

namespace SkinSync.Services.AIPlatform;

public interface IImageStorageService
{
    Task<string> StoreSkinProgressPhotoAsync(SkinProgressPhotoUploadRequestDto request, CancellationToken cancellationToken);
    Task<string> BuildImageSourceAsync(string imageUrl, CancellationToken cancellationToken);
    void TryDeleteLocalFile(string? url);
}

public class ImageStorageService : IImageStorageService
{
    private readonly IWebHostEnvironment _environment;

    public ImageStorageService(IWebHostEnvironment environment)
    {
        _environment = environment;
    }

    public async Task<string> StoreSkinProgressPhotoAsync(
        SkinProgressPhotoUploadRequestDto request,
        CancellationToken cancellationToken)
    {
        if (request.Image is null)
        {
            return request.ImageUrl!.Trim();
        }

        var uploadDir = Path.Combine(
            _environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot"),
            "uploads",
            "skin-progress");
        Directory.CreateDirectory(uploadDir);

        var extension = Path.GetExtension(request.Image.FileName);
        var fileName = $"{Guid.NewGuid():N}{extension}";
        var fullPath = Path.Combine(uploadDir, fileName);

        await using var stream = File.Create(fullPath);
        await request.Image.CopyToAsync(stream, cancellationToken);
        return $"/uploads/skin-progress/{fileName}";
    }

    public async Task<string> BuildImageSourceAsync(string imageUrl, CancellationToken cancellationToken)
    {
        if (imageUrl.StartsWith("data:", StringComparison.OrdinalIgnoreCase) ||
            imageUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ||
            imageUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase))
        {
            return imageUrl;
        }

        var webRoot = _environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot");
        var absolutePath = Path.Combine(webRoot, imageUrl.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
        var bytes = await File.ReadAllBytesAsync(absolutePath, cancellationToken);
        var contentType = ImageMimeTypeHelper.ResolveForPath(absolutePath, bytes);
        return $"data:{contentType};base64,{Convert.ToBase64String(bytes)}";
    }

    public void TryDeleteLocalFile(string? url)
    {
        if (string.IsNullOrWhiteSpace(url) || url.StartsWith("http", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var webRoot = _environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot");
        var fullPath = Path.Combine(webRoot, url.TrimStart('/').Replace('/', Path.DirectorySeparatorChar));
        if (File.Exists(fullPath))
        {
            File.Delete(fullPath);
        }
    }
}
