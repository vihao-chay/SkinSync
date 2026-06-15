import { useEffect, useMemo, useState } from "react";
import {
  ChevronDown,
  Loader2,
  Package,
  Pencil,
  Plus,
  Search,
  Trash2,
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
  updateAdminProduct,
  type AdminProductItem,
  type AdminProductStatus,
  type AdminProductUpsertInput,
} from "../../services/adminProductsService";

const PAGE_SIZE = 8;

const statusStyle: Record<AdminProductStatus, string> = {
  active: "bg-emerald-50 text-emerald-600 border border-emerald-100",
  inactive: "bg-[#f3f4f6] text-[#6b7280] border border-[#e5e7eb]",
  out_of_stock: "bg-red-50 text-red-500 border border-red-100",
};

const statusLabel: Record<AdminProductStatus, string> = {
  active: "Hoạt động",
  inactive: "Tạm ẩn",
  out_of_stock: "Hết hàng",
};

const defaultFormState: AdminProductUpsertInput = {
  name: "",
  brand: "",
  category: "",
  description: "",
  ingredient: "",
  usageGuide: "",
  price: 0,
  currency: "VND",
  suitableSkinTypes: [],
  skinConcerns: [],
  keyIngredients: [],
  imageUrl: "",
  rating: null,
  status: "active",
};

function splitCsv(value: string) {
  return value
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function joinCsv(values: string[]) {
  return values.join(", ");
}

function toFormState(product: AdminProductItem): AdminProductUpsertInput {
  return {
    name: product.name,
    brand: product.brand,
    category: product.category,
    description: product.description ?? "",
    ingredient: product.ingredient ?? joinCsv(product.ingredients),
    usageGuide: product.howToUse ?? product.usageGuide ?? "",
    price: product.price,
    currency: product.currency,
    suitableSkinTypes: product.suitableSkinTypes,
    skinConcerns: product.skinConcerns,
    keyIngredients: product.keyIngredients,
    imageUrl: product.imageUrl ?? "",
    rating: product.rating ?? null,
    status: product.status,
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

function ProductFormModal({
  isOpen,
  mode,
  initialData,
  isSaving,
  onClose,
  onSubmit,
}: ProductFormModalProps) {
  const [form, setForm] = useState<AdminProductUpsertInput>(initialData);
  const [skinTypesText, setSkinTypesText] = useState(joinCsv(initialData.suitableSkinTypes));
  const [concernsText, setConcernsText] = useState(joinCsv(initialData.skinConcerns));
  const [keyIngredientsText, setKeyIngredientsText] = useState(joinCsv(initialData.keyIngredients));

  useEffect(() => {
    setForm(initialData);
    setSkinTypesText(joinCsv(initialData.suitableSkinTypes));
    setConcernsText(joinCsv(initialData.skinConcerns));
    setKeyIngredientsText(joinCsv(initialData.keyIngredients));
  }, [initialData, isOpen]);

  if (!isOpen) {
    return null;
  }

  const submit = () => {
    onSubmit({
      ...form,
      suitableSkinTypes: splitCsv(skinTypesText),
      skinConcerns: splitCsv(concernsText),
      keyIngredients: splitCsv(keyIngredientsText),
    });
  };

  const title = mode === "create" ? "Thêm Sản Phẩm Mới" : "Chỉnh Sửa Sản Phẩm";

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 backdrop-blur-sm px-4">
      <div className="w-full max-w-3xl rounded-3xl border border-[#e5e7eb] bg-white shadow-2xl">
        <div className="flex items-center justify-between border-b border-[#f1f1f1] px-6 py-5">
          <div>
            <h2 className="text-lg text-[#1a1a2e]" style={{ fontWeight: 600 }}>{title}</h2>
            <p className="text-sm text-[#6b7280]">Quản lý catalog thật cho mobile Products flow.</p>
          </div>
          <button
            onClick={onClose}
            disabled={isSaving}
            className="rounded-xl p-2 text-[#6b7280] hover:bg-[#f4f5f7] disabled:opacity-50"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="grid gap-4 px-6 py-5 md:grid-cols-2">
          <Field label="Tên sản phẩm">
            <input
              value={form.name}
              onChange={(event) => setForm((prev) => ({ ...prev, name: event.target.value }))}
              className="w-full rounded-xl border border-[#e5e7eb] px-4 py-3 text-sm outline-none focus:border-[#c4a882]"
            />
          </Field>
          <Field label="Thương hiệu">
            <input
              value={form.brand}
              onChange={(event) => setForm((prev) => ({ ...prev, brand: event.target.value }))}
              className="w-full rounded-xl border border-[#e5e7eb] px-4 py-3 text-sm outline-none focus:border-[#c4a882]"
            />
          </Field>
          <Field label="Category">
            <input
              value={form.category}
              onChange={(event) => setForm((prev) => ({ ...prev, category: event.target.value }))}
              className="w-full rounded-xl border border-[#e5e7eb] px-4 py-3 text-sm outline-none focus:border-[#c4a882]"
            />
          </Field>
          <Field label="Status">
            <select
              value={form.status}
              onChange={(event) => setForm((prev) => ({ ...prev, status: event.target.value as AdminProductStatus }))}
              className="w-full rounded-xl border border-[#e5e7eb] px-4 py-3 text-sm outline-none focus:border-[#c4a882]"
            >
              <option value="active">Active</option>
              <option value="inactive">Inactive</option>
              <option value="out_of_stock">Out of stock</option>
            </select>
          </Field>
          <Field label="Giá">
            <input
              type="number"
              min="0"
              value={form.price}
              onChange={(event) => setForm((prev) => ({ ...prev, price: Number(event.target.value || 0) }))}
              className="w-full rounded-xl border border-[#e5e7eb] px-4 py-3 text-sm outline-none focus:border-[#c4a882]"
            />
          </Field>
          <Field label="Currency">
            <input
              value={form.currency}
              onChange={(event) => setForm((prev) => ({ ...prev, currency: event.target.value }))}
              className="w-full rounded-xl border border-[#e5e7eb] px-4 py-3 text-sm uppercase outline-none focus:border-[#c4a882]"
            />
          </Field>
          <Field label="Rating">
            <input
              type="number"
              min="0"
              max="5"
              step="0.1"
              value={form.rating ?? ""}
              onChange={(event) => setForm((prev) => ({
                ...prev,
                rating: event.target.value ? Number(event.target.value) : null,
              }))}
              className="w-full rounded-xl border border-[#e5e7eb] px-4 py-3 text-sm outline-none focus:border-[#c4a882]"
            />
          </Field>
          <Field label="Image URL">
            <input
              value={form.imageUrl ?? ""}
              onChange={(event) => setForm((prev) => ({ ...prev, imageUrl: event.target.value }))}
              className="w-full rounded-xl border border-[#e5e7eb] px-4 py-3 text-sm outline-none focus:border-[#c4a882]"
            />
          </Field>
          <Field label="Suitable skin types" className="md:col-span-2">
            <input
              value={skinTypesText}
              onChange={(event) => setSkinTypesText(event.target.value)}
              placeholder="Oily, Dry, Sensitive"
              className="w-full rounded-xl border border-[#e5e7eb] px-4 py-3 text-sm outline-none focus:border-[#c4a882]"
            />
          </Field>
          <Field label="Skin concerns" className="md:col-span-2">
            <input
              value={concernsText}
              onChange={(event) => setConcernsText(event.target.value)}
              placeholder="Acne, Barrier support"
              className="w-full rounded-xl border border-[#e5e7eb] px-4 py-3 text-sm outline-none focus:border-[#c4a882]"
            />
          </Field>
          <Field label="Key ingredients" className="md:col-span-2">
            <input
              value={keyIngredientsText}
              onChange={(event) => setKeyIngredientsText(event.target.value)}
              placeholder="Niacinamide, Ceramide"
              className="w-full rounded-xl border border-[#e5e7eb] px-4 py-3 text-sm outline-none focus:border-[#c4a882]"
            />
          </Field>
          <Field label="Description" className="md:col-span-2">
            <textarea
              rows={3}
              value={form.description ?? ""}
              onChange={(event) => setForm((prev) => ({ ...prev, description: event.target.value }))}
              className="w-full rounded-xl border border-[#e5e7eb] px-4 py-3 text-sm outline-none focus:border-[#c4a882]"
            />
          </Field>
          <Field label="Ingredients text" className="md:col-span-2">
            <textarea
              rows={3}
              value={form.ingredient ?? ""}
              onChange={(event) => setForm((prev) => ({ ...prev, ingredient: event.target.value }))}
              className="w-full rounded-xl border border-[#e5e7eb] px-4 py-3 text-sm outline-none focus:border-[#c4a882]"
            />
          </Field>
          <Field label="How to use" className="md:col-span-2">
            <textarea
              rows={3}
              value={form.usageGuide ?? ""}
              onChange={(event) => setForm((prev) => ({ ...prev, usageGuide: event.target.value }))}
              className="w-full rounded-xl border border-[#e5e7eb] px-4 py-3 text-sm outline-none focus:border-[#c4a882]"
            />
          </Field>
        </div>

        <div className="flex items-center justify-end gap-3 border-t border-[#f1f1f1] px-6 py-5">
          <button
            onClick={onClose}
            disabled={isSaving}
            className="rounded-xl border border-[#e5e7eb] px-4 py-2.5 text-sm text-[#6b7280] hover:bg-[#f4f5f7] disabled:opacity-50"
          >
            Hủy
          </button>
          <button
            onClick={submit}
            disabled={isSaving || !form.name.trim() || !form.brand.trim() || !form.category.trim()}
            className="flex items-center gap-2 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] px-5 py-2.5 text-sm text-white shadow-lg shadow-[#c4a882]/25 disabled:opacity-50"
          >
            {isSaving && <Loader2 className="w-4 h-4 animate-spin" />}
            {mode === "create" ? "Lưu sản phẩm" : "Cập nhật"}
          </button>
        </div>
      </div>
    </div>
  );
}

function Field({
  label,
  children,
  className = "",
}: {
  label: string;
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <label className={`block ${className}`}>
      <span className="mb-1.5 block text-xs text-[#6b7280]">{label}</span>
      {children}
    </label>
  );
}

export function AdminProductsPage() {
  const [products, setProducts] = useState<AdminProductItem[]>([]);
  const [pageIndex, setPageIndex] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalRow, setTotalRow] = useState(0);
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState<"all" | AdminProductStatus>("all");
  const [categoryFilter, setCategoryFilter] = useState("all");
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);
  const [isDeletingId, setIsDeletingId] = useState<string | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [editingProductId, setEditingProductId] = useState<string | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formState, setFormState] = useState<AdminProductUpsertInput>(defaultFormState);

  const categories = useMemo(() => {
    const values = Array.from(new Set(products.map((item) => item.category).filter(Boolean)));
    return ["all", ...values];
  }, [products]);

  useEffect(() => {
    setPageIndex(1);
  }, [search, statusFilter, categoryFilter]);

  useEffect(() => {
    let active = true;

    const load = async () => {
      setIsLoading(true);
      setLoadError(null);
      const result = await getAdminProducts(pageIndex, PAGE_SIZE, {
        search,
        status: statusFilter,
        category: categoryFilter,
      });

      if (!active) {
        return;
      }

      if (!result.success || !result.content) {
        setProducts([]);
        setTotalPages(1);
        setTotalRow(0);
        setLoadError(result.message || "Không thể tải danh sách sản phẩm.");
      } else {
        setProducts(result.content.items);
        setPageIndex(result.content.pageIndex);
        setTotalPages(Math.max(1, result.content.totalPages));
        setTotalRow(result.content.totalRow);
      }

      setIsLoading(false);
    };

    load();
    return () => {
      active = false;
    };
  }, [pageIndex, search, statusFilter, categoryFilter]);

  const filteredProducts = useMemo(() => products, [products]);

  const openCreateModal = () => {
    setEditingProductId(null);
    setFormState(defaultFormState);
    setIsModalOpen(true);
  };

  const openEditModal = async (productId: string) => {
    setIsSaving(true);
    const result = await getAdminProductDetail(productId);
    setIsSaving(false);

    if (!result.success || !result.content) {
      toast.error(result.message || "Không thể tải chi tiết sản phẩm.");
      return;
    }

    setEditingProductId(productId);
    setFormState(toFormState(result.content));
    setIsModalOpen(true);
  };

  const handleSubmit = async (input: AdminProductUpsertInput) => {
    setIsSaving(true);
    const result = editingProductId
      ? await updateAdminProduct(editingProductId, input)
      : await createAdminProduct(input);

    setIsSaving(false);

    if (!result.success || !result.content) {
      toast.error(result.message || "Không thể lưu sản phẩm.");
      return;
    }

    setIsModalOpen(false);
    setEditingProductId(null);
    toast.success(editingProductId ? "Đã cập nhật sản phẩm." : "Đã tạo sản phẩm.");

    const refreshed = await getAdminProducts(pageIndex, PAGE_SIZE, {
      search,
      status: statusFilter,
      category: categoryFilter,
    });
    if (refreshed.success && refreshed.content) {
      setProducts(refreshed.content.items);
      setPageIndex(refreshed.content.pageIndex);
      setTotalPages(Math.max(1, refreshed.content.totalPages));
      setTotalRow(refreshed.content.totalRow);
    }
  };

  const handleDelete = async (productId: string) => {
    const target = products.find((item) => item.id === productId);
    if (!target) {
      return;
    }

    if (!window.confirm(`Xóa sản phẩm "${target.name}"?`)) {
      return;
    }

    setIsDeletingId(productId);
    const result = await deleteAdminProduct(productId);
    setIsDeletingId(null);

    if (!result.success) {
      toast.error(result.message || "Không thể xóa sản phẩm.");
      return;
    }

    toast.success("Đã xóa sản phẩm.");
    setProducts((prev) => prev.filter((item) => item.id !== productId));
    setTotalRow((prev) => Math.max(0, prev - 1));
  };

  return (
    <AdminLayout title="Quản Lý Kho Sản Phẩm">
      <div className="mb-6 flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div className="flex flex-wrap items-center gap-3">
          <div className="flex min-w-[240px] items-center gap-2 rounded-xl border border-[#e5e7eb] bg-white px-3.5 py-2.5 text-sm shadow-sm">
            <Search className="w-4 h-4 text-[#9ca3af]" />
            <input
              value={search}
              onChange={(event) => setSearch(event.target.value)}
              placeholder="Tìm sản phẩm, thương hiệu..."
              className="w-full bg-transparent outline-none placeholder:text-[#9ca3af]"
            />
          </div>

          <select
            value={statusFilter}
            onChange={(event) => setStatusFilter(event.target.value as "all" | AdminProductStatus)}
            className="rounded-xl border border-[#e5e7eb] bg-white px-3.5 py-2.5 text-sm shadow-sm outline-none"
          >
            <option value="all">Tất cả trạng thái</option>
            <option value="active">Active</option>
            <option value="inactive">Inactive</option>
            <option value="out_of_stock">Out of stock</option>
          </select>

          <div className="relative">
            <select
              value={categoryFilter}
              onChange={(event) => setCategoryFilter(event.target.value)}
              className="appearance-none rounded-xl border border-[#e5e7eb] bg-white px-3.5 py-2.5 pr-9 text-sm shadow-sm outline-none"
            >
              <option value="all">Tất cả category</option>
              {categories.filter((item) => item !== "all").map((category) => (
                <option key={category} value={category}>{category}</option>
              ))}
            </select>
            <ChevronDown className="pointer-events-none absolute right-3 top-1/2 w-4 h-4 -translate-y-1/2 text-[#9ca3af]" />
          </div>
        </div>

        <button
          onClick={openCreateModal}
          className="flex items-center gap-2 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] px-5 py-2.5 text-sm text-white shadow-lg shadow-[#c4a882]/25"
        >
          <Plus className="w-4 h-4" />
          Thêm Sản Phẩm Mới
        </button>
      </div>

      <div className="mb-4 flex items-center gap-3 text-sm text-[#6b7280]">
        <Package className="w-4 h-4" />
        <span>Hiển thị <span className="text-[#1a1a2e]" style={{ fontWeight: 600 }}>{filteredProducts.length}</span> / {totalRow} sản phẩm</span>
      </div>

      {loadError && (
        <div className="mb-4 rounded-xl border border-red-100 bg-red-50 px-4 py-3 text-sm text-red-600">
          {loadError}
        </div>
      )}

      <div className="overflow-hidden rounded-2xl border border-[#e5e7eb] bg-white shadow-sm">
        <div className="grid grid-cols-[56px_2fr_1fr_1fr_120px_120px] gap-4 border-b border-[#e5e7eb] bg-[#f8f9fb] px-5 py-3.5 text-xs uppercase tracking-wide text-[#6b7280]">
          <div>Ảnh</div>
          <div>Sản phẩm</div>
          <div>Category</div>
          <div>Skin types</div>
          <div>Trạng thái</div>
          <div className="text-right">Hành động</div>
        </div>

        <div className="divide-y divide-[#f3f4f6]">
          {isLoading && (
            <div className="px-5 py-8 text-sm text-[#6b7280]">Đang tải sản phẩm...</div>
          )}

          {!isLoading && filteredProducts.length === 0 && (
            <div className="py-16 text-center text-[#6b7280]">
              <Package className="mx-auto mb-3 w-10 h-10 text-[#d1d5db]" />
              <p>Không tìm thấy sản phẩm nào</p>
            </div>
          )}

          {!isLoading && filteredProducts.map((product) => (
            <div
              key={product.id}
              className={`grid grid-cols-[56px_2fr_1fr_1fr_120px_120px] gap-4 px-5 py-4 items-center hover:bg-[#fafafa] ${
                isDeletingId === product.id ? "opacity-50" : ""
              }`}
            >
              <div className="w-11 h-11 overflow-hidden rounded-xl bg-[#f4f5f7]">
                <ImageWithFallback
                  src={product.imageUrl ?? ""}
                  alt={product.name}
                  className="w-full h-full object-cover"
                />
              </div>

              <div>
                <p className="text-sm text-[#1a1a2e]" style={{ fontWeight: 600 }}>{product.name}</p>
                <p className="text-xs text-[#9ca3af]">{product.brand}</p>
                <p className="mt-1 text-xs text-[#6b7280]">
                  {product.price.toLocaleString("vi-VN")} {product.currency}
                </p>
              </div>

              <div>
                <span className="rounded-full bg-[#f3f4f6] px-2.5 py-1 text-xs text-[#6b7280]">
                  {product.category}
                </span>
              </div>

              <div className="flex flex-wrap gap-1.5">
                {(product.suitableSkinTypes.length > 0 ? product.suitableSkinTypes : ["Chưa có"])
                  .slice(0, 2)
                  .map((skinType) => (
                    <span
                      key={skinType}
                      className="rounded-full border border-[#e8d5b7] bg-[#fff8f1] px-2 py-0.5 text-[11px] text-[#8c6e52]"
                    >
                      {skinType}
                    </span>
                  ))}
              </div>

              <div>
                <span className={`rounded-full px-2.5 py-1 text-xs ${statusStyle[product.status]}`}>
                  {statusLabel[product.status]}
                </span>
              </div>

              <div className="flex items-center justify-end gap-2">
                <button
                  onClick={() => void openEditModal(product.id)}
                  className="flex h-8 w-8 items-center justify-center rounded-xl bg-[#f4f5f7] text-[#6b7280] hover:text-[#c4a882]"
                >
                  <Pencil className="w-3.5 h-3.5" />
                </button>
                <button
                  onClick={() => void handleDelete(product.id)}
                  disabled={isDeletingId === product.id}
                  className="flex h-8 w-8 items-center justify-center rounded-xl bg-[#f4f5f7] text-[#6b7280] hover:text-red-500 disabled:opacity-50"
                >
                  {isDeletingId === product.id ? <Loader2 className="w-3.5 h-3.5 animate-spin" /> : <Trash2 className="w-3.5 h-3.5" />}
                </button>
              </div>
            </div>
          ))}
        </div>

        <div className="flex items-center justify-between border-t border-[#f3f4f6] px-5 py-4 text-sm text-[#6b7280]">
          <span>Trang {pageIndex} / {totalPages}</span>
          <div className="flex items-center gap-2">
            <button
              onClick={() => setPageIndex((prev) => Math.max(1, prev - 1))}
              disabled={pageIndex <= 1}
              className="rounded-lg px-3 py-1.5 text-xs hover:bg-[#f4f5f7] disabled:opacity-40"
            >
              {'<'}
            </button>
            <button
              onClick={() => setPageIndex((prev) => Math.min(totalPages, prev + 1))}
              disabled={pageIndex >= totalPages}
              className="rounded-lg px-3 py-1.5 text-xs hover:bg-[#f4f5f7] disabled:opacity-40"
            >
              {'>'}
            </button>
          </div>
        </div>
      </div>

      <ProductFormModal
        isOpen={isModalOpen}
        mode={editingProductId ? "edit" : "create"}
        initialData={formState}
        isSaving={isSaving}
        onClose={() => {
          setIsModalOpen(false);
          setEditingProductId(null);
        }}
        onSubmit={(data) => void handleSubmit(data)}
      />
    </AdminLayout>
  );
}
