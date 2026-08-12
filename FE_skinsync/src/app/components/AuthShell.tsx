import type { ReactNode } from "react";
import { BrandMark } from "./BrandMark";

export function AuthShell({
  eyebrow,
  title,
  description,
  sideTitle,
  sideDescription,
  children,
}: {
  eyebrow: string;
  title: string;
  description: string;
  sideTitle: string;
  sideDescription: string;
  children: ReactNode;
}) {
  return (
    <div className="app-auth-shell">
      <div className="grid min-h-screen lg:grid-cols-[1.02fr_0.98fr]">
        <aside className="relative hidden overflow-hidden lg:flex">
          <div className="absolute inset-0 bg-[radial-gradient(circle_at_top_left,rgba(255,255,255,0.35),transparent_42%),linear-gradient(135deg,rgba(197,168,128,0.96)_0%,rgba(140,110,82,0.92)_52%,rgba(232,213,183,0.88)_100%)]" />
          <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(20,14,10,0.08)_0%,rgba(20,14,10,0.24)_100%)]" />
          <div className="relative flex w-full flex-col justify-between p-10 text-white">
            <div className="flex items-center gap-3">
              <BrandMark className="h-11 w-11 rounded-full ring-1 ring-white/35" />
              <span className="text-lg tracking-[0.18em]" style={{ fontWeight: 600 }}>
                SKINSYNC
              </span>
            </div>

            <div className="max-w-xl space-y-5">
              <span className="inline-flex rounded-full border border-white/20 bg-white/10 px-4 py-2 text-xs uppercase tracking-[0.24em] text-white/85 backdrop-blur-xl">
                {eyebrow}
              </span>
              <h2 className="text-5xl leading-[1.04]" style={{ fontWeight: 600 }}>
                {sideTitle}
              </h2>
              <p className="max-w-lg text-base leading-7 text-white/85">{sideDescription}</p>
            </div>

            <div className="grid gap-3 text-sm text-white/88">
              <div className="rounded-[24px] border border-white/15 bg-white/10 px-5 py-4 backdrop-blur-xl">
                Premium skincare visual language, same API behavior.
              </div>
              <div className="rounded-[24px] border border-white/15 bg-white/10 px-5 py-4 backdrop-blur-xl">
                Auth flow, redirects, and validation remain intact.
              </div>
            </div>
          </div>
        </aside>

        <main className="flex min-h-screen items-center justify-center px-5 py-10 sm:px-8">
          <div className="app-auth-card w-full max-w-xl">
            <div className="mb-8 space-y-3">
              <span className="inline-flex rounded-full border border-border/70 bg-card px-3 py-1 text-xs uppercase tracking-[0.2em] text-primary">
                {eyebrow}
              </span>
              <h1 className="text-4xl text-foreground" style={{ fontWeight: 600 }}>
                {title}
              </h1>
              <p className="max-w-lg text-sm leading-6 text-muted-foreground">{description}</p>
            </div>
            <div className="space-y-5">{children}</div>
          </div>
        </main>
      </div>
    </div>
  );
}
