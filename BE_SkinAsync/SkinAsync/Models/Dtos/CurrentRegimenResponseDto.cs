namespace SkinAsync.Models.Dtos;

public class CurrentRegimenResponseDto
{
    public Guid RegimenId { get; set; }
    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }
    public decimal TotalEstimatedCost { get; set; }
    public IEnumerable<RegimenProductDto> Morning { get; set; } = Array.Empty<RegimenProductDto>();
    public IEnumerable<RegimenProductDto> Evening { get; set; } = Array.Empty<RegimenProductDto>();
}

public class RegimenProductDto
{
    public Guid ProductId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public decimal Price { get; set; }
    public string? ImageUrl { get; set; }
    public int StepOrder { get; set; }
}
