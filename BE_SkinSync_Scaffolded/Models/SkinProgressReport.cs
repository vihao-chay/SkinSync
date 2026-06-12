using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class SkinProgressReport
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string? PeriodType { get; set; }

    public DateOnly? PeriodStart { get; set; }

    public DateOnly? PeriodEnd { get; set; }

    public string ProgressStatus { get; set; } = null!;

    public string Summary { get; set; } = null!;

    public string ScoreChanges { get; set; } = null!;

    public string MainFindings { get; set; } = null!;

    public string? RoutineFeedback { get; set; }

    public string NextSuggestions { get; set; } = null!;

    public string? RawAiResponse { get; set; }

    public DateTime CreatedAt { get; set; }

    public string ReportCategory { get; set; } = null!;

    public string Source { get; set; } = null!;

    public Guid? RelatedAnalysisId { get; set; }

    public string? ProductFeedback { get; set; }

    public virtual SkinProgressAnalysis? RelatedAnalysis { get; set; }

    public virtual User1 User { get; set; } = null!;
}
