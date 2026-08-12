import type { LucideIcon } from "lucide-react";
import { Sparkles } from "lucide-react";
import type { ReactNode } from "react";

export function AppEmptyState({
  title,
  description,
  icon: Icon = Sparkles,
  action,
}: {
  title: string;
  description: string;
  icon?: LucideIcon;
  action?: ReactNode;
}) {
  return (
    <div className="app-ghost-panel rounded-[28px] p-6">
      <div className="flex items-start gap-4">
        <div className="rounded-2xl bg-card p-3 text-primary shadow-sm">
          <Icon className="h-5 w-5" />
        </div>
        <div className="space-y-3">
          <div className="space-y-1">
            <p className="text-lg font-medium text-foreground">{title}</p>
            <p className="max-w-2xl text-sm leading-6 text-muted-foreground">{description}</p>
          </div>
          {action}
        </div>
      </div>
    </div>
  );
}
