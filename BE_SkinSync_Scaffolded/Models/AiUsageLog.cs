using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class AiUsageLog
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string FeatureName { get; set; } = null!;

    public DateTime UsedAt { get; set; }

    public int? InputTokens { get; set; }

    public int? OutputTokens { get; set; }

    public string? Model { get; set; }

    public decimal? CostEstimate { get; set; }

    public virtual User1 User { get; set; } = null!;
}
