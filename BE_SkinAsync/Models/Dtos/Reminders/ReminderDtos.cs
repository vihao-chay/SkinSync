using System.ComponentModel.DataAnnotations;

namespace SkinAsync.Models.Dtos.Reminders;

public class ReminderResponseDto
{
    public Guid ReminderId { get; set; }
    public string Time { get; set; } = string.Empty;
    public string RoutineType { get; set; } = string.Empty;
    public bool IsEnabled { get; set; }
}

public class ReminderUpsertRequestDto
{
    [Required]
    public string Time { get; set; } = string.Empty;

    [Required]
    [MaxLength(20)]
    public string RoutineType { get; set; } = "Morning";

    public bool IsEnabled { get; set; } = true;
}
