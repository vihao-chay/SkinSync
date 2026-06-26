import type { ReactNode } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "./ui/card";

export function AppSection({
  title,
  description,
  action,
  children,
  contentClassName = "",
}: {
  title: string;
  description?: string;
  action?: ReactNode;
  children: ReactNode;
  contentClassName?: string;
}) {
  return (
    <Card className="app-surface rounded-[30px] overflow-hidden">
      <CardHeader className="flex flex-col gap-4 border-b border-border/60 pb-5 sm:flex-row sm:items-start sm:justify-between">
        <div className="space-y-1">
          <CardTitle className="text-[1.35rem] text-foreground">{title}</CardTitle>
          {description ? <p className="max-w-2xl text-sm leading-6 text-muted-foreground">{description}</p> : null}
        </div>
        {action}
      </CardHeader>
      <CardContent className={`pt-6 ${contentClassName}`}>{children}</CardContent>
    </Card>
  );
}
