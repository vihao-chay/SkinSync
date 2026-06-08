import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface SkinAnalyzeRequest {
  imageUrl: string;
}

export interface SkinAnalyzeResponse {
  skinType: string;
  acneScore: number;
  oilinessScore: number;
  rednessScore: number;
  pigmentationScore: number;
  concerns: string[];
  rawAiResponse?: string | null;
}

export async function analyzeSkinApi(request: SkinAnalyzeRequest): Promise<ApiResponse<SkinAnalyzeResponse>> {
  return apiRequest<SkinAnalyzeResponse>(
    "/skin/analyze",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(request),
    },
    { requiresAuth: true }
  );
}

export async function getLatestAnalysisApi(): Promise<ApiResponse<any>> {
  return apiRequest<any>("/analysis/latest", { method: "GET" }, { requiresAuth: true });
}
