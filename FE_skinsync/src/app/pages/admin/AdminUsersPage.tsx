import { useEffect, useMemo, useState } from "react";
import {
  Search,
  X,
  Users,
  UserCheck,
  UserX,
  TrendingUp,
  MoreHorizontal,
  Pencil,
  Ban,
  Mail,
  Star,
  Flame,
  Filter,
  CheckCircle,
  XCircle,
  Send,
  Loader2,
} from "lucide-react";
import { toast } from "sonner";
import { AdminLayout } from "../../components/AdminSidebar";
import { ImageWithFallback } from "../../components/figma/ImageWithFallback";
import {
  getAdminUsersFromSupabase,
  updateAdminUserStatus,
  type AdminUsersPagedData,
  type AdminUserListItem,
  type AdminUserStatus,
} from "../../services/adminUsersService";

const statusStyle: Record<AdminUserStatus, string> = {
  active: "bg-emerald-50 text-emerald-600 border border-emerald-100",
  inactive: "bg-amber-50 text-amber-600 border border-amber-100",
  banned: "bg-red-50 text-red-500 border border-red-100",
};
const statusLabel: Record<AdminUserStatus, string> = {
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
  Combination: "bg-purple-50 text-purple-600 border-purple-100",
  Oily: "bg-blue-50 text-blue-600 border-blue-100",
  Dry: "bg-amber-50 text-amber-600 border-amber-100",
  Sensitive: "bg-pink-50 text-pink-600 border-pink-100",
  Normal: "bg-emerald-50 text-emerald-600 border-emerald-100",
};

const statusFilters: { label: string; value: string }[] = [
  { label: "Tất Cả", value: "all" },
  { label: "Hoạt Động", value: "active" },
  { label: "Không Hoạt Động", value: "inactive" },
  { label: "Đã Cấm", value: "banned" },
];

type ConfirmAction = {
  type: "suspend" | "activate" | "ban";
  userId: AdminUserListItem["id"];
  userName: string;
};

type EmailData = {
  userEmail: string;
  userName: string;
};

type AdminToastVariant = "success" | "error";

function showAdminToast(variant: AdminToastVariant, title: string, message: string) {
  const isSuccess = variant === "success";

  toast.custom((id) => (
    <div className="w-[360px] max-w-[calc(100vw-2rem)] rounded-2xl border border-[#e8d5b7]/50 bg-white/90 backdrop-blur-xl shadow-xl shadow-[#8c6e52]/10 overflow-hidden">
      <div className="flex gap-3 p-4">
        <div
          className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${
            isSuccess ? "bg-emerald-50 text-emerald-600" : "bg-red-50 text-red-500"
          }`}
        >
          {isSuccess ? <CheckCircle className="w-5 h-5" /> : <XCircle className="w-5 h-5" />}
        </div>
        <div className="min-w-0 flex-1">
          <p className="text-sm text-[#2a2a2a]" style={{ fontWeight: 600 }}>{title}</p>
          <p className="text-xs text-[#6b7280] leading-relaxed mt-1">{message}</p>
        </div>
        <button
          type="button"
          onClick={() => toast.dismiss(id)}
          className="w-7 h-7 rounded-lg text-[#9ca3af] hover:text-[#8c6e52] hover:bg-[#f5f0e8] flex items-center justify-center transition-colors"
          aria-label="Đóng thông báo"
        >
          <X className="w-3.5 h-3.5" />
        </button>
      </div>
      <div className={`h-1 ${isSuccess ? "bg-[#c4a882]" : "bg-red-400"}`} />
    </div>
  ), {
    duration: isSuccess ? 3800 : 4800,
  });
}

function getStatusActionSuccessTitle(type: ConfirmAction["type"]) {
  switch (type) {
    case "suspend":
      return "Đã dừng tài khoản";
    case "activate":
      return "Đã mở tài khoản";
    case "ban":
      return "Đã cấm tài khoản";
  }
}

export function AdminUsersPage() {
  const PAGE_SIZE = 5;
  const [search, setSearch] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");
  const [openMenu, setOpenMenu] = useState<string | null>(null);
  const [sortByScore, setSortByScore] = useState(false);
  const [users, setUsers] = useState<AdminUserListItem[]>([]);
  const [paging, setPaging] = useState<Pick<AdminUsersPagedData, "pageIndex" | "pageSize" | "totalRow" | "totalPages">>({
    pageIndex: 1,
    pageSize: PAGE_SIZE,
    totalRow: 0,
    totalPages: 1,
  });
  const [isLoading, setIsLoading] = useState(true);
  const [hasLoadedOnce, setHasLoadedOnce] = useState(false);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [confirmAction, setConfirmAction] = useState<ConfirmAction | null>(null);
  const [emailModal, setEmailModal] = useState<EmailData | null>(null);
  const [emailSubject, setEmailSubject] = useState("");
  const [emailBody, setEmailBody] = useState("");
  const [isSending, setIsSending] = useState(false);
  const [isUpdatingStatus, setIsUpdatingStatus] = useState(false);

  useEffect(() => {
    setPaging((prev) => (prev.pageIndex === 1 ? prev : { ...prev, pageIndex: 1 }));
  }, [search, statusFilter]);

  useEffect(() => {
    let isMounted = true;

    const loadUsers = async () => {
      if (!hasLoadedOnce) {
        setIsLoading(true);
      }
      setLoadError(null);

      const result = await getAdminUsersFromSupabase(paging.pageIndex, PAGE_SIZE, {
        search,
        status: statusFilter as "all" | AdminUserStatus,
      });
      if (!isMounted) {
        return;
      }

      if (result.success && result.content) {
        setUsers(result.content.items);
        setPaging({
          pageIndex: result.content.pageIndex,
          pageSize: result.content.pageSize,
          totalRow: result.content.totalRow,
          totalPages: Math.max(1, result.content.totalPages),
        });
      } else {
        setUsers([]);
        setPaging((prev) => ({ ...prev, totalRow: 0, totalPages: 1 }));
        setLoadError(result.message || "Không thể tải danh sách người dùng.");
      }

      setHasLoadedOnce(true);
      setIsLoading(false);
    };

    loadUsers();

    return () => {
      isMounted = false;
    };
  }, [paging.pageIndex, hasLoadedOnce, search, statusFilter]);

  const paginationItems = useMemo<(number | "...")[]>(() => {
    const total = paging.totalPages;
    const current = paging.pageIndex;

    if (total <= 7) {
      return Array.from({ length: total }, (_, i) => i + 1);
    }

    const pages: (number | "...")[] = [1];
    const start = Math.max(2, current - 1);
    const end = Math.min(total - 1, current + 1);

    if (start > 2) {
      pages.push("...");
    }

    for (let p = start; p <= end; p += 1) {
      pages.push(p);
    }

    if (end < total - 1) {
      pages.push("...");
    }

    pages.push(total);
    return pages;
  }, [paging.pageIndex, paging.totalPages]);

  const filtered = useMemo(() => [...users]
    .sort((a, b) => (sortByScore
      ? b.score - a.score
      : new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())), [users, sortByScore]);

  const stats = useMemo(() => {
    const totalUsers = users.length;
    const activeUsers = users.filter((u) => u.status === "active").length;
    const inactiveUsers = users.filter((u) => u.status === "inactive").length;
    const avgScore = totalUsers
      ? users.reduce((sum, user) => sum + user.score, 0) / totalUsers
      : 0;

    return [
      {
        label: "Tổng Người Dùng",
        value: totalUsers.toLocaleString("vi-VN"),
        icon: <Users className="w-5 h-5" />,
        delta: "Dữ liệu từ hệ thống",
        color: "#c4a882",
        bg: "from-[#c4a882]/10 to-[#c4a882]/5",
        border: "border-[#c4a882]/15",
      },
      {
        label: "Đang Hoạt Động",
        value: activeUsers.toLocaleString("vi-VN"),
        icon: <UserCheck className="w-5 h-5" />,
        delta: totalUsers ? `${((activeUsers / totalUsers) * 100).toFixed(1)}% tổng số` : "0% tổng số",
        color: "#10b981",
        bg: "from-emerald-50 to-teal-50/60",
        border: "border-emerald-100",
      },
      {
        label: "Không Hoạt Động",
        value: inactiveUsers.toLocaleString("vi-VN"),
        icon: <UserX className="w-5 h-5" />,
        delta: totalUsers ? `${((inactiveUsers / totalUsers) * 100).toFixed(1)}% tổng số` : "0% tổng số",
        color: "#f59e0b",
        bg: "from-amber-50 to-orange-50/60",
        border: "border-amber-100",
      },
      {
        label: "Điểm Da TB",
        value: avgScore.toFixed(1),
        icon: <TrendingUp className="w-5 h-5" />,
        delta: "Tính từ phân tích gần nhất",
        color: "#8c6e52",
        bg: "from-[#8c6e52]/10 to-[#8c6e52]/5",
        border: "border-[#8c6e52]/15",
      },
    ];
  }, [users]);

  const handleConfirm = async () => {
    if (!confirmAction) return;

    const currentAction = confirmAction;
    const nextStatus: AdminUserStatus =
      currentAction.type === "suspend"
        ? "inactive"
        : currentAction.type === "activate"
          ? "active"
          : "banned";

    setIsUpdatingStatus(true);

    try {
      const result = await updateAdminUserStatus(currentAction.userId, nextStatus);
      if (!result.success || !result.content) {
        showAdminToast(
          "error",
          "Cập nhật thất bại",
          result.message || `Không thể cập nhật trạng thái cho ${currentAction.userName}.`
        );
        return;
      }

      const updatedStatus = result.content;

      setUsers((prev) => prev.map((u) => (u.id === currentAction.userId ? { ...u, status: updatedStatus } : u)));
      showAdminToast(
        "success",
        getStatusActionSuccessTitle(currentAction.type),
        `${currentAction.userName} đã được cập nhật trạng thái thành công.`
      );
      setConfirmAction(null);
    } catch {
      showAdminToast(
        "error",
        "Cập nhật thất bại",
        `Không thể cập nhật trạng thái cho ${currentAction.userName}. Vui lòng thử lại.`
      );
    } finally {
      setIsUpdatingStatus(false);
    }
  };

  const getActionConfig = (type: ConfirmAction["type"]) => {
    switch (type) {
      case "suspend":
        return {
          title: "Xác nhận dừng tài khoản?",
          action: "dừng",
          buttonClass: "bg-gradient-to-r from-orange-500 to-amber-500 hover:from-orange-600 hover:to-amber-600",
        };
      case "activate":
        return {
          title: "Xác nhận mở tài khoản?",
          action: "mở",
          buttonClass: "bg-gradient-to-r from-emerald-500 to-teal-500 hover:from-emerald-600 hover:to-teal-600",
        };
      case "ban":
        return {
          title: "Xác nhận cấm tài khoản?",
          action: "cấm",
          buttonClass: "bg-gradient-to-r from-red-500 to-rose-500 hover:from-red-600 hover:to-rose-600",
        };
    }
  };

  const handleSendEmail = async () => {
    if (!emailModal) return;
    if (!emailSubject.trim() || !emailBody.trim()) {
      showAdminToast(
        "error",
        "Thiếu nội dung email",
        "Vui lòng điền đầy đủ chủ đề và nội dung trước khi gửi."
      );
      return;
    }

    setIsSending(true);

    try {
      await new Promise((resolve) => {
        setTimeout(resolve, 1500);
      });

      console.log("Sending email to:", emailModal.userEmail, {
        subject: emailSubject,
        body: emailBody,
      });

      showAdminToast(
        "success",
        "Email đã được gửi",
        `Tin nhắn đã được gửi thành công đến ${emailModal.userName}.`
      );
      setEmailModal(null);
      setEmailSubject("");
      setEmailBody("");
    } catch {
      showAdminToast(
        "error",
        "Gửi email thất bại",
        `Không thể gửi email đến ${emailModal.userName}. Vui lòng thử lại.`
      );
    } finally {
      setIsSending(false);
    }
  };

  const closeEmailModal = () => {
    setEmailModal(null);
    setEmailSubject("");
    setEmailBody("");
    setIsSending(false);
  };

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

      {isLoading && (
        <div className="mb-5 rounded-xl border border-[#e5e7eb] bg-white px-4 py-3 text-sm text-[#6b7280]">
          Đang tải danh sách người dùng...
        </div>
      )}

      {loadError && (
        <div className="mb-5 rounded-xl border border-red-100 bg-red-50 px-4 py-3 text-sm text-red-600">
          {loadError}
        </div>
      )}

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
                <p className="text-[10px] text-[#9ca3af]">Tham gia: {user.joinDate} · SĐT: {user.phone}</p>
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
                    <button
                      onClick={() => {
                        setOpenMenu(null);
                        setEmailModal({ userEmail: user.email, userName: user.name });
                      }}
                      className="w-full flex items-center gap-2.5 px-4 py-2 text-xs transition-colors text-[#4b5563] hover:bg-[#f9fafb] hover:text-[#c4a882]"
                    >
                      <Mail className="w-3.5 h-3.5" />
                      Gửi Email
                    </button>
                    <button
                      onClick={() => {
                        setOpenMenu(null);
                      }}
                      className="w-full flex items-center gap-2.5 px-4 py-2 text-xs transition-colors text-[#4b5563] hover:bg-[#f9fafb] hover:text-[#c4a882]"
                    >
                      <Pencil className="w-3.5 h-3.5" />
                      Chỉnh Sửa
                    </button>
                    <button
                      onClick={() => {
                        setOpenMenu(null);
                      }}
                      className="w-full flex items-center gap-2.5 px-4 py-2 text-xs transition-colors text-[#4b5563] hover:bg-[#f9fafb] hover:text-[#c4a882]"
                    >
                      <Star className="w-3.5 h-3.5" />
                      Xem Hồ Sơ
                    </button>
                    {user.status === "active" && (
                      <button
                        onClick={() => {
                          setOpenMenu(null);
                          setConfirmAction({ type: "suspend", userId: user.id, userName: user.name });
                        }}
                        className="w-full flex items-center gap-2.5 px-4 py-2 text-xs transition-colors text-orange-500 hover:bg-orange-50"
                      >
                        <XCircle className="w-3.5 h-3.5" />
                        Dừng Tài Khoản
                      </button>
                    )}
                    {user.status !== "active" && (
                      <button
                        onClick={() => {
                          setOpenMenu(null);
                          setConfirmAction({ type: "activate", userId: user.id, userName: user.name });
                        }}
                        className="w-full flex items-center gap-2.5 px-4 py-2 text-xs transition-colors text-emerald-500 hover:bg-emerald-50"
                      >
                        <CheckCircle className="w-3.5 h-3.5" />
                        Mở Tài Khoản
                      </button>
                    )}
                    <button
                      onClick={() => {
                        setOpenMenu(null);
                        setConfirmAction({ type: "ban", userId: user.id, userName: user.name });
                      }}
                      className="w-full flex items-center gap-2.5 px-4 py-2 text-xs transition-colors text-red-500 hover:bg-red-50"
                    >
                      <Ban className="w-3.5 h-3.5" />
                      Cấm Tài Khoản
                    </button>
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
          <span>Hiển thị {filtered.length} / {paging.totalRow} người dùng</span>
          <div className="flex items-center gap-1">
            <button
              onClick={() => setPaging((prev) => ({ ...prev, pageIndex: Math.max(1, prev.pageIndex - 1) }))}
              disabled={paging.pageIndex <= 1}
              className="min-w-[32px] h-8 px-2 rounded-lg text-xs transition-colors disabled:opacity-40 disabled:cursor-not-allowed hover:bg-[#f4f5f7]"
            >
              {'<'}
            </button>
            {paginationItems.map((p, i) => (
              <button
                key={`${p}-${i}`}
                onClick={() => {
                  if (typeof p === "number") {
                    setPaging((prev) => ({ ...prev, pageIndex: p }));
                  }
                }}
                disabled={p === "..."}
                className={`min-w-[32px] h-8 px-2 rounded-lg text-xs transition-colors ${
                  p === paging.pageIndex
                    ? "bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white shadow-sm"
                    : "hover:bg-[#f4f5f7] text-[#6b7280]"
                }`}
              >
                {p}
              </button>
            ))}
            <button
              onClick={() => setPaging((prev) => ({ ...prev, pageIndex: Math.min(prev.totalPages, prev.pageIndex + 1) }))}
              disabled={paging.pageIndex >= paging.totalPages}
              className="min-w-[32px] h-8 px-2 rounded-lg text-xs transition-colors disabled:opacity-40 disabled:cursor-not-allowed hover:bg-[#f4f5f7]"
            >
              {'>'}
            </button>
          </div>
        </div>
      </div>

      {/* Confirmation Modal */}
      {confirmAction && (
        <div className="fixed inset-0 bg-black/30 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-in fade-in duration-200">
          <div className="bg-white rounded-3xl shadow-2xl border border-[#e5e7eb] max-w-md w-full p-6 animate-in zoom-in-95 duration-200">
            <div className="text-center mb-5">
              <div
                className={`w-14 h-14 mx-auto mb-4 rounded-2xl flex items-center justify-center ${
                  confirmAction.type === "suspend"
                    ? "bg-orange-50"
                    : confirmAction.type === "activate"
                      ? "bg-emerald-50"
                      : "bg-red-50"
                }`}
              >
                {confirmAction.type === "suspend" && <XCircle className="w-7 h-7 text-orange-500" />}
                {confirmAction.type === "activate" && <CheckCircle className="w-7 h-7 text-emerald-500" />}
                {confirmAction.type === "ban" && <Ban className="w-7 h-7 text-red-500" />}
              </div>
              <h3 className="text-xl text-[#1a1a2e] mb-2" style={{ fontWeight: 600 }}>
                {getActionConfig(confirmAction.type).title}
              </h3>
              <p className="text-sm text-[#6b7280] leading-relaxed">
                Bạn có chắc chắn muốn {getActionConfig(confirmAction.type).action} người dùng{" "}
                <span className="text-[#1a1a2e]" style={{ fontWeight: 500 }}>
                  {confirmAction.userName}
                </span>{" "}
                không? Hành động này sẽ áp dụng ngay lập tức.
              </p>
            </div>
            <div className="flex items-center gap-3">
              <button
                onClick={() => setConfirmAction(null)}
                disabled={isUpdatingStatus}
                className="flex-1 px-4 py-2.5 rounded-xl border border-[#e5e7eb] text-[#4b5563] text-sm hover:bg-[#f9fafb] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                style={{ fontWeight: 500 }}
              >
                Hủy
              </button>
              <button
                onClick={handleConfirm}
                disabled={isUpdatingStatus}
                className={`flex-1 px-4 py-2.5 rounded-xl text-white text-sm shadow-lg transition-all disabled:opacity-70 disabled:cursor-not-allowed flex items-center justify-center gap-2 ${
                  getActionConfig(confirmAction.type).buttonClass
                }`}
                style={{ fontWeight: 500 }}
              >
                {isUpdatingStatus && <Loader2 className="w-4 h-4 animate-spin" />}
                {isUpdatingStatus ? "Đang cập nhật..." : "Xác nhận"}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Email Modal */}
      {emailModal && (
        <div className="fixed inset-0 bg-black/30 backdrop-blur-sm flex items-center justify-center z-50 p-4 animate-in fade-in duration-200">
          <div className="bg-white rounded-3xl shadow-2xl border border-[#e5e7eb] max-w-2xl w-full p-6 animate-in zoom-in-95 duration-200">
            {/* Header */}
            <div className="flex items-center gap-3 mb-6">
              <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#c4a882] to-[#8c6e52] flex items-center justify-center">
                <Mail className="w-6 h-6 text-white" />
              </div>
              <div className="flex-1">
                <h3 className="text-xl text-[#1a1a2e]" style={{ fontWeight: 600 }}>
                  Gửi Email
                </h3>
                <p className="text-sm text-[#6b7280]">
                  Gửi email đến {emailModal.userName}
                </p>
              </div>
              <button
                onClick={closeEmailModal}
                disabled={isSending}
                className="w-8 h-8 rounded-lg hover:bg-[#f4f5f7] text-[#9ca3af] hover:text-[#1a1a2e] flex items-center justify-center transition-colors disabled:opacity-50"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Form */}
            <div className="space-y-4">
              {/* Recipient */}
              <div>
                <label className="block text-sm text-[#4b5563] mb-2" style={{ fontWeight: 500 }}>
                  Người nhận
                </label>
                <div className="px-4 py-3 rounded-xl bg-[#f9fafb] border border-[#e5e7eb] text-sm text-[#6b7280]">
                  {emailModal.userEmail}
                </div>
              </div>

              {/* Subject */}
              <div>
                <label className="block text-sm text-[#4b5563] mb-2" style={{ fontWeight: 500 }}>
                  Chủ đề <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={emailSubject}
                  onChange={(e) => setEmailSubject(e.target.value)}
                  placeholder="Nhập chủ đề email..."
                  disabled={isSending}
                  className="w-full px-4 py-3 rounded-xl bg-white border border-[#e5e7eb] text-sm text-[#1a1a2e] placeholder:text-[#9ca3af] focus:outline-none focus:ring-2 focus:ring-[#c4a882]/20 focus:border-[#c4a882] transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                />
              </div>

              {/* Message Body */}
              <div>
                <label className="block text-sm text-[#4b5563] mb-2" style={{ fontWeight: 500 }}>
                  Nội dung <span className="text-red-500">*</span>
                </label>
                <textarea
                  value={emailBody}
                  onChange={(e) => setEmailBody(e.target.value)}
                  placeholder="Nhập nội dung email..."
                  disabled={isSending}
                  rows={8}
                  className="w-full px-4 py-3 rounded-xl bg-white border border-[#e5e7eb] text-sm text-[#1a1a2e] placeholder:text-[#9ca3af] focus:outline-none focus:ring-2 focus:ring-[#c4a882]/20 focus:border-[#c4a882] transition-all resize-y disabled:opacity-50 disabled:cursor-not-allowed"
                />
              </div>
            </div>

            {/* Actions */}
            <div className="flex items-center gap-3 mt-6">
              <button
                onClick={closeEmailModal}
                disabled={isSending}
                className="flex-1 px-4 py-3 rounded-xl border border-[#e5e7eb] text-[#4b5563] text-sm hover:bg-[#f9fafb] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                style={{ fontWeight: 500 }}
              >
                Hủy
              </button>
              <button
                onClick={handleSendEmail}
                disabled={isSending || !emailSubject.trim() || !emailBody.trim()}
                className="flex-1 px-4 py-3 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] hover:from-[#b8996f] hover:to-[#7a5d44] text-white text-sm shadow-lg transition-all disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                style={{ fontWeight: 500 }}
              >
                {isSending ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Đang gửi...
                  </>
                ) : (
                  <>
                    <Send className="w-4 h-4" />
                    Gửi Email
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </AdminLayout>
  );
}
