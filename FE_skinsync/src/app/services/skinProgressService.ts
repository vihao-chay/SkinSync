import { apiRequest } from "./apiClient";
import type { ApiResponse } from "./authService";

export interface SkinProgressOverview {
  latestScore?: number | null;
  scoreDelta?: number | null;
  latestEntryId?: string | null;
  totalEntries: number;
  currentStreak: number;
  routineAdherenceRate?: number | null;
  mainConcerns: string[];
  trendSummary: string;
  chartData: Array<{
    entryId: string;
    createdAt: string;
    skinScore?: number | null;
    acneLevel?: number | null;
    rednessLevel?: number | null;
    darkSpotLevel?: number | null;
    textureLevel?: number | null;
    hydrationLevel?: number | null;
    oilLevel?: number | null;
  }>;
}

export interface SkinProgressPhoto {
  photoId: string;
  imageUrl: string;
  thumbnailUrl?: string | null;
  source: string;
  photoDate: string;
  createdAt: string;
}

export interface SkinProgressTimelineEntry {
  entryId: string;
  analysisId?: string | null;
  photoId: string;
  status: string;
  imageUrl: string;
  thumbnailUrl?: string | null;
  skinScore?: number | null;
  summary?: string | null;
  mainConcerns: string[];
  createdAt: string;
}

export async function getSkinProgressOverviewApi(): Promise<ApiResponse<SkinProgressOverview>> {
  return apiRequest<SkinProgressOverview>("/skin-progress/overview", { method: "GET" }, { requiresAuth: true });
}

export async function getSkinProgressPhotosApi(): Promise<ApiResponse<SkinProgressPhoto[]>> {
  return apiRequest<SkinProgressPhoto[]>("/skin-progress/photos", { method: "GET" }, { requiresAuth: true });
}

export async function getSkinProgressTimelineApi(): Promise<ApiResponse<SkinProgressTimelineEntry[]>> {
  return apiRequest<SkinProgressTimelineEntry[]>("/skin-progress/timeline", { method: "GET" }, { requiresAuth: true });
}

export async function uploadSkinProgressPhotoApi(file: File): Promise<ApiResponse<SkinProgressPhoto>> {
  const formData = new FormData();
  formData.append("image", file);
  formData.append("source", "progress");

  return apiRequest<SkinProgressPhoto>(
    "/skin-progress/photos",
    {
      method: "POST",
      body: formData,
    },
    { requiresAuth: true }
  );
}
