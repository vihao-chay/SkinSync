import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface Reminder {
  reminderId: string;
  time: string;
  routineType: "Morning" | "Evening";
  isEnabled: boolean;
}

export interface SaveReminderInput {
  time: string;
  routineType: "Morning" | "Evening";
  isEnabled: boolean;
}

export async function getRemindersApi(): Promise<ApiResponse<Reminder[]>> {
  return apiRequest<Reminder[]>("/reminders", { method: "GET" }, { requiresAuth: true });
}

export async function saveReminderApi(input: SaveReminderInput): Promise<ApiResponse<Reminder>> {
  return apiRequest<Reminder>(
    "/reminders",
    {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    },
    { requiresAuth: true }
  );
}

export async function toggleReminderApi(reminderId: string): Promise<ApiResponse<Reminder>> {
  return apiRequest<Reminder>(`/reminders/${reminderId}/toggle`, { method: "PATCH" }, { requiresAuth: true });
}
