import {
  ArrowRight,
  Check,
  ChevronRight,
  Droplets,
  Moon,
  ScanLine,
  ShieldCheck,
  Sparkles,
  Sun,
  TrendingDown,
  TrendingUp,
} from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router";
import {
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { Button } from "../../components/ui/button";
import { ErrorState } from "../../components/ErrorState";
import { LoadingState } from "../../components/LoadingState";
import { useAuth } from "../../contexts/AuthContext";
import { getLatestAnalysisApi, type AnalysisDetail } from "../../services/analysisService";
import { getCurrentRegimenApi, type CurrentRegimenResponse, type RegimenProduct } from "../../services/regimenService";
import {
  getLatestRecommendationsApi,
  type SavedRecommendationProduct,
  type SavedRecommendationResponse,
} from "../../services/recommendationService";
import { getTodayRoutineTrackingApi, type RoutineTrackingToday } from "../../services/routineTrackingService";
import { getSkinProgressOverviewApi, type SkinProgressOverview } from "../../services/skinProgressService";
import { getSurveyApi, type SurveyResponse } from "../../services/surveyService";
import { firstName } from "../../utils/appFormat";

type ProgressMetric = "skinScore" | "hydrationLevel" | "oilLevel" | "acneLevel";

const metricLabels: Record<ProgressMetric, string> = {
  skinScore: "Skin Score",
  hydrationLevel: "Hydration",
  oilLevel: "Oil",
  acneLevel: "Acne",
};

export function AppDashboardPage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [survey, setSurvey] = useState<SurveyResponse | null>(null);
  const [analysis, setAnalysis] = useState<AnalysisDetail | null>(null);
  const [regimen, setRegimen] = useState<CurrentRegimenResponse | null>(null);
  const [tracking, setTracking] = useState<RoutineTrackingToday | null>(null);
  const [progress, setProgress] = useState<SkinProgressOverview | null>(null);
  const [recommendations, setRecommendations] = useState<SavedRecommendationResponse | null>(null);
  const [metric, setMetric] = useState<ProgressMetric>("skinScore");

  useEffect(() => {
    let active = true;
    async function load() {
      const [surveyResult, analysisResult, regimenResult, trackingResult, progressResult, recommendationResult] =
        await Promise.all([
          getSurveyApi(),
          getLatestAnalysisApi(),
          getCurrentRegimenApi(),
          getTodayRoutineTrackingApi(),
          getSkinProgressOverviewApi(),
          getLatestRecommendationsApi(),
        ]);

      if (!active) return;
      if (!surveyResult.success && !analysisResult.success && !regimenResult.success && !progressResult.success) {
        setError("Unable to load your dashboard right now.");
        setLoading(false);
        return;
      }

      setSurvey(surveyResult.content ?? null);
      setAnalysis(analysisResult.content ?? null);
      setRegimen(regimenResult.content ?? null);
      setTracking(trackingResult.content ?? null);
      setProgress(progressResult.content ?? null);
      setRecommendations(recommendationResult.content ?? null);
      setLoading(false);
    }

    void load();
    return () => {
      active = false;
    };
  }, []);

  const latestPoint = progress?.chartData?.[progress.chartData.length - 1];
  const score = analysis?.overallScore ?? progress?.latestScore ?? null;
  const scoreDelta = progress?.scoreDelta ?? null;
  const recommendationProducts = useMemo(() => {
    const directProducts = recommendations?.products ?? [];
    const categoryProducts = (recommendations?.categories ?? []).flatMap((category) => category.items ?? category.products ?? []);
    return (directProducts.length ? directProducts : categoryProducts).slice(0, 3);
  }, [recommendations]);

  const insights = useMemo(() => {
    const items: string[] = [];
    if (scoreDelta !== null && scoreDelta !== undefined) {
      items.push(`Your skin score ${scoreDelta >= 0 ? "improved" : "shifted"} by ${Math.abs(scoreDelta)} points since your last check-in.`);
    }
    if (latestPoint?.hydrationLevel !== null && latestPoint?.hydrationLevel !== undefined) {
      items.push(`Hydration is currently tracking at ${formatMetric(latestPoint.hydrationLevel)}.`);
    }
    analysis?.recommendations?.slice(0, 2).forEach((item) => items.push(item.title || item.content));
    if (!items.length && tracking) {
      items.push(`Your routine is ${Math.round(tracking.completionPercent)}% complete today. Consistency compounds over time.`);
    }
    return items.slice(0, 3);
  }, [analysis, latestPoint, scoreDelta, tracking]);

  const chartData = useMemo(
    () =>
      (progress?.chartData ?? [])
        .map((item) => ({
          label: new Date(item.createdAt).toLocaleDateString(undefined, { month: "short", day: "numeric" }),
          value: item[metric],
        }))
        .filter((item): item is { label: string; value: number } => typeof item.value === "number"),
    [metric, progress],
  );

  if (loading) return <LoadingState label="Loading your skin care overview..." />;
  if (error) return <ErrorState message={error} />;

  return (
    <div className="space-y-8 pb-8">
      <section className="overflow-hidden rounded-[28px] border border-[#ded6ca] bg-[#f4efe7] shadow-[0_18px_45px_rgba(70,55,39,0.08)]">
        <div className="grid gap-8 px-6 py-7 md:px-9 md:py-9 lg:grid-cols-[1fr_250px] lg:items-center">
          <div className="max-w-2xl">
            <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#977b56]">Your SkinSync overview</p>
            <h1 className="mt-3 text-3xl font-semibold tracking-[-0.04em] text-[#222] sm:text-5xl">Good morning, {firstName(user?.fullName)}</h1>
            <p className="mt-4 max-w-xl text-base leading-7 text-[#777]">{analysis?.overview || progress?.trendSummary || "Your personalized skin journey starts with one clear check-in today."}</p>
            <div className="mt-6 flex flex-wrap gap-3">
              <Button asChild className="bg-[#222] text-white hover:bg-[#3d3a36]"><Link to="/app/analysis"><ScanLine className="h-4 w-4" />Analyze Again</Link></Button>
              <Button asChild variant="outline" className="border-[#c2a67d] bg-white/50 text-[#6f593b] hover:bg-white"><Link to="/app/routine"><ArrowRight className="h-4 w-4" />Today's Routine</Link></Button>
            </div>
          </div>
          <div className="flex items-center gap-4 rounded-2xl border border-white/80 bg-white/65 p-5">
            <div className="flex h-24 w-24 shrink-0 items-center justify-center rounded-full border-[7px] border-[#c2a67d]/25 bg-white text-center">
              <div><p className="text-3xl font-semibold text-[#222]">{score ?? "--"}</p><p className="text-[10px] uppercase tracking-[0.14em] text-[#999]">/ 100</p></div>
            </div>
            <div><p className="text-sm font-semibold text-[#222]">Current skin score</p><p className="mt-1 text-xs leading-5 text-[#777]">{analysis ? "Based on your latest AI analysis" : "Complete a scan to personalize this score"}</p></div>
          </div>
        </div>
      </section>

      <section>
        <SectionHeading eyebrow="Health Overview" title="Know your skin at a glance" />
        <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
          <HealthMetric icon={Sparkles} label="Skin Score" value={score} trend={scoreDelta} progress={score} tone="gold" />
          <HealthMetric icon={Droplets} label="Hydration" value={latestPoint?.hydrationLevel} caption="Latest progress reading" tone="blue" />
          <HealthMetric icon={ShieldCheck} label="Oil Balance" value={null} caption={survey?.skinType ? `${survey.skinType} profile` : "Needs a fresh scan"} tone="sage" />
          <HealthMetric icon={Sparkles} label="Acne" value={latestPoint?.acneLevel} caption="Latest progress reading" tone="rose" />
        </div>
      </section>

      <div className="grid gap-6 xl:grid-cols-[1.05fr_0.95fr]">
        <section className="rounded-[24px] border border-[#e6e0d7] bg-white p-5 shadow-[0_12px_30px_rgba(70,55,39,0.05)] sm:p-6">
          <div className="flex items-start justify-between gap-4"><SectionHeading eyebrow="Daily care" title="Today's Routine" /><Link to="/app/routine" className="mt-1 inline-flex items-center text-sm font-semibold text-[#977b56]">View all<ChevronRight className="h-4 w-4" /></Link></div>
          <RoutineBlock title="Morning" icon={Sun} products={regimen?.morning ?? []} tracking={tracking} />
          <RoutineBlock title="Evening" icon={Moon} products={regimen?.evening ?? []} tracking={tracking} />
        </section>

        <section className="rounded-[24px] border border-[#e6e0d7] bg-[#fbfaf8] p-5 shadow-[0_12px_30px_rgba(70,55,39,0.05)] sm:p-6">
          <div className="flex items-start justify-between gap-4"><SectionHeading eyebrow="Personalized by AI" title="AI Recommendations" /><Link to="/app/recommendations" className="mt-1 inline-flex items-center text-sm font-semibold text-[#977b56]">Explore<ChevronRight className="h-4 w-4" /></Link></div>
          <div className="mt-5 space-y-3">
            {recommendationProducts.length ? recommendationProducts.map((product) => <RecommendationRow key={product.productId} product={product} />) : <EmptyInline title="No recommendations yet" description="Complete your skin profile and analysis to unlock personalized picks." to="/app/recommendations" />}
          </div>
        </section>
      </div>

      <section className="rounded-[24px] border border-[#e6e0d7] bg-white p-5 shadow-[0_12px_30px_rgba(70,55,39,0.05)] sm:p-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between"><SectionHeading eyebrow="Skin journey" title="Track your progress" /><div className="flex flex-wrap gap-1 rounded-xl bg-[#f7f4ef] p-1">{(Object.keys(metricLabels) as ProgressMetric[]).map((key) => <button key={key} type="button" onClick={() => setMetric(key)} className={`rounded-lg px-3 py-2 text-xs font-semibold transition ${metric === key ? "bg-white text-[#6f593b] shadow-sm" : "text-[#999] hover:text-[#555]"}`}>{metricLabels[key]}</button>)}</div></div>
        <div className="mt-6 h-[260px] w-full">{chartData.length > 1 ? <ResponsiveContainer width="100%" height="100%"><LineChart data={chartData} margin={{ top: 8, right: 8, left: -24, bottom: 0 }}><XAxis dataKey="label" axisLine={false} tickLine={false} tick={{ fill: "#999", fontSize: 11 }} /><YAxis domain={[0, 100]} axisLine={false} tickLine={false} tick={{ fill: "#aaa", fontSize: 11 }} /><Tooltip contentStyle={{ borderRadius: 12, border: "1px solid #e6e0d7", boxShadow: "0 8px 20px rgba(0,0,0,.08)" }} formatter={(value) => [`${value}/100`, metricLabels[metric]]} /><Line type="monotone" dataKey="value" stroke="#c2a67d" strokeWidth={3} dot={{ fill: "#c2a67d", r: 3, strokeWidth: 0 }} activeDot={{ r: 5 }} /></LineChart></ResponsiveContainer> : <div className="flex h-full items-center justify-center rounded-2xl bg-[#fbfaf8] text-center"><div><p className="text-sm font-semibold text-[#444]">Not enough data yet</p><p className="mt-1 text-sm text-[#999]">Complete another check-in to chart {metricLabels[metric].toLowerCase()} over time.</p></div></div>}</div>
      </section>

      <section className="rounded-[24px] border border-[#dcd3c5] bg-[#f4efe7] p-5 sm:p-7"><div className="flex items-start gap-3"><div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-white text-[#977b56]"><Sparkles className="h-5 w-5" /></div><div><SectionHeading eyebrow="Personalized guidance" title="AI Insights" /><div className="mt-4 grid gap-3 md:grid-cols-3">{insights.length ? insights.map((insight) => <div key={insight} className="rounded-xl border border-white/80 bg-white/65 p-4 text-sm leading-6 text-[#555]">{insight}</div>) : <p className="text-sm leading-6 text-[#777]">Complete your first analysis to receive personalized insights here.</p>}</div></div></div></section>
    </div>
  );
}

function SectionHeading({ eyebrow, title }: { eyebrow: string; title: string }) {
  return <div><p className="text-[10px] font-semibold uppercase tracking-[0.2em] text-[#b0926a]">{eyebrow}</p><h2 className="mt-1 text-xl font-semibold tracking-[-0.025em] text-[#222]">{title}</h2></div>;
}

function HealthMetric({ icon: Icon, label, value, trend, progress, caption, tone }: { icon: typeof Sparkles; label: string; value?: number | null; trend?: number | null; progress?: number | null; caption?: string; tone: "gold" | "blue" | "sage" | "rose" }) {
  const toneClass = { gold: "bg-[#fbf6ed] text-[#9a7b4e]", blue: "bg-[#eef6f5] text-[#638d8a]", sage: "bg-[#f0f5ef] text-[#718c70]", rose: "bg-[#fbf0ed] text-[#b27d70]" }[tone];
  return <div className="rounded-[20px] border border-[#e6e0d7] bg-white p-4"><div className="flex items-center justify-between"><span className={`flex h-9 w-9 items-center justify-center rounded-xl ${toneClass}`}><Icon className="h-4 w-4" /></span>{trend !== null && trend !== undefined ? <span className={`inline-flex items-center gap-1 text-xs font-semibold ${trend >= 0 ? "text-[#6f9b73]" : "text-[#b27d70]"}`}>{trend >= 0 ? <TrendingUp className="h-3.5 w-3.5" /> : <TrendingDown className="h-3.5 w-3.5" />}{trend >= 0 ? "+" : ""}{trend}%</span> : null}</div><p className="mt-4 text-sm text-[#777]">{label}</p><p className="mt-1 text-3xl font-semibold tracking-[-0.04em] text-[#222]">{value !== null && value !== undefined ? formatMetric(value) : "--"}<span className="ml-1 text-sm font-normal text-[#aaa]">{value !== null && value !== undefined ? "/100" : ""}</span></p>{progress !== null && progress !== undefined ? <div className="mt-3 h-1.5 overflow-hidden rounded-full bg-[#eee9e1]"><div className="h-full rounded-full bg-[#c2a67d]" style={{ width: `${Math.max(0, Math.min(100, progress))}%` }} /></div> : <p className="mt-3 text-xs text-[#aaa]">{caption || "No data available"}</p>}</div>;
}

function RoutineBlock({ title, icon: Icon, products, tracking }: { title: string; icon: typeof Sun; products: RegimenProduct[]; tracking: RoutineTrackingToday | null }) {
  return <div className="mt-6"><div className="flex items-center gap-2 text-sm font-semibold text-[#444]"><Icon className="h-4 w-4 text-[#b0926a]" />{title}<span className="ml-auto text-xs font-normal text-[#aaa]">{products.length} steps</span></div><div className="mt-3 space-y-2">{products.length ? products.map((product) => { const done = tracking?.steps.some((step) => step.productId === product.productId && step.status.toLowerCase() === "completed"); return <div key={product.stepId} className="flex items-center gap-3 rounded-xl border border-[#eee9e1] px-3 py-2.5"><span className={`flex h-6 w-6 items-center justify-center rounded-full border ${done ? "border-[#7bae7f] bg-[#7bae7f] text-white" : "border-[#d9d1c5] text-transparent"}`}><Check className="h-3.5 w-3.5" /></span><div className="min-w-0 flex-1"><p className="truncate text-sm font-medium text-[#333]">{product.name}</p><p className="truncate text-xs text-[#999]">{product.brand || product.category}</p></div>{done ? <span className="text-[10px] font-semibold uppercase tracking-[0.12em] text-[#7bae7f]">Done</span> : null}</div>; }) : <p className="rounded-xl bg-[#fbfaf8] px-3 py-4 text-sm text-[#999]">No {title.toLowerCase()} routine set yet.</p>}</div></div>;
}

function RecommendationRow({ product }: { product: SavedRecommendationProduct }) {
  const match = product.matchPercent ?? product.matchScore;
  return <div className="flex gap-3 rounded-xl border border-[#e8e1d7] bg-white p-3"><div className="h-16 w-16 shrink-0 overflow-hidden rounded-lg bg-[#f3eee7]">{product.imageUrl ? <img src={product.imageUrl} alt={product.name} className="h-full w-full object-cover" /> : <div className="flex h-full items-center justify-center text-[#c2a67d]"><Sparkles className="h-5 w-5" /></div>}</div><div className="min-w-0 flex-1"><div className="flex items-start justify-between gap-2"><div className="min-w-0"><p className="truncate text-sm font-semibold text-[#333]">{product.name}</p><p className="text-xs text-[#999]">{product.brand || product.category}</p></div>{match !== null && match !== undefined ? <span className="shrink-0 text-xs font-semibold text-[#7bae7f]">{Math.round(match)}% match</span> : null}</div><p className="mt-2 line-clamp-2 text-xs leading-5 text-[#777]">{product.aiReason || product.whyRecommended || "Selected for your current skin profile."}</p><Link to={`/app/products/${product.productId}`} className="mt-1 inline-flex items-center text-xs font-semibold text-[#977b56]">View product<ArrowRight className="ml-1 h-3 w-3" /></Link></div></div>;
}

function EmptyInline({ title, description, to }: { title: string; description: string; to: string }) { return <div className="rounded-xl border border-dashed border-[#d9d1c5] px-4 py-8 text-center"><p className="text-sm font-semibold text-[#444]">{title}</p><p className="mx-auto mt-1 max-w-xs text-sm leading-5 text-[#999]">{description}</p><Link to={to} className="mt-4 inline-flex items-center text-sm font-semibold text-[#977b56]">Get started<ArrowRight className="ml-1 h-4 w-4" /></Link></div>; }

function formatMetric(value: number) { return Math.round(value); }
