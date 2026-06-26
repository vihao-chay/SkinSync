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
    <div className="overflow-hidden rounded-[32px] border border-border/70 bg-card/85 p-6 shadow-[0_18px_40px_rgba(91,63,40,0.06)] backdrop-blur-xl lg:p-8">
      <div className="flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
        <div className="max-w-3xl space-y-3">
        {eyebrow ? (
          <p className="ss-title-eyebrow">{eyebrow}</p>
        ) : null}
          <div className="space-y-2">
            <h1 className="text-[2rem] text-foreground md:text-[2.6rem]">{title}</h1>
            <p className="max-w-2xl text-sm leading-7 text-muted-foreground md:text-base">{description}</p>
          </div>
        </div>
        {actions ? <div className="flex flex-wrap gap-3">{actions}</div> : null}
      </div>
    </div>
  );
}
