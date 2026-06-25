import { Button } from "./ui/button";
import type { RegimenProduct } from "../services/regimenService";
import type { RoutineTrackingToday } from "../services/routineTrackingService";

export function AppRoutineStepCard({
  step,
  routineTime,
  tracking,
  onToggle,
}: {
  step: RegimenProduct;
  routineTime: "Morning" | "Evening";
  tracking: RoutineTrackingToday | null;
  onToggle: (stepId: string, completed: boolean) => Promise<void>;
}) {
  const completed = Boolean(
    tracking?.steps?.some((item) => item.stepId === step.stepId && item.status === "completed")
  );

  return (
    <div className="rounded-[24px] border border-border/60 bg-muted/70 p-4">
      <div className="flex flex-col gap-4 xl:flex-row xl:items-start xl:justify-between">
        <div className="space-y-2">
          <div className="flex flex-wrap gap-2">
            <span className="app-pill">Step {step.stepOrder}</span>
            <span className="app-pill">{routineTime}</span>
            {step.category ? <span className="app-pill">{step.category}</span> : null}
          </div>
          <div>
            <p className="text-base font-medium text-foreground">{step.name}</p>
            <p className="text-sm text-muted-foreground">{step.brand || "Brand unavailable"}</p>
          </div>
          <p className="text-sm leading-6 text-muted-foreground">
            {step.instruction || step.usageGuide || "Follow the routine instructions provided by the backend."}
          </p>
          {step.frequency ? <p className="text-xs uppercase tracking-[0.18em] text-muted-foreground">{step.frequency}</p> : null}
        </div>
        <Button
          variant={completed ? "default" : "outline"}
          className={
            completed
              ? "bg-primary text-primary-foreground hover:bg-primary/90"
              : "border-border bg-card text-foreground hover:bg-muted"
          }
          onClick={() => void onToggle(step.stepId, completed)}
        >
          {completed ? "Completed today" : "Mark completed"}
        </Button>
      </div>
    </div>
  );
}
