import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface RegimenProduct {
  stepId: string;
  productId: string;
  name: string;
  brand: string;
  category: string;
  description: string;
  ingredient: string;
  usageGuide: string;
  instruction: string;
  price: number;
  imageUrl?: string | null;
  stepOrder: number;
}

export interface CurrentRegimenResponse {
  regimenId: string;
  name: string;
  startDate: string;
  endDate: string;
  isCustom: boolean;
  totalEstimatedCost: number;
  morning: RegimenProduct[];
  evening: RegimenProduct[];
}

export interface RegimenStepInput {
  productId: string;
  routineTime: "Morning" | "Evening";
  stepOrder: number;
  instruction: string;
}

export interface SaveRegimenInput {
  name: string;
  steps: RegimenStepInput[];
}

export async function getCurrentRegimenApi(): Promise<ApiResponse<CurrentRegimenResponse>> {
  return apiRequest<CurrentRegimenResponse>("/regimens/current", { method: "GET" }, { requiresAuth: true });
}

export async function createCustomRegimenApi(input: SaveRegimenInput): Promise<ApiResponse<CurrentRegimenResponse>> {
  return apiRequest<CurrentRegimenResponse>(
    "/regimens/custom",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    },
    { requiresAuth: true }
  );
}

export async function updateRegimenApi(
  regimenId: string,
  input: SaveRegimenInput
): Promise<ApiResponse<CurrentRegimenResponse>> {
  return apiRequest<CurrentRegimenResponse>(
    `/regimens/${regimenId}`,
    {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    },
    { requiresAuth: true }
  );
}

export async function deleteRegimenApi(regimenId: string): Promise<ApiResponse<object>> {
  return apiRequest<object>(`/regimens/${regimenId}`, { method: "DELETE" }, { requiresAuth: true });
}
