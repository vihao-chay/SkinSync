import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface SurveyResponse {
  userId: string;
  skinType: string;
  skinTypeValue: string;
  skinConcerns: string[];
  skinConcernValues: string[];
  monthlyBudget: string;
  budgetLevel: string;
  age?: number | null;
  birthYear?: number | null;
}

export interface SaveSurveyInput {
  skinType: string;
  skinConcerns: string[];
  monthlyBudget: string;
  age?: number | null;
  birthYear?: number | null;
}

interface RawSurveyResponse {
  userId?: string;
  skinType?: string | null;
  concerns?: string[] | null;
  skinConcerns?: string[] | null;
  budgetLevel?: string | null;
  budgetLabel?: string | null;
  monthlyBudget?: string | number | null;
  age?: number | null;
  birthYear?: number | null;
}

const skinTypeLabelMap: Record<string, string> = {
  oily: "Oily",
  dry: "Dry",
  combination: "Combination",
  sensitive: "Sensitive",
  normal: "Normal",
  mature: "Mature",
};

const concernLabelMap: Record<string, string> = {
  acne: "Acne",
  pigmentation: "Dark spots",
  pores: "Enlarged pores",
  aging: "Fine lines",
  scars: "Scars",
  wrinkles: "Wrinkles",
  dull: "Dullness",
  dry_patches: "Dry patches",
  redness: "Redness",
};

const budgetLabelMap: Record<string, string> = {
  low: "Budget-friendly",
  mid: "Mid-range",
  high: "Premium",
  none: "No preference",
  no_preference: "No preference",
};

function normalizeStringArray(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value
    .map((item) => String(item ?? "").trim())
    .filter(Boolean);
}

function toTitleCase(value: string): string {
  return value
    .split(/[\s_-]+/)
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1).toLowerCase())
    .join(" ");
}

function normalizeBudgetLevel(value?: string | number | null): string {
  return String(value ?? "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "_");
}

function normalizeSkinTypeLabel(value?: string | null): string {
  const normalized = value?.trim().toLowerCase();
  if (!normalized) {
    return "";
  }

  return skinTypeLabelMap[normalized] ?? toTitleCase(normalized);
}

function normalizeConcernLabel(value: string): string {
  const normalized = value.trim().toLowerCase();
  return concernLabelMap[normalized] ?? toTitleCase(normalized);
}

function normalizeBudgetLabel(raw: RawSurveyResponse): string {
  if (raw.budgetLabel?.trim()) {
    return raw.budgetLabel.trim();
  }

  const level = normalizeBudgetLevel(raw.budgetLevel ?? raw.monthlyBudget);
  return budgetLabelMap[level] ?? (level ? toTitleCase(level) : "");
}

function normalizeSurveyResponse(raw: RawSurveyResponse): SurveyResponse {
  const skinTypeValue = raw.skinType?.trim().toLowerCase() ?? "";
  const concernValues = normalizeStringArray(raw.concerns ?? raw.skinConcerns).map((item) => item.toLowerCase());
  const budgetLevel = normalizeBudgetLevel(raw.budgetLevel ?? raw.monthlyBudget);

  return {
    userId: raw.userId ?? "",
    skinType: normalizeSkinTypeLabel(raw.skinType),
    skinTypeValue,
    skinConcerns: concernValues.map(normalizeConcernLabel),
    skinConcernValues: concernValues,
    monthlyBudget: normalizeBudgetLabel(raw),
    budgetLevel,
    age: raw.age ?? null,
    birthYear: raw.birthYear ?? null,
  };
}

export async function getSurveyApi(): Promise<ApiResponse<SurveyResponse>> {
  const result = await apiRequest<RawSurveyResponse>("/users/survey", { method: "GET" }, { requiresAuth: true });

  return {
    ...result,
    content: result.content ? normalizeSurveyResponse(result.content) : null,
  };
}

export async function saveSurveyApi(input: SaveSurveyInput): Promise<ApiResponse<SurveyResponse>> {
  const payload = {
    skinType: input.skinType.trim().toLowerCase(),
    concerns: input.skinConcerns,
    budgetLevel: input.monthlyBudget || null,
    age: input.age ?? null,
    birthYear: input.birthYear ?? null,
  };

  const result = await apiRequest<RawSurveyResponse>(
    "/users/survey",
    {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    },
    { requiresAuth: true }
  );

  return {
    ...result,
    content: result.content ? normalizeSurveyResponse(result.content) : null,
  };
}
