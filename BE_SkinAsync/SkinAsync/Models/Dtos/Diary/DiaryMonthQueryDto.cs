using SkinAsync.Base;

namespace SkinAsync.Models.Dtos.Diary;

public class DiaryMonthQueryDto : PagingQuery
{
    public int? Year { get; set; }
    public int? Month { get; set; }
    public bool? IsIrritated { get; set; }
    public string? SkinFeeling { get; set; }
}
