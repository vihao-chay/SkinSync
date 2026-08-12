import { Minus, SendHorizontal, X } from "lucide-react";
import { useEffect, useRef, useState, type FormEvent } from "react";
import { sendSkinChatMessage } from "../services/skinChatService";
import { BrandMark } from "./BrandMark";

type ChatRole = "assistant" | "user";

interface ChatMessage {
  id: string;
  role: ChatRole;
  text: string;
}

const quickPrompts = [
  "Analyze my skin",
  "Build a routine",
  "Recommend products",
  "Check ingredients",
];

const welcomeMessage =
  "Hello! I am SkinSync AI. I can help you analyze skin concerns, suggest routines, explain ingredients, and answer skincare questions.";

const outOfScopeMessage =
  "I can only help with skincare and facial skin questions. Try asking about acne, oiliness, dryness, irritation, routines, products, or ingredients.";

function buildMessage(text: string, role: ChatRole): ChatMessage {
  return {
    id: crypto.randomUUID(),
    role,
    text,
  };
}

function isSkinFaceTopic(text: string) {
  const normalized = text
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");

  const greetings = ["xin chao", "hello", "hi", "chao"];
  if (greetings.some((word) => normalized.trim() === word)) {
    return true;
  }

  const keywords = [
    "da",
    "mat",
    "skin",
    "face",
    "skincare",
    "mun",
    "nam",
    "tan nhang",
    "lo chan long",
    "dau",
    "kho",
    "nhay cam",
    "kich ung",
    "do da",
    "tham",
    "seo",
    "nep nhan",
    "routine",
    "lo trinh",
    "sua rua mat",
    "toner",
    "serum",
    "duong am",
    "chong nang",
    "retinol",
    "bha",
    "aha",
    "niacinamide",
    "vitamin c",
    "hyaluronic",
    "salicylic",
    "thanh phan",
    "san pham",
  ];

  return keywords.some((keyword) => normalized.includes(keyword));
}

export function SkinAiChatBox() {
  const [isVisible, setIsVisible] = useState(true);
  const [isMinimized, setIsMinimized] = useState(false);
  const [input, setInput] = useState("");
  const [isSending, setIsSending] = useState(false);
  const [messages, setMessages] = useState<ChatMessage[]>([buildMessage(welcomeMessage, "assistant")]);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    scrollRef.current?.scrollTo({
      top: scrollRef.current.scrollHeight,
      behavior: "smooth",
    });
  }, [messages, isSending]);

  async function sendMessage(nextText: string) {
    const trimmed = nextText.trim();
    if (!trimmed || isSending) return;

    setInput("");
    setMessages((current) => [...current, buildMessage(trimmed, "user")]);

    if (!isSkinFaceTopic(trimmed)) {
      setMessages((current) => [...current, buildMessage(outOfScopeMessage, "assistant")]);
      return;
    }

    setIsSending(true);
    const result = await sendSkinChatMessage(trimmed);
    setIsSending(false);

    if (!result.success || !result.content?.response) {
      setMessages((current) => [
        ...current,
        buildMessage(result.message || "SkinSync AI cannot respond right now. Please try again later.", "assistant"),
      ]);
      return;
    }

    setMessages((current) => [...current, buildMessage(result.content.response, "assistant")]);
  }

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    void sendMessage(input);
  }

  if (!isVisible) {
    return (
      <button
        type="button"
        onClick={() => {
          setIsVisible(true);
          setIsMinimized(false);
        }}
        className="fixed bottom-6 right-6 z-[60] flex items-center gap-2 rounded-full border border-border bg-card px-3 py-2 text-primary shadow-2xl shadow-black/10"
        aria-label="Open SkinSync AI"
      >
        <BrandMark className="h-9 w-9 rounded-full ring-1 ring-border" />
        <span className="pr-1 text-sm" style={{ fontWeight: 600 }}>SkinSync AI</span>
      </button>
    );
  }

  if (isMinimized) {
    return (
      <button
        type="button"
        onClick={() => setIsMinimized(false)}
        className="fixed bottom-6 right-6 z-[60] flex items-center gap-2 rounded-full border border-border bg-card px-3 py-2 text-primary shadow-2xl shadow-black/10"
        aria-label="Expand SkinSync AI"
      >
        <BrandMark className="h-9 w-9 rounded-full ring-1 ring-border" />
        <span className="pr-1 text-sm" style={{ fontWeight: 600 }}>SkinSync AI</span>
      </button>
    );
  }

  return (
    <section className="fixed bottom-6 right-6 z-[60] w-[316px] max-w-[calc(100vw-24px)] overflow-hidden rounded-[20px] border border-border bg-card shadow-2xl shadow-black/10">
      <header className="flex items-center justify-between border-b border-border/70 px-4 py-3">
        <div className="min-w-0 flex items-center gap-3">
          <BrandMark className="h-9 w-9 rounded-full ring-1 ring-border" />
          <div className="min-w-0">
            <h2 className="truncate text-[15px] text-primary" style={{ fontWeight: 700 }}>
              SkinSync AI
            </h2>
            <div className="flex items-center gap-1.5 text-[11px] text-muted-foreground">
              <span className="h-2 w-2 rounded-full bg-emerald-500" />
              Online
            </div>
          </div>
        </div>
        <div className="flex items-center gap-1 text-muted-foreground">
          <button
            type="button"
            onClick={() => setIsMinimized(true)}
            className="flex h-7 w-7 items-center justify-center rounded-full transition-colors hover:bg-skin-primarySoft hover:text-primary"
            aria-label="Minimize chat"
          >
            <Minus className="h-4 w-4" />
          </button>
          <button
            type="button"
            onClick={() => setIsVisible(false)}
            className="flex h-7 w-7 items-center justify-center rounded-full transition-colors hover:bg-skin-primarySoft hover:text-primary"
            aria-label="Close chat"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
      </header>

      <div ref={scrollRef} className="h-[360px] overflow-y-auto bg-card px-4 py-5">
        <div className="space-y-4">
          {messages.map((message) => (
            <div
              key={message.id}
              className={`flex items-end gap-2 ${message.role === "user" ? "justify-end" : "justify-start"}`}
            >
              {message.role === "assistant" ? (
                <BrandMark className="h-7 w-7 flex-shrink-0 rounded-full ring-1 ring-border" />
              ) : null}
              <div
                className={`max-w-[235px] whitespace-pre-wrap rounded-2xl px-3.5 py-2.5 text-sm leading-relaxed ${
                  message.role === "user"
                    ? "rounded-br-sm bg-primary text-primary-foreground"
                    : "rounded-bl-sm border border-border/60 bg-muted text-foreground"
                }`}
              >
                {message.text}
              </div>
            </div>
          ))}

          {messages.length === 1 ? (
            <div className="flex flex-wrap gap-2 pl-9">
              {quickPrompts.map((prompt) => (
                <button
                  key={prompt}
                  type="button"
                  onClick={() => void sendMessage(prompt)}
                  disabled={isSending}
                  className="rounded-full border border-border bg-card px-3 py-1.5 text-[11px] text-primary transition-colors hover:bg-skin-primarySoft disabled:opacity-60"
                >
                  {prompt}
                </button>
              ))}
            </div>
          ) : null}

          {isSending ? (
            <div className="flex justify-start gap-2">
              <BrandMark className="h-7 w-7 flex-shrink-0 rounded-full ring-1 ring-border" />
              <div className="rounded-2xl rounded-bl-sm border border-border/60 bg-muted px-4 py-3">
                <div className="flex gap-1.5">
                  {[0, 1, 2].map((dot) => (
                    <span
                      key={dot}
                      className="h-1.5 w-1.5 rounded-full bg-primary animate-pulse"
                      style={{ animationDelay: `${dot * 120}ms` }}
                    />
                  ))}
                </div>
              </div>
            </div>
          ) : null}
        </div>
      </div>

      <div className="bg-card p-3">
        <form
          onSubmit={handleSubmit}
          className="flex items-center gap-2 rounded-xl border border-border bg-skin-surfaceMuted px-3 py-2"
        >
          <input
            value={input}
            onChange={(event) => setInput(event.target.value)}
            placeholder="Type your message..."
            className="min-w-0 flex-1 bg-transparent text-sm text-foreground placeholder:text-muted-foreground outline-none"
          />
          <button
            type="submit"
            disabled={!input.trim() || isSending}
            className="flex h-9 w-9 items-center justify-center rounded-lg bg-primary text-primary-foreground transition-colors hover:bg-primary/90 disabled:opacity-50"
            aria-label="Send message"
          >
            <SendHorizontal className="h-4 w-4" />
          </button>
        </form>
      </div>
    </section>
  );
}
