namespace SkinSync.Models.Entities;

public class SkinProgressAnalysis
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid PhotoId { get; set; }
    public string Status { get; set; } = "pending";
    public string? AiModel { get; set; }
    public string SkinTypeEstimate { get; set; } = "unknown";
    public string HydrationLevel { get; set; } = "unknown";
    public string OilinessLevel { get; set; } = "unknown";
    public int AcneScore { get; set; }
    public int RednessScore { get; set; }
    public int DarkSpotScore { get; set; }
    public int OilinessScore { get; set; }
    public int DrynessScore { get; set; }
    public int TextureScore { get; set; }
    public int SensitivityScore { get; set; }
    public int OverallScore { get; set; }
    public decimal? ConfidenceScore { get; set; }
    public string DetectedConcerns { get; set; } = "[]";
    public string AiSummary { get; set; } = string.Empty;
    public string Recommendations { get; set; } = "[]";
    public string RoutineSuggestions { get; set; } = "{}";
    public string ProductSuggestions { get; set; } = "[]";
    public string SafetyNotes { get; set; } = "[]";
    public string RiskFlags { get; set; } = "[]";
    public string? RawAiResponse { get; set; }
    public string? ParsedAiResponse { get; set; }
    public string? ErrorMessage { get; set; }
    public DateTime? CompletedAt { get; set; }
    public DateTime? DiscardedAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public SkinProgressPhoto Photo { get; set; } = null!;
}
