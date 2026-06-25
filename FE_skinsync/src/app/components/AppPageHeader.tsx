import type { ReactNode } from "react";

export function AppPageHeader({
  eyebrow,
  title,
  description,
  actions,
}: {
  eyebrow?: string;
  title: string;
  description: string;
  actions?: ReactNode;
}) {
  return (
    <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
      <div className="max-w-3xl space-y-2">
        {eyebrow ? (
          <p className="text-xs font-medium uppercase tracking-[0.22em] text-muted-foreground">{eyebrow}</p>
        ) : null}
        <div className="space-y-2">
          <h1 className="text-3xl text-foreground md:text-4xl">{title}</h1>
          <p className="max-w-2xl text-sm leading-6 text-muted-foreground md:text-base">{description}</p>
        </div>
      </div>
      {actions ? <div className="flex flex-wrap gap-3">{actions}</div> : null}
    </div>
  );
}
