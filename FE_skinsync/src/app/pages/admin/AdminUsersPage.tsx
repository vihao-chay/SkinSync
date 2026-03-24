import { useState } from "react";
import {
  Search,
  X,
  ChevronDown,
  Users,
  UserCheck,
  UserX,
  TrendingUp,
  MoreHorizontal,
  Pencil,
  Trash2,
  Ban,
  Mail,
  Star,
  Flame,
  Filter,
} from "lucide-react";
import { AdminLayout } from "../../components/AdminSidebar";
import { ImageWithFallback } from "../../components/figma/ImageWithFallback";

type UserStatus = "active" | "inactive" | "banned";

interface User {
  id: number;
  name: string;
  email: string;
  avatar: string;
  skinType: string;
  status: UserStatus;
  streak: number;
  score: number;
  joinDate: string;
  lastActive: string;
  analyses: number;
}

const avatarUrl = "https://images.unsplash.com/photo-1739208885492-6e202b6f86f0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3b21hbiUyMHBvcnRyYWl0JTIwYXZhdGFyJTIwcHJvZmlsZSUyMHBob3RvJTIwYmVhdXR5fGVufDF8fHx8MTc3NDAxNjIwOHww&ixlib=rb-4.1.0&q=80&w=200";

const users: User[] = [
  { id: 1, name: "Nguyễn Lan Anh", email: "lananh@gmail.com", avatar: avatarUrl, skinType: "Da Hỗn Hợp", status: "active", streak: 14, score: 87, joinDate: "01/2026", lastActive: "2 phút trước", analyses: 8 },
  { id: 2, name: "Trần Minh Khoa", email: "minhkhoa@outlook.com", avatar: avatarUrl, skinType: "Da Dầu", status: "active", streak: 7, score: 72, joinDate: "02/2026", lastActive: "1 giờ trước", analyses: 4 },
  { id: 3, name: "Lê Thị Hoa", email: "thihoa@gmail.com", avatar: avatarUrl, skinType: "Da Khô", status: "active", streak: 28, score: 91, joinDate: "12/2025", lastActive: "15 phút trước", analyses: 12 },
  { id: 4, name: "Phạm Thu Hiền", email: "thuhien@yahoo.com", avatar: avatarUrl, skinType: "Da Nhạy Cảm", status: "inactive", streak: 0, score: 65, joinDate: "01/2026", lastActive: "3 ngày trước", analyses: 3 },
  { id: 5, name: "Đỗ Văn Nam", email: "vannam@gmail.com", avatar: avatarUrl, skinType: "Da Thường", status: "active", streak: 5, score: 78, joinDate: "03/2026", lastActive: "40 phút trước", analyses: 2 },
  { id: 6, name: "Vũ Thanh Hằng", email: "thanhhang@gmail.com", avatar: avatarUrl, skinType: "Da Dầu", status: "banned", streak: 0, score: 45, joinDate: "11/2025", lastActive: "2 tuần trước", analyses: 6 },
  { id: 7, name: "Hoàng Thị Mai", email: "thimai@email.com", avatar: avatarUrl, skinType: "Da Hỗn Hợp", status: "active", streak: 21, score: 88, joinDate: "01/2026", lastActive: "5 phút trước", analyses: 10 },
  { id: 8, name: "Bùi Quốc Hùng", email: "quochung@gmail.com", avatar: avatarUrl, skinType: "Da Khô", status: "inactive", streak: 0, score: 60, joinDate: "02/2026", lastActive: "1 tuần trước", analyses: 1 },
];

const statusStyle: Record<UserStatus, string> = {
  active: "bg-emerald-50 text-emerald-600 border border-emerald-100",
  inactive: "bg-[#f3f4f6] text-[#6b7280] border border-[#e5e7eb]",
  banned: "bg-red-50 text-red-500 border border-red-100",
};
const statusLabel: Record<UserStatus, string> = {
  active: "Hoạt Động",
  inactive: "Không Hoạt Động",
  banned: "Đã Cấm",
};

const skinTypeColors: Record<string, string> = {
  "Da Hỗn Hợp": "bg-purple-50 text-purple-600 border-purple-100",
  "Da Dầu": "bg-blue-50 text-blue-600 border-blue-100",
  "Da Khô": "bg-amber-50 text-amber-600 border-amber-100",
  "Da Nhạy Cảm": "bg-pink-50 text-pink-600 border-pink-100",
  "Da Thường": "bg-emerald-50 text-emerald-600 border-emerald-100",
};

const statusFilters: { label: string; value: string }[] = [
  { label: "Tất Cả", value: "all" },
  { label: "Hoạt Động", value: "active" },
  { label: "Không Hoạt Động", value: "inactive" },
  { label: "Đã Cấm", value: "banned" },
];

export function AdminUsersPage() {
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [openMenu, setOpenMenu] = useState<number | null>(null);
  const [sortByScore, setSortByScore] = useState(false);

  const filtered = users
    .filter((u) => {
      const matchSearch =
        u.name.toLowerCase().includes(search.toLowerCase()) ||
        u.email.toLowerCase().includes(search.toLowerCase());
      const matchStatus = statusFilter === "all" || u.status === statusFilter;
      return matchSearch && matchStatus;
    })
    .sort((a, b) => (sortByScore ? b.score - a.score : a.id - b.id));

  const stats = [
    { label: "Tổng Người Dùng", value: "12,450", icon: <Users className="w-5 h-5" />, delta: "+284 tuần này", color: "#c4a882", bg: "from-[#c4a882]/10 to-[#c4a882]/5", border: "border-[#c4a882]/15" },
    { label: "Đang Hoạt Động", value: "9,820", icon: <UserCheck className="w-5 h-5" />, delta: "78.9% tổng số", color: "#10b981", bg: "from-emerald-50 to-teal-50/60", border: "border-emerald-100" },
    { label: "Không Hoạt Động", value: "2,410", icon: <UserX className="w-5 h-5" />, delta: "19.4% tổng số", color: "#f59e0b", bg: "from-amber-50 to-orange-50/60", border: "border-amber-100" },
    { label: "Điểm Da TB", value: "76.4", icon: <TrendingUp className="w-5 h-5" />, delta: "+3.2 so với tháng trước", color: "#8c6e52", bg: "from-[#8c6e52]/10 to-[#8c6e52]/5", border: "border-[#8c6e52]/15" },
  ];

  return (
    <AdminLayout title="Người Dùng">
      {/* Stats */}
      <div className="grid grid-cols-2 xl:grid-cols-4 gap-4 mb-7">
        {stats.map((s) => (
          <div key={s.label} className={`bg-gradient-to-br ${s.bg} border ${s.border} rounded-2xl p-5 flex flex-col gap-3`}>
            <div className="flex items-center justify-between">
              <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{ background: `${s.color}18` }}>
                <span style={{ color: s.color }}>{s.icon}</span>
              </div>
            </div>
            <div>
              <div className="text-2xl text-[#1a1a2e]" style={{ fontWeight: 700 }}>{s.value}</div>
              <div className="text-xs text-[#6b7280] mt-0.5">{s.label}</div>
              <div className="text-xs mt-1" style={{ color: s.color }}>{s.delta}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-5">
        <div className="flex items-center gap-3 flex-wrap">
          {/* Search */}
          <div className="flex items-center gap-2 px-3.5 py-2.5 rounded-xl bg-white border border-[#e5e7eb] shadow-sm text-sm min-w-[220px]">
            <Search className="w-4 h-4 text-[#9ca3af] flex-shrink-0" />
            <input
              type="text"
              placeholder="Tìm tên, email..."
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

          {/* Status filter pills */}
          <div className="flex items-center gap-1 p-1 bg-white border border-[#e5e7eb] rounded-xl shadow-sm">
            {statusFilters.map((f) => (
              <button
                key={f.value}
                onClick={() => setStatusFilter(f.value)}
                className={`px-3 py-1.5 rounded-lg text-xs transition-all ${
                  statusFilter === f.value
                    ? "bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white shadow-sm"
                    : "text-[#6b7280] hover:text-[#1a1a2e]"
                }`}
              >
                {f.label}
              </button>
            ))}
          </div>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={() => setSortByScore((v) => !v)}
            className={`flex items-center gap-2 px-3.5 py-2.5 rounded-xl border text-xs transition-all ${
              sortByScore
                ? "border-[#c4a882]/40 bg-[#c4a882]/5 text-[#c4a882]"
                : "border-[#e5e7eb] bg-white text-[#6b7280] shadow-sm"
            }`}
          >
            <Filter className="w-3.5 h-3.5" />
            Sắp xếp theo điểm da
          </button>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl border border-[#e5e7eb] shadow-sm overflow-hidden">
        {/* Head */}
        <div className="grid grid-cols-[44px_2fr_1fr_1fr_80px_80px_80px_40px] gap-3 px-5 py-3.5 bg-[#f8f9fb] border-b border-[#e5e7eb] text-xs text-[#6b7280] uppercase tracking-wide">
          <div />
          <div>Người Dùng</div>
          <div>Loại Da</div>
          <div>Trạng Thái</div>
          <div className="text-center">Chuỗi Ngày</div>
          <div className="text-center">Điểm Da</div>
          <div className="text-center">Phân Tích</div>
          <div />
        </div>

        <div className="divide-y divide-[#f3f4f6]">
          {filtered.map((user) => (
            <div
              key={user.id}
              className="grid grid-cols-[44px_2fr_1fr_1fr_80px_80px_80px_40px] gap-3 px-5 py-3.5 items-center hover:bg-[#fafafa] transition-colors relative"
            >
              {/* Avatar */}
              <div className="w-9 h-9 rounded-xl overflow-hidden flex-shrink-0">
                <ImageWithFallback
                  src={user.avatar}
                  alt={user.name}
                  className="w-full h-full object-cover object-top"
                />
              </div>

              {/* Name + email */}
              <div>
                <p className="text-sm text-[#1a1a2e] truncate" style={{ fontWeight: 500 }}>{user.name}</p>
                <p className="text-xs text-[#9ca3af] truncate">{user.email}</p>
                <p className="text-[10px] text-[#9ca3af]">Tham gia: {user.joinDate} · {user.lastActive}</p>
              </div>

              {/* Skin Type */}
              <div>
                <span className={`px-2 py-0.5 rounded-full border text-[11px] ${skinTypeColors[user.skinType] ?? "bg-[#f3f4f6] text-[#6b7280] border-[#e5e7eb]"}`}>
                  {user.skinType}
                </span>
              </div>

              {/* Status */}
              <div>
                <span className={`px-2.5 py-1 rounded-full text-xs ${statusStyle[user.status]}`}>
                  {statusLabel[user.status]}
                </span>
              </div>

              {/* Streak */}
              <div className="text-center">
                <div className="flex items-center justify-center gap-1">
                  {user.streak > 0 ? (
                    <>
                      <Flame className="w-3.5 h-3.5 text-orange-400" />
                      <span className="text-sm text-[#1a1a2e]" style={{ fontWeight: 500 }}>{user.streak}</span>
                    </>
                  ) : (
                    <span className="text-sm text-[#d1d5db]">—</span>
                  )}
                </div>
              </div>

              {/* Score */}
              <div className="text-center">
                <span
                  className="text-sm"
                  style={{
                    fontWeight: 600,
                    color: user.score >= 80 ? "#c4a882" : user.score >= 65 ? "#f59e0b" : "#9ca3af",
                  }}
                >
                  {user.score}
                </span>
                <span className="text-xs text-[#9ca3af]">/100</span>
              </div>

              {/* Analyses */}
              <div className="text-center">
                <span className="text-sm text-[#4b5563]">{user.analyses}</span>
              </div>

              {/* Actions Menu */}
              <div className="relative flex justify-center">
                <button
                  onClick={() => setOpenMenu(openMenu === user.id ? null : user.id)}
                  className="w-7 h-7 rounded-lg hover:bg-[#f4f5f7] text-[#9ca3af] hover:text-[#c4a882] flex items-center justify-center transition-colors"
                >
                  <MoreHorizontal className="w-4 h-4" />
                </button>
                {openMenu === user.id && (
                  <div className="absolute right-0 top-full mt-1 w-44 bg-white border border-[#e5e7eb] rounded-2xl shadow-xl py-1.5 z-20">
                    {[
                      { icon: <Mail className="w-3.5 h-3.5" />, label: "Gửi Email", color: "" },
                      { icon: <Pencil className="w-3.5 h-3.5" />, label: "Chỉnh Sửa", color: "" },
                      { icon: <Star className="w-3.5 h-3.5" />, label: "Xem Hồ Sơ", color: "" },
                      { icon: <Ban className="w-3.5 h-3.5" />, label: "Cấm Tài Khoản", color: "text-red-500 hover:bg-red-50" },
                      { icon: <Trash2 className="w-3.5 h-3.5" />, label: "Xóa Tài Khoản", color: "text-red-500 hover:bg-red-50" },
                    ].map((action) => (
                      <button
                        key={action.label}
                        onClick={() => setOpenMenu(null)}
                        className={`w-full flex items-center gap-2.5 px-4 py-2 text-xs transition-colors ${
                          action.color || "text-[#4b5563] hover:bg-[#f9fafb] hover:text-[#c4a882]"
                        }`}
                      >
                        {action.icon}
                        {action.label}
                      </button>
                    ))}
                  </div>
                )}
              </div>
            </div>
          ))}

          {filtered.length === 0 && (
            <div className="py-14 text-center text-[#9ca3af]">
              <Users className="w-10 h-10 mx-auto mb-3 text-[#d1d5db]" />
              <p className="text-sm">Không tìm thấy người dùng nào</p>
            </div>
          )}
        </div>

        {/* Pagination */}
        <div className="px-5 py-4 border-t border-[#f3f4f6] flex items-center justify-between text-sm text-[#6b7280]">
          <span>Hiển thị {filtered.length} / {users.length} người dùng</span>
          <div className="flex items-center gap-1">
            {[1, 2, 3, "...", 156].map((p, i) => (
              <button
                key={i}
                className={`min-w-[32px] h-8 px-2 rounded-lg text-xs transition-colors ${
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
    </AdminLayout>
  );
}