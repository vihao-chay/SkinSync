import type { ApiResponse } from "./authService";
import { apiRequest } from "./apiClient";

export type IngredientConflictSeverity = "warning" | "danger";

export interface IngredientConflictWarning {
  productAId: string;
  productAName: string;
  productBId: string;
  productBName: string;
  ingredientA: string;
  ingredientB: string;
  severity: IngredientConflictSeverity;
  message: string;
  recommendation: string;
}

export interface IngredientConflictCheckResponse {
  productCount: number;
  warningCount: number;
  warnings: IngredientConflictWarning[];
}

export async function checkIngredientConflictsApi(
  productIds: string[]
): Promise<ApiResponse<IngredientConflictCheckResponse>> {
  return apiRequest<IngredientConflictCheckResponse>(
    "/ingredient-conflicts/check",
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ productIds }),
    },
    { requiresAuth: true }
  );
}
