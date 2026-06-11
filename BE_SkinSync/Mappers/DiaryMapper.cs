using SkinSync.Models.Dtos.Diary;
using SkinSync.Models.Entities;
using SkinSync.Helpers;

namespace SkinSync.Mappers;

public static class DiaryMapper
{
    public static DiaryCheckInResponseDto ToCheckInDto(this DailyLog dailyLog)
    {
        var payload = DailyLogPayloadHelper.Parse(dailyLog.Notes);

        return new DiaryCheckInResponseDto
        {
            Id = dailyLog.Id,
            UserId = dailyLog.UserId,
            Date = dailyLog.Date,
            MorningCompleted = dailyLog.MorningCompleted,
            EveningCompleted = dailyLog.EveningCompleted,
            SkinFeeling = dailyLog.SkinFeeling,
            IsIrritated = dailyLog.IsIrritated,
            Notes = payload.Note,
            AcneLevel = payload.AcneLevel,
            DrynessLevel = payload.DrynessLevel,
            RednessLevel = payload.RednessLevel,
            IrritationLevel = payload.IrritationLevel,
            HydrationLevel = payload.HydrationLevel,
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
