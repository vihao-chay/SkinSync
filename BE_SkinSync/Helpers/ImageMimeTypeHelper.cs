using Microsoft.AspNetCore.Http;

namespace SkinSync.Helpers;

public static class ImageMimeTypeHelper
{
    public static string ResolveForUpload(IFormFile file, byte[] bytes)
    {
        var contentType = Normalize(file.ContentType);
        if (IsSupportedImageType(contentType))
        {
            return contentType!;
        }

        var fromExtension = FromExtension(Path.GetExtension(file.FileName));
        if (fromExtension is not null)
        {
            return fromExtension;
        }

        return FromBytes(bytes) ?? "image/jpeg";
    }

    public static string ResolveForPath(string? path, byte[] bytes)
    {
        var fromExtension = FromExtension(Path.GetExtension(path ?? string.Empty));
        if (fromExtension is not null)
        {
            return fromExtension;
        }

        return FromBytes(bytes) ?? "image/jpeg";
    }

    private static string? Normalize(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return value.Trim().ToLowerInvariant();
    }

    private static bool IsSupportedImageType(string? value) =>
        value is "image/jpeg" or "image/jpg" or "image/png" or "image/webp" or "image/gif";

    private static string? FromExtension(string? extension)
    {
        return extension?.Trim().ToLowerInvariant() switch
        {
            ".jpg" => "image/jpeg",
            ".jpeg" => "image/jpeg",
            ".png" => "image/png",
            ".webp" => "image/webp",
            ".gif" => "image/gif",
            _ => null
        };
    }

    private static string? FromBytes(byte[] bytes)
    {
        if (bytes.Length >= 3 &&
            bytes[0] == 0xFF &&
            bytes[1] == 0xD8 &&
            bytes[2] == 0xFF)
        {
            return "image/jpeg";
        }

        if (bytes.Length >= 8 &&
            bytes[0] == 0x89 &&
            bytes[1] == 0x50 &&
            bytes[2] == 0x4E &&
            bytes[3] == 0x47 &&
            bytes[4] == 0x0D &&
            bytes[5] == 0x0A &&
            bytes[6] == 0x1A &&
            bytes[7] == 0x0A)
        {
            return "image/png";
        }

        if (bytes.Length >= 6)
        {
            var header = System.Text.Encoding.ASCII.GetString(bytes, 0, 6);
            if (header is "GIF87a" or "GIF89a")
            {
                return "image/gif";
            }
        }

        if (bytes.Length >= 12 &&
            bytes[0] == 0x52 &&
            bytes[1] == 0x49 &&
            bytes[2] == 0x46 &&
            bytes[3] == 0x46 &&
            bytes[8] == 0x57 &&
            bytes[9] == 0x45 &&
            bytes[10] == 0x42 &&
            bytes[11] == 0x50)
        {
            return "image/webp";
        }

        return null;
    }
}
