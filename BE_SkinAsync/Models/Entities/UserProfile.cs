namespace SkinAsync.Models.Entities;

public class UserProfile
{
    public Guid UserId { get; set; }
    public string SkinType { get; set; } = "Normal";
    public string[] SkinConcerns { get; set; } = Array.Empty<string>();
    public string MonthlyBudget { get; set; } = "Mid-range";
    public int? Age { get; set; }
    public int? BirthYear { get; set; }

    public User User { get; set; } = null!;
}
