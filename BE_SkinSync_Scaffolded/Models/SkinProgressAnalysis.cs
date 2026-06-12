using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class SkinProgressAnalysis
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public Guid PhotoId { get; set; }

    public string SkinTypeEstimate { get; set; } = null!;

    public string HydrationLevel { get; set; } = null!;

    public string OilinessLevel { get; set; } = null!;

    public int AcneScore { get; set; }

    public int RednessScore { get; set; }

    public int DarkSpotScore { get; set; }

    public int OilinessScore { get; set; }

    public int DrynessScore { get; set; }

    public int TextureScore { get; set; }

    public int SensitivityScore { get; set; }

    public int OverallScore { get; set; }

    public string DetectedConcerns { get; set; } = null!;

    public string AiSummary { get; set; } = null!;

    public string Recommendations { get; set; } = null!;

    public string RiskFlags { get; set; } = null!;

    public string? RawAiResponse { get; set; }

    public DateTime CreatedAt { get; set; }

    public string Status { get; set; } = null!;

    public string? AiModel { get; set; }

    public decimal? ConfidenceScore { get; set; }

    public string RoutineSuggestions { get; set; } = null!;

    public string ProductSuggestions { get; set; } = null!;

    public string SafetyNotes { get; set; } = null!;

    public string? ParsedAiResponse { get; set; }

    public string? ErrorMessage { get; set; }

    public DateTime? CompletedAt { get; set; }

    public DateTime? DiscardedAt { get; set; }

    public virtual SkinProgressPhoto Photo { get; set; } = null!;

    public virtual ICollection<SkinPhotoComparison> SkinPhotoComparisonAfterAnalyses { get; set; } = new List<SkinPhotoComparison>();

    public virtual ICollection<SkinPhotoComparison> SkinPhotoComparisonBeforeAnalyses { get; set; } = new List<SkinPhotoComparison>();

    public virtual ICollection<SkinProgressReport> SkinProgressReports { get; set; } = new List<SkinProgressReport>();

    public virtual User1 User { get; set; } = null!;

    public virtual ICollection<UserRegimen> UserRegimen { get; set; } = new List<UserRegimen>();
}
