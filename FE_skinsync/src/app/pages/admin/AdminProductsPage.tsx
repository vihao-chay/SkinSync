import { useEffect, useMemo, useState } from "react";
import {
  Archive,
  CheckCircle2,
  Eye,
  FileUp,
  ImageIcon,
  Loader2,
  Package,
  Pencil,
  Plus,
  RefreshCw,
  Search,
  ShieldCheck,
  X,
} from "lucide-react";
import { toast } from "sonner";
import { AdminLayout } from "../../components/AdminSidebar";
import { ImageWithFallback } from "../../components/figma/ImageWithFallback";
import {
  createAdminProduct,
  deleteAdminProduct,
  getAdminProductDetail,
  getAdminProducts,
  getAdminProductsSummary,
  importAdminProductsCsv,
  toggleAdminProductActive,
  updateAdminProduct,
  type AdminProductItem,
  type AdminProductUpsertInput,
  type AdminProductsSummary,
  type ProductImportResult,
} from "../../services/adminProductsService";

const CATEGORY_OPTIONS = [
  "Cleanser",
  "Toner",
  "Serum",
  "Moisturizer",
  "Sunscreen",
  "Treatment",
  "Mask",
  "Exfoliant",
  "Eye Care",
  "Oil",
  "Mist",
  "Balm",
  "Other",
] as const;

const USAGE_TIME_OPTIONS = ["Morning", "Night", "Both"] as const;
const PAGE_SIZE_OPTIONS = [10, 20, 50, 100] as const;
const SOURCE_OPTIONS = ["SkinSAFE", "IngredientChecker", "unknown"] as const;
const INPUT_BASE_CLASS =
  "w-full rounded-xl border border-[#e5e7eb] bg-white px-3.5 py-2.5 text-sm text-[#0f172a] outline-none transition focus:border-[#1f766e] focus:ring-2 focus:ring-[#1f766e]/15";

const defaultSummary: AdminProductsSummary = {
  totalProducts: 0,
  activeProducts: 0,
  verifiedProducts: 0,
  productsMissingImage: 0,
  productsMissingIngredients: 0,
};

const defaultFormState: AdminProductUpsertInput = {
  name: "",
  brand: "",
  category: "",
  description: "",
  imageUrl: "",
  price: null,
  currency: "",
  skinTypes: [],
  skinConcerns: [],
  usageTime: "",
  howToUse: "",
  ingredients: "",
  isVerified: false,
  isActive: true,
  source: "SkinSAFE",
  sourceUrl: "",
};

function splitSemiColon(value: string) {
  return value
    .split(";")
    .map((item) => item.trim())
    .filter(Boolean);
}

function joinSemiColon(values: string[]) {
  return values.join("; ");
}

function toFormState(product: AdminProductItem): AdminProductUpsertInput {
  return {
    name: product.name,
    brand: product.brand,
    category: product.category,
    description: product.description ?? "",
    imageUrl: product.imageUrl ?? "",
    price: product.price ?? null,
    currency: product.currency,
    skinTypes: product.skinTypes,
    skinConcerns: product.skinConcerns,
    usageTime: product.usageTime ?? "",
    howToUse: product.howToUse ?? "",
    ingredients: product.ingredientsText,
    isVerified: product.isVerified,
    isActive: product.isActive,
    source: product.source || "SkinSAFE",
    sourceUrl: product.sourceUrl ?? "",
  };
}

type ProductFormModalProps = {
  isOpen: boolean;
  mode: "create" | "edit";
  initialData: AdminProductUpsertInput;
  isSaving: boolean;
  onClose: () => void;
  onSubmit: (data: AdminProductUpsertInput) => void;
};

function ProductFormModal({ isOpen, mode, initialData, isSaving, onClose, onSubmit }: ProductFormModalProps) {
  const [form, setForm] = useState<AdminProductUpsertInput>(initialData);
  const [skinTypesText, setSkinTypesText] = useState(joinSemiColon(initialData.skinTypes));
  const [concernsText, setConcernsText] = useState(joinSemiColon(initialData.skinConcerns));

  useEffect(() => {
    setForm(initialData);
    setSkinTypesText(joinSemiColon(initialData.skinTypes));
    setConcernsText(joinSemiColon(initialData.skinConcerns));
  }, [initialData, isOpen]);

  if (!isOpen) {
    return null;
  }

  const submit = () => {
    onSubmit({
      ...form,
      skinTypes: splitSemiColon(skinTypesText),
      skinConcerns: splitSemiColon(concernsText),
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4 py-6">
      <div className="w-full max-w-4xl rounded-3xl border border-[#e5e7eb] bg-white shadow-2xl">
        <div className="flex items-center justify-between border-b border-[#f1f1f1] px-6 py-5">
          <div>
            <h2 className="text-lg text-[#1a1a2e]" style={{ fontWeight: 700 }}>
              {mode === "create" ? "Add Product" : "Edit Product"}
            </h2>
            <p className="text-sm text-[#6b7280]">
              Manage skincare products used by SkinSync recommendations and routines.
            </p>
          </div>
          <button onClick={onClose} className="rounded-xl p-2 text-[#6b7280] hover:bg-[#f4f5f7]">
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="grid gap-4 px-6 py-5 md:grid-cols-2">
          <Field label="Name" required>
            <input value={form.name} onChange={(event) => setForm((prev) => ({ ...prev, name: event.target.value }))} className={INPUT_BASE_CLASS} />
          </Field>
          <Field label="Brand" required>
            <input value={form.brand} onChange={(event) => setForm((prev) => ({ ...prev, brand: event.target.value }))} className={INPUT_BASE_CLASS} />
          </Field>
          <Field label="Category" required>
            <select value={form.category} onChange={(event) => setForm((prev) => ({ ...prev, category: event.target.value }))} className={INPUT_BASE_CLASS}>
              <option value="">Select category</option>
              {CATEGORY_OPTIONS.map((item) => <option key={item} value={item}>{item}</option>)}
            </select>
          </Field>
          <Field label="Usage Time">
            <select value={form.usageTime ?? ""} onChange={(event) => setForm((prev) => ({ ...prev, usageTime: event.target.value }))} className={INPUT_BASE_CLASS}>
              <option value="">Select usage time</option>
              {USAGE_TIME_OPTIONS.map((item) => <option key={item} value={item}>{item}</option>)}
            </select>
          </Field>
          <Field label="Price">
            <input type="number" min="0" step="0.01" value={form.price ?? ""} onChange={(event) => setForm((prev) => ({ ...prev, price: event.target.value ? Number(event.target.value) : null }))} className={INPUT_BASE_CLASS} />
          </Field>
          <Field label="Currency">
            <input value={form.currency} onChange={(event) => setForm((prev) => ({ ...prev, currency: event.target.value }))} className={`${INPUT_BASE_CLASS} uppercase`} />
          </Field>
          <Field label="Image URL">
            <input value={form.imageUrl ?? ""} onChange={(event) => setForm((prev) => ({ ...prev, imageUrl: event.target.value }))} className={INPUT_BASE_CLASS} />
          </Field>
          <Field label="Source">
            <input value={form.source} onChange={(event) => setForm((prev) => ({ ...prev, source: event.target.value }))} className={INPUT_BASE_CLASS} />
          </Field>
          <Field label="Source URL">
            <input value={form.sourceUrl ?? ""} onChange={(event) => setForm((prev) => ({ ...prev, sourceUrl: event.target.value }))} className={INPUT_BASE_CLASS} />
          </Field>
          <Field label="Image Preview">
            <div className="flex h-28 items-center justify-center overflow-hidden rounded-2xl border border-dashed border-[#e5e7eb] bg-[#f9fafb]">
              {form.imageUrl ? (
                <ImageWithFallback src={form.imageUrl} alt={form.name || "Product preview"} className="h-full w-full object-cover" />
              ) : (
                <div className="text-xs text-[#9ca3af]">No image preview</div>
              )}
            </div>
          </Field>
          <Field label="Skin Types" className="md:col-span-2">
            <input value={skinTypesText} onChange={(event) => setSkinTypesText(event.target.value)} placeholder="Dry; Oily; Sensitive" className={INPUT_BASE_CLASS} />
          </Field>
          <Field label="Skin Concerns" className="md:col-span-2">
            <input value={concernsText} onChange={(event) => setConcernsText(event.target.value)} placeholder="Acne; Barrier Repair" className={INPUT_BASE_CLASS} />
          </Field>
          <Field label="Description" className="md:col-span-2">
            <textarea rows={3} value={form.description ?? ""} onChange={(event) => setForm((prev) => ({ ...prev, description: event.target.value }))} className={`${INPUT_BASE_CLASS} min-h-[96px]`} />
          </Field>
          <Field label="How To Use" className="md:col-span-2">
            <textarea rows={3} value={form.howToUse ?? ""} onChange={(event) => setForm((prev) => ({ ...prev, howToUse: event.target.value }))} className={`${INPUT_BASE_CLASS} min-h-[96px]`} />
          </Field>
          <Field label="Ingredients" required className="md:col-span-2">
            <textarea rows={5} value={form.ingredients} onChange={(event) => setForm((prev) => ({ ...prev, ingredients: event.target.value }))} className={`${INPUT_BASE_CLASS} min-h-[140px]`} />
          </Field>
          <div className="md:col-span-2 flex flex-wrap items-center gap-6 rounded-2xl border border-[#eef0f4] bg-[#fafbfc] px-4 py-3">
            <label className="flex items-center gap-2 text-sm text-[#334155]">
              <input type="checkbox" checked={form.isVerified} onChange={(event) => setForm((prev) => ({ ...prev, isVerified: event.target.checked }))} />
              Verified
            </label>
            <label className="flex items-center gap-2 text-sm text-[#334155]">
              <input type="checkbox" checked={form.isActive} onChange={(event) => setForm((prev) => ({ ...prev, isActive: event.target.checked }))} />
              Active
            </label>
          </div>
        </div>

        <div className="flex items-center justify-end gap-3 border-t border-[#f1f1f1] px-6 py-4">
          <button onClick={onClose} className="rounded-xl border border-[#e5e7eb] px-4 py-2.5 text-sm text-[#475569] hover:bg-[#f8fafc]">
            Cancel
          </button>
          <button onClick={submit} disabled={isSaving} className="rounded-xl bg-[#1f766e] px-5 py-2.5 text-sm text-white disabled:opacity-60">
            {isSaving ? "Saving..." : mode === "create" ? "Create Product" : "Save Changes"}
          </button>
        </div>
      </div>
    </div>
  );
}

type ImportModalProps = {
  isOpen: boolean;
  isImporting: boolean;
  result: ProductImportResult | null;
  onClose: () => void;
  onImport: () => void;
};

function ImportModal({ isOpen, isImporting, result, onClose, onImport }: ImportModalProps) {
  if (!isOpen) {
    return null;
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 px-4">
      <div className="w-full max-w-2xl rounded-3xl border border-[#e5e7eb] bg-white shadow-2xl">
        <div className="flex items-center justify-between border-b border-[#f1f1f1] px-6 py-5">
          <div>
            <h2 className="text-lg text-[#1a1a2e]" style={{ fontWeight: 700 }}>Import CSV</h2>
            <p className="text-sm text-[#6b7280]">Import is idempotent and will not create duplicates based on name + brand.</p>
          </div>
          <button onClick={onClose} className="rounded-xl p-2 text-[#6b7280] hover:bg-[#f4f5f7]">
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="space-y-4 px-6 py-5">
          <div className="rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
            V1 import runs from backend fixed path: <span className="font-medium">Data/Import/skinsync_skinsafe_filtered.csv</span>
          </div>

          {result && (
            <div className="grid gap-3 md:grid-cols-3">
              <StatMini label="Total rows" value={result.totalRows} />
              <StatMini label="Inserted" value={result.inserted} />
              <StatMini label="Updated" value={result.updated} />
              <StatMini label="Skipped" value={result.skipped} />
              <StatMini label="Duplicates" value={result.duplicates} />
              <StatMini label="Invalid rows" value={result.invalidRows} />
            </div>
          )}

          {result && result.errors.length > 0 && (
            <div className="rounded-2xl border border-[#e5e7eb] bg-[#fafafa] p-4">
              <p className="mb-2 text-sm text-[#1f2937]" style={{ fontWeight: 600 }}>Import Errors</p>
              <div className="max-h-56 overflow-auto space-y-2 text-xs text-[#6b7280]">
                {result.errors.slice(0, 50).map((error) => (
                  <div key={error} className="rounded-lg bg-white px-3 py-2">{error}</div>
                ))}
              </div>
            </div>
          )}
        </div>

        <div className="flex items-center justify-end gap-3 border-t border-[#f1f1f1] px-6 py-4">
          <button onClick={onClose} className="rounded-xl border border-[#e5e7eb] px-4 py-2.5 text-sm text-[#475569] hover:bg-[#f8fafc]">
            Close
          </button>
          <button onClick={onImport} disabled={isImporting} className="inline-flex items-center gap-2 rounded-xl bg-[#7c5c3b] px-5 py-2.5 text-sm text-white disabled:opacity-60">
            {isImporting ? <Loader2 className="h-4 w-4 animate-spin" /> : <FileUp className="h-4 w-4" />}
            {isImporting ? "Importing..." : "Run Import"}
          </button>
        </div>
      </div>
    </div>
  );
}

function Field({ label, children, className, required = false }: { label: string; children: React.ReactNode; className?: string; required?: boolean }) {
  return (
    <label className={className}>
      <div className="mb-2 text-sm text-[#334155]" style={{ fontWeight: 600 }}>
        {label} {required && <span className="text-[#dc2626]">*</span>}
      </div>
      {children}
    </label>
  );
}

function StatCard({ label, value, hint, icon }: { label: string; value: number; hint: string; icon: React.ReactNode }) {
  return (
    <div className="rounded-2xl border border-[#e5e7eb] bg-white p-4 shadow-sm">
      <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-2xl bg-[#f5f7fa] text-[#7c5c3b]">{icon}</div>
      <div className="text-2xl text-[#1f2937]" style={{ fontWeight: 700 }}>{value}</div>
      <div className="mt-1 text-sm text-[#334155]" style={{ fontWeight: 600 }}>{label}</div>
      <div className="mt-1 text-xs text-[#64748b]">{hint}</div>
    </div>
  );
}

function StatMini({ label, value }: { label: string; value: number }) {
  return (
    <div className="rounded-2xl border border-[#e5e7eb] bg-white px-4 py-3">
      <div className="text-lg text-[#111827]" style={{ fontWeight: 700 }}>{value}</div>
      <div className="text-xs text-[#6b7280]">{label}</div>
    </div>
  );
}

function formatDate(value?: string | null) {
  if (!value) {
    return "—";
  }

  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return "—";
  }

  return date.toLocaleString("vi-VN");
}

function formatPrice(price?: number | null, currency?: string) {
  if (price == null) {
    return "—";
  }

  return `${price.toLocaleString("vi-VN")} ${currency || ""}`.trim();
}

export function AdminProductsPage() {
  const [products, setProducts] = useState<AdminProductItem[]>([]);
  const [summary, setSummary] = useState<AdminProductsSummary>(defaultSummary);
  const [isLoading, setIsLoading] = useState(true);
  const [loadError, setLoadError] = useState("");
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState<number>(20);
  const [totalPages, setTotalPages] = useState(1);
  const [totalItems, setTotalItems] = useState(0);
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("all");
  const [brand, setBrand] = useState("");
  const [usageTime, setUsageTime] = useState("all");
  const [isActive, setIsActive] = useState<"all" | "true" | "false">("all");
  const [isVerified, setIsVerified] = useState<"all" | "true" | "false">("all");
  const [source, setSource] = useState("all");
  const [hasImage, setHasImage] = useState<"all" | "true" | "false">("all");
  const [hasIngredients, setHasIngredients] = useState<"all" | "true" | "false">("all");
  const [isSaving, setIsSaving] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [editingProductId, setEditingProductId] = useState<string | null>(null);
  const [formState, setFormState] = useState<AdminProductUpsertInput>(defaultFormState);
  const [isFormOpen, setIsFormOpen] = useState(false);
  const [isImportOpen, setIsImportOpen] = useState(false);
  const [isImporting, setIsImporting] = useState(false);
  const [importResult, setImportResult] = useState<ProductImportResult | null>(null);

  const filters = useMemo(() => ({
    search,
    category,
    brand,
    usageTime,
    isActive,
    isVerified,
    source,
    hasImage,
    hasIngredients,
    sortBy: "updatedAt",
    sortDirection: "desc" as const,
  }), [search, category, brand, usageTime, isActive, isVerified, source, hasImage, hasIngredients]);

  const loadProducts = async (showRefreshing = false) => {
    if (showRefreshing) {
      setIsRefreshing(true);
    } else {
      setIsLoading(true);
    }

    const [listResult, summaryResult] = await Promise.all([
      getAdminProducts(page, pageSize, filters),
      getAdminProductsSummary(),
    ]);

    if (!listResult.success || !listResult.content) {
      setLoadError(listResult.message || "Khong the tai danh sach san pham.");
      setProducts([]);
    } else {
      setLoadError("");
      setProducts(listResult.content.items);
      setTotalItems(listResult.content.totalItems);
      setTotalPages(Math.max(1, listResult.content.totalPages));
    }

    if (summaryResult.success && summaryResult.content) {
      setSummary(summaryResult.content);
    }

    setIsLoading(false);
    setIsRefreshing(false);
  };

  useEffect(() => {
    void loadProducts();
  }, [page, pageSize, filters]);

  useEffect(() => {
    setPage(1);
  }, [search, category, brand, usageTime, isActive, isVerified, source, hasImage, hasIngredients, pageSize]);

  const openCreateModal = () => {
    setEditingProductId(null);
    setFormState(defaultFormState);
    setIsFormOpen(true);
  };

  const openEditModal = async (productId: string) => {
    const result = await getAdminProductDetail(productId);
    if (!result.success || !result.content) {
      toast.error(result.message || "Khong the tai chi tiet san pham.");
      return;
    }

    setEditingProductId(productId);
    setFormState(toFormState(result.content));
    setIsFormOpen(true);
  };

  const handleSubmit = async (input: AdminProductUpsertInput) => {
    setIsSaving(true);
    const action = editingProductId
      ? updateAdminProduct(editingProductId, input)
      : createAdminProduct(input);
    const result = await action;
    setIsSaving(false);

    if (!result.success || !result.content) {
      toast.error(result.message || "Khong the luu san pham.");
      return;
    }

    toast.success(editingProductId ? "Da cap nhat san pham." : "Da tao san pham moi.");
    setIsFormOpen(false);
    setEditingProductId(null);
    await loadProducts(true);
  };

  const handleToggleActive = async (productId: string) => {
    const result = await toggleAdminProductActive(productId);
    if (!result.success || !result.content) {
      toast.error(result.message || "Khong the doi trang thai san pham.");
      return;
    }

    toast.success(result.content.isActive ? "San pham da hien lai." : "San pham da duoc an.");
    setProducts((prev) => prev.map((item) => item.id === productId ? result.content! : item));
    await loadProducts(true);
  };

  const handleArchive = async (productId: string) => {
    const target = products.find((item) => item.id === productId);
    if (!target) {
      return;
    }

    if (!window.confirm(`Archive product "${target.name}"?`)) {
      return;
    }

    const result = await deleteAdminProduct(productId);
    if (!result.success) {
      toast.error(result.message || "Khong the archive san pham.");
      return;
    }

    toast.success("San pham da duoc archive.");
    await loadProducts(true);
  };

  const handleImport = async () => {
    setIsImporting(true);
    const result = await importAdminProductsCsv();
    setIsImporting(false);

    if (!result.success || !result.content) {
      toast.error(result.message || "Khong the import CSV.");
      return;
    }

    setImportResult(result.content);
    toast.success(`Import xong: ${result.content.inserted} inserted, ${result.content.updated} updated.`);
    await loadProducts(true);
  };

  return (
    <AdminLayout title="Product Management">
      <div className="space-y-6">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <h2 className="text-2xl text-[#111827]" style={{ fontWeight: 700 }}>Product Management</h2>
            <p className="mt-1 text-sm text-[#6b7280]">
              Manage skincare products used by SkinSync recommendations and routines.
            </p>
          </div>

          <div className="flex flex-wrap gap-3">
            <button onClick={() => void loadProducts(true)} className="inline-flex items-center gap-2 rounded-xl border border-[#e5e7eb] bg-white px-4 py-2.5 text-sm text-[#475569] hover:bg-[#f8fafc]">
              <RefreshCw className={`h-4 w-4 ${isRefreshing ? "animate-spin" : ""}`} />
              Refresh
            </button>
            <button onClick={() => setIsImportOpen(true)} className="inline-flex items-center gap-2 rounded-xl border border-[#e5e7eb] bg-white px-4 py-2.5 text-sm text-[#475569] hover:bg-[#f8fafc]">
              <FileUp className="h-4 w-4" />
              Import CSV
            </button>
            <button onClick={openCreateModal} className="inline-flex items-center gap-2 rounded-xl bg-[#1f766e] px-4 py-2.5 text-sm text-white shadow-lg shadow-[#1f766e]/20">
              <Plus className="h-4 w-4" />
              Add Product
            </button>
          </div>
        </div>

        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-5">
          <StatCard label="Total products" value={summary.totalProducts} hint="All catalog products in database" icon={<Package className="h-5 w-5" />} />
          <StatCard label="Active products" value={summary.activeProducts} hint="Visible to user-facing app" icon={<Eye className="h-5 w-5" />} />
          <StatCard label="Verified products" value={summary.verifiedProducts} hint="Marked verified in catalog" icon={<ShieldCheck className="h-5 w-5" />} />
          <StatCard label="Missing image" value={summary.productsMissingImage} hint="Need image quality follow-up" icon={<ImageIcon className="h-5 w-5" />} />
          <StatCard label="Missing ingredients" value={summary.productsMissingIngredients} hint="Need ingredient data completion" icon={<CheckCircle2 className="h-5 w-5" />} />
        </div>

        <div className="rounded-3xl border border-[#e5e7eb] bg-white p-5 shadow-sm">
          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-5">
            <div className="xl:col-span-2">
              <label className="mb-2 block text-sm text-[#334155]" style={{ fontWeight: 600 }}>Search</label>
              <div className="flex items-center gap-2 rounded-xl border border-[#e5e7eb] px-3.5 py-2.5">
                <Search className="h-4 w-4 text-[#94a3b8]" />
                <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search name, brand, ingredients..." className="w-full bg-transparent text-sm outline-none" />
              </div>
            </div>

            <FilterSelect label="Category" value={category} onChange={setCategory} options={["all", ...CATEGORY_OPTIONS]} />
            <div>
              <label className="mb-2 block text-sm text-[#334155]" style={{ fontWeight: 600 }}>Brand</label>
              <input value={brand} onChange={(event) => setBrand(event.target.value)} placeholder="Filter brand..." className={INPUT_BASE_CLASS} />
            </div>
            <FilterSelect label="Usage Time" value={usageTime} onChange={setUsageTime} options={["all", ...USAGE_TIME_OPTIONS]} />
            <FilterSelect label="Active" value={isActive} onChange={(value) => setIsActive(value as "all" | "true" | "false")} options={["all", "true", "false"]} optionLabels={{ all: "All", true: "Active", false: "Inactive" }} />
            <FilterSelect label="Verified" value={isVerified} onChange={(value) => setIsVerified(value as "all" | "true" | "false")} options={["all", "true", "false"]} optionLabels={{ all: "All", true: "Verified", false: "Unverified" }} />
            <FilterSelect label="Source" value={source} onChange={setSource} options={["all", ...SOURCE_OPTIONS]} optionLabels={{ all: "All", unknown: "Unknown" }} />
            <FilterSelect label="Has Image" value={hasImage} onChange={(value) => setHasImage(value as "all" | "true" | "false")} options={["all", "true", "false"]} optionLabels={{ all: "All", true: "Yes", false: "No" }} />
            <FilterSelect label="Has Ingredients" value={hasIngredients} onChange={(value) => setHasIngredients(value as "all" | "true" | "false")} options={["all", "true", "false"]} optionLabels={{ all: "All", true: "Yes", false: "No" }} />
          </div>

          <div className="mt-4 flex justify-end">
            <button
              onClick={() => {
                setSearch("");
                setCategory("all");
                setBrand("");
                setUsageTime("all");
                setIsActive("all");
                setIsVerified("all");
                setSource("all");
                setHasImage("all");
                setHasIngredients("all");
              }}
              className="rounded-xl border border-[#e5e7eb] px-4 py-2 text-sm text-[#475569] hover:bg-[#f8fafc]"
            >
              Reset filters
            </button>
          </div>
        </div>

        <div className="rounded-3xl border border-[#e5e7eb] bg-white shadow-sm">
          <div className="flex items-center justify-between border-b border-[#eef0f4] px-5 py-4">
            <div className="text-sm text-[#64748b]">
              Showing <span className="font-semibold text-[#0f172a]">{products.length}</span> of {totalItems} products
            </div>
            <div className="flex items-center gap-3">
              <span className="text-sm text-[#64748b]">Page size</span>
              <select value={pageSize} onChange={(event) => setPageSize(Number(event.target.value))} className="rounded-xl border border-[#e5e7eb] px-3 py-2 text-sm">
                {PAGE_SIZE_OPTIONS.map((option) => <option key={option} value={option}>{option}</option>)}
              </select>
            </div>
          </div>

          {loadError && (
            <div className="mx-5 mt-5 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
              {loadError}
            </div>
          )}

          <div className="overflow-x-auto">
            <table className="min-w-full text-sm">
              <thead className="bg-[#f8fafc] text-left text-xs uppercase tracking-wide text-[#64748b]">
                <tr>
                  <th className="px-5 py-3">Image</th>
                  <th className="px-5 py-3">Name</th>
                  <th className="px-5 py-3">Brand</th>
                  <th className="px-5 py-3">Category</th>
                  <th className="px-5 py-3">Usage Time</th>
                  <th className="px-5 py-3">Skin Concerns</th>
                  <th className="px-5 py-3">Verified</th>
                  <th className="px-5 py-3">Active</th>
                  <th className="px-5 py-3">Source</th>
                  <th className="px-5 py-3">Updated At</th>
                  <th className="px-5 py-3 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#eef0f4]">
                {isLoading && (
                  <tr>
                    <td colSpan={11} className="px-5 py-10 text-center text-[#64748b]">
                      <div className="inline-flex items-center gap-2">
                        <Loader2 className="h-4 w-4 animate-spin" />
                        Loading products...
                      </div>
                    </td>
                  </tr>
                )}

                {!isLoading && products.length === 0 && (
                  <tr>
                    <td colSpan={11} className="px-5 py-14 text-center text-[#64748b]">
                      <Package className="mx-auto mb-3 h-10 w-10 text-[#cbd5e1]" />
                      <p className="text-sm font-medium text-[#334155]">No products found</p>
                      <p className="mt-1 text-xs text-[#94a3b8]">Try changing filters or run the CSV import.</p>
                    </td>
                  </tr>
                )}

                {!isLoading && products.map((product) => (
                  <tr key={product.id} className="hover:bg-[#fcfcfd]">
                    <td className="px-5 py-4">
                      <div className="h-14 w-14 overflow-hidden rounded-2xl bg-[#f4f5f7]">
                        <ImageWithFallback src={product.imageUrl ?? ""} alt={product.name} className="h-full w-full object-cover" />
                      </div>
                    </td>
                    <td className="px-5 py-4">
                      <div className="max-w-[240px]">
                        <div className="text-[#0f172a]" style={{ fontWeight: 700 }}>{product.name}</div>
                        <div className="mt-1 text-xs text-[#64748b]">{formatPrice(product.price, product.currency)}</div>
                      </div>
                    </td>
                    <td className="px-5 py-4 text-[#334155]">{product.brand}</td>
                    <td className="px-5 py-4"><Badge>{product.category}</Badge></td>
                    <td className="px-5 py-4">{product.usageTime ? <Badge tone="secondary">{product.usageTime}</Badge> : "—"}</td>
                    <td className="px-5 py-4">
                      <div className="max-w-[200px] truncate text-[#475569]">
                        {product.skinConcerns.length > 0 ? product.skinConcerns.join("; ") : "—"}
                      </div>
                    </td>
                    <td className="px-5 py-4">{product.isVerified ? <Badge tone="success">Verified</Badge> : <Badge tone="muted">No</Badge>}</td>
                    <td className="px-5 py-4">{product.isActive ? <Badge tone="success">Active</Badge> : <Badge tone="danger">Hidden</Badge>}</td>
                    <td className="px-5 py-4 text-[#475569]">{product.source || "unknown"}</td>
                    <td className="px-5 py-4 text-[#475569]">{formatDate(product.updatedAt ?? product.createdAt)}</td>
                    <td className="px-5 py-4">
                      <div className="flex justify-end gap-2">
                        <button onClick={() => void openEditModal(product.id)} className="rounded-xl border border-[#e5e7eb] p-2 text-[#475569] hover:bg-[#f8fafc]">
                          <Pencil className="h-4 w-4" />
                        </button>
                        <button onClick={() => void handleToggleActive(product.id)} className="rounded-xl border border-[#e5e7eb] p-2 text-[#475569] hover:bg-[#f8fafc]">
                          {product.isActive ? <Eye className="h-4 w-4" /> : <RefreshCw className="h-4 w-4" />}
                        </button>
                        <button onClick={() => void handleArchive(product.id)} className="rounded-xl border border-[#e5e7eb] p-2 text-[#b45309] hover:bg-[#fff7ed]">
                          <Archive className="h-4 w-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="flex items-center justify-between border-t border-[#eef0f4] px-5 py-4 text-sm">
            <span className="text-[#64748b]">Page {page} of {totalPages}</span>
            <div className="flex items-center gap-2">
              <button onClick={() => setPage((prev) => Math.max(1, prev - 1))} disabled={page <= 1} className="rounded-xl border border-[#e5e7eb] px-3 py-2 disabled:opacity-40">
                Previous
              </button>
              <button onClick={() => setPage((prev) => Math.min(totalPages, prev + 1))} disabled={page >= totalPages} className="rounded-xl border border-[#e5e7eb] px-3 py-2 disabled:opacity-40">
                Next
              </button>
            </div>
          </div>
        </div>
      </div>

      <ProductFormModal
        isOpen={isFormOpen}
        mode={editingProductId ? "edit" : "create"}
        initialData={formState}
        isSaving={isSaving}
        onClose={() => {
          setIsFormOpen(false);
          setEditingProductId(null);
        }}
        onSubmit={(data) => void handleSubmit(data)}
      />

      <ImportModal
        isOpen={isImportOpen}
        isImporting={isImporting}
        result={importResult}
        onClose={() => setIsImportOpen(false)}
        onImport={() => void handleImport()}
      />
    </AdminLayout>
  );
}

function FilterSelect({
  label,
  value,
  onChange,
  options,
  optionLabels = {},
}: {
  label: string;
  value: string;
  onChange: (value: string) => void;
  options: readonly string[];
  optionLabels?: Record<string, string>;
}) {
  return (
    <div>
      <label className="mb-2 block text-sm text-[#334155]" style={{ fontWeight: 600 }}>{label}</label>
      <select value={value} onChange={(event) => onChange(event.target.value)} className={INPUT_BASE_CLASS}>
        {options.map((option) => (
          <option key={option} value={option}>{optionLabels[option] ?? option}</option>
        ))}
      </select>
    </div>
  );
}

function Badge({ children, tone = "default" }: { children: React.ReactNode; tone?: "default" | "secondary" | "success" | "danger" | "muted" }) {
  const toneClass = {
    default: "bg-[#f8f1e8] text-[#7c5c3b] border-[#ead9c3]",
    secondary: "bg-[#eef6ff] text-[#27548a] border-[#d2e7ff]",
    success: "bg-emerald-50 text-emerald-700 border-emerald-200",
    danger: "bg-rose-50 text-rose-700 border-rose-200",
    muted: "bg-slate-100 text-slate-600 border-slate-200",
  }[tone];

  return (
    <span className={`inline-flex rounded-full border px-2.5 py-1 text-xs ${toneClass}`}>
      {children}
    </span>
  );
}
