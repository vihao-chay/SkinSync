import { Card, CardContent } from "./ui/card";

export function AppStatCard({
  label,
  value,
  helper,
  tone = "default",
}: {
  label: string;
  value: string;
  helper: string;
  tone?: "default" | "premium" | "success" | "info";
}) {
  const toneClass = {
    default: "app-surface",
    premium: "app-surface-highlight",
    success: "border-[#8fae8b]/55 bg-[#f1f7ef] shadow-[0_12px_28px_rgba(95,143,104,0.1)]",
    info: "border-[#8aaabd]/55 bg-[#eef6fa] shadow-[0_12px_28px_rgba(79,113,130,0.1)]",
  }[tone];

  return (
    <Card className={`${toneClass} rounded-[26px]`}>
      <CardContent className="space-y-3 pt-6">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground">{label}</p>
        <p className="text-[1.9rem] font-semibold leading-none text-foreground">{value}</p>
        <p className="text-sm leading-6 text-muted-foreground">{helper}</p>
      </CardContent>
    </Card>
  );
}
