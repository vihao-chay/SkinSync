import { Button } from "./ui/button";
import { Card, CardContent } from "./ui/card";
import type { SubscriptionPlan } from "../services/subscriptionService";

export function AppPlanCard({
  plan,
  isCurrent,
  disabled,
  onSelect,
}: {
  plan: SubscriptionPlan;
  isCurrent: boolean;
  disabled: boolean;
  onSelect: () => void;
}) {
  return (
    <Card className={`rounded-[28px] border ${isCurrent ? "border-primary/60 bg-muted/80" : "border-border/70 bg-card/95"} shadow-sm`}>
      <CardContent className="space-y-5 pt-6">
        <div className="space-y-2">
          <div className="flex items-center justify-between gap-3">
            <p className="text-xl font-medium text-foreground">{plan.name}</p>
            {isCurrent ? <span className="app-pill">Current plan</span> : null}
          </div>
          <p className="text-sm leading-6 text-muted-foreground">{plan.description || "Plan details are provided by the backend."}</p>
          <p className="text-2xl font-medium text-foreground">
            {plan.price} {plan.currency}
            <span className="ml-1 text-sm text-muted-foreground">/ {plan.billingPeriod}</span>
          </p>
        </div>
        <div className="space-y-2">
          {plan.features.map((feature) => (
            <div key={feature.featureKey} className="rounded-2xl border border-border/60 bg-muted/70 px-4 py-3">
              <p className="text-sm font-medium text-foreground">{feature.displayName}</p>
              <p className="mt-1 text-sm text-muted-foreground">
                {feature.isEnabled
                  ? feature.monthlyLimit
                    ? `${feature.monthlyLimit} ${feature.unit}`
                    : "Included"
                  : "Not included"}
              </p>
            </div>
          ))}
        </div>
        <Button
          className="w-full bg-primary text-primary-foreground hover:bg-primary/90"
          disabled={disabled || isCurrent}
          onClick={onSelect}
        >
          {isCurrent ? "Current plan" : "Upgrade disabled until payment is ready"}
        </Button>
      </CardContent>
    </Card>
  );
}
