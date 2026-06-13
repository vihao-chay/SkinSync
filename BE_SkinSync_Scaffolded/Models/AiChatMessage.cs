using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class AiChatMessage
{
    public Guid Id { get; set; }

    public Guid ConversationId { get; set; }

    public string Role { get; set; } = null!;

    public string Content { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public virtual AiChatConversation Conversation { get; set; } = null!;
}
