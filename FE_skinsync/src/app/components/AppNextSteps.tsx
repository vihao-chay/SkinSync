import { CheckCircle2, Circle } from "lucide-react";
import { Button } from "./ui/button";
import { Link } from "react-router";

export interface AppNextStepItem {
  label: string;
  done: boolean;
  ctaLabel?: string;
  ctaTo?: string;
}

export function AppNextSteps({ items }: { items: AppNextStepItem[] }) {
  return (
    <div className="space-y-3">
      {items.map((item) => (
        <div
          key={item.label}
          className="flex flex-col gap-3 rounded-2xl border border-border/60 bg-muted/70 px-4 py-3 sm:flex-row sm:items-center sm:justify-between"
        >
          <div className="flex items-center gap-3">
            {item.done ? (
              <CheckCircle2 className="h-5 w-5 text-primary" />
            ) : (
              <Circle className="h-5 w-5 text-muted-foreground" />
            )}
            <span className="text-sm text-foreground">{item.label}</span>
          </div>
          {!item.done && item.ctaLabel && item.ctaTo ? (
            <Button asChild variant="outline" className="border-border bg-card hover:bg-muted">
              <Link to={item.ctaTo}>{item.ctaLabel}</Link>
            </Button>
          ) : null}
        </div>
      ))}
    </div>
  );
}
