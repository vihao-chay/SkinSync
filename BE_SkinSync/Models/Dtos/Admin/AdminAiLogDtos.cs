namespace SkinSync.Models.Dtos.Admin;

public class AdminAiUsageLogItemDto
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string UserEmail { get; set; } = string.Empty;
    public string UserName { get; set; } = string.Empty;
    public string FeatureName { get; set; } = string.Empty;
    public string? Model { get; set; }
    public int? InputTokens { get; set; }
    public int? OutputTokens { get; set; }
    public decimal? CostEstimate { get; set; }
    public DateTime UsedAt { get; set; }
}

public class AdminAiLogsResponseDto
{
    public int TotalLogs { get; set; }
    public int DistinctUsers { get; set; }
    public IReadOnlyCollection<AdminAiUsageLogItemDto> Items { get; set; } = Array.Empty<AdminAiUsageLogItemDto>();
}
