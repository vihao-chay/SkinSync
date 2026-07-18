import { Check } from "lucide-react";
import { cn } from "./ui/utils";

export function SelectableChip({
  label,
  selected,
  onClick,
  disabled = false,
  className,
}: {
  label: string;
  selected: boolean;
  onClick: () => void;
  disabled?: boolean;
  className?: string;
}) {
  return (
    <button
      type="button"
      aria-pressed={selected}
      disabled={disabled}
      onClick={onClick}
      className={cn(
        "inline-flex min-h-11 items-center gap-2 rounded-full border px-3.5 py-2.5 text-sm font-medium transition-all outline-none focus-visible:ring-2 focus-visible:ring-primary/20 disabled:cursor-not-allowed disabled:opacity-50",
        selected
          ? "border-[var(--ss-gold-hover)] bg-primary text-primary-foreground shadow-[0_10px_22px_rgba(194,166,125,0.18)]"
          : "border-border bg-card text-muted-foreground hover:border-[var(--ss-border-medium)] hover:bg-secondary hover:text-foreground",
        className,
      )}
    >
      {selected ? <Check className="h-3.5 w-3.5 shrink-0" /> : null}
      <span>{label}</span>
    </button>
  );
}
