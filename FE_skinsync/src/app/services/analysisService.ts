import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface AnalysisIssue {
  id: string;
  issueType: string;
  severityScore: number;
  confidenceScore?: number | null;
  description?: string | null;
}

export interface AnalysisRecommendation {
  id: string;
  recommendationType: string;
  title: string;
  content: string;
  priority: number;
}

export interface AnalysisDetail {
  id: string;
  userId: string;
  imageUrl: string;
  skinType: string;
  overallScore: number;
  confidenceScore: number;
  skinAge?: number | null;
  recoveryCapacity?: number | null;
  uvDamage?: number | null;
  agingRisk?: number | null;
  issuesDetected?: string | null;
  rootCauses?: string | null;
  overview?: string | null;
  aiModel?: string | null;
  status: string;
  disclaimer: string;
  warnings: string[];
  generatedAt: string;
  createdAt: string;
  issues: AnalysisIssue[];
  recommendations: AnalysisRecommendation[];
}

export interface AnalysisHistoryItem {
  id: string;
  createdAt: string;
  overallScore: number;
  skinAge?: number | null;
  skinType?: string | null;
}

export interface AnalysisHistoryResponse {
  items: AnalysisHistoryItem[];
  pageIndex: number;
  pageSize: number;
  totalRow: number;
}

export async function uploadSkinAnalysisApi(file: File): Promise<ApiResponse<unknown>> {
  const formData = new FormData();
  formData.append("image", file);

  return apiRequest<unknown>(
    "/analysis/scan",
    {
      method: "POST",
      body: formData,
    },
    { requiresAuth: true }
  );
}

export async function getLatestAnalysisApi(): Promise<ApiResponse<AnalysisDetail>> {
  return apiRequest<AnalysisDetail>("/analysis/latest", { method: "GET" }, { requiresAuth: true });
}

export async function getAnalysisDetailApi(id: string): Promise<ApiResponse<AnalysisDetail>> {
  return apiRequest<AnalysisDetail>(`/analysis/${id}`, { method: "GET" }, { requiresAuth: true });
}

export async function getAnalysisHistoryApi(pageIndex = 1, pageSize = 10): Promise<ApiResponse<AnalysisHistoryResponse>> {
  return apiRequest<AnalysisHistoryResponse>(
    `/analysis/history?pageIndex=${pageIndex}&pageSize=${pageSize}`,
    { method: "GET" },
    { requiresAuth: true }
  );
}
