import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface DiaryCheckInResponse {
  id: string;
  userId: string;
  date: string;
  morningCompleted: boolean;
  eveningCompleted: boolean;
  skinFeeling: string;
  isIrritated: boolean;
  notes?: string | null;
  dailyImageUrl?: string | null;
}

export interface SaveCheckInInput {
  date?: string;
  morningCompleted: boolean;
  eveningCompleted: boolean;
  skinFeeling: string;
  isIrritated: boolean;
  notes?: string;
  image?: File | null;
}

export async function getTodayCheckInApi(): Promise<ApiResponse<DiaryCheckInResponse>> {
  return apiRequest<DiaryCheckInResponse>("/diary/today", { method: "GET" }, { requiresAuth: true });
}

export async function getDiaryByDateApi(date: string): Promise<ApiResponse<DiaryCheckInResponse>> {
  return apiRequest<DiaryCheckInResponse>(`/diary/day?date=${encodeURIComponent(date)}`, { method: "GET" }, { requiresAuth: true });
}

export async function saveCheckInApi(input: SaveCheckInInput): Promise<ApiResponse<DiaryCheckInResponse>> {
  const formData = new FormData();
  if (input.date) {
    formData.append("date", input.date);
  }

  formData.append("morningCompleted", String(input.morningCompleted));
  formData.append("eveningCompleted", String(input.eveningCompleted));
  formData.append("skinFeeling", input.skinFeeling);
  formData.append("isIrritated", String(input.isIrritated));

  if (input.notes?.trim()) {
    formData.append("notes", input.notes.trim());
  }

  if (input.image) {
    formData.append("image", input.image);
  }

  return apiRequest<DiaryCheckInResponse>(
    "/diary/check-in",
    {
      method: "POST",
      body: formData,
    },
    { requiresAuth: true }
  );
}
