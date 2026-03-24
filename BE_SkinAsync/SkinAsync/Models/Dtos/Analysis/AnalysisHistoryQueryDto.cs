using SkinAsync.Base;

namespace SkinAsync.Models.Dtos.Analysis;

public class AnalysisHistoryQueryDto : PagingQuery
{
    public int? MinOverallScore { get; set; }
    public int? MaxOverallScore { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
}
