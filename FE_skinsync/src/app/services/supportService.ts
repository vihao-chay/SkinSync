import type { ApiResponse } from "./authService";

export interface SupportRequestInput {
  name: string;
  email: string;
  category: string;
  message: string;
}

export async function submitSupportRequestApi(_: SupportRequestInput): Promise<ApiResponse<object>> {
  return {
    success: false,
    statusCode: 501,
    message: "Feature not available yet.",
    content: null,
  };
}
