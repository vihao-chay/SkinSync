import { useEffect, useState, useRef } from "react";
import { Link } from "react-router";
import {
  Flame,
  TrendingUp,
  Star,
  CheckCircle2,
  Circle,
  ChevronRight,
  Bell,
  Settings,
  Award,
  Droplets,
  Shield,
  Activity,
  Edit3,
  Camera,
} from "lucide-react";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import { ImageWithFallback } from "../components/figma/ImageWithFallback";
import { useAuth } from "../contexts/AuthContext";
import { updateAvatarApi } from "../services/authService";
import { resolveUserAvatar } from "../utils/avatar";

type TabType = "overview" | "products" | "history";

const skinTrendData = [
  { day: "T2", score: 70 },
  { day: "T3", score: 73 },
  { day: "T4", score: 71 },
  { day: "T5", score: 76 },
  { day: "T6", score: 79 },
  { day: "T7", score: 82 },
  { day: "CN", score: 87 },
];

const todayRoutine = [
  { name: "Sữa Rửa Mặt (Sáng)", done: true },
  { name: "Toner", done: true },
  { name: "Serum Vitamin C", done: false },
  { name: "Kem Chống Nắng SPF 50+", done: false },
  { name: "Tẩy Trang (Tối)", done: false },
  { name: "Serum Niacinamide", done: false },
];

const usingProducts = [
  {
    name: "CeraVe Cleanser",
    cat: "Sữa Rửa Mặt",
    daysLeft: 14,
    pct: 45,
    img: "https://images.unsplash.com/photo-1685052388326-b6383ec2d524?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMGNsZWFuc2VyJTIwZm9hbSUyMHByb2R1Y3QlMjBlbGVnYW50fGVufDF8fHx8MTc3NDAxMzAxN3ww&ixlib=rb-4.1.0&q=80&w=200",
    rating: 4.8,
  },
  {
    name: "Niacinamide 10%",
    cat: "Serum Trị Liệu",
    daysLeft: 22,
    pct: 67,
    img: "https://images.unsplash.com/photo-1770048792339-d8f8d8d2dbeb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMHNlcnVtJTIwYm90dGxlJTIwcHJvZHVjdCUyMG1pbmltYWxpc3QlMjB3aGl0ZXxlbnwxfHx8fDE3NzQwMTMwMTd8MA&ixlib=rb-4.1.0&q=80&w=200",
    rating: 4.9,
  },
  {
    name: "La Roche-Posay SPF 50",
    cat: "Chống Nắng",
    daysLeft: 8,
    pct: 20,
    img: "https://images.unsplash.com/photo-1594332322527-08753d4473c1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzdW5zY3JlZW4lMjBtb2lzdHVyaXplciUyMHNraW5jYXJlJTIwdHViZSUyMHByb2R1Y3R8ZW58MXx8fHwxNzc0MDEzMDE4fDA&ixlib=rb-4.1.0&q=80&w=200",
    rating: 4.9,
  },
  {
    name: "Klairs Night Cream",
    cat: "Dưỡng Đêm",
    daysLeft: 30,
    pct: 90,
    img: "https://images.unsplash.com/photo-1767360963892-3353defd6584?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMG5pZ2h0JTIwY3JlYW0lMjBtb2lzdHVyaXplciUyMGx1eHVyeSUyMGphcnxlbnwxfHx8fDE3NzQwMTMwMjF8MA&ixlib=rb-4.1.0&q=80&w=200",
    rating: 4.7,
  },
];

const analysisHistory = [
  { date: "20/03/2026", score: 87, type: "Da Hỗn Hợp", notes: "Cải thiện thâm rõ rệt, lỗ chân lông thu nhỏ 30%" },
  { date: "27/02/2026", score: 75, type: "Da Hỗn Hợp", notes: "Mụn giảm, nhưng vùng T vẫn còn dầu" },
  { date: "30/01/2026", score: 63, type: "Da Hỗn Hợp", notes: "Bắt đầu lộ trình, da đang thích nghi" },
  { date: "05/01/2026", score: 52, type: "Da Hỗn Hợp", notes: "Phân tích lần đầu — nhiều vấn đề cần giải quyết" },
];

const CustomTooltip = ({ active, payload }: any) => {
  if (active && payload?.length) {
    return (
      <div className="bg-white/90 backdrop-blur-md border border-white/60 rounded-xl px-3 py-2 shadow-lg">
        <p className="text-xs text-[#c4a882]">Điểm: {payload[0].value}/100</p>
      </div>
    );
  }
  return null;
};

export function ProfilePage() {
  const { user, setCurrentUser } = useAuth();
  const [activeTab, setActiveTab] = useState<TabType>("overview");
  const [routineChecks, setRoutineChecks] = useState(
    todayRoutine.map((t) => t.done)
  );
  const [avatarUrl, setAvatarUrl] = useState(resolveUserAvatar(user));
  const [avatarUploading, setAvatarUploading] = useState(false);
  const avatarInputRef = useRef<HTMLInputElement>(null);

  const completedToday = routineChecks.filter(Boolean).length;

  const toggleCheck = (i: number) => {
    setRoutineChecks((prev) => prev.map((v, idx) => (idx === i ? !v : v)));
  };

  const handleAvatarChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) {
      return;
    }

    setAvatarUploading(true);

    try {
      const result = await updateAvatarApi(file);
      if (result.success && result.content) {
        setCurrentUser(result.content);
        setAvatarUrl(resolveUserAvatar(result.content));
      }
    } finally {
      setAvatarUploading(false);
      e.target.value = "";
    }
  };

  const displayName = user?.fullName ?? "Bạn";
  const displayEmail = user?.email ?? "";

  useEffect(() => {
    setAvatarUrl(resolveUserAvatar(user));
  }, [user]);

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#f5f5f0] via-[#d4f4f4]/10 to-white pt-20">

      {/* Profile Header */}
      <div className="relative overflow-hidden bg-gradient-to-br from-white via-[#fce7f3]/30 to-[#d4f4f4]/20 border-b border-white/60">
        {/* Background blobs */}
        <div className="absolute top-0 right-0 w-80 h-80 bg-gradient-to-bl from-[#8c6e52]/15 to-transparent rounded-full blur-3xl pointer-events-none" />
        <div className="absolute bottom-0 left-1/4 w-60 h-60 bg-gradient-to-tr from-[#d4f4f4]/40 to-transparent rounded-full blur-2xl pointer-events-none" />

        <div className="relative max-w-7xl mx-auto px-6 py-8">
          <div className="flex flex-col sm:flex-row sm:items-center gap-6">
            {/* Avatar */}
            <div className="relative flex-shrink-0">
              <div className="absolute -inset-1.5 rounded-full bg-gradient-to-br from-[#c4a882] via-[#8c6e52] to-[#e8d5b7] animate-pulse opacity-70" />
              <input
                ref={avatarInputRef}
                type="file"
                accept="image/*"
                className="hidden"
                onChange={handleAvatarChange}
              />
              <button
                onClick={() => avatarInputRef.current?.click()}
                disabled={avatarUploading}
                className="relative w-24 h-24 rounded-full overflow-hidden border-4 border-white shadow-xl group cursor-pointer"
              >
                <ImageWithFallback
                  src={avatarUrl}
                  alt="User Avatar"
                  className="w-full h-full object-cover object-top"
                />
                <div className="absolute inset-0 bg-black/30 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                  {avatarUploading ? (
                    <div className="w-5 h-5 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                  ) : (
                    <Camera className="w-5 h-5 text-white" />
                  )}
                </div>
              </button>
            </div>

            {/* User Info */}
            <div className="flex-1">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div className="flex items-center gap-2 mb-1">
                    <h1 className="text-2xl text-[#2a2a2a]">Xin chào, {displayName} 👋</h1>
                    <Link
                      to="/settings/security"
                      className="p-1.5 rounded-full hover:bg-[#c4a882]/10 text-[#9ca3af] hover:text-[#c4a882] transition-colors"
                      title="Chỉnh sửa thông tin tài khoản"
                    >
                      <Edit3 className="w-4 h-4" />
                    </Link>
                  </div>
                  <p className="text-[#6b7280] text-sm">{displayName} · {displayEmail}</p>
                </div>
                <div className="flex items-center gap-2">
                  <button className="p-2 rounded-full hover:bg-white/70 transition-colors">
                    <Bell className="w-4 h-4 text-[#6b7280]" />
                  </button>
                  <button className="p-2 rounded-full hover:bg-white/70 transition-colors">
                    <Settings className="w-4 h-4 text-[#6b7280]" />
                  </button>
                </div>
              </div>

              {/* Quick Stats */}
              <div className="flex flex-wrap gap-3 mt-4">
                <div className="flex items-center gap-2.5 px-4 py-2.5 rounded-2xl bg-gradient-to-r from-[#c4a882]/10 to-[#8c6e52]/10 border border-[#c4a882]/20">
                  <Flame className="w-4 h-4 text-orange-500" />
                  <div>
                    <div className="text-sm text-[#2a2a2a]">
                      Chuỗi Ngày Skincare:{" "}
                      <span className="text-[#c4a882]">14 Ngày 🔥</span>
                    </div>
                    <div className="text-xs text-[#9ca3af]">Kỷ lục: 28 ngày</div>
                  </div>
                </div>

                <div className="flex items-center gap-2.5 px-4 py-2.5 rounded-2xl bg-white/70 border border-white/80 shadow-sm">
                  <Star className="w-4 h-4 text-[#c4a882]" />
                  <div>
                    <div className="text-sm text-[#2a2a2a]">
                      Điểm Da:{" "}
                      <span className="text-[#c4a882]">87/100</span>
                    </div>
                    <div className="text-xs text-emerald-600">↑ +35 pts so với lần đầu</div>
                  </div>
                </div>

                <div className="flex items-center gap-2.5 px-4 py-2.5 rounded-2xl bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-100">
                  <Award className="w-4 h-4 text-amber-500" />
                  <div className="text-sm text-[#2a2a2a]">Huy Hiệu: <span className="text-amber-600">Người Kiên Trì ⭐</span></div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="max-w-7xl mx-auto px-6">
        <div className="flex gap-1 pt-5 border-b border-gray-100">
          {(["overview", "products", "history"] as TabType[]).map((tab) => {
            const labels: Record<TabType, string> = {
              overview: "Tổng Quan",
              products: "Sản Phẩm Đang Dùng",
              history: "Lịch Sử Phân Tích",
            };
            return (
              <button
                key={tab}
                onClick={() => setActiveTab(tab)}
                className={`px-5 py-3 rounded-t-xl text-sm transition-all relative ${activeTab === tab
                  ? "text-[#c4a882] bg-white shadow-sm"
                  : "text-[#6b7280] hover:text-[#2a2a2a]"
                  }`}
              >
                {labels[tab]}
                {activeTab === tab && (
                  <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-gradient-to-r from-[#c4a882] to-[#8c6e52] rounded-full" />
                )}
              </button>
            );
          })}
        </div>

        {/* ── TAB: OVERVIEW ── */}
        {activeTab === "overview" && (
          <div className="py-6 grid lg:grid-cols-3 gap-5">
            {/* Left Col */}
            <div className="lg:col-span-2 flex flex-col gap-5">
              {/* Skin Summary Card */}
              <div className="bg-white/80 backdrop-blur-md rounded-3xl border border-white/80 shadow-sm p-5">
                <h3 className="text-[#2a2a2a] mb-4">Tình Trạng Da Hiện Tại</h3>
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                  {[
                    { label: "Loại Da", value: "Da Hỗn Hợp", icon: <Droplets className="w-4 h-4" />, color: "#c4a882" },
                    { label: "Điểm Da", value: "87/100", icon: <Star className="w-4 h-4" />, color: "#8c6e52" },
                    { label: "Hàng Rào Da", value: "Tốt", icon: <Shield className="w-4 h-4" />, color: "#10b981" },
                    { label: "Phục Hồi", value: "Nhanh", icon: <Activity className="w-4 h-4" />, color: "#f59e0b" },
                  ].map((s) => (
                    <div
                      key={s.label}
                      className="rounded-2xl p-3 border border-gray-100 bg-[#fafafa] text-center"
                    >
                      <div className="flex justify-center mb-2" style={{ color: s.color }}>
                        {s.icon}
                      </div>
                      <div className="text-sm text-[#2a2a2a] mb-0.5" style={{ color: s.color }}>
                        {s.value}
                      </div>
                      <div className="text-xs text-[#9ca3af]">{s.label}</div>
                    </div>
                  ))}
                </div>

                <div className="mt-4 p-3.5 rounded-2xl bg-gradient-to-r from-[#c4a882]/8 to-[#8c6e52]/8 border border-[#c4a882]/15">
                  <p className="text-sm text-[#4b5563]">
                    🎯 <strong className="text-[#2a2a2a]">Vấn Đề Đang Cải Thiện:</strong>{" "}
                    Mụn giảm 65%, thâm mờ đi rõ rệt, lỗ chân lông đang thu nhỏ dần.
                    AI dự báo đạt điểm{" "}
                    <span className="text-[#c4a882]">92/100</span> trong 2 tuần tới.
                  </p>
                </div>
              </div>

              {/* Mini Progress Chart */}
              <div className="bg-white/80 backdrop-blur-md rounded-3xl border border-white/80 shadow-sm p-5">
                <div className="flex items-center justify-between mb-4">
                  <div>
                    <h3 className="text-[#2a2a2a]">Xu Hướng Điểm Da</h3>
                    <p className="text-xs text-[#6b7280]">7 ngày gần nhất</p>
                  </div>
                  <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-emerald-50 border border-emerald-100">
                    <TrendingUp className="w-3.5 h-3.5 text-emerald-600" />
                    <span className="text-xs text-emerald-600">+17 pts</span>
                  </div>
                </div>
                <div className="h-40">
                  <ResponsiveContainer width="100%" height="100%">
                    <AreaChart id="profile-skin-trend" data={skinTrendData} margin={{ top: 5, right: 5, left: -28, bottom: 0 }}>
                      <defs>
                        <linearGradient id="profileTrendGrad" x1="0" y1="0" x2="0" y2="1">
                          <stop offset="5%" stopColor="#c4a882" stopOpacity={0.2} />
                          <stop offset="95%" stopColor="#c4a882" stopOpacity={0} />
                        </linearGradient>
                      </defs>
                      <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" vertical={false} />
                      <XAxis dataKey="day" axisLine={false} tickLine={false} tick={{ fill: "#9ca3af", fontSize: 11 }} />
                      <YAxis domain={[60, 95]} axisLine={false} tickLine={false} tick={{ fill: "#9ca3af", fontSize: 11 }} />
                      <Tooltip content={<CustomTooltip />} />
                      <Area
                        type="monotone"
                        dataKey="score"
                        stroke="#c4a882"
                        strokeWidth={2.5}
                        fill="url(#profileTrendGrad)"
                        dot={{ fill: "#c4a882", r: 3.5, strokeWidth: 2, stroke: "#fff" }}
                        activeDot={{ r: 5, fill: "#c4a882", stroke: "#fff", strokeWidth: 2 }}
                      />
                    </AreaChart>
                  </ResponsiveContainer>
                </div>
              </div>
            </div>

            {/* Right Col — Today's Routine */}
            <div className="flex flex-col gap-5">
              <div className="bg-white/80 backdrop-blur-md rounded-3xl border border-white/80 shadow-sm p-5">
                <div className="flex items-center justify-between mb-1">
                  <h3 className="text-[#2a2a2a]">Lộ Trình Hôm Nay</h3>
                  <Link to="/routine" className="text-xs text-[#c4a882] hover:text-[#8c6e52] transition-colors flex items-center gap-0.5">
                    Chi Tiết <ChevronRight className="w-3 h-3" />
                  </Link>
                </div>
                <p className="text-xs text-[#6b7280] mb-4">
                  {completedToday}/{todayRoutine.length} bước hoàn thành
                </p>

                <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden mb-4">
                  <div
                    className="h-full rounded-full bg-gradient-to-r from-[#c4a882] to-[#8c6e52] transition-all duration-500"
                    style={{ width: `${(completedToday / todayRoutine.length) * 100}%` }}
                  />
                </div>

                <div className="flex flex-col gap-2">
                  {todayRoutine.map((item, i) => (
                    <button
                      key={i}
                      onClick={() => toggleCheck(i)}
                      className={`flex items-center gap-3 p-2.5 rounded-xl text-left transition-all ${routineChecks[i]
                        ? "bg-[#c4a882]/5 border border-[#c4a882]/15"
                        : "hover:bg-[#f9fafb] border border-transparent"
                        }`}
                    >
                      {routineChecks[i] ? (
                        <CheckCircle2 className="w-4 h-4 text-[#c4a882] flex-shrink-0" />
                      ) : (
                        <Circle className="w-4 h-4 text-[#d1d5db] flex-shrink-0" />
                      )}
                      <span
                        className={`text-sm transition-colors ${routineChecks[i]
                          ? "text-[#9ca3af] line-through"
                          : "text-[#2a2a2a]"
                          }`}
                      >
                        {item.name}
                      </span>
                    </button>
                  ))}
                </div>

                {completedToday === todayRoutine.length && (
                  <div className="mt-4 p-3 rounded-2xl bg-gradient-to-r from-emerald-50 to-teal-50 border border-emerald-100 text-center">
                    <p className="text-sm text-emerald-700">🎉 Hoàn thành lộ trình hôm nay!</p>
                  </div>
                )}
              </div>

              {/* Quick Links */}
              <div className="bg-white/60 rounded-2xl p-4 border border-white/80 flex flex-col gap-2">
                {[
                  { label: "Xem Báo Cáo Da", to: "/analysis", icon: "📊" },
                  { label: "Cập Nhật Lộ Trình", to: "/routine", icon: "🌿" },
                  { label: "Tiến Trình 30 Ngày", to: "/progress", icon: "📈" },
                ].map((link) => (
                  <Link
                    key={link.label}
                    to={link.to}
                    className="flex items-center gap-3 p-2.5 rounded-xl hover:bg-white transition-colors group"
                  >
                    <span className="text-base">{link.icon}</span>
                    <span className="text-sm text-[#4b5563] group-hover:text-[#c4a882] transition-colors flex-1">
                      {link.label}
                    </span>
                    <ChevronRight className="w-3.5 h-3.5 text-[#9ca3af] group-hover:text-[#c4a882] transition-colors" />
                  </Link>
                ))}
              </div>
            </div>
          </div>
        )}

        {/* ── TAB: PRODUCTS ── */}
        {activeTab === "products" && (
          <div className="py-6">
            <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {usingProducts.map((p) => (
                <div
                  key={p.name}
                  className="bg-white/80 backdrop-blur-md rounded-3xl border border-white/80 shadow-sm p-4 flex flex-col gap-3"
                >
                  <div className="aspect-square rounded-2xl overflow-hidden bg-[#f5f5f0]">
                    <ImageWithFallback
                      src={p.img}
                      alt={p.name}
                      className="w-full h-full object-cover"
                    />
                  </div>
                  <div>
                    <p className="text-sm text-[#2a2a2a] mb-0.5">{p.name}</p>
                    <p className="text-xs text-[#9ca3af]">{p.cat}</p>
                    <div className="flex items-center gap-1 mt-1">
                      <Star className="w-3 h-3 fill-amber-400 text-amber-400" />
                      <span className="text-xs text-[#6b7280]">{p.rating}</span>
                    </div>
                  </div>
                  <div>
                    <div className="flex justify-between text-xs mb-1">
                      <span className="text-[#6b7280]">Còn lại</span>
                      <span className={p.daysLeft <= 10 ? "text-red-500" : "text-[#c4a882]"}>
                        {p.daysLeft} ngày
                      </span>
                    </div>
                    <div className="h-1.5 bg-gray-100 rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all"
                        style={{
                          width: `${p.pct}%`,
                          backgroundColor: p.daysLeft <= 10 ? "#ef4444" : "#c4a882",
                        }}
                      />
                    </div>
                  </div>
                  {p.daysLeft <= 10 && (
                    <div className="px-2 py-1 rounded-lg bg-red-50 text-red-600 text-xs text-center">
                      ⚠️ Sắp hết — Đặt mua lại
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}

        {/* ── TAB: HISTORY ── */}
        {activeTab === "history" && (
          <div className="py-6 max-w-3xl">
            <div className="flex flex-col gap-4">
              {analysisHistory.map((record, i) => (
                <div
                  key={i}
                  className="flex gap-4 bg-white/80 backdrop-blur-md rounded-2xl border border-white/80 shadow-sm p-5 hover:shadow-md transition-shadow"
                >
                  <div className="flex flex-col items-center">
                    <div
                      className="w-4 h-4 rounded-full flex-shrink-0 border-2 border-white shadow-sm"
                      style={{
                        background: i === 0
                          ? "linear-gradient(135deg, #c4a882, #8c6e52)"
                          : "#e5e7eb",
                      }}
                    />
                    {i < analysisHistory.length - 1 && (
                      <div className="flex-1 w-0.5 bg-gray-100 mt-2" />
                    )}
                  </div>

                  <div className="flex-1 pb-2">
                    <div className="flex items-start justify-between gap-2 mb-2">
                      <div>
                        <span className="text-xs text-[#9ca3af]">{record.date}</span>
                        <div className="flex items-center gap-2 mt-0.5">
                          <span className="text-sm text-[#2a2a2a]">{record.type}</span>
                          {i === 0 && (
                            <span className="px-2 py-0.5 rounded-full bg-[#c4a882]/10 text-[#c4a882] text-[10px]">
                              Mới nhất
                            </span>
                          )}
                        </div>
                      </div>
                      <div
                        className="text-xl flex-shrink-0"
                        style={{ color: record.score >= 80 ? "#c4a882" : record.score >= 65 ? "#f59e0b" : "#9ca3af" }}
                      >
                        {record.score}
                        <span className="text-sm text-[#9ca3af]">/100</span>
                      </div>
                    </div>
                    <p className="text-xs text-[#6b7280] leading-relaxed">{record.notes}</p>
                    <Link
                      to="/analysis"
                      className="inline-flex items-center gap-1 text-xs text-[#c4a882] hover:text-[#8c6e52] transition-colors mt-2"
                    >
                      Xem Chi Tiết <ChevronRight className="w-3 h-3" />
                    </Link>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="pb-8" />
      </div>
    </div>
  );
}