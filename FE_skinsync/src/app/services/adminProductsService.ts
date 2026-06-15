import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export type AdminProductStatus = "active" | "inactive" | "out_of_stock";

export interface AdminProductItem {
  id: string;
  name: string;
  brand: string;
  category: string;
  description?: string | null;
  ingredient?: string | null;
  ingredients: string[];
  usageGuide?: string | null;
  howToUse?: string | null;
  usageTime?: string | null;
  price: number;
  currency: string;
  suitableSkinTypes: string[];
  skinConcerns: string[];
  keyIngredients: string[];
  cautions: string[];
  conflicts: string[];
  imageUrl?: string | null;
  rating?: number | null;
  status: AdminProductStatus;
  createdAt: string;
  updatedAt?: string | null;
}

export interface AdminProductsPagedData {
  items: AdminProductItem[];
  pageIndex: number;
  pageSize: number;
  totalRow: number;
  totalPages: number;
}

export interface AdminProductUpsertInput {
  name: string;
  brand: string;
  category: string;
  description?: string;
  ingredient?: string;
  usageGuide?: string;
  price: number;
  currency: string;
  suitableSkinTypes: string[];
  skinConcerns: string[];
  keyIngredients: string[];
  imageUrl?: string;
  rating?: number | null;
  status: AdminProductStatus;
}

type PagedResponse<T> = {
  items?: T[];
  pageIndex?: number;
  pageSize?: number;
  totalRow?: number;
  totalPages?: number;
};

type ProductApiShape = Partial<AdminProductItem> & {
  suitableFor?: string[];
};

function buildFailureResponse<T>(message: string, statusCode = 500): ApiResponse<T> {
  return {
    success: false,
    statusCode,
    message,
    content: null,
  };
}

function normalizeStatus(value: string | null | undefined): AdminProductStatus {
  const normalized = value?.trim().toLowerCase();
  if (normalized === "inactive" || normalized === "out_of_stock") {
    return normalized;
  }

  return "active";
}

function normalizeStringArray(values: unknown): string[] {
  if (!Array.isArray(values)) {
    return [];
  }

  return values
    .map((item) => String(item).trim())
    .filter(Boolean);
}

function mapProduct(item: ProductApiShape): AdminProductItem {
  return {
    id: String(item.id ?? ""),
    name: String(item.name ?? ""),
    brand: String(item.brand ?? ""),
    category: String(item.category ?? ""),
    description: item.description ?? null,
    ingredient: item.ingredient ?? null,
    ingredients: normalizeStringArray(item.ingredients),
    usageGuide: item.usageGuide ?? null,
    howToUse: item.howToUse ?? null,
    usageTime: item.usageTime ?? null,
    price: typeof item.price === "number" ? item.price : Number(item.price ?? 0),
    currency: String(item.currency ?? "VND"),
    suitableSkinTypes: normalizeStringArray(item.suitableSkinTypes ?? item.suitableFor),
    skinConcerns: normalizeStringArray(item.skinConcerns),
    keyIngredients: normalizeStringArray(item.keyIngredients),
    cautions: normalizeStringArray(item.cautions),
    conflicts: normalizeStringArray(item.conflicts),
    imageUrl: item.imageUrl ?? null,
    rating: typeof item.rating === "number" ? item.rating : null,
    status: normalizeStatus(item.status),
    createdAt: String(item.createdAt ?? ""),
    updatedAt: item.updatedAt ?? null,
  };
}

function toPayload(input: AdminProductUpsertInput) {
  return {
    name: input.name.trim(),
    brand: input.brand.trim(),
    category: input.category.trim(),
    description: input.description?.trim() ?? "",
    ingredient: input.ingredient?.trim() ?? "",
    usageGuide: input.usageGuide?.trim() ?? "",
    price: input.price,
    currency: input.currency.trim().toUpperCase(),
    suitableSkinTypes: input.suitableSkinTypes,
    skinConcerns: input.skinConcerns,
    keyIngredients: input.keyIngredients,
    imageUrl: input.imageUrl?.trim() ?? "",
    rating: input.rating,
    status: input.status,
  };
}

export async function getAdminProducts(
  pageIndex = 1,
  pageSize = 8,
  options?: {
    search?: string;
    category?: string;
    status?: "all" | AdminProductStatus;
    sortBy?: string;
    sortDirection?: "asc" | "desc";
  }
): Promise<ApiResponse<AdminProductsPagedData>> {
  const params = new URLSearchParams({
    pageIndex: String(pageIndex),
    pageSize: String(pageSize),
    sortBy: options?.sortBy ?? "createdAt",
    sortDirection: options?.sortDirection ?? "desc",
  });

  const trimmedSearch = options?.search?.trim();
  if (trimmedSearch) {
    params.set("search", trimmedSearch);
  }

  const trimmedCategory = options?.category?.trim();
  if (trimmedCategory && trimmedCategory.toLowerCase() !== "all") {
    params.set("category", trimmedCategory);
  }

  if (options?.status && options.status !== "all") {
    params.set("status", options.status);
  }

  const response = await apiRequest<PagedResponse<ProductApiShape>>(
    `/admin/products?${params.toString()}`,
    { method: "GET" },
    { requiresAuth: true }
  );

  if (!response.success || !response.content) {
    return buildFailureResponse<AdminProductsPagedData>(response.message, response.statusCode);
  }

  const items = (response.content.items ?? []).map(mapProduct);
  return {
    success: true,
    statusCode: response.statusCode,
    message: response.message,
    content: {
      items,
      pageIndex: response.content.pageIndex ?? pageIndex,
      pageSize: response.content.pageSize ?? pageSize,
      totalRow: response.content.totalRow ?? items.length,
      totalPages: response.content.totalPages ?? 1,
    },
  };
}

export async function getAdminProductDetail(productId: string): Promise<ApiResponse<AdminProductItem>> {
  const response = await apiRequest<ProductApiShape>(
    `/admin/products/${productId}`,
    { method: "GET" },
    { requiresAuth: true }
  );

  if (!response.success || !response.content) {
    return buildFailureResponse<AdminProductItem>(response.message, response.statusCode);
  }

  return {
    success: true,
    statusCode: response.statusCode,
    message: response.message,
    content: mapProduct(response.content),
  };
}

export async function createAdminProduct(input: AdminProductUpsertInput): Promise<ApiResponse<AdminProductItem>> {
  const response = await apiRequest<ProductApiShape>(
    "/admin/products",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(toPayload(input)),
    },
    { requiresAuth: true }
  );

  if (!response.success || !response.content) {
    return buildFailureResponse<AdminProductItem>(response.message, response.statusCode);
  }

  return {
    success: true,
    statusCode: response.statusCode,
    message: response.message,
    content: mapProduct(response.content),
  };
}

export async function updateAdminProduct(
  productId: string,
  input: AdminProductUpsertInput
): Promise<ApiResponse<AdminProductItem>> {
  const response = await apiRequest<ProductApiShape>(
    `/admin/products/${productId}`,
    {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(toPayload(input)),
    },
    { requiresAuth: true }
  );

  if (!response.success || !response.content) {
    return buildFailureResponse<AdminProductItem>(response.message, response.statusCode);
  }

  return {
    success: true,
    statusCode: response.statusCode,
    message: response.message,
    content: mapProduct(response.content),
  };
}

export async function deleteAdminProduct(productId: string): Promise<ApiResponse<null>> {
  const response = await apiRequest<null>(
    `/admin/products/${productId}`,
    { method: "DELETE" },
    { requiresAuth: true }
  );

  if (!response.success) {
    return buildFailureResponse<null>(response.message, response.statusCode);
  }

  return {
    success: true,
    statusCode: response.statusCode,
    message: response.message,
    content: null,
  };
}
