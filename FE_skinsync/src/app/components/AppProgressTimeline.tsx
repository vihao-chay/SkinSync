import type { SkinProgressTimelineEntry } from "../services/skinProgressService";
import { formatDate } from "../utils/appFormat";
import { Button } from "./ui/button";

export function AppProgressTimeline({ entries }: { entries: SkinProgressTimelineEntry[] }) {
  return (
    <div className="space-y-4">
      {entries.map((entry) => (
        <div key={entry.entryId} className="rounded-[24px] border border-border/60 bg-muted/70 p-4">
          <div className="grid gap-4 lg:grid-cols-[220px_minmax(0,1fr)]">
            <div className="overflow-hidden rounded-[24px] border border-border/60 bg-card">
              <img
                src={entry.thumbnailUrl || entry.imageUrl}
                alt={`Progress entry ${formatDate(entry.createdAt)}`}
                className="h-52 w-full object-cover"
              />
            </div>
            <div className="space-y-3">
              <div className="flex flex-wrap items-center gap-2">
                <span className="app-pill">{formatDate(entry.createdAt)}</span>
                {entry.skinScore ? <span className="app-pill">Score {entry.skinScore}</span> : null}
                {entry.status ? <span className="app-pill">{entry.status}</span> : null}
              </div>
              <p className="text-sm leading-6 text-muted-foreground">
                {entry.summary || "Summary unavailable for this progress entry."}
              </p>
              <div className="flex flex-wrap gap-2">
                {(entry.mainConcerns || []).map((concern) => (
                  <span key={concern} className="app-pill">
                    {concern}
                  </span>
                ))}
              </div>
              <Button variant="outline" className="border-border bg-card hover:bg-muted" disabled>
                Compare/report availability depends on backend support
              </Button>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
