import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface AnalysisDetail {
  id: string;
  userId: string;
  imageUrl: string;
  overallScore: number;
  skinAge: number;
  recoveryCapacity: number;
  uvDamage: number;
  agingRisk: number;
  issuesDetected: string;
  rootCauses: string;
  createdAt: string;
}

export async function getLatestAnalysisApi(): Promise<ApiResponse<AnalysisDetail>> {
  return apiRequest<AnalysisDetail>("/analysis/latest", { method: "GET" }, { requiresAuth: true });
}
