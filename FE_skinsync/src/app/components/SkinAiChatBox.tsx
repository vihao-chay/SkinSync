import { useEffect, useRef, useState, type FormEvent } from "react";
import { Minus, SendHorizontal, X } from "lucide-react";
import { BrandMark } from "./BrandMark";
import { sendSkinChatMessage } from "../services/skinChatService";

type ChatRole = "assistant" | "user";

interface ChatMessage {
  id: string;
  role: ChatRole;
  text: string;
}

const quickPrompts = [
  "Phân tích da",
  "Xây dựng lộ trình",
  "Gợi ý sản phẩm",
  "Kiểm tra thành phần",
];

const welcomeMessage =
  "Xin chào! Tôi là SkinAsync AI. Tôi có thể giúp bạn phân tích da, gợi ý lộ trình chăm sóc, giải thích thành phần và trả lời các câu hỏi về da mặt.";

const outOfScopeMessage =
  "Mình chỉ hỗ trợ các câu hỏi liên quan đến da mặt và chăm sóc da. Bạn có thể hỏi về mụn, da dầu, da khô, routine, sản phẩm hoặc thành phần skincare.";

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
  const [messages, setMessages] = useState<ChatMessage[]>([
    buildMessage(welcomeMessage, "assistant"),
  ]);
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    scrollRef.current?.scrollTo({
      top: scrollRef.current.scrollHeight,
      behavior: "smooth",
    });
  }, [messages, isSending]);

  async function sendMessage(nextText: string) {
    const trimmed = nextText.trim();
    if (!trimmed || isSending) {
      return;
    }

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
        buildMessage(result.message || "SkinAsync AI chưa thể phản hồi lúc này. Vui lòng thử lại sau.", "assistant"),
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
        className="fixed bottom-6 right-6 z-[60] flex items-center gap-2 rounded-full bg-white px-3 py-2 shadow-2xl shadow-[#8c6e52]/20 border border-[#eadfce] text-[#8c6e52]"
        aria-label="Mở SkinAsync AI"
      >
        <BrandMark className="w-9 h-9 rounded-full ring-1 ring-[#eadfce]" />
        <span className="pr-1 text-sm" style={{ fontWeight: 600 }}>SkinAsync AI</span>
      </button>
    );
  }

  if (isMinimized) {
    return (
      <button
        type="button"
        onClick={() => setIsMinimized(false)}
        className="fixed bottom-6 right-6 z-[60] flex items-center gap-2 rounded-full bg-white px-3 py-2 shadow-2xl shadow-[#8c6e52]/20 border border-[#eadfce] text-[#8c6e52]"
        aria-label="Mở rộng SkinAsync AI"
      >
        <BrandMark className="w-9 h-9 rounded-full ring-1 ring-[#eadfce]" />
        <span className="pr-1 text-sm" style={{ fontWeight: 600 }}>SkinAsync AI</span>
      </button>
    );
  }

  return (
    <section className="fixed bottom-6 right-6 z-[60] w-[316px] max-w-[calc(100vw-24px)] overflow-hidden rounded-[20px] bg-white shadow-2xl shadow-[#8c6e52]/18 border border-[#eadfce]">
      <header className="flex items-center justify-between px-4 py-3 border-b border-[#f0e6d8]">
        <div className="flex items-center gap-3 min-w-0">
          <BrandMark className="w-9 h-9 rounded-full ring-1 ring-[#eadfce]" />
          <div className="min-w-0">
            <h2 className="text-[15px] text-[#8c6e52] truncate" style={{ fontWeight: 700 }}>
              SkinAsync AI
            </h2>
            <div className="flex items-center gap-1.5 text-[11px] text-[#9c8065]">
              <span className="w-2 h-2 rounded-full bg-emerald-500" />
              Đang trực tuyến
            </div>
          </div>
        </div>
        <div className="flex items-center gap-1 text-[#a98768]">
          <button
            type="button"
            onClick={() => setIsMinimized(true)}
            className="w-7 h-7 rounded-full hover:bg-[#f7f0e7] flex items-center justify-center transition-colors"
            aria-label="Thu nhỏ chat"
          >
            <Minus className="w-4 h-4" />
          </button>
          <button
            type="button"
            onClick={() => setIsVisible(false)}
            className="w-7 h-7 rounded-full hover:bg-[#f7f0e7] flex items-center justify-center transition-colors"
            aria-label="Đóng chat"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      </header>

      <div ref={scrollRef} className="h-[360px] overflow-y-auto px-4 py-5 bg-white">
        <div className="space-y-4">
          {messages.map((message) => (
            <div
              key={message.id}
              className={`flex items-end gap-2 ${message.role === "user" ? "justify-end" : "justify-start"}`}
            >
              {message.role === "assistant" && (
                <BrandMark className="w-7 h-7 rounded-full ring-1 ring-[#eadfce] flex-shrink-0" />
              )}
              <div
                className={`max-w-[235px] rounded-2xl px-3.5 py-2.5 text-sm leading-relaxed whitespace-pre-wrap ${
                  message.role === "user"
                    ? "bg-[#c6a77e] text-white rounded-br-sm"
                    : "bg-[#f6efe6] text-[#5b4632] border border-[#efe2d1] rounded-bl-sm"
                }`}
              >
                {message.text}
              </div>
            </div>
          ))}

          {messages.length === 1 && (
            <div className="flex flex-wrap gap-2 pl-9">
              {quickPrompts.map((prompt) => (
                <button
                  key={prompt}
                  type="button"
                  onClick={() => void sendMessage(prompt)}
                  disabled={isSending}
                  className="px-3 py-1.5 rounded-full border border-[#d9b98e] text-[#b48c60] bg-white text-[11px] hover:bg-[#faf5ee] disabled:opacity-60 transition-colors"
                >
                  {prompt}
                </button>
              ))}
            </div>
          )}

          {isSending && (
            <div className="flex items-end gap-2 justify-start">
              <BrandMark className="w-7 h-7 rounded-full ring-1 ring-[#eadfce] flex-shrink-0" />
              <div className="rounded-2xl rounded-bl-sm bg-[#f6efe6] border border-[#efe2d1] px-4 py-3">
                <div className="flex gap-1.5">
                  {[0, 1, 2].map((dot) => (
                    <span
                      key={dot}
                      className="w-1.5 h-1.5 rounded-full bg-[#c2a27b] animate-pulse"
                      style={{ animationDelay: `${dot * 120}ms` }}
                    />
                  ))}
                </div>
              </div>
            </div>
          )}
        </div>
      </div>

      <div className="p-3 bg-white">
        <form
          onSubmit={handleSubmit}
          className="flex items-center gap-2 rounded-xl bg-[#f8f1e8] border border-[#eadfce] px-3 py-2"
        >
          <input
            value={input}
            onChange={(event) => setInput(event.target.value)}
            placeholder="Nhập tin nhắn..."
            className="min-w-0 flex-1 bg-transparent text-sm text-[#5b4632] placeholder:text-[#b8a797] outline-none"
          />
          <button
            type="submit"
            disabled={!input.trim() || isSending}
            className="w-9 h-9 rounded-lg bg-[#c6a77e] text-white flex items-center justify-center disabled:opacity-50 hover:bg-[#b8956e] transition-colors"
            aria-label="Gửi tin nhắn"
          >
            <SendHorizontal className="w-4 h-4" />
          </button>
        </form>
      </div>
    </section>
  );
}
