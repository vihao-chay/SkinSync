import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface ProgressOverview {
  startScore?: number | null;
  currentScore?: number | null;
  improvementPercent: number;
  completedDaysLast28: number;
  completionRateLast28: number;
  currentStreak: number;
}

export interface ProgressChartPoint {
  date: string;
  overallScore: number;
  hydrationScore?: number | null;
}

export interface ProgressStreakDay {
  date: string;
  completed: boolean;
}

export interface ProgressStreak {
  currentStreak: number;
  bestStreak: number;
  lastDays: ProgressStreakDay[];
}

export async function getProgressOverviewApi(): Promise<ApiResponse<ProgressOverview>> {
  return apiRequest<ProgressOverview>("/progress/overview", { method: "GET" }, { requiresAuth: true });
}

export async function getProgressChartApi(days = 30): Promise<ApiResponse<ProgressChartPoint[]>> {
  return apiRequest<ProgressChartPoint[]>(`/progress/chart?days=${days}`, { method: "GET" }, { requiresAuth: true });
}

export async function getProgressStreakApi(days = 30): Promise<ApiResponse<ProgressStreak>> {
  return apiRequest<ProgressStreak>(`/progress/streak?days=${days}`, { method: "GET" }, { requiresAuth: true });
}
