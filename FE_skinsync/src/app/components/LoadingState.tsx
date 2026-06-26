export function LoadingState({ label = "Loading..." }: { label?: string }) {
  return (
    <div className="flex min-h-[240px] flex-col items-center justify-center gap-4 rounded-[30px] border border-border/70 bg-card/85 p-8 shadow-[0_18px_44px_rgba(91,63,40,0.06)]">
      <div className="h-10 w-10 animate-spin rounded-full border-2 border-primary/20 border-t-primary" />
      <p className="text-sm text-muted-foreground">{label}</p>
    </div>
  );
}
