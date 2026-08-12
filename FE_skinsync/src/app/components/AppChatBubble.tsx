import { Bot, UserRound } from "lucide-react";
import { formatTime } from "../utils/appFormat";

export function AppChatBubble({
  role,
  message,
  createdAt,
  error = false,
}: {
  role: "user" | "assistant";
  message: string;
  createdAt: string;
  error?: boolean;
}) {
  const isUser = role === "user";

  return (
    <div className={`flex gap-3 ${isUser ? "justify-end" : "justify-start"}`}>
      {!isUser ? (
        <div className={`mt-1 flex h-10 w-10 items-center justify-center rounded-2xl ${error ? "bg-red-50 text-red-500" : "bg-card text-primary"}`}>
          <Bot className="h-5 w-5" />
        </div>
      ) : null}
      <div
        className={`max-w-[85%] rounded-[24px] px-4 py-3 text-sm leading-6 ${
          isUser ? "bg-primary text-primary-foreground" : error ? "bg-red-50 text-red-700" : "bg-muted text-foreground"
        }`}
      >
        <p className="whitespace-pre-wrap">{message}</p>
        <p className={`mt-2 text-xs ${isUser ? "text-primary-foreground/80" : error ? "text-red-500" : "text-muted-foreground"}`}>
          {formatTime(createdAt)}
        </p>
      </div>
      {isUser ? (
        <div className="mt-1 flex h-10 w-10 items-center justify-center rounded-2xl bg-card text-foreground">
          <UserRound className="h-5 w-5" />
        </div>
      ) : null}
    </div>
  );
}
