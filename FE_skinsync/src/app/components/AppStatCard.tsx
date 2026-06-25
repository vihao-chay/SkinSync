import { Card, CardContent } from "./ui/card";

export function AppStatCard({
  label,
  value,
  helper,
}: {
  label: string;
  value: string;
  helper: string;
}) {
  return (
    <Card className="app-surface rounded-[24px]">
      <CardContent className="space-y-2 pt-6">
        <p className="text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground">{label}</p>
        <p className="text-2xl font-medium text-foreground">{value}</p>
        <p className="text-sm text-muted-foreground">{helper}</p>
      </CardContent>
    </Card>
  );
}
