import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface SurveyResponse {
  userId: string;
  skinType: string;
  skinConcerns: string[];
  monthlyBudget: string;
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

const skinTypeMap: Record<string, string> = {
  oily: "Oily",
  dry: "Dry",
  combination: "Combination",
  sensitive: "Sensitive",
  normal: "Normal",
  mature: "Mature",
};

const budgetMap: Record<string, string> = {
  low: "Low",
  mid: "Mid-range",
  high: "Premium",
};

export async function getSurveyApi(): Promise<ApiResponse<SurveyResponse>> {
  return apiRequest<SurveyResponse>("/users/survey", { method: "GET" }, { requiresAuth: true });
}

export async function saveSurveyApi(input: SaveSurveyInput): Promise<ApiResponse<SurveyResponse>> {
  const payload = {
    skinType: skinTypeMap[input.skinType] ?? input.skinType,
    skinConcerns: input.skinConcerns,
    monthlyBudget: budgetMap[input.monthlyBudget] ?? input.monthlyBudget,
    age: input.age ?? null,
    birthYear: input.birthYear ?? null,
  };

  return apiRequest<SurveyResponse>(
    "/users/survey",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    },
    { requiresAuth: true }
  );
}
