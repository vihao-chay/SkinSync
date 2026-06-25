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
        description="Capture routine completion and how your skin feels today without inventing backend fields that do not exist."
      />

      <div className="grid gap-4 xl:grid-cols-[1fr_0.9fr]">
        <AppSection title="Today's routine checklist" description="Keep daily log state aligned with backend routine completion when available.">
          {hasRoutine ? (
            <div className="grid gap-4">
              <label className="flex items-center justify-between rounded-2xl border border-border/60 bg-muted/70 px-4 py-4">
                <span className="text-sm text-foreground">Morning routine completed</span>
                <input
                  type="checkbox"
                  checked={form.morningCompleted}
                  onChange={(event) => setForm((prev) => ({ ...prev, morningCompleted: event.target.checked }))}
                />
              </label>
              <label className="flex items-center justify-between rounded-2xl border border-border/60 bg-muted/70 px-4 py-4">
                <span className="text-sm text-foreground">Evening routine completed</span>
                <input
                  type="checkbox"
                  checked={form.eveningCompleted}
                  onChange={(event) => setForm((prev) => ({ ...prev, eveningCompleted: event.target.checked }))}
                />
              </label>
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

        <AppSection title="Skin condition log" description="Only the fields already supported by the current backend contract are shown.">
          <div className="grid gap-4">
            <AppField label="Skin feeling">
              <select
                className="app-input"
                value={form.skinFeeling}
                onChange={(event) => setForm((prev) => ({ ...prev, skinFeeling: event.target.value }))}
              >
                <option value="">Select today's feeling</option>
                <option value="Balanced">Balanced</option>
                <option value="Dry">Dry</option>
                <option value="Oily">Oily</option>
                <option value="Sensitive">Sensitive</option>
                <option value="Breakout-prone">Breakout-prone</option>
              </select>
            </AppField>
            <label className="flex items-center gap-3 rounded-2xl border border-border/60 bg-muted/70 px-4 py-4 text-sm text-foreground">
              <input
                type="checkbox"
                checked={form.isIrritated}
                onChange={(event) => setForm((prev) => ({ ...prev, isIrritated: event.target.checked }))}
              />
              I feel irritation today
            </label>
            <AppField label="Notes">
              <textarea
                className="app-textarea"
                placeholder="Add daily notes about dryness, new breakouts, or anything worth tracking."
                value={form.notes}
                onChange={(event) => setForm((prev) => ({ ...prev, notes: event.target.value }))}
              />
            </AppField>
            <Button
              className="bg-primary text-primary-foreground hover:bg-primary/90"
              disabled={saving}
              onClick={async () => {
                setSaving(true);
                const result = await saveCheckInApi(form);
                setSaving(false);
                setFeedback(result.message || (result.success ? "Daily log saved." : "Unable to save daily log."));
              }}
            >
              {saving ? "Saving..." : "Save daily log"}
            </Button>
            {feedback ? <p className="text-sm text-muted-foreground">{feedback}</p> : null}
          </div>
        </AppSection>
      </div>
    </div>
  );
}
