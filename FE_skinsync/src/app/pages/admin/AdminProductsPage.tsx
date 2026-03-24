import { useState } from "react";
import {
  Plus,
  Pencil,
  Trash2,
  Search,
  ChevronDown,
  Filter,
  Star,
  Package,
  ArrowUpDown,
  X,
} from "lucide-react";
import { AdminLayout } from "../../components/AdminSidebar";
import { ImageWithFallback } from "../../components/figma/ImageWithFallback";

type SkinTag = "Da Dầu" | "Da Khô" | "Hỗn Hợp" | "Nhạy Cảm" | "Mụn" | "Lão Hóa" | "Thâm Nám" | "Mọi Loại Da";

interface Product {
  id: number;
  image: string;
  name: string;
  brand: string;
  category: string;
  skinTypes: SkinTag[];
  rating: number;
  reviews: number;
  status: "active" | "draft" | "out_of_stock";
}

const tagColors: Record<SkinTag, string> = {
  "Da Dầu": "bg-blue-50 text-blue-600 border-blue-100",
  "Da Khô": "bg-amber-50 text-amber-600 border-amber-100",
  "Hỗn Hợp": "bg-purple-50 text-purple-600 border-purple-100",
  "Nhạy Cảm": "bg-pink-50 text-pink-600 border-pink-100",
  "Mụn": "bg-red-50 text-red-500 border-red-100",
  "Lão Hóa": "bg-emerald-50 text-emerald-600 border-emerald-100",
  "Thâm Nám": "bg-orange-50 text-orange-600 border-orange-100",
  "Mọi Loại Da": "bg-[#c4a882]/8 text-[#c4a882] border-[#c4a882]/15",
};

const statusStyle: Record<string, string> = {
  active: "bg-emerald-50 text-emerald-600 border border-emerald-100",
  draft: "bg-[#f3f4f6] text-[#6b7280] border border-[#e5e7eb]",
  out_of_stock: "bg-red-50 text-red-500 border border-red-100",
};
const statusLabel: Record<string, string> = {
  active: "Hoạt Động",
  draft: "Nháp",
  out_of_stock: "Hết Hàng",
};

const products: Product[] = [
  {
    id: 1,
    image: "https://images.unsplash.com/photo-1677735476292-0fc57ab097b2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMHByb2R1Y3QlMjBib3R0bGUlMjBzZXJ1bSUyMGNsZWFuc2VyJTIwd2hpdGUlMjBtaW5pbWFsfGVufDF8fHx8MTc3NDA2NDU0Mnww&ixlib=rb-4.1.0&q=80&w=400",
    name: "Sữa Rửa Mặt CeraVe",
    brand: "CeraVe",
    category: "Sữa Rửa Mặt",
    skinTypes: ["Da Dầu", "Mụn", "Hỗn Hợp"],
    rating: 4.8,
    reviews: 2140,
    status: "active",
  },
  {
    id: 2,
    image: "https://images.unsplash.com/photo-1763503839418-2b45c3d7a3c3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb2lzdHVyaXplciUyMGNyZWFtJTIwamFyJTIwbHV4dXJ5JTIwc2tpbmNhcmUlMjBwcm9kdWN0fGVufDF8fHx8MTc3NDA2NDU0NHww&ixlib=rb-4.1.0&q=80&w=400",
    name: "Kem Dưỡng Klairs Midnight",
    brand: "Klairs",
    category: "Dưỡng Ẩm",
    skinTypes: ["Da Khô", "Nhạy Cảm"],
    rating: 4.7,
    reviews: 1820,
    status: "active",
  },
  {
    id: 3,
    image: "https://images.unsplash.com/photo-1763757933292-d8290692edde?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzdW5zY3JlZW4lMjB0dWJlJTIwcHJvZHVjdCUyMHdoaXRlJTIwYmFja2dyb3VuZCUyMGNsZWFufGVufDF8fHx8MTc3NDA2NDU0Nnww&ixlib=rb-4.1.0&q=80&w=400",
    name: "Kem Chống Nắng Anessa SPF 50+",
    brand: "Anessa",
    category: "Chống Nắng",
    skinTypes: ["Mọi Loại Da"],
    rating: 4.9,
    reviews: 3560,
    status: "active",
  },
  {
    id: 4,
    image: "https://images.unsplash.com/photo-1677735476292-0fc57ab097b2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMHByb2R1Y3QlMjBib3R0bGUlMjBzZXJ1bSUyMGNsZWFuc2VyJTIwd2hpdGUlMjBtaW5pbWFsfGVufDF8fHx8MTc3NDA2NDU0Mnww&ixlib=rb-4.1.0&q=80&w=400",
    name: "Serum Niacinamide 10% Paula's",
    brand: "Paula's Choice",
    category: "Serum",
    skinTypes: ["Da Dầu", "Mụn", "Thâm Nám"],
    rating: 4.6,
    reviews: 2890,
    status: "active",
  },
  {
    id: 5,
    image: "https://images.unsplash.com/photo-1763503839418-2b45c3d7a3c3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb2lzdHVyaXplciUyMGNyZWFtJTIwamFyJTIwbHV4dXJ5JTIwc2tpbmNhcmUlMjBwcm9kdWN0fGVufDF8fHx8MTc3NDA2NDU0NHww&ixlib=rb-4.1.0&q=80&w=400",
    name: "Retinol 0.5% La Roche-Posay",
    brand: "La Roche-Posay",
    category: "Serum",
    skinTypes: ["Lão Hóa", "Thâm Nám"],
    rating: 4.5,
    reviews: 1340,
    status: "draft",
  },
  {
    id: 6,
    image: "https://images.unsplash.com/photo-1763757933292-d8290692edde?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzdW5zY3JlZW4lMjB0dWJlJTIwcHJvZHVjdCUyMHdoaXRlJTIwYmFja2dyb3VuZCUyMGNsZWFufGVufDF8fHx8MTc3NDA2NDU0Nnww&ixlib=rb-4.1.0&q=80&w=400",
    name: "Toner AHA 7% The Ordinary",
    brand: "The Ordinary",
    category: "Toner",
    skinTypes: ["Da Dầu", "Mụn", "Lão Hóa"],
    rating: 4.4,
    reviews: 4120,
    status: "out_of_stock",
  },
  {
    id: 7,
    image: "https://images.unsplash.com/photo-1677735476292-0fc57ab097b2?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMHByb2R1Y3QlMjBib3R0bGUlMjBzZXJ1bSUyMGNsZWFuc2VyJTIwd2hpdGUlMjBtaW5pbWFsfGVufDF8fHx8MTc3NDA2NDU0Mnww&ixlib=rb-4.1.0&q=80&w=400",
    name: "Kem Mắt Estée Lauder Advanced",
    brand: "Estée Lauder",
    category: "Dưỡng Mắt",
    skinTypes: ["Lão Hóa", "Nhạy Cảm"],
    rating: 4.8,
    reviews: 987,
    status: "active",
  },
  {
    id: 8,
    image: "https://images.unsplash.com/photo-1763503839418-2b45c3d7a3c3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtb2lzdHVyaXplciUyMGNyZWFtJTIwamFyJTIwbHV4dXJ5JTIwc2tpbmNhcmUlMjBwcm9kdWN0fGVufDF8fHx8MTc3NDA2NDU0NHww&ixlib=rb-4.1.0&q=80&w=400",
    name: "Vitamin C Serum Skinceuticals",
    brand: "SkinCeuticals",
    category: "Serum",
    skinTypes: ["Thâm Nám", "Lão Hóa", "Mọi Loại Da"],
    rating: 4.9,
    reviews: 2250,
    status: "active",
  },
];

const brands = ["Tất Cả", "CeraVe", "Klairs", "Anessa", "Paula's Choice", "La Roche-Posay", "The Ordinary", "Estée Lauder", "SkinCeuticals"];
const categories = ["Tất Cả", "Sữa Rửa Mặt", "Dưỡng Ẩm", "Chống Nắng", "Serum", "Toner", "Dưỡng Mắt"];

export function AdminProductsPage() {
  const [search, setSearch] = useState("");
  const [selectedBrand, setSelectedBrand] = useState("Tất Cả");
  const [selectedCategory, setSelectedCategory] = useState("Tất Cả");
  const [brandOpen, setBrandOpen] = useState(false);
  const [categoryOpen, setCategoryOpen] = useState(false);
  const [deletingId, setDeletingId] = useState<number | null>(null);
  const [showModal, setShowModal] = useState(false);

  const filtered = products.filter((p) => {
    const matchSearch = p.name.toLowerCase().includes(search.toLowerCase()) ||
      p.brand.toLowerCase().includes(search.toLowerCase());
    const matchBrand = selectedBrand === "Tất Cả" || p.brand === selectedBrand;
    const matchCategory = selectedCategory === "Tất Cả" || p.category === selectedCategory;
    return matchSearch && matchBrand && matchCategory;
  });

  return (
    <AdminLayout title="Quản Lý Kho Sản Phẩm">
      {/* Header Action Row */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div className="flex items-center gap-3 flex-wrap">
          {/* Search */}
          <div className="flex items-center gap-2 px-3.5 py-2.5 rounded-xl bg-white border border-[#e5e7eb] shadow-sm text-sm min-w-[220px]">
            <Search className="w-4 h-4 text-[#9ca3af] flex-shrink-0" />
            <input
              type="text"
              placeholder="Tìm sản phẩm, thương hiệu..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="bg-transparent outline-none text-[#1a1a2e] placeholder:text-[#9ca3af] w-full"
            />
            {search && (
              <button onClick={() => setSearch("")}>
                <X className="w-3.5 h-3.5 text-[#9ca3af] hover:text-[#c4a882]" />
              </button>
            )}
          </div>

          <div className="flex items-center gap-2">
            <Filter className="w-3.5 h-3.5 text-[#9ca3af]" />
            {/* Brand Filter */}
            <div className="relative">
              <button
                onClick={() => { setBrandOpen((v) => !v); setCategoryOpen(false); }}
                className="flex items-center gap-2 px-3.5 py-2.5 rounded-xl bg-white border border-[#e5e7eb] shadow-sm text-sm text-[#4b5563] hover:border-[#c4a882]/40 transition-colors"
              >
                Thương Hiệu: <span className="text-[#c4a882]">{selectedBrand}</span>
                <ChevronDown className={`w-3.5 h-3.5 transition-transform ${brandOpen ? "rotate-180" : ""}`} />
              </button>
              {brandOpen && (
                <div className="absolute top-full mt-1 left-0 w-48 bg-white border border-[#e5e7eb] rounded-2xl shadow-xl py-1.5 z-20">
                  {brands.map((b) => (
                    <button
                      key={b}
                      onClick={() => { setSelectedBrand(b); setBrandOpen(false); }}
                      className={`w-full text-left px-4 py-2 text-sm transition-colors ${
                        selectedBrand === b ? "text-[#c4a882] bg-[#c4a882]/5" : "text-[#4b5563] hover:bg-[#f9fafb]"
                      }`}
                    >
                      {b}
                    </button>
                  ))}
                </div>
              )}
            </div>

            {/* Category Filter */}
            <div className="relative">
              <button
                onClick={() => { setCategoryOpen((v) => !v); setBrandOpen(false); }}
                className="flex items-center gap-2 px-3.5 py-2.5 rounded-xl bg-white border border-[#e5e7eb] shadow-sm text-sm text-[#4b5563] hover:border-[#c4a882]/40 transition-colors"
              >
                Loại: <span className="text-[#c4a882]">{selectedCategory}</span>
                <ChevronDown className={`w-3.5 h-3.5 transition-transform ${categoryOpen ? "rotate-180" : ""}`} />
              </button>
              {categoryOpen && (
                <div className="absolute top-full mt-1 left-0 w-44 bg-white border border-[#e5e7eb] rounded-2xl shadow-xl py-1.5 z-20">
                  {categories.map((c) => (
                    <button
                      key={c}
                      onClick={() => { setSelectedCategory(c); setCategoryOpen(false); }}
                      className={`w-full text-left px-4 py-2 text-sm transition-colors ${
                        selectedCategory === c ? "text-[#c4a882] bg-[#c4a882]/5" : "text-[#4b5563] hover:bg-[#f9fafb]"
                      }`}
                    >
                      {c}
                    </button>
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Add Button */}
        <button
          onClick={() => setShowModal(true)}
          className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white text-sm shadow-lg shadow-[#c4a882]/25 hover:shadow-[#c4a882]/40 hover:scale-[1.02] transition-all flex-shrink-0"
        >
          <Plus className="w-4 h-4" />
          Thêm Sản Phẩm Mới
        </button>
      </div>

      {/* Summary Pills */}
      <div className="flex items-center gap-3 mb-4 text-sm text-[#6b7280]">
        <Package className="w-4 h-4" />
        <span>Hiển thị <span className="text-[#1a1a2e]" style={{ fontWeight: 600 }}>{filtered.length}</span> / {products.length} sản phẩm</span>
        {(selectedBrand !== "Tất Cả" || selectedCategory !== "Tất Cả" || search) && (
          <button
            onClick={() => { setSelectedBrand("Tất Cả"); setSelectedCategory("Tất Cả"); setSearch(""); }}
            className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-[#c4a882]/8 text-[#c4a882] text-xs hover:bg-[#c4a882]/15 transition-colors"
          >
            <X className="w-3 h-3" /> Xóa bộ lọc
          </button>
        )}
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl border border-[#e5e7eb] shadow-sm overflow-hidden">
        {/* Table Head */}
        <div className="grid grid-cols-[56px_2fr_1fr_1.5fr_1fr_auto] gap-4 px-5 py-3.5 bg-[#f8f9fb] border-b border-[#e5e7eb] text-xs text-[#6b7280] uppercase tracking-wide">
          <div>Ảnh</div>
          <div className="flex items-center gap-1 cursor-pointer hover:text-[#c4a882] transition-colors">
            Tên Sản Phẩm <ArrowUpDown className="w-3 h-3" />
          </div>
          <div>Phân Loại</div>
          <div>Thích Hợp Cho Da</div>
          <div>Trạng Thái</div>
          <div className="text-right">Hành Động</div>
        </div>

        {/* Rows */}
        <div className="divide-y divide-[#f3f4f6]">
          {filtered.map((product) => (
            <div
              key={product.id}
              className={`grid grid-cols-[56px_2fr_1fr_1.5fr_1fr_auto] gap-4 px-5 py-4 items-center hover:bg-[#fafafa] transition-colors ${
                deletingId === product.id ? "opacity-40" : ""
              }`}
            >
              {/* Image */}
              <div className="w-11 h-11 rounded-xl overflow-hidden bg-[#f4f5f7] flex-shrink-0">
                <ImageWithFallback
                  src={product.image}
                  alt={product.name}
                  className="w-full h-full object-cover"
                />
              </div>

              {/* Name + brand + rating */}
              <div>
                <p className="text-sm text-[#1a1a2e] mb-0.5" style={{ fontWeight: 500 }}>{product.name}</p>
                <div className="flex items-center gap-2">
                  <span className="text-xs text-[#9ca3af]">{product.brand}</span>
                  <span className="flex items-center gap-0.5 text-xs text-amber-500">
                    <Star className="w-3 h-3 fill-amber-400" />{product.rating}
                    <span className="text-[#9ca3af] ml-0.5">({product.reviews.toLocaleString()})</span>
                  </span>
                </div>
              </div>

              {/* Category */}
              <div>
                <span className="px-2.5 py-1 rounded-full bg-[#f3f4f6] text-[#6b7280] text-xs">
                  {product.category}
                </span>
              </div>

              {/* Skin Tags */}
              <div className="flex flex-wrap gap-1.5">
                {product.skinTypes.slice(0, 3).map((tag) => (
                  <span
                    key={tag}
                    className={`px-2 py-0.5 rounded-full border text-[11px] ${tagColors[tag]}`}
                  >
                    {tag}
                  </span>
                ))}
              </div>

              {/* Status */}
              <div>
                <span className={`px-2.5 py-1 rounded-full text-xs ${statusStyle[product.status]}`}>
                  {statusLabel[product.status]}
                </span>
              </div>

              {/* Actions */}
              <div className="flex items-center gap-2 justify-end">
                <button className="w-8 h-8 rounded-xl bg-[#f4f5f7] hover:bg-[#c4a882]/10 hover:text-[#c4a882] text-[#6b7280] flex items-center justify-center transition-colors">
                  <Pencil className="w-3.5 h-3.5" />
                </button>
                <button
                  onClick={() => setDeletingId(deletingId === product.id ? null : product.id)}
                  className="w-8 h-8 rounded-xl bg-[#f4f5f7] hover:bg-red-50 hover:text-red-500 text-[#6b7280] flex items-center justify-center transition-colors"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>
          ))}

          {filtered.length === 0 && (
            <div className="py-16 text-center text-[#6b7280]">
              <Package className="w-10 h-10 mx-auto mb-3 text-[#d1d5db]" />
              <p>Không tìm thấy sản phẩm nào</p>
            </div>
          )}
        </div>

        {/* Pagination */}
        <div className="px-5 py-4 border-t border-[#f3f4f6] flex items-center justify-between text-sm text-[#6b7280]">
          <span>Tổng: {products.length} sản phẩm</span>
          <div className="flex items-center gap-1">
            {[1, 2, 3].map((p) => (
              <button
                key={p}
                className={`w-8 h-8 rounded-lg text-xs transition-colors ${
                  p === 1
                    ? "bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white shadow-sm"
                    : "hover:bg-[#f4f5f7] text-[#6b7280]"
                }`}
              >
                {p}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Add Product Modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/30 backdrop-blur-sm">
          <div className="bg-white rounded-3xl shadow-2xl border border-[#e5e7eb] p-8 w-full max-w-md mx-4">
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-[#1a1a2e] text-lg" style={{ fontWeight: 600 }}>Thêm Sản Phẩm Mới</h2>
              <button onClick={() => setShowModal(false)} className="p-2 rounded-xl hover:bg-[#f4f5f7] transition-colors">
                <X className="w-4 h-4 text-[#6b7280]" />
              </button>
            </div>
            <div className="flex flex-col gap-4">
              {[
                { label: "Tên Sản Phẩm", placeholder: "Nhập tên sản phẩm..." },
                { label: "Thương Hiệu", placeholder: "Nhập thương hiệu..." },
                { label: "Phân Loại", placeholder: "Serum, Toner, Kem Dưỡng..." },
              ].map((field) => (
                <div key={field.label}>
                  <label className="text-xs text-[#6b7280] mb-1.5 block">{field.label}</label>
                  <input
                    type="text"
                    placeholder={field.placeholder}
                    className="w-full px-4 py-2.5 rounded-xl border border-[#e5e7eb] text-sm text-[#1a1a2e] placeholder:text-[#9ca3af] focus:outline-none focus:border-[#c4a882]/50 transition-colors"
                  />
                </div>
              ))}
              <div className="flex gap-3 mt-2">
                <button onClick={() => setShowModal(false)} className="flex-1 py-3 rounded-xl border border-[#e5e7eb] text-sm text-[#6b7280] hover:bg-[#f4f5f7] transition-colors">
                  Hủy
                </button>
                <button onClick={() => setShowModal(false)} className="flex-1 py-3 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white text-sm shadow-md shadow-[#c4a882]/20 hover:shadow-[#c4a882]/35 transition-all">
                  Lưu Sản Phẩm
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  );
}