using Microsoft.AspNetCore.Http;

namespace SkinAsync.Models.Dtos;

public class AnalysisScanRequestDto
{
    public IFormFile Image { get; set; } = null!;
}
