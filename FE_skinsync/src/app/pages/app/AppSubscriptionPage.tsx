import { CreditCard, ShieldAlert } from "lucide-react";
import { useEffect, useState } from "react";
import { AppEmptyState } from "../../components/AppEmptyState";
import { AppGuidanceCard } from "../../components/AppGuidanceCard";
import { AppPageHeader } from "../../components/AppPageHeader";
import { AppPlanCard } from "../../components/AppPlanCard";
import { AppSection } from "../../components/AppSection";
import { AppStatCard } from "../../components/AppStatCard";
import { Button } from "../../components/ui/button";
import { LoadingState } from "../../components/LoadingState";
import { useImpersonation } from "../../contexts/ImpersonationContext";
import { cancelSubscriptionApi, getCurrentSubscriptionApi, getSubscriptionPlansApi, type CurrentSubscription, type SubscriptionPlan } from "../../services/subscriptionService";
import { formatDate } from "../../utils/appFormat";

export function AppSubscriptionPage() {
  const { isImpersonating } = useImpersonation();
  const [loading, setLoading] = useState(true);
  const [feedback, setFeedback] = useState("");
  const [current, setCurrent] = useState<CurrentSubscription | null>(null);
  const [plans, setPlans] = useState<SubscriptionPlan[]>([]);

  useEffect(() => {
    let active = true;
    void Promise.all([getCurrentSubscriptionApi(), getSubscriptionPlansApi()]).then(([currentResult, plansResult]) => {
      if (!active) return;
      setCurrent(currentResult.content ?? null);
      setPlans(plansResult.content ?? []);
      setLoading(false);
    });
    return () => {
      active = false;
    };
  }, []);

  if (loading) {
    return <LoadingState label="Loading subscription details..." />;
  }

  return (
    <div className="space-y-6">
      <AppPageHeader
        eyebrow="Subscription"
        title="Manage your SkinSync plan"
        description="Review plan status, feature access, and quota usage. Payment actions stay explicit and disabled if the current flow is not ready."
      />

      {isImpersonating ? (
        <AppGuidanceCard
          title="Payment actions are disabled while viewing as user."
          description="Upgrade, downgrade, cancel, and checkout actions stay locked during impersonation so the admin session remains safe."
          icon={ShieldAlert}
        />
      ) : null}

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <AppStatCard label="Current plan" value={current?.plan?.name || "Unavailable"} helper="Plan returned by backend" />
        <AppStatCard label="Status" value={current?.subscription?.status || "Unavailable"} helper="Current subscription status" />
        <AppStatCard label="Renewal / expiry" value={formatDate(current?.subscription?.currentPeriodEnd)} helper="Period end if available" />
        <AppStatCard
          label="Usage preview"
          value={current?.usage?.length ? `${current.usage.length} tracked features` : "Unavailable"}
          helper="Quota data from the subscription endpoint"
        />
      </div>

      <AppSection title="Current plan hero" description="A quick summary of what the active plan unlocks today.">
        {current ? (
          <div className="grid gap-4 xl:grid-cols-[1.1fr_0.9fr]">
            <div className="rounded-[28px] border border-border/60 bg-muted/70 p-6">
              <p className="text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground">Current plan</p>
              <h2 className="mt-2 text-3xl text-foreground">{current.plan.name}</h2>
              <p className="mt-2 text-sm leading-6 text-muted-foreground">
                {current.plan.description || "Plan description unavailable from the backend."}
              </p>
              <div className="mt-4 flex flex-wrap gap-2">
                <span className="app-pill">{current.subscription.status}</span>
                <span className="app-pill">Renews {formatDate(current.subscription.currentPeriodEnd)}</span>
              </div>
            </div>
            <div className="rounded-[28px] border border-border/60 bg-card p-6">
              <p className="text-sm font-medium text-foreground">Feature access</p>
              <div className="mt-4 space-y-3">
                {current.usage?.length ? (
                  current.usage.map((item) => (
                    <div key={item.featureKey} className="rounded-2xl border border-border/60 bg-muted/70 px-4 py-3">
                      <div className="flex items-center justify-between gap-3">
                        <span className="text-sm text-foreground">{item.displayName}</span>
                        <span className="text-sm text-muted-foreground">
                          {item.isUnlimited ? "Unlimited" : `${item.used}/${item.limit ?? "-"} ${item.unit}`}
                        </span>
                      </div>
                    </div>
                  ))
                ) : (
                  <AppEmptyState
                    title="Usage unavailable"
                    description="Quota details are not available for this account yet."
                    icon={CreditCard}
                  />
                )}
              </div>
              <div className="mt-4 flex flex-wrap gap-3">
                <Button variant="outline" className="border-border bg-card hover:bg-muted" disabled>
                  Payment is not available yet.
                </Button>
                <Button
                  variant="outline"
                  className="border-border bg-card hover:bg-muted"
                  disabled={isImpersonating || !current.subscription.subscriptionId}
                  onClick={async () => {
                    const result = await cancelSubscriptionApi();
                    setFeedback(result.message || "Subscription update requested.");
                    if (result.success) {
                      setCurrent(result.content ?? null);
                    }
                  }}
                >
                  Cancel subscription
                </Button>
              </div>
            </div>
          </div>
        ) : (
          <AppEmptyState
            title="No subscription data"
            description="The backend did not return current subscription details for this account."
          />
        )}
      </AppSection>

      <AppSection title="Plan comparison" description="Compare plans returned by the backend without inventing pricing tiers.">
        {plans.length ? (
          <div className="grid gap-4 xl:grid-cols-3">
            {plans.map((plan) => (
              <AppPlanCard
                key={plan.id}
                plan={plan}
                isCurrent={current?.plan?.code === plan.code}
                disabled
                onSelect={() => setFeedback("Payment is not available yet.")}
              />
            ))}
          </div>
        ) : (
          <AppEmptyState
            title="No plan catalog available"
            description="The subscription plan list is not available from the backend right now."
          />
        )}
      </AppSection>

      {feedback ? (
        <div className="rounded-2xl border border-border/70 bg-muted/70 px-4 py-3 text-sm text-foreground">{feedback}</div>
      ) : null}
    </div>
  );
}
