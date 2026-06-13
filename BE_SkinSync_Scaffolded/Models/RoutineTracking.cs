using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class RoutineTracking
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public Guid StepId { get; set; }

    public DateTime? CompletedAt { get; set; }

    public string Status { get; set; } = null!;

    public string? Note { get; set; }

    public DateOnly TrackingDate { get; set; }

    public string RoutineTime { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime? UpdatedAt { get; set; }

    public virtual RegimenItem Step { get; set; } = null!;

    public virtual User1 User { get; set; } = null!;
}
