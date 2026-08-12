import { apiRequest } from "./apiClient";
import type { ApiResponse } from "./authService";

export type AdminUserStatus = "active" | "inactive" | "banned";

export interface AdminUserItem {
  id: string;
  fullName: string;
  email: string;
  phone?: string | null;
  role: string;
  status: AdminUserStatus;
  planType: string;
  createdAt: string;
}

export interface AdminUserDetail extends AdminUserItem {
  avatarUrl?: string | null;
  profile?: {
    skinType?: string | null;
    skinConcerns: string[];
    monthlyBudget?: number | null;
    age?: number | null;
    birthYear?: number | null;
    gender?: string | null;
    allergies: string[];
    sensitiveIngredients: string[];
    skinGoals: string[];
    routinePreference?: string | null;
    updatedAt?: string | null;
  } | null;
  subscription?: unknown;
  progressOverview?: {
    startScore?: number | null;
    currentScore?: number | null;
    improvementPercent: number;
    completedDaysLast28: number;
    completionRateLast28: number;
    currentStreak: number;
    progressInsight?: string | null;
  } | null;
  currentRegimen?: unknown;
  latestAnalysis?: unknown;
  recentActivities: Array<{
    type: string;
    title: string;
    description?: string | null;
    occurredAt: string;
  }>;
}

export interface AdminUsersPaged {
  items: AdminUserItem[];
  pageIndex: number;
  pageSize: number;
  totalRow: number;
  totalPages: number;
}

type AdminUsersResponseShape = {
  items?: AdminUserItem[];
  pageIndex?: number;
  pageSize?: number;
  totalRow?: number;
  totalPages?: number;
};

export async function getAdminUsersApi(search = "", status = "all", pageIndex = 1, pageSize = 20): Promise<ApiResponse<AdminUsersPaged>> {
  const params = new URLSearchParams({
    pageIndex: String(pageIndex),
    pageSize: String(pageSize),
    role: "user",
  });

  if (search.trim()) {
    params.set("search", search.trim());
  }

  if (status !== "all") {
    params.set("status", status);
  }

  const response = await apiRequest<AdminUsersResponseShape>(`/admin/users?${params.toString()}`, { method: "GET" }, { requiresAuth: true });
  if (!response.success || !response.content) {
    return { ...response, content: null };
  }

  return {
    ...response,
    content: {
      items: response.content.items ?? [],
      pageIndex: response.content.pageIndex ?? pageIndex,
      pageSize: response.content.pageSize ?? pageSize,
      totalRow: response.content.totalRow ?? 0,
      totalPages: response.content.totalPages ?? 1,
    },
  };
}

export async function getAdminUserDetailApi(userId: string): Promise<ApiResponse<AdminUserDetail>> {
  return apiRequest<AdminUserDetail>(`/admin/users/${userId}`, { method: "GET" }, { requiresAuth: true });
}

export async function updateAdminUserStatusApi(userId: string, status: AdminUserStatus): Promise<ApiResponse<AdminUserItem>> {
  return apiRequest<AdminUserItem>(
    `/admin/users/${userId}/status`,
    {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status }),
    },
    { requiresAuth: true }
  );
}
