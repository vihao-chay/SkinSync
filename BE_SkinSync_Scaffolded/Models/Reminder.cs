using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class Reminder
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public TimeOnly Time { get; set; }

    public string RoutineType { get; set; } = null!;

    public bool IsEnabled { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public string Frequency { get; set; } = null!;

    public bool IsAdaptive { get; set; }

    public string Priority { get; set; } = null!;

    public string? Reason { get; set; }

    public virtual User1 User { get; set; } = null!;
}
