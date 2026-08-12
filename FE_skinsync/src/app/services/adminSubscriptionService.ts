import { apiRequest } from "./apiClient";
import type { ApiResponse } from "./authService";

export interface AdminSubscriptionItem {
  subscriptionId: string;
  userId: string;
  userEmail: string;
  userName: string;
  planCode: string;
  planName: string;
  status: string;
  pricePaid: number;
  currency: string;
  billingPeriod: string;
  startedAt: string;
  endsAt?: string | null;
  cancelledAt?: string | null;
}

export interface AdminSubscriptionsData {
  totalSubscriptions: number;
  activeSubscriptions: number;
  items: AdminSubscriptionItem[];
}

export async function getAdminSubscriptionsApi(): Promise<ApiResponse<AdminSubscriptionsData>> {
  return apiRequest<AdminSubscriptionsData>("/admin/subscriptions", { method: "GET" }, { requiresAuth: true });
}
