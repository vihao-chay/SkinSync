import { ImagePlus } from "lucide-react";
import { Button } from "./ui/button";
import { formatFileSize } from "../utils/appFormat";

export function AppUploadZone({
  title,
  description,
  file,
  previewUrl,
  onPick,
  accept,
  helper,
}: {
  title: string;
  description: string;
  file: File | null;
  previewUrl?: string | null;
  onPick: (file: File | null) => void;
  accept: string;
  helper?: string;
}) {
  return (
    <label className="block cursor-pointer">
      <input
        type="file"
        accept={accept}
        className="sr-only"
        onChange={(event) => onPick(event.target.files?.[0] ?? null)}
      />
      <div className="app-ghost-panel rounded-[32px] p-6 transition hover:border-primary/50 hover:bg-muted">
        <div className="flex flex-col gap-5 lg:flex-row lg:items-center">
          <div className="flex h-16 w-16 items-center justify-center rounded-3xl bg-card text-primary shadow-sm">
            <ImagePlus className="h-7 w-7" />
          </div>
          <div className="flex-1 space-y-2">
            <p className="text-lg font-medium text-foreground">{title}</p>
            <p className="text-sm leading-6 text-muted-foreground">{description}</p>
            {helper ? <p className="text-xs uppercase tracking-[0.18em] text-muted-foreground">{helper}</p> : null}
            {file ? (
              <div className="rounded-2xl border border-border/60 bg-card px-4 py-3 text-sm text-muted-foreground">
                {file.name} · {formatFileSize(file.size)}
              </div>
            ) : null}
          </div>
          <Button type="button" className="bg-primary text-primary-foreground hover:bg-primary/90">
            Choose image
          </Button>
        </div>
        {previewUrl ? (
          <div className="mt-5 overflow-hidden rounded-[28px] border border-border/60 bg-card">
            <img src={previewUrl} alt="Preview" className="h-[320px] w-full object-cover" />
          </div>
        ) : null}
      </div>
    </label>
  );
}
