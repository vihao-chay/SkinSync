import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface SkinChatResponse {
  response: string;
  providerUsed: string;
  modelUsed: string;
}

export async function sendSkinChatMessage(message: string): Promise<ApiResponse<SkinChatResponse>> {
  return apiRequest<SkinChatResponse>(
    "/skin/chat",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ message }),
    },
    { requiresAuth: false, retryOnUnauthorized: false }
  );
}
