import { apiRequest } from "./apiClient";
import type { ApiResponse } from "./authService";

export interface AdminAiLogItem {
  id: string;
  userId: string;
  userEmail: string;
  userName: string;
  featureName: string;
  model?: string | null;
  inputTokens?: number | null;
  outputTokens?: number | null;
  costEstimate?: number | null;
  usedAt: string;
}

export interface AdminAiLogsData {
  totalLogs: number;
  distinctUsers: number;
  items: AdminAiLogItem[];
}

export async function getAdminAiLogsApi(): Promise<ApiResponse<AdminAiLogsData>> {
  return apiRequest<AdminAiLogsData>("/admin/ai-logs", { method: "GET" }, { requiresAuth: true });
}
