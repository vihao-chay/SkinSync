import { AlertCircle, ArrowRight, CircleCheck, Droplets, Loader2, RefreshCw, Sparkles, SunMedium } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router";
import { AppEmptyState } from "../../components/AppEmptyState";
import { AppGuidanceCard } from "../../components/AppGuidanceCard";
import { AppPageHeader } from "../../components/AppPageHeader";
import { AppSection } from "../../components/AppSection";
import { AppUploadZone } from "../../components/AppUploadZone";
import { Button } from "../../components/ui/button";
import { ErrorState } from "../../components/ErrorState";
import { LoadingState } from "../../components/LoadingState";
import {
  getAnalysisHistoryApi,
  getLatestAnalysisApi,
  uploadSkinAnalysisApi,
  type AnalysisDetail,
  type AnalysisHistoryItem,
} from "../../services/analysisService";
import { getCurrentSubscriptionApi } from "../../services/subscriptionService";
import { getSurveyApi } from "../../services/surveyService";
import { IMAGE_TYPES, MAX_FILE_SIZE } from "../../constants/appShell";
import { formatDate } from "../../utils/appFormat";

export function AppAnalysisPage() {
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState("");
  const [feedback, setFeedback] = useState("");
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [latest, setLatest] = useState<AnalysisDetail | null>(null);
  const [history, setHistory] = useState<AnalysisHistoryItem[]>([]);
  const [hasProfile, setHasProfile] = useState(false);
  const [quotaSummary, setQuotaSummary] = useState("Quota unavailable");

  useEffect(() => {
    let active = true;
    void Promise.all([getLatestAnalysisApi(), getAnalysisHistoryApi(1, 6), getSurveyApi(), getCurrentSubscriptionApi()]).then(
      ([latestResult, historyResult, surveyResult, subscriptionResult]) => {
        if (!active) return;
        setLatest(latestResult.content ?? null);
        setHistory(historyResult.content?.items ?? []);
        setHasProfile(Boolean(surveyResult.content));
        const analysisUsage = subscriptionResult.content?.usage?.find((item) =>
          item.featureKey.toLowerCase().includes("analysis")
        );
        if (analysisUsage) {
          setQuotaSummary(
            analysisUsage.isUnlimited
              ? "Unlimited analysis access"
              : `${analysisUsage.used}/${analysisUsage.limit ?? "-"} ${analysisUsage.unit}`
          );
        }
        setLoading(false);
      }
    );

    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    if (!selectedFile) {
      setPreviewUrl(null);
      return;
    }

    const url = URL.createObjectURL(selectedFile);
    setPreviewUrl(url);
    return () => URL.revokeObjectURL(url);
  }, [selectedFile]);

  const readinessItems = useMemo(
    () => [
      { label: "Skin profile", value: hasProfile ? "Ready" : "Not completed yet" },
      { label: "Photo guideline", value: "Use a clear, front-facing image with soft lighting." },
      { label: "AI quota", value: quotaSummary },
    ],
    [hasProfile, quotaSummary]
  );

  if (loading) {
    return <LoadingState label="Loading your analysis workspace..." />;
  }

  if (error) {
    return <ErrorState message={error} />;
  }

  return (
    <div className="space-y-6">
      <AppPageHeader
        eyebrow="Analysis"
        title="Skin Analysis"
        description="Analyze your current skin condition and receive personalized AI insights."
      />

      <div className="grid gap-4 xl:grid-cols-[1.15fr_0.85fr]">
        <div className="space-y-4">
          <AppSection
            title="Upload Image"
            description="Use a clear, front-facing photo in soft natural light for the most useful reading."
          >
            <div className="space-y-4">
              <AppUploadZone
                title="Upload a skin photo"
                description="Supported formats: JPEG, PNG, WEBP. The upload is sent to the backend for analysis only."
                file={selectedFile}
                previewUrl={previewUrl}
                accept={IMAGE_TYPES.join(",")}
                helper="Up to 5 MB"
                onPick={(file) => {
                  setFeedback("");
                  if (!file) {
                    setSelectedFile(null);
                    return;
                  }
                  if (!IMAGE_TYPES.includes(file.type)) {
                    setFeedback("Please choose a JPEG, PNG, or WEBP image.");
                    return;
                  }
                  if (file.size > MAX_FILE_SIZE) {
                    setFeedback("Please choose an image smaller than 5 MB.");
                    return;
                  }
                  setSelectedFile(file);
                }}
              />
              <div className="flex flex-wrap gap-3">
                <Button
                  className="bg-primary text-primary-foreground hover:bg-primary/90"
                  disabled={!selectedFile || uploading}
                  onClick={async () => {
                    if (!selectedFile) return;
                    setUploading(true);
                    setFeedback("Uploading photo...");
                    const result = await uploadSkinAnalysisApi(selectedFile);
                    if (result.success) {
                      setFeedback("Preparing result...");
                      const [latestResult, historyResult] = await Promise.all([getLatestAnalysisApi(), getAnalysisHistoryApi(1, 6)]);
                      setLatest(latestResult.content ?? null);
                      setHistory(historyResult.content?.items ?? []);
                      setSelectedFile(null);
                      setFeedback("Analysis completed.");
                    } else {
                      setFeedback(result.message || "Analysis failed.");
                    }
                    setUploading(false);
                  }}
                >
                  {uploading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : null}
                  {uploading ? "Running backend analysis" : "Analyze skin"}
                </Button>
                <Button
                  variant="outline"
                  className="border-border bg-card hover:bg-muted"
                  disabled={uploading}
                  onClick={() => {
                    setSelectedFile(null);
                    setFeedback("");
                  }}
                >
                  Reset
                </Button>
              </div>
              {feedback ? <p className="text-sm text-muted-foreground">{feedback}</p> : null}
            </div>
          </AppSection>

          <AppSection
            title="Your latest reading"
            description="A concise view of the signals SkinSync found in your latest scan."
            action={
              latest ? (
                <Button asChild variant="ghost" className="px-0 text-primary hover:bg-transparent hover:text-primary/80">
                  <Link to="/app/routine">
                    Review routine
                    <ArrowRight className="ml-1 h-4 w-4" />
                  </Link>
                </Button>
              ) : undefined
            }
          >
            {latest ? (
              <>
              <div className="grid gap-5 lg:grid-cols-[190px_1fr] lg:items-center">
                <div className="mx-auto flex h-40 w-40 items-center justify-center rounded-full border-[12px] border-[#c2a67d]/25 bg-[#fbf6ed] text-center"><div><p className="text-5xl font-semibold tracking-[-0.06em] text-[#222]">{latest.overallScore || "--"}</p><p className="text-xs uppercase tracking-[0.16em] text-[#977b56]">Skin score</p></div></div>
                <div className="space-y-4"><div className="flex flex-wrap gap-2"><span className="app-pill-success"><CircleCheck className="h-3.5 w-3.5" />{latest.status || "Available"}</span><span className="app-pill">{latest.skinType || "Skin type unavailable"}</span><span className="app-pill">Confidence {latest.confidenceScore || "--"}%</span></div><div className="space-y-3"><MetricBar icon={Droplets} label="Hydration" value={latest.recoveryCapacity} tone="bg-[#7ba7a0]" /><MetricBar icon={SunMedium} label="Oil balance" value={latest.uvDamage} tone="bg-[#c2a67d]" /><MetricBar icon={Sparkles} label="Skin resilience" value={latest.confidenceScore} tone="bg-[#9a8db5]" /></div></div>
              </div>
              <div className="mt-6 border-t border-border/60 pt-5"><p className="text-xs font-semibold uppercase tracking-[0.18em] text-[#977b56]">Detected concerns</p><div className="mt-3 flex flex-wrap gap-2">{latest.issues?.length ? latest.issues.map((issue) => <span key={issue.id} className="app-pill-warning">{issue.issueType}</span>) : <span className="text-sm text-muted-foreground">No concerns returned</span>}</div><p className="mt-5 text-sm leading-7 text-[#777]">{latest.overview || latest.rootCauses || "No summary available."}</p></div>
              </>
            ) : (
              <AppEmptyState
                title="No skin analysis yet"
                description="Upload a clear skin photo to generate your first backend-backed analysis."
                action={
                  <Button className="bg-primary text-primary-foreground hover:bg-primary/90" disabled>
                    Upload a photo above
                  </Button>
                }
              />
            )}
          </AppSection>
        </div>

        <div className="space-y-4">
          <AppSection title="Analysis readiness" description="Everything this page can validate before you run the next scan.">
            <div className="grid gap-3">
              {readinessItems.map((item) => (
                <ResultTile key={item.label} label={item.label} value={item.value} />
              ))}
            </div>
          </AppSection>

          <AppGuidanceCard
            title="Privacy and safety note"
            description="Images are used for backend skin analysis. This experience should avoid medical claims and keep recommendations informational."
            icon={AlertCircle}
          />

          <AppSection
            title="History"
            description="Recent analysis entries, kept lightweight until a dedicated detail flow is available."
            action={
              <Button
                variant="outline"
                className="border-border bg-card hover:bg-muted"
                onClick={async () => {
                  const result = await getAnalysisHistoryApi(1, 6);
                  setHistory(result.content?.items ?? []);
                }}
              >
                <RefreshCw className="mr-2 h-4 w-4" />
                Refresh
              </Button>
            }
          >
            {history.length ? (
                <div className="relative space-y-3 pl-6 before:absolute before:bottom-2 before:left-2 before:top-2 before:w-px before:bg-[#ded3c3]">
                  {history.map((item) => (
                  <div key={item.id} className="relative rounded-2xl border border-border/60 bg-[#fbfaf8] px-4 py-3 before:absolute before:-left-[1.65rem] before:top-5 before:h-3 before:w-3 before:rounded-full before:border-2 before:border-[#c2a67d] before:bg-white">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="app-pill">{formatDate(item.createdAt)}</span>
                      {item.overallScore ? <span className="app-pill">Score {item.overallScore}</span> : null}
                      {item.skinType ? <span className="app-pill">{item.skinType}</span> : null}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <AppEmptyState
                title="No history yet"
                description="Once you run analysis, recent entries will appear here with date and basic status."
              />
            )}
          </AppSection>
        </div>
      </div>
    </div>
  );
}

function ResultTile({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-border/60 bg-muted/70 px-4 py-3">
      <p className="text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground">{label}</p>
      <p className="mt-1 text-sm leading-6 text-foreground">{value}</p>
    </div>
  );
}

function MetricBar({ icon: Icon, label, value, tone }: { icon: typeof Droplets; label: string; value?: number | null; tone: string }) {
  const safeValue = typeof value === "number" ? Math.max(0, Math.min(100, value)) : 0;
  return <div><div className="mb-1.5 flex items-center justify-between text-xs text-[#777]"><span className="flex items-center gap-2"><Icon className="h-3.5 w-3.5 text-[#977b56]" />{label}</span><span>{typeof value === "number" ? `${Math.round(value)}/100` : "Pending"}</span></div><div className="h-2 overflow-hidden rounded-full bg-[#eee9e1]"><div className={`h-full rounded-full ${tone} transition-all duration-700`} style={{ width: `${safeValue}%` }} /></div></div>;
}
