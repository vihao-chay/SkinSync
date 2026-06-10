namespace SkinSync.Models.Entities;

public class AiChatMessage
{
    public Guid Id { get; set; }
    public Guid ConversationId { get; set; }
    public string Role { get; set; } = "user";
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public AiChatConversation Conversation { get; set; } = null!;
}
