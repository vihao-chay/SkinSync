import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router";
import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import {
  Sparkles,
  TrendingUp,
  Camera,
  CheckCircle2,
  ChevronRight,
  Star,
  RefreshCw,
  Flame,
  Sun,
  Moon,
  ArrowUpRight,
  Zap,
  Droplets,
} from "lucide-react";
import { ImageWithFallback } from "../components/figma/ImageWithFallback";
import {
  getMonthlyReportApi,
  getProgressChartApi,
  getProgressOverviewApi,
  getProgressStreakApi,
  getWeeklyCompletionApi,
} from "../services/progressService";

const fallbackSkinScoreData = [
  { label: "T1 W1", score: 52, hydration: 45 },
  { label: "T1 W2", score: 60, hydration: 55 },
  { label: "T2 W1", score: 63, hydration: 60 },
  { label: "T2 W2", score: 70, hydration: 68 },
  { label: "T3 W1", score: 75, hydration: 72 },
  { label: "T3 W2", score: 80, hydration: 79 },
  { label: "T4",    score: 87, hydration: 85 },
];

const morningRoutineNew = [
  { step: 1, name: "Sữa Rửa Mặt Nhẹ",    product: "Gentle Hydrating Cleanser",  isUpdated: false, icon: "🌿" },
  { step: 2, name: "Toner Cân Bằng",       product: "pH Balancing Toner",         isUpdated: false, icon: "💧" },
  { step: 3, name: "Serum HA ×2",          product: "Hyaluronic Acid Boost",      isUpdated: true,  icon: "✨" },
  { step: 4, name: "Kem Dưỡng Phục Hồi",  product: "Barrier Repair Moisturizer", isUpdated: true,  icon: "🌸" },
  { step: 5, name: "Kem Chống Nắng SPF 50+", product: "Invisible Sunscreen",     isUpdated: false, icon: "☀️" },
];

const eveningRoutineNew = [
  { step: 1, name: "Tẩy Trang",         product: "Cleansing Oil DHC",          isUpdated: false, icon: "🫧" },
  { step: 2, name: "Sữa Rửa Mặt",       product: "Gentle Foam Cleanser",       isUpdated: false, icon: "🌿" },
  { step: 3, name: "Serum Niacinamide",  product: "Niacinamide 5% (Giảm)",     isUpdated: true,  icon: "💊" },
  { step: 4, name: "Kem Dưỡng Ẩm Đậm",  product: "Rich Barrier Night Cream",   isUpdated: true,  icon: "🌙" },
];

const CustomTooltip = ({ active, payload, label }: any) => {
  if (active && payload?.length) {
    return (
      <div className="bg-white border border-[#e8ddd0] rounded-2xl px-4 py-3 shadow-lg">
        <p className="text-xs text-[#9ca3af] mb-1">{label}</p>
        <p className="text-sm text-[#c4a882]">Điểm Da: {payload[0]?.value}/100</p>
        <p className="text-sm text-[#8c6e52]">Độ Ẩm: {payload[1]?.value}%</p>
      </div>
    );
  }
  return null;
};

export function ProgressPage() {
  const navigate = useNavigate();
  const [overview, setOverview] = useState({
    startScore: 52,
    currentScore: 87,
    improvementPercent: 67,
    completedDaysLast28: 28,
    currentStreak: 13,
  });
  const [chartData, setChartData] = useState(fallbackSkinScoreData);
  const [weeklyCompletion, setWeeklyCompletion] = useState(86);
  const [monthlyReport, setMonthlyReport] = useState({
    completedDays: 24,
    fullRoutineDays: 18,
    bestStreak: 13,
  });

  useEffect(() => {
    let isMounted = true;

    const load = async () => {
      const [overviewResult, chartResult, streakResult, weeklyResult, monthlyResult] = await Promise.all([
        getProgressOverviewApi(),
        getProgressChartApi(30),
        getProgressStreakApi(30),
        getWeeklyCompletionApi(),
        getMonthlyReportApi(),
      ]);

      if (!isMounted) {
        return;
      }

      if (overviewResult.success && overviewResult.content) {
        setOverview((prev) => ({
          ...prev,
          startScore: overviewResult.content.startScore ?? prev.startScore,
          currentScore: overviewResult.content.currentScore ?? prev.currentScore,
          improvementPercent: Math.round(overviewResult.content.improvementPercent),
          completedDaysLast28: overviewResult.content.completedDaysLast28,
          currentStreak: overviewResult.content.currentStreak,
        }));
      }

      if (streakResult.success && streakResult.content) {
        setOverview((prev) => ({
          ...prev,
          currentStreak: streakResult.content.currentStreak,
        }));
      }

      if (chartResult.success && chartResult.content && chartResult.content.length > 0) {
        const mapped = chartResult.content.map((item) => ({
          label: item.date,
          score: item.overallScore,
          hydration: item.hydrationScore ?? item.overallScore,
        }));

        setChartData(mapped);
      }

      if (weeklyResult.success && weeklyResult.content) {
        setWeeklyCompletion(Math.round(weeklyResult.content.completionPercent));
      }

      if (monthlyResult.success && monthlyResult.content) {
        setMonthlyReport({
          completedDays: monthlyResult.content.completedDays,
          fullRoutineDays: monthlyResult.content.fullRoutineDays,
          bestStreak: monthlyResult.content.bestStreak,
        });
      }
    };

    void load();
    return () => {
      isMounted = false;
    };
  }, []);

  const improvementPercent = useMemo(() => overview.improvementPercent, [overview.improvementPercent]);

  return (
    <div className="min-h-screen bg-[#faf7f2] pt-20">

      {/* ── HERO HEADER ── */}
      <div className="bg-white border-b border-[#ede8e0]">
        <div className="max-w-6xl mx-auto px-6 py-10">
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div>
              <div className="flex items-center gap-2 mb-3">
                <span className="px-3 py-1 rounded-full bg-[#f5ede3] border border-[#e8d5b7] text-[#8c6e52] text-xs">
                  ✦ Báo Cáo 4 Tuần
                </span>
                <span className="px-3 py-1 rounded-full bg-orange-50 border border-orange-100 text-orange-600 text-xs flex items-center gap-1">
                  <Flame className="w-3 h-3" /> {overview.currentStreak} ngày streak
                </span>
              </div>
              <h1 className="text-3xl text-[#2a2a2a] mb-1">Tiến Độ Của Bạn</h1>
              <p className="text-[#6b7280] text-sm">
                AI theo dõi và tối ưu lộ trình theo phản hồi thực tế của làn da bạn.
              </p>
            </div>
            <div className="flex gap-2 flex-shrink-0">
              <button
                onClick={() => navigate("/checkin")}
                className="flex items-center gap-2 px-5 py-2.5 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white text-sm shadow-sm hover:opacity-90 transition-opacity"
              >
                <Camera className="w-4 h-4" />
                Check-in
                <ArrowUpRight className="w-3.5 h-3.5" />
              </button>
              <Link
                to="/routine"
                className="flex items-center gap-2 px-5 py-2.5 rounded-xl border border-[#c4a882]/40 text-[#c4a882] text-sm hover:bg-[#c4a882]/5 transition-colors bg-white"
              >
                <RefreshCw className="w-4 h-4" />
                Lộ Trình
              </Link>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-6xl mx-auto px-6 py-8 flex flex-col gap-6">

        {/* ── STATS ROW ── */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
          {[
            { label: "Điểm Da Hiện Tại",  value: `${overview.currentScore}`, unit: "/100", color: "#c4a882", bg: "#fdf8f2", icon: <Star className="w-4 h-4" /> },
            { label: "Cải Thiện",          value: `+${improvementPercent}`, unit: "%", color: "#10b981", bg: "#f0fdf4", icon: <TrendingUp className="w-4 h-4" /> },
            { label: "Hoàn Thành Tuần",       value: `${weeklyCompletion}`, unit: "%", color: "#8c6e52", bg: "#fdf8f2", icon: <CheckCircle2 className="w-4 h-4" /> },
            { label: "Streak Hiện Tại",    value: `${overview.currentStreak}`, unit: " ngày", color: "#f97316", bg: "#fff7ed", icon: <Flame className="w-4 h-4" /> },
          ].map((s) => (
            <div
              key={s.label}
              className="rounded-2xl border border-[#ede8e0] p-4 flex flex-col gap-2"
              style={{ backgroundColor: s.bg }}
            >
              <div className="flex items-center gap-1.5" style={{ color: s.color }}>
                {s.icon}
                <span className="text-xs text-[#6b7280]">{s.label}</span>
              </div>
              <div className="text-2xl" style={{ color: s.color }}>
                {s.value}
                <span className="text-sm text-[#9ca3af]">{s.unit}</span>
              </div>
            </div>
          ))}
        </div>

        <div className="grid sm:grid-cols-3 gap-4">
          {[
            { label: "Check-in Tháng Này", value: `${monthlyReport.completedDays}`, unit: " ngày" },
            { label: "Đủ Sáng Và Tối", value: `${monthlyReport.fullRoutineDays}`, unit: " ngày" },
            { label: "Best Streak Tháng", value: `${monthlyReport.bestStreak}`, unit: " ngày" },
          ].map((item) => (
            <div key={item.label} className="rounded-2xl border border-[#e8d5b7]/50 bg-white p-4 shadow-sm">
              <p className="text-xs text-[#6b7280] mb-2">{item.label}</p>
              <p className="text-2xl text-[#8c6e52]">
                {item.value}
                <span className="text-sm text-[#9ca3af]">{item.unit}</span>
              </p>
            </div>
          ))}
        </div>

        {/* ── CHART + AI ANALYSIS ── */}
        <div className="grid lg:grid-cols-3 gap-6">

          {/* Chart */}
          <div className="lg:col-span-2 bg-white rounded-3xl border border-[#ede8e0] shadow-sm p-6">
            <div className="flex items-start justify-between mb-5 gap-3 flex-wrap">
              <div>
                <h2 className="text-[#2a2a2a] mb-1">Biểu Đồ Cải Thiện Da</h2>
                <p className="text-sm text-[#6b7280]">Điểm da tăng từ {overview.startScore} → {overview.currentScore} trong 4 tuần</p>
              </div>
              <div className="flex items-center gap-4 text-xs text-[#9ca3af]">
                <span className="flex items-center gap-1.5">
                  <span className="w-2.5 h-2.5 rounded-full bg-[#c4a882] inline-block" />Điểm Da
                </span>
                <span className="flex items-center gap-1.5">
                  <span className="w-2.5 h-2.5 rounded-full bg-[#8c6e52] inline-block" />Độ Ẩm
                </span>
              </div>
            </div>

            <div className="h-52">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart id="progress-main-chart" data={chartData} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
                  <defs>
                    <linearGradient id="pgScoreGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#c4a882" stopOpacity={0.18} />
                      <stop offset="95%" stopColor="#c4a882" stopOpacity={0} />
                    </linearGradient>
                    <linearGradient id="pgHydroGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#8c6e52" stopOpacity={0.12} />
                      <stop offset="95%" stopColor="#8c6e52" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f0ebe3" vertical={false} />
                  <XAxis dataKey="label" axisLine={false} tickLine={false} tick={{ fill: "#9ca3af", fontSize: 11 }} />
                  <YAxis domain={[40, 100]} axisLine={false} tickLine={false} tick={{ fill: "#9ca3af", fontSize: 11 }} />
                  <Tooltip content={<CustomTooltip />} />
                  <Area type="monotone" dataKey="score" stroke="#c4a882" strokeWidth={2.5} fill="url(#pgScoreGrad)"
                    dot={{ fill: "#c4a882", r: 4, strokeWidth: 2, stroke: "#fff" }}
                    activeDot={{ r: 6, fill: "#c4a882", stroke: "#fff", strokeWidth: 2 }}
                  />
                  <Area type="monotone" dataKey="hydration" stroke="#8c6e52" strokeWidth={2}
                    strokeDasharray="5 3" fill="url(#pgHydroGrad)"
                    dot={{ fill: "#8c6e52", r: 3, strokeWidth: 2, stroke: "#fff" }}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>

            {/* Week milestones */}
            <div className="grid grid-cols-4 gap-3 mt-5 pt-5 border-t border-[#f0ebe3]">
              {[
                { label: "Tuần 1", score: 52, note: "Bắt đầu",   active: false },
                { label: "Tuần 2", score: 63, note: "Ổn định",   active: false },
                { label: "Tuần 3", score: 75, note: "Cải thiện", active: false },
                { label: "Tuần 4", score: 87, note: "Bứt phá 🎉", active: true },
              ].map((w) => (
                <div key={w.label} className="text-center">
                  <p className="text-xs text-[#9ca3af] mb-2">{w.label}</p>
                  <div className="flex items-end justify-center h-16 mb-1">
                    <div
                      className="w-7 rounded-t-lg"
                      style={{
                        height: `${(w.score / 100) * 64}px`,
                        background: w.active ? "linear-gradient(to top, #c4a882, #8c6e52)" : "#e8ddd0",
                      }}
                    />
                  </div>
                  <div className="text-sm" style={{ color: w.active ? "#c4a882" : "#9ca3af" }}>{w.score}</div>
                  <div className="text-[10px] text-[#9ca3af] mt-0.5">{w.note}</div>
                </div>
              ))}
            </div>
          </div>

          {/* AI Analysis */}
          <div className="bg-white rounded-3xl border border-[#e8d5b7] shadow-sm overflow-hidden">
            {/* Header */}
            <div className="bg-gradient-to-r from-[#c4a882]/10 to-[#8c6e52]/10 px-5 py-4 border-b border-[#e8d5b7]/60 flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[#c4a882] to-[#8c6e52] flex items-center justify-center shadow-sm">
                <Sparkles className="w-4 h-4 text-white" />
              </div>
              <div>
                <h3 className="text-[#2a2a2a] text-sm">AI Phân Tích & Điều Chỉnh</h3>
                <div className="flex items-center gap-1.5 mt-0.5">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                  <span className="text-xs text-[#6b7280]">Thời gian thực</span>
                </div>
              </div>
            </div>

            <div className="p-5 flex flex-col gap-4">
              {/* AI note */}
              <div className="bg-[#fdf8f2] rounded-2xl p-4 border border-[#e8d5b7]/50">
                <p className="text-xs text-[#9ca3af] mb-2">🧠 Nhận xét của AI</p>
                <p className="text-sm text-[#4b5563] leading-relaxed">
                  Da bạn đang cải thiện tốt nhưng có{" "}
                  <span className="text-amber-600">chút khô hơn</span> ở vùng má. AI đã{" "}
                  <span className="text-[#c4a882]">giảm Serum trị liệu</span> và{" "}
                  <span className="text-[#c4a882]">tăng cường dưỡng ẩm</span> để cân bằng hàng rào da.
                </p>
              </div>

              {/* Changes */}
              <div className="flex flex-col gap-2">
                <p className="text-xs text-[#9ca3af] uppercase tracking-wide">Thay đổi lộ trình</p>
                {[
                  { text: "Giảm Serum Vitamin C → 3×/tuần", type: "down", icon: "⬇️" },
                  { text: "Tăng Serum HA → 2 lớp sáng",     type: "up",   icon: "⬆️" },
                  { text: "Thêm Kem Barrier Repair tối",     type: "new",  icon: "✨" },
                ].map((c, i) => (
                  <div
                    key={i}
                    className={`flex items-center gap-2.5 px-3 py-2.5 rounded-xl text-xs border ${
                      c.type === "up"
                        ? "bg-emerald-50 text-emerald-700 border-emerald-100"
                        : c.type === "down"
                        ? "bg-amber-50 text-amber-700 border-amber-100"
                        : "bg-[#fdf8f2] text-[#c4a882] border-[#e8d5b7]"
                    }`}
                  >
                    <span>{c.icon}</span>
                    <span>{c.text}</span>
                  </div>
                ))}
              </div>

              {/* Skin metrics */}
              <div className="flex flex-col gap-3">
                <p className="text-xs text-[#9ca3af] uppercase tracking-wide">Chỉ số da</p>
                {[
                  { label: "Độ Ẩm Da",       value: 85, color: "#c4a882" },
                  { label: "Độ Sáng",         value: 78, color: "#8c6e52" },
                  { label: "Kết Cấu Da",      value: 82, color: "#10b981" },
                  { label: "Kiểm Soát Dầu",   value: 70, color: "#f59e0b" },
                ].map((item) => (
                  <div key={item.label}>
                    <div className="flex justify-between text-xs mb-1">
                      <span className="text-[#6b7280]">{item.label}</span>
                      <span style={{ color: item.color }}>{item.value}%</span>
                    </div>
                    <div className="h-1.5 bg-[#f0ebe3] rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all"
                        style={{ width: `${item.value}%`, backgroundColor: item.color }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* ── BEFORE / AFTER ── */}
        <div className="bg-white rounded-3xl border border-[#ede8e0] shadow-sm p-6">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h2 className="text-[#2a2a2a] mb-1">So Sánh Trước & Sau</h2>
              <p className="text-sm text-[#6b7280]">Kết quả sau 4 tuần theo lộ trình AI</p>
            </div>
            <Link
              to="/checkin"
              className="flex items-center gap-2 px-4 py-2 rounded-full border border-[#c4a882]/30 text-[#c4a882] text-sm hover:bg-[#c4a882]/5 transition-colors"
            >
              <Camera className="w-4 h-4" />
              Thêm Ảnh
            </Link>
          </div>

          <div className="grid sm:grid-cols-2 gap-5">
            {/* Before */}
            <div className="relative overflow-hidden rounded-2xl aspect-[4/3]">
              <div className="absolute top-3 left-3 z-10 px-3 py-1 rounded-full bg-black/50 backdrop-blur-sm text-white text-xs">
                Tuần 1
              </div>
              <ImageWithFallback
                src="https://images.unsplash.com/photo-1679584169621-db3aa6c0fbd6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMGJlZm9yZSUyMGFmdGVyJTIwbmF0dXJhbCUyMHNraW4lMjBnbG93fGVufDF8fHx8MTc3NDAwNjkzM3ww&ixlib=rb-4.1.0&q=80&w=1080"
                alt="Da trước"
                className="w-full h-full object-cover grayscale-[30%]"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/40 to-transparent" />
              <div className="absolute bottom-3 left-3 right-3">
                <div className="bg-black/30 backdrop-blur-sm rounded-xl px-3 py-2 text-center">
                  <span className="text-white text-xs">Điểm Da: 52/100</span>
                </div>
              </div>
            </div>

            {/* After */}
            <div className="relative overflow-hidden rounded-2xl aspect-[4/3] ring-2 ring-[#c4a882]/40">
              <div className="absolute top-3 left-3 z-10 px-3 py-1 rounded-full bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white text-xs">
                Hiện Tại ✦
              </div>
              <ImageWithFallback
                src="https://images.unsplash.com/photo-1596663265694-0a8d593a74cc?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkZXd5JTIwZ2xvd2luZyUyMGNsZWFyJTIwc2tpbiUyMHBvcnRyYWl0JTIwcmFkaWFudCUyMGJlYXV0eXxlbnwxfHx8fDE3NzQwMTQ2ODV8MA&ixlib=rb-4.1.0&q=80&w=1080"
                alt="Da sau"
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-[#8c6e52]/30 to-transparent" />
              <div className="absolute bottom-3 left-3 right-3">
                <div className="bg-white/25 backdrop-blur-sm rounded-xl px-3 py-2 text-center">
                  <span className="text-white text-xs">Điểm Da: 87/100 ↑ +67%</span>
                </div>
              </div>
            </div>
          </div>

          {/* Metrics row */}
          <div className="grid grid-cols-3 gap-4 mt-5 pt-5 border-t border-[#f0ebe3]">
            {[
              { label: "Giảm Thâm",   value: "74%",  icon: "🌟", color: "#c4a882" },
              { label: "Tăng Độ Ẩm",  value: "+89%", icon: "💧", color: "#8c6e52" },
              { label: "Sáng Da",     value: "+63%", icon: "✨", color: "#10b981" },
            ].map((m) => (
              <div
                key={m.label}
                className="bg-[#fdf8f2] rounded-2xl p-4 text-center border border-[#e8d5b7]/50"
              >
                <div className="text-2xl mb-2">{m.icon}</div>
                <div className="text-lg mb-0.5" style={{ color: m.color }}>{m.value}</div>
                <div className="text-xs text-[#6b7280]">{m.label}</div>
              </div>
            ))}
          </div>
        </div>

        {/* ── NEW ROUTINE ── */}
        <div className="bg-white rounded-3xl border border-[#ede8e0] shadow-sm p-6">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h2 className="text-[#2a2a2a] mb-1">Lộ Trình Mới Của Bạn</h2>
              <p className="text-sm text-[#6b7280]">Đã được AI tối ưu cho tuần 5</p>
            </div>
            <span className="px-3 py-1.5 rounded-full bg-[#f5ede3] border border-[#e8d5b7] text-[#8c6e52] text-xs">
              Tuần 5 →
            </span>
          </div>

          <div className="grid sm:grid-cols-2 gap-4">
            {/* Morning */}
            <div className="rounded-2xl border border-[#ede8e0] overflow-hidden">
              <div className="flex items-center gap-3 px-4 py-3 bg-gradient-to-r from-amber-50 to-orange-50 border-b border-orange-100">
                <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-amber-400 to-orange-400 flex items-center justify-center">
                  <Sun className="w-4 h-4 text-white" />
                </div>
                <div>
                  <div className="text-sm text-[#2a2a2a]">Quy Trình Sáng</div>
                  <div className="text-xs text-[#9ca3af]">07:00 – 07:10</div>
                </div>
              </div>
              <div className="p-3 flex flex-col gap-2">
                {morningRoutineNew.map((step) => (
                  <div
                    key={step.step}
                    className={`flex items-center gap-3 px-3 py-2.5 rounded-xl border ${
                      step.isUpdated
                        ? "bg-[#fdf8f2] border-[#e8d5b7]"
                        : "bg-[#fafaf8] border-transparent"
                    }`}
                  >
                    <span className="text-base flex-shrink-0">{step.icon}</span>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-1.5 flex-wrap">
                        <span className={`text-sm ${step.isUpdated ? "text-[#c4a882]" : "text-[#2a2a2a]"}`}>
                          {step.name}
                        </span>
                        {step.isUpdated && (
                          <span className="flex items-center gap-0.5 px-1.5 py-0.5 rounded-full bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white text-[10px]">
                            <Zap className="w-2 h-2" /> Mới
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-[#9ca3af] truncate">{step.product}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Evening */}
            <div className="rounded-2xl border border-[#ede8e0] overflow-hidden">
              <div className="flex items-center gap-3 px-4 py-3 bg-gradient-to-r from-[#fdf8f2] to-[#f5ede3] border-b border-[#e8d5b7]">
                <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-[#c4a882] to-[#8c6e52] flex items-center justify-center">
                  <Moon className="w-4 h-4 text-white" />
                </div>
                <div>
                  <div className="text-sm text-[#2a2a2a]">Quy Trình Tối</div>
                  <div className="text-xs text-[#9ca3af]">21:00 – 21:10</div>
                </div>
              </div>
              <div className="p-3 flex flex-col gap-2">
                {eveningRoutineNew.map((step) => (
                  <div
                    key={step.step}
                    className={`flex items-center gap-3 px-3 py-2.5 rounded-xl border ${
                      step.isUpdated
                        ? "bg-[#fdf8f2] border-[#e8d5b7]"
                        : "bg-[#fafaf8] border-transparent"
                    }`}
                  >
                    <span className="text-base flex-shrink-0">{step.icon}</span>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-1.5 flex-wrap">
                        <span className={`text-sm ${step.isUpdated ? "text-[#c4a882]" : "text-[#2a2a2a]"}`}>
                          {step.name}
                        </span>
                        {step.isUpdated && (
                          <span className="flex items-center gap-0.5 px-1.5 py-0.5 rounded-full bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white text-[10px]">
                            <Zap className="w-2 h-2" /> Mới
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-[#9ca3af] truncate">{step.product}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <Link
            to="/routine"
            className="flex items-center justify-center gap-2 w-full mt-4 py-3 rounded-xl border border-[#c4a882]/30 text-[#c4a882] text-sm hover:bg-[#c4a882]/5 transition-colors"
          >
            <RefreshCw className="w-4 h-4" />
            Xem Lộ Trình Chi Tiết
            <ChevronRight className="w-4 h-4" />
          </Link>
        </div>

        {/* ── TIP BANNER ── */}
        <div className="relative overflow-hidden rounded-2xl">
          <ImageWithFallback
            src="https://images.unsplash.com/photo-1723466394553-f52d59876483?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3b21hbiUyMHNraW5jYXJlJTIwbW9ybmluZyUyMHJvdXRpbmUlMjBmYWNlJTIwZnJlc2glMjBnbG93fGVufDF8fHx8MTc3NDAxNDY4NHww&ixlib=rb-4.1.0&q=80&w=1080"
            alt="Tip"
            className="w-full h-24 object-cover object-center"
          />
          <div className="absolute inset-0 bg-gradient-to-r from-[#c4a882]/85 to-[#8c6e52]/70 flex items-center gap-4 px-6">
            <Droplets className="w-5 h-5 text-white flex-shrink-0" />
            <div className="text-white">
              <p className="text-xs opacity-80 mb-0.5">💡 Mẹo từ AI</p>
              <p className="text-sm">Uống 2L nước/ngày tăng hiệu quả dưỡng ẩm lên <strong>30%</strong></p>
            </div>
          </div>
        </div>

      </div>
    </div>
  );
}
