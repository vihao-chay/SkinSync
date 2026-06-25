import { ArrowRight, Camera, ClipboardCheck, MessageSquareText, Sparkles } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router";
import { AppEmptyState } from "../../components/AppEmptyState";
import { AppGuidanceCard } from "../../components/AppGuidanceCard";
import { AppNextSteps } from "../../components/AppNextSteps";
import { AppPageHeader } from "../../components/AppPageHeader";
import { AppProductCard } from "../../components/AppProductCard";
import { AppSection } from "../../components/AppSection";
import { AppStatCard } from "../../components/AppStatCard";
import { Button } from "../../components/ui/button";
import { ErrorState } from "../../components/ErrorState";
import { LoadingState } from "../../components/LoadingState";
import { useAuth } from "../../contexts/AuthContext";
import { getLatestAnalysisApi, type AnalysisDetail } from "../../services/analysisService";
import { getProductsApi, type ProductDetail } from "../../services/productService";
import { getCurrentRegimenApi, type CurrentRegimenResponse } from "../../services/regimenService";
import { getTodayRoutineTrackingApi, type RoutineTrackingToday } from "../../services/routineTrackingService";
import { getSkinProgressOverviewApi, type SkinProgressOverview } from "../../services/skinProgressService";
import { getCurrentSubscriptionApi, type CurrentSubscription } from "../../services/subscriptionService";
import { getSurveyApi, type SurveyResponse } from "../../services/surveyService";
import { firstName, formatDate } from "../../utils/appFormat";

export function AppDashboardPage() {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [survey, setSurvey] = useState<SurveyResponse | null>(null);
  const [analysis, setAnalysis] = useState<AnalysisDetail | null>(null);
  const [regimen, setRegimen] = useState<CurrentRegimenResponse | null>(null);
  const [tracking, setTracking] = useState<RoutineTrackingToday | null>(null);
  const [progress, setProgress] = useState<SkinProgressOverview | null>(null);
  const [subscription, setSubscription] = useState<CurrentSubscription | null>(null);
  const [products, setProducts] = useState<ProductDetail[]>([]);

  useEffect(() => {
    let active = true;
    async function load() {
      const [surveyResult, analysisResult, regimenResult, trackingResult, progressResult, subscriptionResult, productsResult] =
        await Promise.all([
          getSurveyApi(),
          getLatestAnalysisApi(),
          getCurrentRegimenApi(),
          getTodayRoutineTrackingApi(),
          getSkinProgressOverviewApi(),
          getCurrentSubscriptionApi(),
          getProductsApi(),
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
      setSubscription(subscriptionResult.content ?? null);
      setProducts((productsResult.content ?? []).filter((item) => item.status?.toLowerCase() === "active").slice(0, 3));
      setLoading(false);
    }

    void load();
    return () => {
      active = false;
    };
  }, []);

  const nextStep = useMemo(() => {
    if (!survey) {
      return {
        status: "Complete your skin profile to unlock more relevant care guidance.",
        primary: { label: "Complete profile", to: "/app/skin-profile" },
        secondary: { label: "Ask AI assistant", to: "/app/chat" },
      };
    }
    if (!analysis) {
      return {
        status: "Upload your first skin photo to generate a backend-backed analysis.",
        primary: { label: "Analyze skin", to: "/app/analysis" },
        secondary: { label: "Open skin profile", to: "/app/skin-profile" },
      };
    }
    if (!regimen || !tracking) {
      return {
        status: "Review your routine plan and make today easier to follow.",
        primary: { label: "Open routine", to: "/app/routine" },
        secondary: { label: "Daily check-up", to: "/app/check-up" },
      };
    }
    return {
      status: `You have ${tracking.totalSteps} routine steps scheduled today.`,
      primary: { label: "Daily check-up", to: "/app/check-up" },
      secondary: { label: "View progress", to: "/app/progress" },
    };
  }, [survey, analysis, regimen, tracking]);

  if (loading) {
    return <LoadingState label="Loading your skin care overview..." />;
  }

  if (error) {
    return <ErrorState message={error} />;
  }

  return (
    <div className="space-y-6">
      <AppPageHeader
        eyebrow="Today"
        title={`Welcome back, ${firstName(user?.fullName)}`}
        description={nextStep.status}
        actions={
          <>
            <Button asChild className="bg-primary text-primary-foreground hover:bg-primary/90">
              <Link to={nextStep.primary.to}>{nextStep.primary.label}</Link>
            </Button>
            <Button asChild variant="outline" className="border-border bg-card hover:bg-muted">
              <Link to={nextStep.secondary.to}>{nextStep.secondary.label}</Link>
            </Button>
          </>
        }
      />

      <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <AppStatCard label="Skin type" value={survey?.skinType || "Not set"} helper="Saved from your profile" />
        <AppStatCard
          label="Latest analysis"
          value={analysis?.overallScore ? `${analysis.overallScore}/100` : analysis ? "Available" : "Not started"}
          helper={analysis ? `Updated ${formatDate(analysis.createdAt)}` : "Upload a clear skin photo"}
        />
        <AppStatCard
          label="Routine today"
          value={tracking ? `${tracking.completedSteps}/${tracking.totalSteps}` : "No routine"}
          helper="Completed steps / total steps"
        />
        <AppStatCard
          label="Progress streak"
          value={progress ? `${progress.currentStreak} days` : "No data"}
          helper={progress ? `${progress.totalEntries} progress entries recorded` : "Start tracking changes"}
        />
        <AppStatCard
          label="Current plan"
          value={subscription?.plan?.name || "Unavailable"}
          helper={subscription?.subscription?.status || "No subscription data"}
        />
      </div>

      <div className="grid gap-4 xl:grid-cols-[1.2fr_0.8fr]">
        <AppSection
          title="Next steps"
          description="A quick checklist of what is already done and what will unlock more value next."
        >
          <AppNextSteps
            items={[
              { label: "Skin profile completed", done: Boolean(survey), ctaLabel: "Complete profile", ctaTo: "/app/skin-profile" },
              { label: "Skin analysis completed", done: Boolean(analysis), ctaLabel: "Analyze skin", ctaTo: "/app/analysis" },
              { label: "Routine available", done: Boolean(regimen), ctaLabel: "Open routine", ctaTo: "/app/routine" },
              { label: "Daily check-up saved today", done: Boolean(tracking?.morningCompleted || tracking?.eveningCompleted), ctaLabel: "Daily check-up", ctaTo: "/app/check-up" },
              { label: "Progress photo uploaded", done: Boolean(progress?.totalEntries), ctaLabel: "Upload progress", ctaTo: "/app/progress" },
            ]}
          />
        </AppSection>

        <AppGuidanceCard
          title="Today panel"
          description="Use SkinSync like a real care flow: keep your profile complete, review analysis, follow the daily routine, and log how your skin feels."
        >
          <div className="flex flex-wrap gap-3">
            <Button asChild variant="outline" className="border-border bg-card hover:bg-background">
              <Link to="/app/chat">
                <MessageSquareText className="mr-2 h-4 w-4" />
                Ask AI assistant
              </Link>
            </Button>
            <Button asChild variant="outline" className="border-border bg-card hover:bg-background">
              <Link to="/app/progress">
                <Camera className="mr-2 h-4 w-4" />
                Upload progress photo
              </Link>
            </Button>
          </div>
        </AppGuidanceCard>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <AppSection
          title="Today routine preview"
          description="A quick look at where your morning and evening plan stands."
          action={
            <Button asChild variant="ghost" className="px-0 text-primary hover:bg-transparent hover:text-primary/80">
              <Link to="/app/routine">
                Open routine
                <ArrowRight className="ml-1 h-4 w-4" />
              </Link>
            </Button>
          }
        >
          {regimen && tracking ? (
            <div className="grid gap-3 sm:grid-cols-2">
              <InfoTile label="Routine name" value={regimen.name} />
              <InfoTile label="Completion today" value={`${tracking.completedSteps}/${tracking.totalSteps} steps`} />
              <InfoTile label="Morning" value={tracking.morningCompleted ? "Completed" : "Still in progress"} />
              <InfoTile label="Evening" value={tracking.eveningCompleted ? "Completed" : "Still in progress"} />
            </div>
          ) : (
            <AppEmptyState
              title="No routine available yet"
              description="Complete your profile, run an analysis, and open the routine page to review the plan generated from backend data."
              action={
                <Button asChild className="bg-primary text-primary-foreground hover:bg-primary/90">
                  <Link to="/app/routine">Go to routine</Link>
                </Button>
              }
            />
          )}
        </AppSection>

        <AppSection
          title="Latest analysis preview"
          description="Your most recent backend analysis result and what to do with it next."
          action={
            <Button asChild variant="ghost" className="px-0 text-primary hover:bg-transparent hover:text-primary/80">
              <Link to="/app/analysis">
                {analysis ? "View analysis" : "Upload photo"}
                <ArrowRight className="ml-1 h-4 w-4" />
              </Link>
            </Button>
          }
        >
          {analysis ? (
            <div className="grid gap-3">
              <InfoTile label="Date" value={formatDate(analysis.createdAt)} />
              <InfoTile label="Skin type" value={analysis.skinType || "Unavailable"} />
              <InfoTile
                label="Main concerns"
                value={analysis.issues?.length ? analysis.issues.map((issue) => issue.issueType).join(", ") : "No concerns returned"}
              />
              <InfoTile label="Summary" value={analysis.overview || analysis.rootCauses || "No summary available"} />
            </div>
          ) : (
            <AppEmptyState
              title="No skin analysis yet"
              description="Upload a clear skin photo to generate your first backend-backed analysis."
              icon={Sparkles}
              action={
                <Button asChild className="bg-primary text-primary-foreground hover:bg-primary/90">
                  <Link to="/app/analysis">Upload photo</Link>
                </Button>
              }
            />
          )}
        </AppSection>
      </div>

      <div className="grid gap-4 lg:grid-cols-2">
        <AppSection
          title="Progress snapshot"
          description="See whether your routine is turning into consistent tracking data."
          action={
            <Button asChild variant="ghost" className="px-0 text-primary hover:bg-transparent hover:text-primary/80">
              <Link to="/app/progress">
                View progress
                <ArrowRight className="ml-1 h-4 w-4" />
              </Link>
            </Button>
          }
        >
          {progress ? (
            <div className="grid gap-3 sm:grid-cols-2">
              <InfoTile label="Total photos" value={`${progress.totalEntries}`} />
              <InfoTile label="Current streak" value={`${progress.currentStreak} days`} />
              <InfoTile label="Latest score" value={progress.latestScore ? `${progress.latestScore}/100` : "Unavailable"} />
              <InfoTile label="Timeline insight" value={progress.trendSummary || "No trend summary available"} />
            </div>
          ) : (
            <AppEmptyState
              title="No progress entries yet"
              description="Upload your first progress photo so SkinSync can begin building a timeline of changes."
              icon={Camera}
              action={
                <Button asChild className="bg-primary text-primary-foreground hover:bg-primary/90">
                  <Link to="/app/progress">Upload progress photo</Link>
                </Button>
              }
            />
          )}
        </AppSection>

        <AppSection
          title="Product catalog preview"
          description="Real products from the backend catalog. These are not labeled as personalized unless recommendation data exists."
          action={
            <Button asChild variant="ghost" className="px-0 text-primary hover:bg-transparent hover:text-primary/80">
              <Link to="/app/products">
                Browse products
                <ArrowRight className="ml-1 h-4 w-4" />
              </Link>
            </Button>
          }
        >
          {products.length ? (
            <div className="grid gap-3 sm:grid-cols-3">
              {products.map((product) => (
                <AppProductCard key={product.id} product={product} compact />
              ))}
            </div>
          ) : (
            <AppEmptyState
              title="Catalog unavailable right now"
              description="The product catalog is currently empty or could not be loaded from the backend."
              action={
                <Button asChild className="bg-primary text-primary-foreground hover:bg-primary/90">
                  <Link to="/app/products">Open products</Link>
                </Button>
              }
            />
          )}
        </AppSection>
      </div>

      <AppSection
        title="Subscription snapshot"
        description="See plan status and quota usage without leaving the dashboard."
        action={
          <Button asChild variant="ghost" className="px-0 text-primary hover:bg-transparent hover:text-primary/80">
            <Link to="/app/subscription">
              Manage subscription
              <ArrowRight className="ml-1 h-4 w-4" />
            </Link>
          </Button>
        }
      >
        {subscription ? (
          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-4">
            <InfoTile label="Plan" value={subscription.plan.name} />
            <InfoTile label="Status" value={subscription.subscription.status} />
            <InfoTile label="Renewal" value={formatDate(subscription.subscription.currentPeriodEnd)} />
            <InfoTile
              label="Quota preview"
              value={
                subscription.usage?.length
                  ? subscription.usage
                      .slice(0, 2)
                      .map((item) => `${item.displayName}: ${item.isUnlimited ? "Unlimited" : `${item.used}/${item.limit ?? "-"}`}`)
                      .join(" · ")
                  : "Usage unavailable"
              }
            />
          </div>
        ) : (
          <AppEmptyState
            title="Subscription data unavailable"
            description="You can still open the subscription page to retry or review feature access states."
            action={
              <Button asChild className="bg-primary text-primary-foreground hover:bg-primary/90">
                <Link to="/app/subscription">Open subscription</Link>
              </Button>
            }
          />
        )}
      </AppSection>
    </div>
  );
}

function InfoTile({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-border/60 bg-muted/70 px-4 py-3">
      <p className="text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground">{label}</p>
      <p className="mt-1 text-sm leading-6 text-foreground">{value}</p>
    </div>
  );
}
