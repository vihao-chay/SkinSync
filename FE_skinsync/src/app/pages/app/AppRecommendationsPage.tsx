import { AlertTriangle, ArrowRight, CheckCircle2, Sparkles } from "lucide-react";
import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router";
import { AppEmptyState } from "../../components/AppEmptyState";
import { AppPageHeader } from "../../components/AppPageHeader";
import { AppProductVisual } from "../../components/AppProductCard";
import { AppSection } from "../../components/AppSection";
import { Button } from "../../components/ui/button";
import { ErrorState } from "../../components/ErrorState";
import { LoadingState } from "../../components/LoadingState";
import { getSurveyApi, type SurveyResponse } from "../../services/surveyService";
import {
  generateRecommendationsApi,
  type RecommendationProduct,
  type RecommendationRequest,
  type RecommendationResponse,
} from "../../services/recommendationService";

export function AppRecommendationsPage() {
  const [loading, setLoading] = useState(true);
  const [generating, setGenerating] = useState(false);
  const [error, setError] = useState("");
  const [profile, setProfile] = useState<SurveyResponse | null>(null);
  const [recommendation, setRecommendation] = useState<RecommendationResponse | null>(null);

  const generate = useCallback(async (survey?: SurveyResponse | null) => {
    setGenerating(true);
    setError("");

    try {
      const currentProfile = survey ?? profile ?? (await getSurveyApi()).content;
      if (!currentProfile?.skinTypeValue && !currentProfile?.skinType) {
        setError("Complete your skin profile before generating personalized recommendations.");
        return;
      }

      setProfile(currentProfile);
      const request: RecommendationRequest = {
        skinType: currentProfile.skinTypeValue || currentProfile.skinType,
        concerns: currentProfile.skinConcernValues.length
          ? currentProfile.skinConcernValues
          : currentProfile.skinConcerns,
        sensitivity: "Medium",
        goals: [],
      };
      const result = await generateRecommendationsApi(request);
      if (!result.success || !result.content) {
        setError(result.message || "Recommendations could not be generated right now.");
        return;
      }

      setRecommendation(result.content);
    } catch {
      setError("Recommendations could not be generated right now. Please try again.");
    } finally {
      setGenerating(false);
      setLoading(false);
    }
  }, [profile]);

  useEffect(() => {
    let active = true;
    async function load() {
      try {
        const result = await getSurveyApi();
        if (!active) return;
        setProfile(result.content);
        await generate(result.content);
      } catch {
        if (active) {
          setError("Your skin profile could not be loaded. Please try again.");
          setLoading(false);
        }
      }
    }

    void load();
    return () => {
      active = false;
    };
  }, []);

  if (loading && !recommendation) {
    return <LoadingState label="Building recommendations from your skin profile..." />;
  }

  const hasProducts = Boolean(
    recommendation &&
      (recommendation.morningRoutine.length || recommendation.nightRoutine.length || recommendation.alternatives.length),
  );

  return (
    <div className="space-y-6">
      <AppPageHeader
        eyebrow="AI tools"
        title="AI Recommendations"
        description="Personalized for your skin, your goals, and the routine you can actually keep."
        actions={
          <Button onClick={() => void generate()} disabled={generating} className="gap-2">
            <Sparkles className="h-4 w-4" />
            {generating ? "Generating..." : recommendation ? "Generate new" : "Generate recommendations"}
          </Button>
        }
      />

      {error && !recommendation ? (
        <ErrorState
          title="Recommendations unavailable"
          message={error}
          action={
            <Button variant="outline" onClick={() => void generate()} disabled={generating}>
              Try again
            </Button>
          }
        />
      ) : null}

      {recommendation && hasProducts ? (
        <>
          <RecommendationSummary recommendation={recommendation} profile={profile} />
          {recommendation.warnings.length ? <Warnings warnings={recommendation.warnings} /> : null}
          <RoutineSection title="Morning routine" description="Start with these steps in the suggested order." products={recommendation.morningRoutine} />
          <RoutineSection title="Night routine" description="Use these evening steps as your skin allows." products={recommendation.nightRoutine} />
          <AlternativesSection recommendation={recommendation} />
        </>
      ) : !error ? (
        <AppEmptyState
          title="No compatible products yet"
          description="Complete your skin profile and keep an active product catalog so SkinSync can build a personalized routine."
          action={
            <Button asChild variant="outline">
              <Link to="/app/skin-profile">Review skin profile</Link>
            </Button>
          }
        />
      ) : null}
    </div>
  );
}

function RecommendationSummary({
  recommendation,
  profile,
}: {
  recommendation: RecommendationResponse;
  profile: SurveyResponse | null;
}) {
  return (
    <AppSection
      title="Your recommendation snapshot"
      description="The score reflects catalog compatibility, skin type, concerns, ingredients, and routine timing."
      tone="highlight"
      action={
        <span className="inline-flex items-center gap-2 rounded-full bg-card px-3 py-2 text-sm font-medium text-foreground shadow-sm">
          <CheckCircle2 className="h-4 w-4 text-primary" />
          {recommendation.overallCompatibilityScore}% match
        </span>
      }
    >
      <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <SummaryItem label="Skin type" value={recommendation.skinSummary.skinType || profile?.skinType || "Not set"} />
        <SummaryItem label="Sensitivity" value={recommendation.skinSummary.sensitivity || "Medium"} />
        <SummaryItem label="Concerns" value={recommendation.skinSummary.concerns.join(", ") || "Not set"} />
        <SummaryItem label="Generated" value={formatDate(recommendation.generatedAt)} />
      </div>
      {recommendation.ingredientHighlights.length ? (
        <div className="mt-4 flex flex-wrap gap-2">
          {recommendation.ingredientHighlights.slice(0, 8).map((item) => (
            <span key={item.ingredient} className="app-pill">
              {item.ingredient}
            </span>
          ))}
        </div>
      ) : null}
    </AppSection>
  );
}

function SummaryItem({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl border border-border/60 bg-card/70 px-4 py-3">
      <p className="text-xs font-medium uppercase tracking-[0.16em] text-muted-foreground">{label}</p>
      <p className="mt-1 text-sm font-medium leading-6 text-foreground">{value}</p>
    </div>
  );
}

function RoutineSection({ title, description, products }: { title: string; description: string; products: RecommendationProduct[] }) {
  if (!products.length) return null;

  return (
    <AppSection title={title} description={description}>
      <div className="grid gap-4 lg:grid-cols-2">
        {products.map((product) => <RecommendationCard key={`${title}-${product.productId}`} product={product} />)}
      </div>
    </AppSection>
  );
}

function AlternativesSection({ recommendation }: { recommendation: RecommendationResponse }) {
  const categories = recommendation.alternatives.filter((category) => category.products.length);
  if (!categories.length) return null;

  return (
    <AppSection title="Alternatives" description="Other catalog products that fit the same routine slots." tone="muted">
      <div className="space-y-6">
        {categories.map((category) => (
          <div key={category.categoryKey} className="space-y-3">
            <div className="flex flex-wrap items-center justify-between gap-2">
              <h3 className="text-lg font-medium text-foreground">{category.categoryName}</h3>
              <span className="app-pill">{category.routineTime}</span>
            </div>
            <div className="grid gap-4 lg:grid-cols-2">
              {category.products.map((product) => <RecommendationCard key={`${category.categoryKey}-${product.productId}`} product={product} compact />)}
            </div>
          </div>
        ))}
      </div>
    </AppSection>
  );
}

function RecommendationCard({ product, compact = false }: { product: RecommendationProduct; compact?: boolean }) {
  return (
    <article className="grid gap-4 rounded-[26px] border border-border/70 bg-card/75 p-4 shadow-sm sm:grid-cols-[150px_1fr]">
      <AppProductVisual
        product={{
          id: product.productId,
          name: product.name,
          brand: product.brand,
          category: product.category,
          price: product.price ?? 0,
          currency: product.currency,
          status: "active",
          suitableSkinTypes: [],
          skinConcerns: [],
          imageUrl: product.imageUrl,
          createdAt: "",
          updatedAt: null,
        }}
      />
      <div className="min-w-0 space-y-3">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <p className="truncate text-base font-medium text-foreground">{product.name}</p>
            <p className="text-sm text-muted-foreground">{product.brand || "Brand unavailable"} · {product.category}</p>
          </div>
          <span className="shrink-0 rounded-full bg-secondary px-3 py-1 text-sm font-medium text-secondary-foreground">{product.score}%</span>
        </div>
        <p className={compact ? "line-clamp-2 text-sm leading-6 text-muted-foreground" : "text-sm leading-6 text-muted-foreground"}>
          {product.reason || product.reasons.join(" ") || "Matched to your current skin profile."}
        </p>
        {product.keyIngredients.length ? (
          <div className="flex flex-wrap gap-2">
            {product.keyIngredients.slice(0, 4).map((ingredient) => <span key={ingredient} className="app-pill">{ingredient}</span>)}
          </div>
        ) : null}
        {product.cautions.length ? (
          <p className="flex items-start gap-2 text-xs leading-5 text-[var(--ss-danger)]">
            <AlertTriangle className="mt-0.5 h-3.5 w-3.5 shrink-0" />
            {product.cautions.join(" ")}
          </p>
        ) : null}
        <div className="flex flex-wrap items-center justify-between gap-3">
          <p className="font-medium text-foreground">{formatPrice(product.price, product.currency)}</p>
          <Button asChild variant="outline" size="sm">
            <Link to={`/app/products/${product.productId}`}>View details <ArrowRight className="h-3.5 w-3.5" /></Link>
          </Button>
        </div>
      </div>
    </article>
  );
}

function Warnings({ warnings }: { warnings: string[] }) {
  return (
    <div className="rounded-[26px] border border-amber-200 bg-amber-50/80 p-5 text-amber-950">
      <div className="flex items-start gap-3">
        <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0" />
        <div className="space-y-1">
          <p className="font-medium">Compatibility notes</p>
          {warnings.map((warning) => <p key={warning} className="text-sm leading-6">{warning}</p>)}
        </div>
      </div>
    </div>
  );
}

function formatPrice(price?: number | null, currency?: string) {
  if (price == null) return "Price unavailable";
  return `${new Intl.NumberFormat("en-US", { maximumFractionDigits: 0 }).format(price)} ${currency || ""}`.trim();
}

function formatDate(value?: string | null) {
  if (!value) return "Just now";
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? "Just now" : date.toLocaleDateString(undefined, { month: "short", day: "numeric", year: "numeric" });
}
