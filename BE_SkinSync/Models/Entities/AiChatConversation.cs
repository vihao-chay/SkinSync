namespace SkinSync.Models.Entities;

public class AiChatConversation
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Title { get; set; } = "New chat";
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    public DateTime LastMessageAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
    public ICollection<AiChatMessage> Messages { get; set; } = new List<AiChatMessage>();
}
