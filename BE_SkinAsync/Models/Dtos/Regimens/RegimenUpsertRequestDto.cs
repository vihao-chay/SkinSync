using System.ComponentModel.DataAnnotations;

namespace SkinAsync.Models.Dtos.Regimens;

public class RegimenUpsertRequestDto
{
    [MaxLength(120)]
    public string Name { get; set; } = "Lộ trình chăm sóc da";

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
