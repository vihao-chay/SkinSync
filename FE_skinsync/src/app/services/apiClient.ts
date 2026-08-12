import {
  type ApiResponse,
  clearAuthData,
  getAccessToken,
  refreshSession,
} from "./authService";
import { clearImpersonationSession, getImpersonationToken } from "./impersonationService";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "/api";

function buildFailureResponse<T>(message: string, statusCode = 500): ApiResponse<T> {
  return {
    success: false,
    statusCode,
    message,
    content: null,
  };
}

async function parseApiResponse<T>(response: Response): Promise<ApiResponse<T>> {
  try {
    const data = (await response.json()) as Partial<ApiResponse<T>>;
    if (!("success" in data) && !("content" in data)) {
      return {
        success: response.ok,
        statusCode: response.status,
        message: response.ok ? "Success" : "Request failed",
        content: response.ok ? (data as T) : null,
      };
    }

    return {
      success: Boolean(data.success),
      statusCode: typeof data.statusCode === "number" ? data.statusCode : response.status,
      message: data.message ?? (response.ok ? "Success" : "Request failed"),
      content: (data.content ?? null) as T | null,
    };
  } catch {
    return buildFailureResponse<T>("Không đọc được phản hồi từ server.", response.status || 500);
  }
}

function getAuthHeaders(baseHeaders?: HeadersInit): Headers {
  const headers = new Headers(baseHeaders ?? {});
  const token = getAccessToken();
  const impersonationToken = getImpersonationToken();

  if (token) {
    headers.set("Authorization", `Bearer ${token}`);
  }

  if (impersonationToken) {
    headers.set("X-Impersonation-Token", impersonationToken);
  }

  return headers;
}

export async function apiRequest<T>(
  path: string,
  init?: RequestInit,
  options?: { requiresAuth?: boolean; retryOnUnauthorized?: boolean }
): Promise<ApiResponse<T>> {
  const requiresAuth = options?.requiresAuth ?? true;
  const retryOnUnauthorized = options?.retryOnUnauthorized ?? true;
  const headers = requiresAuth ? getAuthHeaders(init?.headers) : new Headers(init?.headers ?? {});

  try {
    const response = await fetch(`${API_BASE_URL}${path}`, {
      ...init,
      headers,
    });

    if (requiresAuth && response.status === 401 && retryOnUnauthorized) {
      clearImpersonationSession();
      const refreshed = await refreshSession();
      if (refreshed) {
        return apiRequest<T>(path, init, { requiresAuth: true, retryOnUnauthorized: false });
      }

      clearAuthData();
      return buildFailureResponse<T>("Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.", 401);
    }

    return parseApiResponse<T>(response);
  } catch {
    return buildFailureResponse<T>("Không thể kết nối đến server.");
  }
}
