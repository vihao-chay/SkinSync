namespace SkinSync.Models.Dtos.Diary;

public class MonthlyDiaryResponseDto
{
    public int Year { get; set; }
    public int Month { get; set; }
    public IEnumerable<MonthlyDiaryDayDto> Days { get; set; } = Array.Empty<MonthlyDiaryDayDto>();
}

public class MonthlyDiaryDayDto
{
    public DateOnly Date { get; set; }
    public bool MorningCompleted { get; set; }
    public bool EveningCompleted { get; set; }
    public string? SkinFeeling { get; set; }
    public bool IsIrritated { get; set; }
    public bool HasImage { get; set; }
}
