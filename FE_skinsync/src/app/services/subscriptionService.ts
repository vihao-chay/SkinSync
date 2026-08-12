import { apiRequest } from "./apiClient";
import type { ApiResponse } from "./authService";

export interface SubscriptionPlanFeature {
  featureKey: string;
  displayName: string;
  description?: string | null;
  isEnabled: boolean;
  monthlyLimit?: number | null;
  unit: string;
}

export interface SubscriptionPlan {
  id: string;
  code: string;
  name: string;
  description?: string | null;
  price: number;
  currency: string;
  billingPeriod: string;
  sortOrder: number;
  features: SubscriptionPlanFeature[];
}

export interface CurrentSubscription {
  plan: SubscriptionPlan;
  subscription: {
    subscriptionId?: string | null;
    planCode: string;
    status: string;
    startedAt?: string | null;
    currentPeriodStart?: string | null;
    currentPeriodEnd?: string | null;
    canceledAt?: string | null;
  };
  usage: Array<{
    featureKey: string;
    displayName: string;
    used: number;
    remaining?: number | null;
    limit?: number | null;
    unit: string;
    isUnlimited: boolean;
  }>;
}

export async function getSubscriptionPlansApi(): Promise<ApiResponse<SubscriptionPlan[]>> {
  return apiRequest<SubscriptionPlan[]>("/subscription-plans", { method: "GET" }, { requiresAuth: false });
}

export async function getCurrentSubscriptionApi(): Promise<ApiResponse<CurrentSubscription>> {
  return apiRequest<CurrentSubscription>("/subscriptions/me", { method: "GET" }, { requiresAuth: true });
}

export async function subscribePlanApi(planCode: string): Promise<ApiResponse<CurrentSubscription>> {
  return apiRequest<CurrentSubscription>(
    "/subscriptions/subscribe",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ planCode }),
    },
    { requiresAuth: true }
  );
}

export async function cancelSubscriptionApi(): Promise<ApiResponse<CurrentSubscription>> {
  return apiRequest<CurrentSubscription>("/subscriptions/cancel", { method: "POST" }, { requiresAuth: true });
}
