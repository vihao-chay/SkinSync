import { apiRequest } from "./apiClient";
import type { ApiResponse } from "./authService";

const IMPERSONATION_STORAGE_KEY = "skinsync_impersonation";

export interface ImpersonationSession {
  impersonationToken: string;
  originalAdminId: string;
  effectiveUserId: string;
  impersonatedUserId: string;
  impersonatedUserName: string;
  impersonatedUserEmail: string;
  expiresAt: string;
}

export interface StartImpersonationInput {
  userId: string;
}

export function getImpersonationSession(): ImpersonationSession | null {
  const raw = localStorage.getItem(IMPERSONATION_STORAGE_KEY);
  if (!raw) {
    return null;
  }

  try {
    const parsed = JSON.parse(raw) as ImpersonationSession;
    if (!parsed.impersonationToken) {
      return null;
    }

    return parsed;
  } catch {
    return null;
  }
}

export function getImpersonationToken(): string | null {
  const session = getImpersonationSession();
  if (!session) {
    return null;
  }

  if (new Date(session.expiresAt).getTime() <= Date.now()) {
    clearImpersonationSession();
    return null;
  }

  return session.impersonationToken;
}

export function saveImpersonationSession(session: ImpersonationSession) {
  localStorage.setItem(IMPERSONATION_STORAGE_KEY, JSON.stringify(session));
  window.dispatchEvent(new Event("skinsync-impersonation-changed"));
}

export function clearImpersonationSession() {
  localStorage.removeItem(IMPERSONATION_STORAGE_KEY);
  window.dispatchEvent(new Event("skinsync-impersonation-changed"));
}

export async function startImpersonationApi(input: StartImpersonationInput): Promise<ApiResponse<ImpersonationSession>> {
  return apiRequest<ImpersonationSession>(
    "/admin/impersonation/start",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(input),
    },
    { requiresAuth: true }
  );
}

export async function endImpersonationApi(): Promise<ApiResponse<object>> {
  return apiRequest<object>(
    "/admin/impersonation/end",
    { method: "POST" },
    { requiresAuth: true }
  );
}
