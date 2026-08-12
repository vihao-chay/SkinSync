import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export interface AdminProductItem {
  id: string;
  name: string;
  brand: string;
  category: string;
  description?: string | null;
  imageUrl?: string | null;
  price?: number | null;
  currency: string;
  skinTypes: string[];
  skinConcerns: string[];
  usageTime?: string | null;
  howToUse?: string | null;
  ingredientsText: string;
  ingredients: string[];
  isVerified: boolean;
  isActive: boolean;
  source: string;
  sourceUrl?: string | null;
  createdAt: string;
  updatedAt?: string | null;
}

export interface AdminProductsSummary {
  totalProducts: number;
  activeProducts: number;
  verifiedProducts: number;
  productsMissingImage: number;
  productsMissingIngredients: number;
}

export interface AdminProductsPagedData {
  items: AdminProductItem[];
  page: number;
  pageSize: number;
  totalItems: number;
  totalPages: number;
}

export interface ProductImportResult {
  totalRows: number;
  inserted: number;
  updated: number;
  skipped: number;
  duplicates: number;
  invalidRows: number;
  errors: string[];
}

export interface AdminProductUpsertInput {
  name: string;
  brand: string;
  category: string;
  description?: string;
  imageUrl?: string;
  price?: number | null;
  currency: string;
  skinTypes: string[];
  skinConcerns: string[];
  usageTime?: string;
  howToUse?: string;
  ingredients: string;
  isVerified: boolean;
  isActive: boolean;
  source: string;
  sourceUrl?: string;
}

type ProductApiShape = Partial<AdminProductItem> & {
  ingredientsText?: string;
};

type PagedResponse<T> = {
  items?: T[];
  page?: number;
  pageSize?: number;
  totalItems?: number;
  totalPages?: number;
};

function buildFailureResponse<T>(message: string, statusCode = 500): ApiResponse<T> {
  return {
    success: false,
    statusCode,
    message,
    content: null,
  };
}

function normalizeStringArray(values: unknown): string[] {
  if (!Array.isArray(values)) {
    return [];
  }

  return values
    .map((item) => String(item).trim())
    .filter(Boolean);
}

function splitIngredients(text: string | null | undefined): string[] {
  if (!text) {
    return [];
  }

  return text
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function mapProduct(item: ProductApiShape): AdminProductItem {
  const ingredientsText = String(item.ingredientsText ?? "");
  return {
    id: String(item.id ?? ""),
    name: String(item.name ?? ""),
    brand: String(item.brand ?? ""),
    category: String(item.category ?? ""),
    description: item.description ?? null,
    imageUrl: item.imageUrl ?? null,
    price: typeof item.price === "number" ? item.price : item.price ? Number(item.price) : null,
    currency: String(item.currency ?? ""),
    skinTypes: normalizeStringArray(item.skinTypes),
    skinConcerns: normalizeStringArray(item.skinConcerns),
    usageTime: item.usageTime ?? null,
    howToUse: item.howToUse ?? null,
    ingredientsText,
    ingredients: normalizeStringArray(item.ingredients).length > 0
      ? normalizeStringArray(item.ingredients)
      : splitIngredients(ingredientsText),
    isVerified: Boolean(item.isVerified),
    isActive: Boolean(item.isActive),
    source: String(item.source ?? ""),
    sourceUrl: item.sourceUrl ?? null,
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
    imageUrl: input.imageUrl?.trim() ?? "",
    price: input.price ?? null,
    currency: input.currency.trim().toUpperCase(),
    skinTypes: input.skinTypes,
    skinConcerns: input.skinConcerns,
    usageTime: input.usageTime?.trim() ?? "",
    howToUse: input.howToUse?.trim() ?? "",
    ingredients: input.ingredients.trim(),
    isVerified: input.isVerified,
    isActive: input.isActive,
    source: input.source.trim(),
    sourceUrl: input.sourceUrl?.trim() ?? "",
  };
}

export async function getAdminProducts(
  page = 1,
  pageSize = 20,
  options?: {
    search?: string;
    category?: string;
    brand?: string;
    usageTime?: string;
    isActive?: "all" | "true" | "false";
    isVerified?: "all" | "true" | "false";
    source?: string;
    hasImage?: "all" | "true" | "false";
    hasIngredients?: "all" | "true" | "false";
    sortBy?: string;
    sortDirection?: "asc" | "desc";
  }
): Promise<ApiResponse<AdminProductsPagedData>> {
  const params = new URLSearchParams({
    pageIndex: String(page),
    pageSize: String(pageSize),
    sortBy: options?.sortBy ?? "updatedAt",
    sortDirection: options?.sortDirection ?? "desc",
  });

  const appendIfPresent = (key: string, value?: string) => {
    if (value && value.trim() && value !== "all") {
      params.set(key, value.trim());
    }
  };

  appendIfPresent("search", options?.search);
  appendIfPresent("category", options?.category);
  appendIfPresent("brand", options?.brand);
  appendIfPresent("usageTime", options?.usageTime);
  appendIfPresent("source", options?.source);
  appendIfPresent("isActive", options?.isActive);
  appendIfPresent("isVerified", options?.isVerified);
  appendIfPresent("hasImage", options?.hasImage);
  appendIfPresent("hasIngredients", options?.hasIngredients);

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
      page: response.content.page ?? page,
      pageSize: response.content.pageSize ?? pageSize,
      totalItems: response.content.totalItems ?? items.length,
      totalPages: response.content.totalPages ?? 1,
    },
  };
}

export async function getAdminProductsSummary(): Promise<ApiResponse<AdminProductsSummary>> {
  return apiRequest<AdminProductsSummary>("/admin/products/summary", { method: "GET" }, { requiresAuth: true });
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

export async function updateAdminProduct(productId: string, input: AdminProductUpsertInput): Promise<ApiResponse<AdminProductItem>> {
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

export async function toggleAdminProductActive(productId: string): Promise<ApiResponse<AdminProductItem>> {
  const response = await apiRequest<ProductApiShape>(
    `/admin/products/${productId}/toggle-active`,
    { method: "PATCH" },
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

export async function importAdminProductsCsv(): Promise<ApiResponse<ProductImportResult>> {
  return apiRequest<ProductImportResult>(
    "/admin/products/import-csv",
    { method: "POST" },
    { requiresAuth: true }
  );
}
