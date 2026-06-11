namespace SkinSync.Models.Dtos.Admin;

public class AdminDashboardResponseDto
{
    public int TotalUsers { get; set; }
    public int TotalAnalyses { get; set; }
    public int ActiveUsers { get; set; }
    public IDictionary<string, int> SkinTypeDistribution { get; set; } = new Dictionary<string, int>();
}
