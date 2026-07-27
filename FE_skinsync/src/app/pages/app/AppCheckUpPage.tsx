import { Check, Droplets, Flame, Moon, ShieldCheck, Smile, Sun } from "lucide-react";
import { useEffect, useState } from "react";
import { Link } from "react-router";
import { AppEmptyState } from "../../components/AppEmptyState";
import { AppField } from "../../components/AppField";
import { AppPageHeader } from "../../components/AppPageHeader";
import { AppSection } from "../../components/AppSection";
import { Button } from "../../components/ui/button";
import { LoadingState } from "../../components/LoadingState";
import { getTodayCheckInApi, saveCheckInApi } from "../../services/diaryService";
import { getCurrentRegimenApi } from "../../services/regimenService";
import { getTodayRoutineTrackingApi } from "../../services/routineTrackingService";

export function AppCheckUpPage() {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState("");
  const [hasRoutine, setHasRoutine] = useState(false);
  const [form, setForm] = useState({
    morningCompleted: false,
    eveningCompleted: false,
    skinFeeling: "",
    isIrritated: false,
    notes: "",
  });

  useEffect(() => {
    let active = true;
    void Promise.all([getTodayCheckInApi(), getCurrentRegimenApi(), getTodayRoutineTrackingApi()]).then(
      ([checkInResult, regimenResult, trackingResult]) => {
        if (!active) return;
        setHasRoutine(Boolean(regimenResult.content));
        if (checkInResult.content) {
          setForm({
            morningCompleted: checkInResult.content.morningCompleted,
            eveningCompleted: checkInResult.content.eveningCompleted,
            skinFeeling: checkInResult.content.skinFeeling || "",
            isIrritated: checkInResult.content.isIrritated,
            notes: checkInResult.content.notes || "",
          });
        } else if (trackingResult.content) {
          setForm((prev) => ({
            ...prev,
            morningCompleted: trackingResult.content?.morningCompleted ?? false,
            eveningCompleted: trackingResult.content?.eveningCompleted ?? false,
          }));
        }
        setLoading(false);
      }
    );
    return () => {
      active = false;
    };
  }, []);

  if (loading) {
    return <LoadingState label="Loading your daily check-up..." />;
  }

  return (
    <div className="space-y-6">
      <AppPageHeader
        eyebrow="Daily diary"
        title="Daily Check-up"
        description="A quick, thoughtful log of how your skin feels today."
      />

      <div className="grid gap-4 xl:grid-cols-[1fr_0.9fr]">
        <AppSection title="Today's skin" description="A few seconds now helps your future self spot patterns.">
          {hasRoutine ? (
            <div className="grid gap-4">
              <CheckRow label="Morning routine completed" icon={Sun} checked={form.morningCompleted} onChange={(value) => setForm((prev) => ({ ...prev, morningCompleted: value }))} />
              <CheckRow label="Evening routine completed" icon={Moon} checked={form.eveningCompleted} onChange={(value) => setForm((prev) => ({ ...prev, eveningCompleted: value }))} />
            </div>
          ) : (
            <AppEmptyState
              title="No routine available"
              description="Daily check-up can still store skin feeling and notes, but there is no backend routine checklist for this user yet."
              action={
                <Button asChild className="bg-primary text-primary-foreground hover:bg-primary/90">
                  <Link to="/app/routine">Open routine</Link>
                </Button>
              }
            />
          )}
        </AppSection>

        <AppSection title="How does your skin feel?" description="Choose the closest feeling, then add a note if something stands out.">
          <div className="grid gap-4">
            <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">{["Balanced", "Dry", "Oily", "Sensitive"].map((feeling) => <button key={feeling} type="button" onClick={() => setForm((prev) => ({ ...prev, skinFeeling: feeling }))} className={`rounded-2xl border p-4 text-left transition hover:-translate-y-1 ${form.skinFeeling === feeling ? "border-[#c2a67d] bg-[#fbf6ed]" : "border-border/60 bg-[#fbfaf8]"}`}><Smile className={`h-5 w-5 ${form.skinFeeling === feeling ? "text-[#977b56]" : "text-[#aaa]"}`} /><p className="mt-3 text-sm font-semibold text-[#333]">{feeling}</p></button>)}</div>
            <CheckRow label="I feel irritation today" icon={ShieldCheck} checked={form.isIrritated} onChange={(value) => setForm((prev) => ({ ...prev, isIrritated: value }))} />
            <AppField label="Notes">
              <textarea
                className="app-textarea"
                placeholder="Add daily notes about dryness, new breakouts, or anything worth tracking."
                value={form.notes}
                onChange={(event) => setForm((prev) => ({ ...prev, notes: event.target.value }))}
              />
            </AppField>
            <Button
              className="h-12 w-full bg-[#222] text-white hover:bg-[#3d3a36]"
              disabled={saving}
              onClick={async () => {
                setSaving(true);
                const result = await saveCheckInApi(form);
                setSaving(false);
                setFeedback(result.message || (result.success ? "Daily log saved." : "Unable to save daily log."));
              }}
            >
              {saving ? "Saving..." : "Save Today's Check-in"}
            </Button>
            {feedback ? <p className="text-sm text-muted-foreground">{feedback}</p> : null}
          </div>
        </AppSection>
      </div>
    </div>
  );
}

function CheckRow({ label, icon: Icon, checked, onChange }: { label: string; icon: typeof Sun; checked: boolean; onChange: (value: boolean) => void }) {
  return <button type="button" onClick={() => onChange(!checked)} className={`flex w-full items-center justify-between rounded-2xl border px-4 py-4 text-left transition hover:-translate-y-0.5 ${checked ? "border-[#7bae7f] bg-[#f0f6ef]" : "border-border/60 bg-[#fbfaf8]"}`}><span className="flex items-center gap-3"><Icon className={`h-5 w-5 ${checked ? "text-[#6f9b73]" : "text-[#a68a63]"}`} /><span className="text-sm font-medium text-[#333]">{label}</span></span><span className={`flex h-6 w-6 items-center justify-center rounded-full border ${checked ? "border-[#7bae7f] bg-[#7bae7f] text-white" : "border-[#d8d0c3] text-transparent"}`}><Check className="h-3.5 w-3.5" /></span></button>;
}
