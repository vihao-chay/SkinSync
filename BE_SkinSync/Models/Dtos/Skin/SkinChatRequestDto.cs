namespace SkinSync.Models.Dtos.Skin;

public class SkinChatRequestDto
{
    public string Message { get; set; } = string.Empty;
    public UserSkinProfileDto? UserProfile { get; set; }
}

public class UserSkinProfileDto
{
    public string SkinType { get; set; } = string.Empty;
    public List<string> SkinConcerns { get; set; } = new();
    public string MonthlyBudget { get; set; } = string.Empty;
    public int? Age { get; set; }
}
