using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class RegimenItem
{
    public Guid Id { get; set; }

    public Guid RegimenId { get; set; }

    public Guid ProductId { get; set; }

    public string RoutineTime { get; set; } = null!;

    public int StepOrder { get; set; }

    public string? Instruction { get; set; }

    public DateTime CreatedAt { get; set; }

    public string? Frequency { get; set; }

    public virtual Product Product { get; set; } = null!;

    public virtual UserRegimen Regimen { get; set; } = null!;

    public virtual ICollection<RoutineTracking> RoutineTrackings { get; set; } = new List<RoutineTracking>();
}
