import { useEffect, useState } from "react";
import { Link } from "react-router";
import { Button } from "../../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../../components/ui/card";
import { EmptyState } from "../../components/EmptyState";
import { ErrorState } from "../../components/ErrorState";
import { LoadingState } from "../../components/LoadingState";
import { PageHeader } from "../../components/PageHeader";
import { getSubscriptionPlansApi } from "../../services/subscriptionService";
import { submitSupportRequestApi } from "../../services/supportService";

export function FeaturesPage() {
  const features = [
    "AI skin analysis",
    "Personalized routine generation",
    "Product recommendations from backend catalog",
    "Daily check-up and progress tracking",
    "Subscription plans with quota-aware access",
  ];

  return (
    <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6 lg:px-8">
      <PageHeader title="Features" description="SkinSync turns skincare workflows from the mobile app into a web-first experience grounded in backend data." />
      <div className="mt-8 grid gap-4 md:grid-cols-2">
        {features.map((feature) => (
          <Card key={feature} className="border-[#e8d5b7]/60 bg-white/90">
            <CardHeader><CardTitle className="text-xl">{feature}</CardTitle></CardHeader>
            <CardContent className="text-sm text-[#78716c]">Available through authenticated web flows and backed by the SkinSync API.</CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}

export function PricingPage() {
  const [plansState, setPlansState] = useState<"idle" | "loading" | "ready" | "error">("idle");
  const [plans, setPlans] = useState<Array<{ id: string; code: string; name: string; description?: string | null; price: number; currency: string; billingPeriod: string; features: Array<{ displayName: string; isEnabled: boolean }> }>>([]);
  const [message, setMessage] = useState("");

  useEffect(() => {
    if (plansState !== "idle") return;
    setPlansState("loading");
    void getSubscriptionPlansApi().then((result) => {
      if (!result.success || !result.content) {
        setPlansState("error");
        setMessage(result.message || "Unable to load pricing.");
        return;
      }

      setPlans(result.content);
      setPlansState("ready");
    });
  }, [plansState]);

  return (
    <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6 lg:px-8">
      <PageHeader title="Pricing" description="Plans come directly from backend configuration. If payment is not yet wired, the UI stays explicit about that state." />
      <div className="mt-8">
        {plansState === "loading" ? <LoadingState label="Loading plans..." /> : null}
        {plansState === "error" ? <ErrorState message={message} /> : null}
        {plansState === "ready" ? (
          <div className="grid gap-4 md:grid-cols-3">
            {plans.map((plan) => (
              <Card key={plan.id} className="border-[#e8d5b7]/60 bg-white/90">
                <CardHeader>
                  <CardTitle>{plan.name}</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                  <p className="text-sm text-[#78716c]">{plan.description || "Subscription benefits are managed from backend plan settings."}</p>
                  <p className="text-2xl text-[#2c2a28]">{plan.price} {plan.currency}</p>
                  <p className="text-xs uppercase tracking-wide text-[#8c6e52]">{plan.billingPeriod}</p>
                  <ul className="space-y-2 text-sm text-[#5b5249]">
                    {plan.features.filter((feature) => feature.isEnabled).map((feature) => (
                      <li key={feature.displayName}>• {feature.displayName}</li>
                    ))}
                  </ul>
                  <Button asChild className="w-full bg-[#c2a67d] hover:bg-[#b0946b]">
                    <Link to="/register">Get Started</Link>
                  </Button>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : null}
      </div>
    </div>
  );
}

export function AboutPage() {
  return (
    <div className="mx-auto max-w-5xl px-4 py-10 sm:px-6 lg:px-8">
      <PageHeader title="How It Works" description="Create an account, complete your skin profile, upload analysis photos, receive a routine, and track progress over time." />
      <div className="mt-8 grid gap-4 md:grid-cols-2">
        {["Create account", "Complete onboarding", "Upload analysis photo", "Receive routine", "Track progress", "Update daily check-up"].map((step, index) => (
          <Card key={step} className="border-[#e8d5b7]/60 bg-white/90">
            <CardHeader><CardTitle className="text-lg">{index + 1}. {step}</CardTitle></CardHeader>
          </Card>
        ))}
      </div>
    </div>
  );
}

export function FaqPage() {
  const items = [
    "Analysis is processed by backend AI services only.",
    "Routines and recommendations reflect backend-supported data.",
    "Subscription access controls quota-limited features.",
    "Privacy-sensitive operations remain authenticated and role-guarded.",
  ];

  return (
    <div className="mx-auto max-w-5xl px-4 py-10 sm:px-6 lg:px-8">
      <PageHeader title="FAQ" description="Short answers for the main questions around analysis, routine, subscriptions, and privacy." />
      <div className="mt-8 space-y-4">
        {items.map((item) => (
          <Card key={item} className="border-[#e8d5b7]/60 bg-white/90">
            <CardContent className="pt-6 text-sm text-[#5b5249]">{item}</CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}

export function ContactPage() {
  const [form, setForm] = useState({ name: "", email: "", category: "general", message: "" });
  const [state, setState] = useState<"idle" | "submitting" | "submitted" | "error">("idle");
  const [message, setMessage] = useState("");

  return (
    <div className="mx-auto max-w-4xl px-4 py-10 sm:px-6 lg:px-8">
      <PageHeader title="Support" description="Contact support through a backend-backed flow when available. Until then, the UI stays honest and explicit." />
      <Card className="mt-8 border-[#e8d5b7]/60 bg-white/90">
        <CardContent className="grid gap-4 pt-6">
          <input className="rounded-2xl border border-[#e8d5b7] bg-[#faf7f2] px-4 py-3" placeholder="Name" value={form.name} onChange={(event) => setForm((prev) => ({ ...prev, name: event.target.value }))} />
          <input className="rounded-2xl border border-[#e8d5b7] bg-[#faf7f2] px-4 py-3" placeholder="Email" value={form.email} onChange={(event) => setForm((prev) => ({ ...prev, email: event.target.value }))} />
          <select className="rounded-2xl border border-[#e8d5b7] bg-[#faf7f2] px-4 py-3" value={form.category} onChange={(event) => setForm((prev) => ({ ...prev, category: event.target.value }))}>
            <option value="general">General</option>
            <option value="subscription">Subscription</option>
            <option value="analysis">Analysis</option>
          </select>
          <textarea className="min-h-40 rounded-2xl border border-[#e8d5b7] bg-[#faf7f2] px-4 py-3" placeholder="Message" value={form.message} onChange={(event) => setForm((prev) => ({ ...prev, message: event.target.value }))} />
          <Button
            className="w-full bg-[#c2a67d] hover:bg-[#b0946b]"
            disabled={state === "submitting"}
            onClick={async () => {
              setState("submitting");
              const result = await submitSupportRequestApi(form);
              if (!result.success) {
                setState("error");
                setMessage(result.message || "Support form is not available yet.");
                return;
              }

              setState("submitted");
              setMessage(result.message || "Support request sent.");
            }}
          >
            {state === "submitting" ? "Sending..." : "Send request"}
          </Button>
        </CardContent>
      </Card>
      {state === "error" ? <div className="mt-4"><ErrorState message={message} /></div> : null}
      {state === "submitted" ? <div className="mt-4"><EmptyState title="Submitted" description={message} /></div> : null}
    </div>
  );
}
