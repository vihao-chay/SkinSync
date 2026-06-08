using SkinSync.Models.Dtos.Diary;
using SkinSync.Models.Entities;

namespace SkinSync.Mappers;

public static class DiaryMapper
{
    public static DiaryCheckInResponseDto ToCheckInDto(this DailyLog dailyLog)
    {
        return new DiaryCheckInResponseDto
        {
            Id = dailyLog.Id,
            UserId = dailyLog.UserId,
            Date = dailyLog.Date,
            MorningCompleted = dailyLog.MorningCompleted,
            EveningCompleted = dailyLog.EveningCompleted,
            SkinFeeling = dailyLog.SkinFeeling,
            IsIrritated = dailyLog.IsIrritated,
            Notes = dailyLog.Notes,
            DailyImageUrl = dailyLog.DailyImageUrl
        };
    }

    public static MonthlyDiaryDayDto ToMonthlyDayDto(this DailyLog dailyLog)
    {
        return new MonthlyDiaryDayDto
        {
            Date = dailyLog.Date,
            MorningCompleted = dailyLog.MorningCompleted,
            EveningCompleted = dailyLog.EveningCompleted,
            SkinFeeling = dailyLog.SkinFeeling,
            IsIrritated = dailyLog.IsIrritated,
            HasImage = !string.IsNullOrWhiteSpace(dailyLog.DailyImageUrl)
        };
    }
}
