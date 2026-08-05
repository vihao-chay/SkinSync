import { ArrowRight, ClipboardCheck, Sparkles } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router";
import { AppEmptyState } from "../../components/AppEmptyState";
import { AppGuidanceCard } from "../../components/AppGuidanceCard";
import { AppPageHeader } from "../../components/AppPageHeader";
import { AppRoutineStepCard } from "../../components/AppRoutineStepCard";
import { AppSection } from "../../components/AppSection";
import { Button } from "../../components/ui/button";
import { ErrorState } from "../../components/ErrorState";
import { LoadingState } from "../../components/LoadingState";
import { getLatestAnalysisApi } from "../../services/analysisService";
import { getCurrentRegimenApi, type CurrentRegimenResponse } from "../../services/regimenService";
import {
  completeRoutineStepApi,
  getTodayRoutineTrackingApi,
  uncompleteRoutineStepApi,
  type RoutineTrackingToday,
} from "../../services/routineTrackingService";
import { getSurveyApi } from "../../services/surveyService";

export function AppRoutinePage() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [regimen, setRegimen] = useState<CurrentRegimenResponse | null>(null);
  const [tracking, setTracking] = useState<RoutineTrackingToday | null>(null);
  const [hasProfile, setHasProfile] = useState(false);
  const [hasAnalysis, setHasAnalysis] = useState(false);

  async function reload() {
    const [regimenResult, trackingResult, surveyResult, analysisResult] = await Promise.all([
      getCurrentRegimenApi(),
      getTodayRoutineTrackingApi(),
      getSurveyApi(),
      getLatestAnalysisApi(),
    ]);

    if (!regimenResult.success && !trackingResult.success) {
      setError("Unable to load your routine right now.");
      setLoading(false);
      return;
    }

    setRegimen(regimenResult.content ?? null);
    setTracking(trackingResult.content ?? null);
    setHasProfile(Boolean(surveyResult.content));
    setHasAnalysis(Boolean(analysisResult.content));
    setLoading(false);
  }

  useEffect(() => {
    void reload();
  }, []);

  const morningCompleted = useMemo(
    () => regimen?.morning.filter((step) => tracking?.steps?.some((item) => item.stepId === step.stepId && item.status === "completed")).length ?? 0,
    [regimen, tracking]
  );
  const eveningCompleted = useMemo(
    () => regimen?.evening.filter((step) => tracking?.steps?.some((item) => item.stepId === step.stepId && item.status === "completed")).length ?? 0,
    [regimen, tracking]
  );

  if (loading) {
    return <LoadingState label="Loading your routine..." />;
  }

  if (error) {
    return <ErrorState message={error} />;
  }

  return (
    <div className="space-y-6">
      <AppPageHeader
        eyebrow="Routine"
        title="Today's Routine"
        description="A focused morning and evening ritual designed around your skin profile."
        actions={
          <>
            <Button asChild className="bg-primary text-primary-foreground hover:bg-primary/90">
              <Link to="/app/check-up">Daily Check-up</Link>
            </Button>
            <Button asChild variant="outline" className="border-border bg-card hover:bg-muted">
              <Link to="/app/analysis">Analyze skin</Link>
            </Button>
          </>
        }
      />

      {regimen && tracking ? (
        <>
          <div className="grid gap-5 rounded-[24px] border border-[#ded3c3] bg-[linear-gradient(135deg,#fffdf8,#f2e7d6)] p-6 lg:grid-cols-[auto_1fr_auto] lg:items-center">
            <div className="flex h-28 w-28 items-center justify-center rounded-full border-[10px] border-[#c2a67d]/25 bg-white text-center"><div><p className="text-3xl font-semibold text-[#222]">{tracking.completionPercent}%</p><p className="text-[10px] uppercase tracking-[0.14em] text-[#977b56]">Complete</p></div></div>
            <div><p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#977b56]">{regimen.name}</p><h2 className="mt-1 text-2xl font-semibold text-[#222]">Your care rhythm is taking shape.</h2><p className="mt-2 text-sm leading-6 text-[#777]">{tracking.completedSteps} of {tracking.totalSteps} steps completed today.</p></div>
            <div className="grid grid-cols-2 gap-3 text-center"><div className="rounded-2xl bg-white/70 px-4 py-3"><p className="text-2xl font-semibold text-[#222]">{morningCompleted}</p><p className="text-xs text-[#777]">Morning</p></div><div className="rounded-2xl bg-white/70 px-4 py-3"><p className="text-2xl font-semibold text-[#222]">{eveningCompleted}</p><p className="text-xs text-[#777]">Evening</p></div></div>
          </div>

        <AppSection title="Today's progress" description="Move through each step in sequence and keep the rhythm gentle. ">
            <div className="space-y-4">
              <div>
                <div className="mb-2 flex items-center justify-between text-sm text-muted-foreground">
                  <span>Completion today</span>
                  <span>{tracking.completionPercent}%</span>
                </div>
                <div className="h-3 overflow-hidden rounded-full bg-muted">
                  <div className="h-full rounded-full bg-primary" style={{ width: `${tracking.completionPercent}%` }} />
                </div>
              </div>
              <div className="grid gap-3 sm:grid-cols-2">
                <div className="rounded-2xl border border-border/60 bg-muted/70 px-4 py-3">
                  <p className="text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground">Morning status</p>
                  <p className="mt-1 text-sm text-foreground">{tracking.morningCompleted ? "Completed" : "Still in progress"}</p>
                </div>
                <div className="rounded-2xl border border-border/60 bg-muted/70 px-4 py-3">
                  <p className="text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground">Evening status</p>
                  <p className="mt-1 text-sm text-foreground">{tracking.eveningCompleted ? "Completed" : "Still in progress"}</p>
                </div>
              </div>
            </div>
          </AppSection>

          <div className="grid gap-4 xl:grid-cols-2">
            <AppSection title="Morning routine" description="Start-of-day steps powered by the current regimen.">
              <div className="relative space-y-3 pl-5 before:absolute before:bottom-4 before:left-2 before:top-4 before:w-px before:bg-[#ded3c3]">
                {regimen.morning.length ? (
                  regimen.morning.map((step) => (
                    <AppRoutineStepCard
                      key={step.stepId}
                      step={step}
                      routineTime="Morning"
                      tracking={tracking}
                      onToggle={async (stepId, completed) => {
                        const result = completed ? await uncompleteRoutineStepApi(stepId) : await completeRoutineStepApi(stepId);
                        if (result.success) {
                          setTracking(result.content ?? null);
                        }
                      }}
                    />
                  ))
                ) : (
                  <AppEmptyState title="No morning steps" description="This regimen does not include morning steps right now." />
                )}
              </div>
            </AppSection>

            <AppSection title="Evening routine" description="End-of-day steps, tracked separately from morning completion.">
              <div className="relative space-y-3 pl-5 before:absolute before:bottom-4 before:left-2 before:top-4 before:w-px before:bg-[#ded3c3]">
                {regimen.evening.length ? (
                  regimen.evening.map((step) => (
                    <AppRoutineStepCard
                      key={step.stepId}
                      step={step}
                      routineTime="Evening"
                      tracking={tracking}
                      onToggle={async (stepId, completed) => {
                        const result = completed ? await uncompleteRoutineStepApi(stepId) : await completeRoutineStepApi(stepId);
                        if (result.success) {
                          setTracking(result.content ?? null);
                        }
                      }}
                    />
                  ))
                ) : (
                  <AppEmptyState title="No evening steps" description="This regimen does not include evening steps right now." />
                )}
              </div>
            </AppSection>
          </div>
        </>
      ) : (
        <div className="grid gap-4 xl:grid-cols-[1.15fr_0.85fr]">
          <AppSection title="Routine unavailable" description="This user does not have a current regimen from the backend yet.">
            <AppEmptyState
              title="No routine yet"
              description="Instead of showing a fake routine, SkinSync will guide you through the real prerequisites."
              action={
                <Button asChild className="bg-primary text-primary-foreground hover:bg-primary/90">
                  <Link to={hasProfile ? (hasAnalysis ? "/app/analysis" : "/app/analysis") : "/app/skin-profile"}>Continue setup</Link>
                </Button>
              }
            />
          </AppSection>

          <AppGuidanceCard
            title="How to unlock a routine"
            description="Routine generation depends on saved profile and analysis context. Until then, this page stays honest about missing backend data."
            icon={Sparkles}
          >
            <div className="space-y-3 text-sm text-foreground">
              <div className="flex items-center justify-between rounded-2xl border border-border/60 bg-card px-4 py-3">
                <span>Complete skin profile</span>
                <span>{hasProfile ? "Done" : "Pending"}</span>
              </div>
              <div className="flex items-center justify-between rounded-2xl border border-border/60 bg-card px-4 py-3">
                <span>Run skin analysis</span>
                <span>{hasAnalysis ? "Done" : "Pending"}</span>
              </div>
              <Button asChild variant="outline" className="border-border bg-card hover:bg-background">
                <Link to="/app/check-up">
                  <ClipboardCheck className="mr-2 h-4 w-4" />
                  Open daily check-up
                </Link>
              </Button>
            </div>
          </AppGuidanceCard>
        </div>
      )}
    </div>
  );
}
