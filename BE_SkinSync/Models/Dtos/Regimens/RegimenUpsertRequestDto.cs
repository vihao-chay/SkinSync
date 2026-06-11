using System.ComponentModel.DataAnnotations;

namespace SkinSync.Models.Dtos.Regimens;

public class RegimenUpsertRequestDto
{
    [MaxLength(120)]
    public string Name { get; set; } = "Lá»™ trÃ¬nh chÄƒm sÃ³c da";

    public IEnumerable<RegimenStepUpsertDto> Steps { get; set; } = Array.Empty<RegimenStepUpsertDto>();
}

public class RegimenStepUpsertDto
{
    [Required]
    public Guid ProductId { get; set; }

    [Required]
    [MaxLength(20)]
    public string RoutineTime { get; set; } = "Morning";

    [Range(1, 100)]
    public int StepOrder { get; set; }

    public string Instruction { get; set; } = string.Empty;
}
