using SkinSync.Models.Dtos.Diary;
using SkinSync.Models.Entities;
using SkinSync.Helpers;

namespace SkinSync.Mappers;

public static class DiaryMapper
{
    public static DiaryCheckInResponseDto ToCheckInDto(this DailyLog dailyLog)
    {
        var payload = DailyLogPayloadHelper.Parse(dailyLog.Notes);
        var note = dailyLog.AcneLevel.HasValue
                   || dailyLog.DrynessLevel.HasValue
                   || dailyLog.RednessLevel.HasValue
                   || dailyLog.IrritationLevel.HasValue
                   || dailyLog.HydrationLevel.HasValue
            ? dailyLog.Notes
            : payload.Note;

        return new DiaryCheckInResponseDto
        {
            Id = dailyLog.Id,
            UserId = dailyLog.UserId,
            Date = dailyLog.Date,
            MorningCompleted = dailyLog.MorningCompleted,
            EveningCompleted = dailyLog.EveningCompleted,
            SkinFeeling = dailyLog.SkinFeeling,
            IsIrritated = dailyLog.IsIrritated,
            Notes = note,
            AcneLevel = dailyLog.AcneLevel ?? payload.AcneLevel,
            DrynessLevel = dailyLog.DrynessLevel ?? payload.DrynessLevel,
            RednessLevel = dailyLog.RednessLevel ?? payload.RednessLevel,
            IrritationLevel = dailyLog.IrritationLevel ?? payload.IrritationLevel,
            HydrationLevel = dailyLog.HydrationLevel ?? payload.HydrationLevel,
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
