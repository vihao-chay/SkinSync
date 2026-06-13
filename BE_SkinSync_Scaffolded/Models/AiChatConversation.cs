using System;
using System.Collections.Generic;

namespace SkinSync;

public partial class AiChatConversation
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }

    public string Title { get; set; } = null!;

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public DateTime LastMessageAt { get; set; }

    public virtual ICollection<AiChatMessage> AiChatMessages { get; set; } = new List<AiChatMessage>();

    public virtual User1 User { get; set; } = null!;
}
