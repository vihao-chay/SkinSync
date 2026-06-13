using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class DailyLog
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public DateOnly Date { get; set; }

    public bool MorningCompleted { get; set; }

    public bool EveningCompleted { get; set; }

    public string? SkinFeeling { get; set; }

    public bool IsIrritated { get; set; }

    public string? Notes { get; set; }

    public string? DailyImageUrl { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public int? AcneLevel { get; set; }

    public int? DrynessLevel { get; set; }

    public int? RednessLevel { get; set; }

    public int? IrritationLevel { get; set; }

    public int? HydrationLevel { get; set; }

    public virtual User1 User { get; set; } = null!;
}
