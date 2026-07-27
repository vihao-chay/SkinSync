import type { ReactNode } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";

export function AppSection({
  title,
  description,
  action,
  children,
  contentClassName = "",
  tone = "default",
}: {
  title: string;
  description?: string;
  action?: ReactNode;
  children: ReactNode;
  contentClassName?: string;
  tone?: "default" | "highlight" | "muted";
}) {
  return (
    <Card className={`${tone === "highlight" ? "app-surface-highlight" : tone === "muted" ? "app-surface-muted" : "app-surface"} rounded-[24px] overflow-hidden transition duration-200 hover:-translate-y-0.5 hover:shadow-[0_18px_36px_rgba(70,55,39,0.1)]`}>
      <CardHeader className="flex flex-col gap-4 border-b border-border/50 pb-5 sm:flex-row sm:items-start sm:justify-between">
        <div className="space-y-1">
          <CardTitle className="text-[1.5rem] font-semibold tracking-[-0.025em] text-[#222]">{title}</CardTitle>
          {description ? <p className="max-w-2xl text-sm leading-6 text-muted-foreground">{description}</p> : null}
        </div>
        {action}
      </CardHeader>
      <CardContent className={`pt-6 ${contentClassName}`}>{children}</CardContent>
    </Card>
  );
}
