namespace SkinSync.Models.Dtos.Skin;

public class SkinRoutineRequestDto
{
    public string SkinType { get; set; } = string.Empty;
    public List<string> Concerns { get; set; } = new();
    public string Budget { get; set; } = string.Empty;
}
