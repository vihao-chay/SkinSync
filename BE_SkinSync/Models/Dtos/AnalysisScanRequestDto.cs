using Microsoft.AspNetCore.Http;

namespace SkinSync.Models.Dtos;

public class AnalysisScanRequestDto
{
    public IFormFile Image { get; set; } = null!;
}
