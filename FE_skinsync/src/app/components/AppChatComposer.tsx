import type { KeyboardEvent } from "react";
import { Send } from "lucide-react";
import { Button } from "./ui/button";

export function AppChatComposer({
  value,
  disabled,
  onChange,
  onSend,
}: {
  value: string;
  disabled: boolean;
  onChange: (value: string) => void;
  onSend: () => void;
}) {
  return (
    <div className="rounded-[28px] border border-border/70 bg-card p-4">
      <textarea
        className="app-textarea min-h-24 border-none bg-transparent px-0 py-0 focus:ring-0"
        placeholder="Ask about your routine, analysis, ingredients, or what to track next."
        value={value}
        onChange={(event) => onChange(event.target.value)}
        onKeyDown={(event: KeyboardEvent<HTMLTextAreaElement>) => {
          if (event.key === "Enter" && !event.shiftKey) {
            event.preventDefault();
            if (!disabled) {
              onSend();
            }
          }
        }}
      />
      <div className="mt-4 flex justify-end">
        <Button
          className="bg-primary text-primary-foreground hover:bg-primary/90"
          disabled={disabled}
          onClick={onSend}
        >
          <Send className="mr-2 h-4 w-4" />
          Send
        </Button>
      </div>
    </div>
  );
}
