import { CheckCircle2, Sparkles } from "lucide-react";
import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router";
import { AppField } from "../../components/AppField";
import { AppGuidanceCard } from "../../components/AppGuidanceCard";
import { AppPageHeader } from "../../components/AppPageHeader";
import { AppSection } from "../../components/AppSection";
import { Button } from "../../components/ui/button";
import { LoadingState } from "../../components/LoadingState";
import { saveSurveyApi, getSurveyApi } from "../../services/surveyService";

export function AppSkinProfileForm({
  title,
  description,
  redirectTo,
}: {
  title: string;
  description: string;
  redirectTo: string;
}) {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState("");
  const [form, setForm] = useState({
    skinType: "",
    concerns: "",
    monthlyBudget: "",
    age: "",
  });

  useEffect(() => {
    let active = true;
    void getSurveyApi().then((result) => {
      if (!active) return;
      if (result.success && result.content) {
        setForm({
          skinType: result.content.skinType || "",
          concerns: (result.content.skinConcerns || []).join(", "),
          monthlyBudget: result.content.monthlyBudget || "",
          age: result.content.age ? String(result.content.age) : "",
        });
      }
      setLoading(false);
    });

    return () => {
      active = false;
    };
  }, []);

  if (loading) {
    return <LoadingState label="Loading your skin profile..." />;
  }

  return (
    <div className="space-y-6">
      <AppPageHeader title={title} description={description} eyebrow="Profile setup" />

      <div className="grid gap-4 xl:grid-cols-[1.15fr_0.85fr]">
        <AppSection title="Profile details" description="This information keeps analysis, routine, and product context aligned.">
          <div className="grid gap-4">
            <AppField label="Skin type">
              <input
                className="app-input"
                placeholder="Combination, oily, dry..."
                value={form.skinType}
                onChange={(event) => setForm((prev) => ({ ...prev, skinType: event.target.value }))}
              />
            </AppField>
            <AppField label="Skin concerns" hint="Use commas to separate multiple concerns.">
              <textarea
                className="app-textarea"
                placeholder="Acne, redness, dark spots..."
                value={form.concerns}
                onChange={(event) => setForm((prev) => ({ ...prev, concerns: event.target.value }))}
              />
            </AppField>
            <div className="grid gap-4 md:grid-cols-2">
              <AppField label="Monthly budget">
                <input
                  className="app-input"
                  placeholder="Low, mid-range, premium"
                  value={form.monthlyBudget}
                  onChange={(event) => setForm((prev) => ({ ...prev, monthlyBudget: event.target.value }))}
                />
              </AppField>
              <AppField label="Age">
                <input
                  className="app-input"
                  type="number"
                  min="0"
                  placeholder="Age"
                  value={form.age}
                  onChange={(event) => setForm((prev) => ({ ...prev, age: event.target.value }))}
                />
              </AppField>
            </div>
            <div className="flex flex-wrap gap-3">
              <Button
                className="bg-primary text-primary-foreground hover:bg-primary/90"
                disabled={saving}
                onClick={async () => {
                  setSaving(true);
                  const result = await saveSurveyApi({
                    skinType: form.skinType,
                    skinConcerns: form.concerns.split(",").map((item) => item.trim()).filter(Boolean),
                    monthlyBudget: form.monthlyBudget,
                    age: form.age ? Number(form.age) : null,
                  });
                  setSaving(false);
                  setFeedback(result.message);
                  if (result.success) {
                    navigate(redirectTo);
                  }
                }}
              >
                {saving ? "Saving..." : "Save skin profile"}
              </Button>
              <Button asChild variant="outline" className="border-border bg-card hover:bg-muted">
                <Link to="/app/dashboard">Back to dashboard</Link>
              </Button>
            </div>
            {feedback ? <p className="text-sm text-muted-foreground">{feedback}</p> : null}
          </div>
        </AppSection>

        <div className="space-y-4">
          <AppGuidanceCard
            title="Why this matters"
            description="A complete skin profile improves how SkinSync interprets your analysis and organizes your routine."
            icon={Sparkles}
          >
            <div className="space-y-2">
              {[
                "Save your core skin details",
                "Run a backend skin analysis",
                "Review a routine designed around those signals",
              ].map((text) => (
                <div key={text} className="flex items-center gap-2 text-sm text-foreground">
                  <CheckCircle2 className="h-4 w-4 text-primary" />
                  <span>{text}</span>
                </div>
              ))}
            </div>
          </AppGuidanceCard>
        </div>
      </div>
    </div>
  );
}
