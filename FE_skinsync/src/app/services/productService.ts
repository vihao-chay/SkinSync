import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface ProductDetail {
  id: string;
  name: string;
  brand: string;
  category: string;
  description?: string | null;
  ingredient?: string | null;
  ingredients?: string[];
  usageGuide?: string | null;
  howToUse?: string | null;
  usageTime?: string | null;
  price: number;
  currency: string;
  suitableSkinTypes: string[];
  skinConcerns?: string[];
  keyIngredients?: string[];
  cautions?: string[];
  conflicts?: string[];
  imageUrl?: string | null;
  rating?: number | null;
  status: string;
  createdAt: string;
  updatedAt?: string | null;
}

export async function getProductsApi(options?: {
  search?: string;
  category?: string;
}): Promise<ApiResponse<ProductDetail[]>> {
  const params = new URLSearchParams();
  if (options?.search?.trim()) {
    params.set("search", options.search.trim());
  }

  if (options?.category?.trim()) {
    params.set("category", options.category.trim());
  }

  const query = params.toString();
  return apiRequest<ProductDetail[]>(`/products${query ? `?${query}` : ""}`, { method: "GET" }, { requiresAuth: true });
}

export async function getProductDetailApi(productId: string): Promise<ApiResponse<ProductDetail>> {
  return apiRequest<ProductDetail>(`/products/${productId}`, { method: "GET" }, { requiresAuth: true });
}
