import { Bot } from "lucide-react";
import { useMemo, useState } from "react";
import { AppChatBubble } from "../../components/AppChatBubble";
import { AppChatComposer } from "../../components/AppChatComposer";
import { AppEmptyState } from "../../components/AppEmptyState";
import { AppPageHeader } from "../../components/AppPageHeader";
import { AppSection } from "../../components/AppSection";
import { Button } from "../../components/ui/button";
import { APP_SUGGESTED_CHAT_PROMPTS } from "../../constants/appShell";
import { sendSkinChatMessage } from "../../services/skinChatService";

interface ChatMessage {
  id: string;
  role: "user" | "assistant";
  message: string;
  createdAt: string;
  error?: boolean;
}

export function AppChatPage() {
  const [value, setValue] = useState("");
  const [loading, setLoading] = useState(false);
  const [messages, setMessages] = useState<ChatMessage[]>([]);

  const canSend = useMemo(() => value.trim().length > 0 && !loading, [loading, value]);

  async function submitMessage(nextMessage?: string) {
    const content = (nextMessage ?? value).trim();
    if (!content || loading) return;

    const now = new Date().toISOString();
    setMessages((prev) => [...prev, { id: `${Date.now()}-user`, role: "user", message: content, createdAt: now }]);
    setValue("");
    setLoading(true);

    const result = await sendSkinChatMessage(content);
    setLoading(false);

    setMessages((prev) => [
      ...prev,
      {
        id: `${Date.now()}-assistant`,
        role: "assistant",
        message: result.success ? result.content?.response || "No response returned." : result.message || "Unable to reach the skincare assistant.",
        createdAt: new Date().toISOString(),
        error: !result.success,
      },
    ]);
  }

  return (
    <div className="space-y-6">
      <AppPageHeader
        eyebrow="AI Assistant"
        title="Ask your skincare assistant"
        description="Send raw user messages to the backend chat service. The frontend does not build OpenAI prompts or call providers directly."
      />

      <div className="grid gap-4 xl:grid-cols-[1.1fr_0.9fr]">
        <AppSection title="Conversation" description="A real chat layout with sticky-feeling composer, clear role separation, and explicit error bubbles.">
          <div className="flex min-h-[620px] flex-col">
            <div className="flex-1 space-y-4 overflow-y-auto pb-4">
              {messages.length ? (
                messages.map((message) => (
                  <AppChatBubble
                    key={message.id}
                    role={message.role}
                    message={message.message}
                    createdAt={message.createdAt}
                    error={message.error}
                  />
                ))
              ) : (
                <AppEmptyState
                  title="Start the conversation"
                  description="Ask about routines, ingredient compatibility, dryness, irritation, or how to interpret your latest analysis."
                  icon={Bot}
                />
              )}
              {loading ? (
                <AppChatBubble
                  role="assistant"
                  message="Thinking through your skincare question..."
                  createdAt={new Date().toISOString()}
                />
              ) : null}
            </div>
            <div className="mt-4">
              <AppChatComposer value={value} disabled={!canSend} onChange={setValue} onSend={() => void submitMessage()} />
            </div>
          </div>
        </AppSection>

        <AppSection title="Suggested prompts" description="Quick-start prompts to make the empty state feel purposeful instead of blank.">
          <div className="space-y-3">
            {APP_SUGGESTED_CHAT_PROMPTS.map((prompt) => (
              <Button
                key={prompt}
                variant="outline"
                className="w-full justify-start border-border bg-card text-left text-foreground hover:bg-muted"
                onClick={() => {
                  setValue(prompt);
                  void submitMessage(prompt);
                }}
              >
                {prompt}
              </Button>
            ))}
          </div>
        </AppSection>
      </div>
    </div>
  );
}
