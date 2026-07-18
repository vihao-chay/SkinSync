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
  return (
    <Card className={`${tone === "premium" ? "app-surface-highlight" : "app-surface"} rounded-[26px]`}>
      <CardContent className="space-y-3 pt-6">
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground">{label}</p>
        <p className="text-[1.9rem] font-semibold leading-none text-foreground">{value}</p>
        <p className="text-sm leading-6 text-muted-foreground">{helper}</p>
      </CardContent>
    </Card>
  );
}
