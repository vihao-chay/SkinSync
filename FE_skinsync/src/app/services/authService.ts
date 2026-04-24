import { createClient } from "@supabase/supabase-js";

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? "/api";
const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;

export interface AuthUser {
  id: string;
  fullName: string;
  email: string;
  phone: string;
  avatarUrl?: string | null;
  role: string;
  status: string;
}

export interface LoginResponse {
  tokenType: string;
  accessToken: string;
  refreshToken: string;
  accessTokenExpiresAtUtc: string;
  refreshTokenExpiresAtUtc: string;
  user: AuthUser;
}

export type RegisterResponse = AuthUser;
export type SocialAuthProvider = "google" | "facebook";
export type AuthProvider = "password" | SocialAuthProvider;

export interface ApiResponse<T> {
  success: boolean;
  statusCode: number;
  message: string;
  content: T | null;
}

const TOKEN_KEY = "skinsync_access_token";
const REFRESH_TOKEN_KEY = "skinsync_refresh_token";
const USER_KEY = "skinsync_user";
const AUTH_PROVIDER_KEY = "skinsync_auth_provider";
export const AUTH_STATE_CHANGED_EVENT = "skinsync-auth-changed";

let refreshPromise: Promise<boolean> | null = null;

const supabase = SUPABASE_URL && SUPABASE_ANON_KEY
  ? createClient(SUPABASE_URL, SUPABASE_ANON_KEY)
  : null;

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
  const accessToken = getAccessToken();

  if (accessToken) {
    headers.set("Authorization", `Bearer ${accessToken}`);
  }

  return headers;
}

function notifyAuthStateChanged() {
  window.dispatchEvent(new Event(AUTH_STATE_CHANGED_EVENT));
}

async function performRefreshToken(): Promise<boolean> {
  const refreshToken = getRefreshToken();
  if (!refreshToken) {
    clearAuthData();
    return false;
  }

  const response = await fetch(`${API_BASE_URL}/auth/refresh`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refreshToken }),
  });

  const parsed = await parseApiResponse<LoginResponse>(response);
  if (!parsed.success || !parsed.content) {
    clearAuthData();
    return false;
  }

  saveAuthData(parsed.content);
  return true;
}

async function tryRefreshToken(): Promise<boolean> {
  if (refreshPromise) {
    return refreshPromise;
  }

  refreshPromise = performRefreshToken()
    .catch(() => {
      clearAuthData();
      return false;
    })
    .finally(() => {
      refreshPromise = null;
    });

  return refreshPromise;
}

async function requestApi<T>(
  path: string,
  init?: RequestInit,
  options?: { requiresAuth?: boolean; retryOnUnauthorized?: boolean }
): Promise<ApiResponse<T>> {
  const requiresAuth = options?.requiresAuth ?? false;
  const retryOnUnauthorized = options?.retryOnUnauthorized ?? true;

  const headers = requiresAuth ? getAuthHeaders(init?.headers) : new Headers(init?.headers ?? {});

  try {
    const response = await fetch(`${API_BASE_URL}${path}`, {
      ...init,
      headers,
    });

    if (requiresAuth && response.status === 401 && retryOnUnauthorized) {
      const refreshed = await tryRefreshToken();
      if (refreshed) {
        return requestApi<T>(path, init, { requiresAuth: true, retryOnUnauthorized: false });
      }

      return buildFailureResponse<T>("Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.", 401);
    }

    return parseApiResponse<T>(response);
  } catch {
    return buildFailureResponse<T>("Không thể kết nối đến server.");
  }
}

export function saveAuthData(loginResponse: LoginResponse) {
  localStorage.setItem(TOKEN_KEY, loginResponse.accessToken);
  localStorage.setItem(REFRESH_TOKEN_KEY, loginResponse.refreshToken);
  localStorage.setItem(USER_KEY, JSON.stringify(loginResponse.user));
  notifyAuthStateChanged();
}

export function getAccessToken(): string | null {
  return localStorage.getItem(TOKEN_KEY);
}

export function getRefreshToken(): string | null {
  return localStorage.getItem(REFRESH_TOKEN_KEY);
}

export function getSavedUser(): AuthUser | null {
  const raw = localStorage.getItem(USER_KEY);
  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(raw) as AuthUser;
  } catch {
    return null;
  }
}

export function setSavedUser(user: AuthUser) {
  localStorage.setItem(USER_KEY, JSON.stringify(user));
  notifyAuthStateChanged();
}

export function clearAuthData() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
  localStorage.removeItem(AUTH_PROVIDER_KEY);
  notifyAuthStateChanged();
}

export function setAuthProvider(provider: AuthProvider) {
  localStorage.setItem(AUTH_PROVIDER_KEY, provider);
  notifyAuthStateChanged();
}

export function getAuthProvider(): AuthProvider | null {
  const value = localStorage.getItem(AUTH_PROVIDER_KEY);
  if (value === "password" || value === "google" || value === "facebook") {
    return value;
  }

  return null;
}

export function isAuthenticated(): boolean {
  return Boolean(getAccessToken());
}

export async function loginApi(email: string, password: string): Promise<ApiResponse<LoginResponse>> {
  return requestApi<LoginResponse>("/auth/login", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password }),
  });
}

export async function registerApi(
  fullName: string,
  email: string,
  phone: string,
  password: string
): Promise<ApiResponse<RegisterResponse>> {
  return requestApi<RegisterResponse>("/auth/register", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ fullName, email, phone, password }),
  });
}

export async function refreshTokenApi(refreshToken: string): Promise<ApiResponse<LoginResponse>> {
  return requestApi<LoginResponse>("/auth/refresh", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refreshToken }),
  }, { requiresAuth: false, retryOnUnauthorized: false });
}

export async function refreshSession(): Promise<boolean> {
  return tryRefreshToken();
}

export async function meApi(): Promise<ApiResponse<AuthUser>> {
  return requestApi<AuthUser>("/auth/me", {
    method: "GET",
  }, { requiresAuth: true });
}

export async function logoutApi(): Promise<ApiResponse<object>> {
  const result = await requestApi<object>("/auth/logout", {
    method: "POST",
  }, { requiresAuth: true, retryOnUnauthorized: false });

  clearAuthData();
  return result;
}

export async function forgotPasswordApi(email: string, redirectTo: string): Promise<ApiResponse<object>> {
  return requestApi<object>("/auth/forgot-password", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, redirectTo }),
  });
}

export async function resetPasswordApi(accessToken: string, newPassword: string): Promise<ApiResponse<object>> {
  return requestApi<object>("/auth/reset-password", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ accessToken, newPassword }),
  });
}

export async function changePasswordApi(oldPassword: string, newPassword: string): Promise<ApiResponse<object>> {
  return requestApi<object>("/auth/change-password", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ oldPassword, newPassword }),
  }, { requiresAuth: true });
}

export async function updateProfileApi(fullName: string, phone: string): Promise<ApiResponse<AuthUser>> {
  return requestApi<AuthUser>("/auth/profile", {
    method: "PUT",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ fullName, phone }),
  }, { requiresAuth: true });
}

export async function updateAvatarApi(file: File): Promise<ApiResponse<AuthUser>> {
  const formData = new FormData();
  formData.append("avatar", file);

  return requestApi<AuthUser>("/auth/avatar", {
    method: "PUT",
    body: formData,
  }, { requiresAuth: true });
}

export async function getGoogleLoginUrl(redirectTo: string): Promise<string> {
  const result = await requestApi<{ url: string }>(
    `/auth/google/url?redirectTo=${encodeURIComponent(redirectTo)}`,
    { method: "GET" }
  );

  if (!result.success || !result.content?.url) {
    throw new Error(result.message || "Không thể lấy Google login URL");
  }

  return result.content.url;
}

export async function loginWithGoogleToken(supabaseAccessToken: string): Promise<ApiResponse<LoginResponse>> {
  return requestApi<LoginResponse>("/auth/login/google", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ supabaseAccessToken }),
  });
}

export async function startSupabaseOAuth(provider: SocialAuthProvider, redirectTo: string): Promise<string> {
  if (!supabase) {
    const missingVars = [
      !SUPABASE_URL ? "VITE_SUPABASE_URL" : null,
      !SUPABASE_ANON_KEY ? "VITE_SUPABASE_ANON_KEY" : null,
    ].filter(Boolean).join(", ");

    throw new Error(`Thiếu cấu hình Supabase trên frontend (${missingVars}).`);
  }

  const { data, error } = await supabase.auth.signInWithOAuth({
    provider,
    options: {
      redirectTo,
      skipBrowserRedirect: true,
    },
  });

  if (error || !data?.url) {
    throw new Error(error?.message || "Không thể khởi tạo đăng nhập mạng xã hội.");
  }

  return data.url;
}
