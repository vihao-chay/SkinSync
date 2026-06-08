namespace SkinSync.Models.Dtos;

public class CurrentRegimenResponseDto
{
    public Guid RegimenId { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateOnly StartDate { get; set; }
    public DateOnly? EndDate { get; set; }
    public bool IsCustom { get; set; }
    public decimal TotalEstimatedCost { get; set; }
    public IEnumerable<RegimenProductDto> Morning { get; set; } = Array.Empty<RegimenProductDto>();
    public IEnumerable<RegimenProductDto> Evening { get; set; } = Array.Empty<RegimenProductDto>();
}

public class RegimenProductDto
{
    public Guid StepId { get; set; }
    public Guid ProductId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Brand { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? Ingredient { get; set; }
    public string? UsageGuide { get; set; }
    public string? Instruction { get; set; }
    public decimal Price { get; set; }
    public string? ImageUrl { get; set; }
    public int StepOrder { get; set; }
}
