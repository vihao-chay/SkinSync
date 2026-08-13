import { apiRequest } from "./apiClient";
import type { ApiResponse } from "./authService";

export interface AppInstallSummary {
  totalDownloads: number;
}

export async function getAppInstallSummaryApi(): Promise<ApiResponse<AppInstallSummary>> {
  const result = await apiRequest<Record<string, unknown>>(
    "/app-installs/summary",
    { method: "GET" },
    { requiresAuth: false }
  );

  if (!result.success || !result.content) {
    return {
      ...result,
      content: null,
    };
  }

  const rawTotal = result.content.totalDownloads ?? result.content.TotalDownloads;
  return {
    ...result,
    content: {
      totalDownloads: typeof rawTotal === "number" ? rawTotal : Number(rawTotal) || 0,
    },
  };
}
