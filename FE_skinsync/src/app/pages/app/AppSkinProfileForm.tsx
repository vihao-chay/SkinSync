import { CheckCircle2, PencilLine, RotateCcw, Sparkles } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router";
import { AppField } from "../../components/AppField";
import { AppGuidanceCard } from "../../components/AppGuidanceCard";
import { AppPageHeader } from "../../components/AppPageHeader";
import { AppSection } from "../../components/AppSection";
import { SelectableChip } from "../../components/SelectableChip";
import { Button } from "../../components/ui/button";
import { LoadingState } from "../../components/LoadingState";
import { getSurveyApi, saveSurveyApi, type SurveyResponse } from "../../services/surveyService";

const SKIN_TYPES = [
  { value: "normal", label: "Normal" },
  { value: "dry", label: "Dry" },
  { value: "oily", label: "Oily" },
  { value: "combination", label: "Combination" },
  { value: "sensitive", label: "Sensitive" },
] as const;

const DEFAULT_SKIN_CONCERNS = [
  { value: "acne", label: "Acne" },
  { value: "redness", label: "Redness" },
  { value: "pigmentation", label: "Dark spots" },
  { value: "pores", label: "Enlarged pores" },
  { value: "dull", label: "Dullness" },
  { value: "dry_patches", label: "Dry patches" },
  { value: "aging", label: "Fine lines" },
  { value: "wrinkles", label: "Wrinkles" },
  { value: "scars", label: "Scars" },
] as const;

const BUDGET_OPTIONS = [
  { value: "low", label: "Budget-friendly" },
  { value: "mid", label: "Mid-range" },
  { value: "high", label: "Premium" },
  { value: "none", label: "No preference" },
] as const;

type ProfileFormState = {
  skinType: string;
  concerns: string[];
  monthlyBudget: string;
  age: string;
};

function makeEmptyForm(): ProfileFormState {
  return {
    skinType: "",
    concerns: [],
    monthlyBudget: "",
    age: "",
  };
}

function createFormState(profile?: SurveyResponse | null): ProfileFormState {
  return {
    skinType: profile?.skinTypeValue ?? "",
    concerns: profile?.skinConcernValues ? [...profile.skinConcernValues] : [],
    monthlyBudget: profile?.budgetLevel ?? "",
    age: profile?.age ? String(profile.age) : "",
  };
}

function prettifyUnknownValue(value: string): string {
  return value.replace(/_/g, " ").replace(/\b\w/g, (char) => char.toUpperCase());
}

export function AppSkinProfileForm({
  title,
  description,
  redirectTo,
  saveBehavior = "stay",
}: {
  title: string;
  description: string;
  redirectTo?: string;
  saveBehavior?: "stay" | "redirect";
}) {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [feedback, setFeedback] = useState("");
  const [errors, setErrors] = useState<{ skinType?: string; concerns?: string; age?: string }>({});
  const [profile, setProfile] = useState<SurveyResponse | null>(null);
  const [initialForm, setInitialForm] = useState<ProfileFormState>(makeEmptyForm);
  const [form, setForm] = useState<ProfileFormState>(makeEmptyForm);
  const [isEditing, setIsEditing] = useState(saveBehavior === "redirect");

  useEffect(() => {
    let active = true;
    void getSurveyApi().then((result) => {
      if (!active) return;

      if (result.success && result.content) {
        const nextForm = createFormState(result.content);
        setProfile(result.content);
        setInitialForm(nextForm);
        setForm(nextForm);
        setIsEditing(saveBehavior === "redirect" ? true : false);
      } else {
        setIsEditing(true);
      }

      setLoading(false);
    });

    return () => {
      active = false;
    };
  }, [saveBehavior]);

  const hasChanges = useMemo(
    () =>
      JSON.stringify({
        ...form,
        concerns: [...form.concerns].sort(),
      }) !==
      JSON.stringify({
        ...initialForm,
        concerns: [...initialForm.concerns].sort(),
      }),
    [form, initialForm],
  );

  const concernOptions = useMemo(() => {
    const extras = form.concerns
      .filter((value) => !DEFAULT_SKIN_CONCERNS.some((option) => option.value === value))
      .map((value) => ({ value, label: prettifyUnknownValue(value) }));

    return [...DEFAULT_SKIN_CONCERNS, ...extras];
  }, [form.concerns]);

  if (loading) {
    return <LoadingState label="Loading your skin profile..." />;
  }

  function toggleConcern(concern: string) {
    setForm((prev) => ({
      ...prev,
      concerns: prev.concerns.includes(concern)
        ? prev.concerns.filter((item) => item !== concern)
        : [...prev.concerns, concern],
    }));
  }

  function validate() {
    const nextErrors: { skinType?: string; concerns?: string; age?: string } = {};
    if (!form.skinType) {
      nextErrors.skinType = "Please select your skin type.";
    }
    if (!form.concerns.length) {
      nextErrors.concerns = "Select at least one skin concern.";
    }
    if (form.age) {
      const age = Number(form.age);
      if (Number.isNaN(age) || age < 13 || age > 100) {
        nextErrors.age = "Age must be between 13 and 100.";
      }
    }
    setErrors(nextErrors);
    return Object.keys(nextErrors).length === 0;
  }

  return (
    <div className="space-y-6">
      <AppPageHeader title={title} description={description} eyebrow="PROFILE SETUP" />

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_380px]">
        {profile && !isEditing ? (
          <AppSection
            title="Current profile"
            description="This is the profile SkinSync is currently using for analysis, routine logic, and product context."
            tone="highlight"
          >
            <div className="grid gap-4 md:grid-cols-2">
              <ProfileInfoCard label="Skin type" value={profile.skinType || "Not set yet"} />
              <ProfileInfoCard label="Monthly budget" value={profile.monthlyBudget || "Not set yet"} />
              <ProfileInfoCard label="Age" value={profile.age ? `${profile.age}` : "Not set yet"} />
              <ProfileInfoCard
                label="Concerns"
                value={profile.skinConcerns.length ? profile.skinConcerns.join(", ") : "Not set yet"}
                className="md:col-span-2"
              />
            </div>

            <div className="flex flex-wrap gap-3 border-t border-border/70 pt-6">
              <Button
                variant="premium"
                onClick={() => {
                  setFeedback("");
                  setErrors({});
                  setForm(initialForm);
                  setIsEditing(true);
                }}
              >
                <PencilLine className="h-4 w-4" />
                Edit profile
              </Button>
              <Button asChild variant="ghost">
                <Link to="/app/dashboard">Back to dashboard</Link>
              </Button>
            </div>
            {feedback ? <p className="text-sm text-muted-foreground">{feedback}</p> : null}
          </AppSection>
        ) : (
          <AppSection
            title={profile ? "Edit profile" : "Profile details"}
            description="Choose the options that best describe your skin so analysis, routine, and product suggestions stay aligned."
            tone="highlight"
            contentClassName="pt-0"
          >
            <div className="grid gap-6 pt-6">
              <div className="grid gap-3">
                <AppField label="Skin type" hint="Select the single skin type that best fits your current skin.">
                  <div className="flex flex-wrap gap-3">
                    {SKIN_TYPES.map((skinType) => (
                      <SelectableChip
                        key={skinType.value}
                        label={skinType.label}
                        selected={form.skinType === skinType.value}
                        onClick={() => {
                          setErrors((prev) => ({ ...prev, skinType: undefined }));
                          setForm((prev) => ({ ...prev, skinType: skinType.value }));
                        }}
                      />
                    ))}
                  </div>
                </AppField>
                {errors.skinType ? <FieldError message={errors.skinType} /> : null}
              </div>

              <div className="grid gap-3">
                <div className="flex items-center justify-between gap-3">
                  <AppField label="Skin concerns" hint="Select all concerns that apply to your skin.">
                    <div />
                  </AppField>
                  <div className="flex items-center gap-3">
                    <span className="text-xs text-muted-foreground">{form.concerns.length} selected</span>
                    {form.concerns.length ? (
                      <button
                        type="button"
                        className="text-xs font-medium text-primary hover:text-[var(--ss-gold-hover)]"
                        onClick={() => {
                          setErrors((prev) => ({ ...prev, concerns: undefined }));
                          setForm((prev) => ({ ...prev, concerns: [] }));
                        }}
                      >
                        Clear
                      </button>
                    ) : null}
                  </div>
                </div>
                <div className="flex flex-wrap gap-3">
                  {concernOptions.map((concern) => (
                    <SelectableChip
                      key={concern.value}
                      label={concern.label}
                      selected={form.concerns.includes(concern.value)}
                      onClick={() => {
                        setErrors((prev) => ({ ...prev, concerns: undefined }));
                        toggleConcern(concern.value);
                      }}
                    />
                  ))}
                </div>
                {errors.concerns ? <FieldError message={errors.concerns} /> : null}
              </div>

              <div className="grid gap-6 md:grid-cols-2">
                <div className="grid gap-3">
                  <AppField label="Monthly budget" hint="Choose the budget range you usually prefer for skincare.">
                    <div className="flex flex-wrap gap-3">
                      {BUDGET_OPTIONS.map((budget) => (
                        <SelectableChip
                          key={budget.value}
                          label={budget.label}
                          selected={form.monthlyBudget === budget.value}
                          onClick={() => setForm((prev) => ({ ...prev, monthlyBudget: budget.value }))}
                        />
                      ))}
                    </div>
                  </AppField>
                </div>

                <div className="grid gap-3">
                  <AppField label="Age" hint="This helps SkinSync keep recommendations age-appropriate.">
                    <input
                      className="app-input"
                      type="number"
                      min="13"
                      max="100"
                      placeholder="Enter your age"
                      value={form.age}
                      onChange={(event) => {
                        setErrors((prev) => ({ ...prev, age: undefined }));
                        setForm((prev) => ({ ...prev, age: event.target.value }));
                      }}
                    />
                  </AppField>
                  {errors.age ? <FieldError message={errors.age} /> : null}
                </div>
              </div>

              <div className="flex flex-wrap gap-3 border-t border-border/70 pt-6">
                <Button
                  variant="premium"
                  disabled={saving || !hasChanges}
                  onClick={async () => {
                    setFeedback("");
                    if (!validate()) return;
                    setSaving(true);
                    const result = await saveSurveyApi({
                      skinType: form.skinType,
                      skinConcerns: form.concerns,
                      monthlyBudget: form.monthlyBudget,
                      age: form.age ? Number(form.age) : null,
                    });
                    setSaving(false);
                    setFeedback(result.message);
                    if (result.success && result.content) {
                      const nextForm = createFormState(result.content);
                      setProfile(result.content);
                      setInitialForm(nextForm);
                      setForm(nextForm);
                      if (saveBehavior === "redirect" && redirectTo) {
                        navigate(redirectTo);
                        return;
                      }
                      setIsEditing(false);
                    }
                  }}
                >
                  {saving ? "Saving..." : "Save profile"}
                </Button>
                <Button
                  variant="outline"
                  disabled={!hasChanges || saving}
                  onClick={() => {
                    setErrors({});
                    setFeedback("");
                    setForm(initialForm);
                  }}
                >
                  <RotateCcw className="h-4 w-4" />
                  Reset changes
                </Button>
                {profile && saveBehavior === "stay" ? (
                  <Button
                    variant="ghost"
                    disabled={saving}
                    onClick={() => {
                      setErrors({});
                      setFeedback("");
                      setForm(initialForm);
                      setIsEditing(false);
                    }}
                  >
                    Cancel
                  </Button>
                ) : null}
                <Button asChild variant="ghost">
                  <Link to="/app/dashboard">Back to dashboard</Link>
                </Button>
              </div>
              {feedback ? <p className="text-sm text-muted-foreground">{feedback}</p> : null}
            </div>
          </AppSection>
        )}

        <div className="space-y-4">
          <AppGuidanceCard
            title="Why this matters"
            description="A clean skin profile helps SkinSync interpret analysis results and prioritize the right care steps for you."
            icon={Sparkles}
          >
            <div className="space-y-2">
              {[
                "Choose your baseline skin type",
                "Highlight your current concern mix",
                "Keep routine and product guidance more relevant",
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

function FieldError({ message }: { message: string }) {
  return (
    <div className="rounded-2xl border border-[color:rgba(184,92,80,0.18)] bg-[var(--ss-danger-bg)] px-4 py-3 text-sm text-[var(--ss-danger)]">
      {message}
    </div>
  );
}

function ProfileInfoCard({
  label,
  value,
  className = "",
}: {
  label: string;
  value: string;
  className?: string;
}) {
  return (
    <div className={`rounded-3xl border border-border/70 bg-card px-5 py-4 ${className}`}>
      <p className="text-xs font-medium uppercase tracking-[0.18em] text-muted-foreground">{label}</p>
      <p className="mt-2 text-sm leading-6 text-foreground">{value}</p>
    </div>
  );
}
