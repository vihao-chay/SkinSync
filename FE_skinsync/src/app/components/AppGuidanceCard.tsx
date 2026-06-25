import type { LucideIcon } from "lucide-react";
import { Sparkles } from "lucide-react";
import type { ReactNode } from "react";

export function AppGuidanceCard({
  title,
  description,
  icon: Icon = Sparkles,
  children,
}: {
  title: string;
  description: string;
  icon?: LucideIcon;
  children?: ReactNode;
}) {
  return (
    <div className="rounded-[28px] border border-border/70 bg-muted/70 p-6">
      <div className="flex items-start gap-4">
        <div className="rounded-2xl bg-card p-3 text-primary shadow-sm">
          <Icon className="h-5 w-5" />
        </div>
        <div className="min-w-0 space-y-3">
          <div className="space-y-1">
            <p className="text-lg font-medium text-foreground">{title}</p>
            <p className="text-sm leading-6 text-muted-foreground">{description}</p>
          </div>
          {children}
        </div>
      </div>
    </div>
  );
}
