export function LoadingState({ label = "Loading..." }: { label?: string }) {
  return (
    <div className="flex min-h-[240px] flex-col items-center justify-center gap-4 rounded-3xl border border-[#e8d5b7]/50 bg-white/70">
      <div className="h-10 w-10 animate-spin rounded-full border-2 border-[#c2a67d]/20 border-t-[#c2a67d]" />
      <p className="text-sm text-[#78716c]">{label}</p>
    </div>
  );
}
