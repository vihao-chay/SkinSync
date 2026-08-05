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
    <header className="app-page-header">
      <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
        <div className="max-w-3xl space-y-3">
          {eyebrow ? <p className="ss-title-eyebrow">{eyebrow}</p> : null}
          <h1 className="text-[2.25rem] font-semibold leading-[1.05] tracking-[-0.045em] text-[#222] md:text-[2.75rem]">{title}</h1>
          <p className="max-w-2xl text-[15px] leading-7 text-[#777] md:text-base">{description}</p>
        </div>
        {actions ? <div className="flex flex-wrap gap-3">{actions}</div> : null}
      </div>
    </header>
  );
}
