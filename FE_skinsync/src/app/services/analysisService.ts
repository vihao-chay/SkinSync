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

export interface AnalysisScanResponse {
  analysis: AnalysisDetail;
  regimenId: string;
  startDate: string;
  endDate: string;
  isActive: boolean;
  itemCount: number;
}

export interface AnalysisHistoryItem {
  id: string;
  createdAt: string;
  overallScore: number;
  skinAge: number;
  recoveryCapacity: number;
  uvDamage: number;
  agingRisk: number;
}

export interface PagingResult<T> {
  items: T[];
  pageSize: number;
  pageIndex: number;
  totalRow: number;
  totalPages: number;
}

export async function scanAnalysisApi(file: File): Promise<ApiResponse<AnalysisScanResponse>> {
  const formData = new FormData();
  formData.append("Image", file);

  return apiRequest<AnalysisScanResponse>("/analysis/scan", {
    method: "POST",
    body: formData,
  }, { requiresAuth: true });
}

export async function getLatestAnalysisApi(): Promise<ApiResponse<AnalysisDetail>> {
  return apiRequest<AnalysisDetail>("/analysis/latest", { method: "GET" }, { requiresAuth: true });
}

export async function getAnalysisHistoryApi(
  pageIndex = 1,
  pageSize = 5
): Promise<ApiResponse<PagingResult<AnalysisHistoryItem>>> {
  return apiRequest<PagingResult<AnalysisHistoryItem>>(
    `/analysis/history?pageIndex=${pageIndex}&pageSize=${pageSize}`,
    { method: "GET" },
    { requiresAuth: true }
  );
}
