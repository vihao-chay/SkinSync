import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface RecommendationRequest {
  skinType: string;
  concerns: string[];
  sensitivity: string;
  goals: string[];
}

export interface RecommendationProduct {
  productId: string;
  name: string;
  brand: string;
  category: string;
  routineTime: string;
  stepOrder: number;
  price?: number | null;
  currency: string;
  rating?: number | null;
  score: number;
  imageUrl?: string | null;
  keyIngredients: string[];
  reasons: string[];
  reason: string;
  cautions: string[];
}

export interface RecommendationAlternativeCategory {
  categoryKey: string;
  categoryName: string;
  routineTime: string;
  products: RecommendationProduct[];
}

export interface RecommendationResponse {
  sessionId?: string | null;
  expiresAt?: string | null;
  overallCompatibilityScore: number;
  skinSummary: {
    skinType: string;
    concerns: string[];
    sensitivity: string;
    goals: string[];
  };
  morningRoutine: RecommendationProduct[];
  nightRoutine: RecommendationProduct[];
  alternatives: RecommendationAlternativeCategory[];
  ingredientHighlights: { ingredient: string; benefits: string[] }[];
  warnings: string[];
  generatedAt: string;
}

export interface SavedRecommendationProduct {
  productId: string;
  name: string;
  brand: string;
  category: string;
  price?: number | null;
  currency?: string | null;
  matchScore?: number | null;
  matchPercent?: number | null;
  aiReason?: string | null;
  whyRecommended?: string | null;
  warnings?: string[];
  cautions?: string[];
  imageUrl?: string | null;
}

export interface SavedRecommendationCategory {
  key?: string | null;
  label?: string | null;
  categoryKey?: string | null;
  categoryName?: string | null;
  reason?: string | null;
  items?: SavedRecommendationProduct[];
  products?: SavedRecommendationProduct[];
}

export interface SavedRecommendationResponse {
  hasRecommendation: boolean;
  sessionId?: string | null;
  summary?: string | null;
  generatedAt?: string | null;
  products?: SavedRecommendationProduct[];
  categories?: SavedRecommendationCategory[];
}

export async function generateRecommendationsApi(
  request: RecommendationRequest,
): Promise<ApiResponse<RecommendationResponse>> {
  return apiRequest<RecommendationResponse>(
    "/recommendations",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(request),
    },
    { requiresAuth: true },
  );
}

export async function getLatestRecommendationsApi(): Promise<ApiResponse<SavedRecommendationResponse>> {
  return apiRequest<SavedRecommendationResponse>(
    "/ai/products/recommendations/latest",
    { method: "GET" },
    { requiresAuth: true },
  );
}
