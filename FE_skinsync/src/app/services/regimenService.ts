import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface RegimenProduct {
  productId: string;
  name: string;
  category: string;
  price: number;
  imageUrl?: string | null;
  stepOrder: number;
}

export interface CurrentRegimenResponse {
  regimenId: string;
  startDate: string;
  endDate: string;
  totalEstimatedCost: number;
  morning: RegimenProduct[];
  evening: RegimenProduct[];
}

export async function getCurrentRegimenApi(): Promise<ApiResponse<CurrentRegimenResponse>> {
  return apiRequest<CurrentRegimenResponse>("/regimens/current", { method: "GET" }, { requiresAuth: true });
}
