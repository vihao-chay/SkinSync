import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface RoutineStepTracking {
  trackingId: string;
  stepId: string;
  productId: string;
  routineTime: "Morning" | "Evening";
  stepOrder: number;
  productName: string;
  status: string;
  completedAt: string;
}

export interface RoutineTrackingToday {
  date: string;
  totalSteps: number;
  completedSteps: number;
  completionPercent: number;
  morningCompleted: boolean;
  eveningCompleted: boolean;
  steps: RoutineStepTracking[];
}

export async function getTodayRoutineTrackingApi(): Promise<ApiResponse<RoutineTrackingToday>> {
  return apiRequest<RoutineTrackingToday>("/routine-tracking/today", { method: "GET" }, { requiresAuth: true });
}

export async function completeRoutineStepApi(stepId: string): Promise<ApiResponse<RoutineTrackingToday>> {
  return apiRequest<RoutineTrackingToday>(
    `/routine-tracking/steps/${stepId}/complete`,
    { method: "POST" },
    { requiresAuth: true }
  );
}

export async function uncompleteRoutineStepApi(stepId: string): Promise<ApiResponse<RoutineTrackingToday>> {
  return apiRequest<RoutineTrackingToday>(
    `/routine-tracking/steps/${stepId}/complete`,
    { method: "DELETE" },
    { requiresAuth: true }
  );
}

export async function completeRoutineApi(
  routineType: "Morning" | "Evening"
): Promise<ApiResponse<RoutineTrackingToday>> {
  return apiRequest<RoutineTrackingToday>(
    `/routine-tracking/routines/${routineType}/complete`,
    { method: "POST" },
    { requiresAuth: true }
  );
}
