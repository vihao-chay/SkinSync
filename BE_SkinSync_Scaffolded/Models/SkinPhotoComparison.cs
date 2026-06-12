using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class SkinPhotoComparison
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public Guid BeforePhotoId { get; set; }

    public Guid AfterPhotoId { get; set; }

    public Guid BeforeAnalysisId { get; set; }

    public Guid AfterAnalysisId { get; set; }

    public string ProgressStatus { get; set; } = null!;

    public string ComparisonSummary { get; set; } = null!;

    public string Improvements { get; set; } = null!;

    public string WorsenedAreas { get; set; } = null!;

    public string StableAreas { get; set; } = null!;

    public string ScoreChanges { get; set; } = null!;

    public string Recommendations { get; set; } = null!;

    public string? ConfidenceNote { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual SkinProgressAnalysis AfterAnalysis { get; set; } = null!;

    public virtual SkinProgressPhoto AfterPhoto { get; set; } = null!;

    public virtual SkinProgressAnalysis BeforeAnalysis { get; set; } = null!;

    public virtual SkinProgressPhoto BeforePhoto { get; set; } = null!;

    public virtual User1 User { get; set; } = null!;
}
