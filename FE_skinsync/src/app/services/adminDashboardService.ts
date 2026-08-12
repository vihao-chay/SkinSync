import { apiRequest } from "./apiClient";
import type { ApiResponse } from "./authService";

export interface AdminDashboardData {
  totalUsers: number;
  totalAnalyses: number;
  activeUsers: number;
  skinTypeDistribution: Record<string, number>;
}

export async function getAdminDashboardApi(): Promise<ApiResponse<AdminDashboardData>> {
  return apiRequest<AdminDashboardData>("/admin/dashboard", { method: "GET" }, { requiresAuth: true });
}
