import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export type AdminUserStatus = "active" | "inactive" | "banned";

export interface AdminUserListItem {
  id: string;
  name: string;
  email: string;
  phone: string;
  avatar: string;
  skinType: string;
  status: AdminUserStatus;
  streak: number;
  score: number;
  joinDate: string;
  lastActive: string;
  analyses: number;
  createdAt: string;
}

export interface AdminUsersPagedData {
  items: AdminUserListItem[];
  pageIndex: number;
  pageSize: number;
  totalRow: number;
  totalPages: number;
}

type AdminUserApiItem = {
  id?: string;
  fullName?: string | null;
  email?: string | null;
  phone?: string | null;
  role?: string | null;
  status?: string | null;
  createdAt?: string | null;
};

type PagedResponse<T> = {
  items?: T[];
  pageIndex?: number;
  pageSize?: number;
  totalRow?: number;
  totalPages?: number;
};

const fallbackAvatarUrl = "https://images.unsplash.com/photo-1739208885492-6e202b6f86f0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3b21hbiUyMHBvcnRyYWl0JTIwYXZhdGFyJTIwcHJvZmlsZSUyMHBob3RvJTIwYmVhdXR5fGVufDF8fHx8MTc3NDAxNjIwOHww&ixlib=rb-4.1.0&q=80&w=200";

function buildFailureResponse<T>(message: string, statusCode = 500): ApiResponse<T> {
  return {
    success: false,
    statusCode,
    message,
    content: null,
  };
}

function normalizeStatus(value: string | null | undefined): AdminUserStatus {
  const normalized = value?.trim().toLowerCase();

  if (normalized === "banned") {
    return "banned";
  }

  if (normalized === "active") {
    return "active";
  }

  return "inactive";
}

function formatMonthYear(isoDate: string | null | undefined): string {
  if (!isoDate) {
    return "--/----";
  }

  const date = new Date(isoDate);
  if (Number.isNaN(date.getTime())) {
    return "--/----";
  }

  return new Intl.DateTimeFormat("vi-VN", {
    month: "2-digit",
    year: "numeric",
  }).format(date);
}

export async function getAdminUsersFromSupabase(
  pageIndex = 1,
  pageSize = 5,
  options?: {
    search?: string;
    status?: "all" | AdminUserStatus;
  }
): Promise<ApiResponse<AdminUsersPagedData>> {
  const params = new URLSearchParams({
    pageIndex: String(pageIndex),
    pageSize: String(pageSize),
    sortBy: "createdAt",
    sortDirection: "desc",
    role: "user",
  });

  const trimmedSearch = options?.search?.trim();
  if (trimmedSearch) {
    params.set("search", trimmedSearch);
  }

  if (options?.status && options.status !== "all") {
    params.set("status", options.status);
  }

  const response = await apiRequest<PagedResponse<AdminUserApiItem>>(
    `/admin/users?${params.toString()}`,
    { method: "GET" },
    { requiresAuth: true }
  );

  if (!response.success || !response.content) {
    return buildFailureResponse<AdminUsersPagedData>(response.message, response.statusCode);
  }

  const rows = response.content.items ?? [];

  const mapped = rows
    .map((row) => {
      return {
        id: row.id ?? crypto.randomUUID(),
        name: row.fullName?.trim() || "Người dùng chưa đặt tên",
        email: row.email?.trim() || "",
        phone: row.phone?.trim() || "không có",
        avatar: fallbackAvatarUrl,
        skinType: "Không có",
        status: normalizeStatus(row.status),
        streak: 0,
        score: 0,
        joinDate: formatMonthYear(row.createdAt),
        lastActive: "Không có",
        analyses: 0,
        createdAt: row.createdAt ?? "",
      };
    })
    .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

  return {
    success: true,
    statusCode: 200,
    message: "Fetched users successfully.",
    content: {
      items: mapped,
      pageIndex: response.content.pageIndex ?? pageIndex,
      pageSize: response.content.pageSize ?? pageSize,
      totalRow: response.content.totalRow ?? mapped.length,
      totalPages: response.content.totalPages ?? 1,
    },
  };
}

export async function updateAdminUserStatus(
  userId: string,
  status: AdminUserStatus
): Promise<ApiResponse<AdminUserStatus>> {
  const response = await apiRequest<AdminUserApiItem>(
    `/admin/users/${userId}/status`,
    {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status }),
    },
    { requiresAuth: true }
  );

  if (!response.success || !response.content) {
    return buildFailureResponse<AdminUserStatus>(response.message, response.statusCode);
  }

  return {
    success: true,
    statusCode: response.statusCode,
    message: response.message,
    content: normalizeStatus(response.content.status),
  };
}
