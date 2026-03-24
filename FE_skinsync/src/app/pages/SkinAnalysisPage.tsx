import { useNavigate } from "react-router";
import {
  Sparkles,
  ArrowRight,
  AlertCircle,
  Droplets,
  Zap,
  Shield,
  Activity,
  ChevronRight,
} from "lucide-react";
import { ImageWithFallback } from "../components/figma/ImageWithFallback";

const skinMetrics = [
  { label: "Độ Ẩm", value: 68, color: "#c4a882", icon: <Droplets className="w-3.5 h-3.5" /> },
  { label: "Dầu Nhờn", value: 72, color: "#8c6e52", icon: <Activity className="w-3.5 h-3.5" /> },
  { label: "Độ Nhạy Cảm", value: 35, color: "#f59e0b", icon: <Zap className="w-3.5 h-3.5" /> },
  { label: "Hàng Rào Da", value: 80, color: "#10b981", icon: <Shield className="w-3.5 h-3.5" /> },
];

const issuePoints = [
  { top: "22%", left: "50%", label: "Lỗ Chân Lông To", color: "#c4a882" },
  { top: "38%", left: "25%", label: "Mụn Vùng Má", color: "#8c6e52" },
  { top: "38%", left: "75%", label: "Mụn Vùng Má", color: "#8c6e52" },
  { top: "55%", left: "50%", label: "Vùng T Dầu", color: "#f59e0b" },
  { top: "70%", left: "35%", label: "Thâm Nhẹ", color: "#c4a882" },
];

export function SkinAnalysisPage() {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#f5f5f0] via-white to-[#d4f4f4]/20 pt-20">
      {/* Page Header Banner */}
      <div className="relative overflow-hidden bg-gradient-to-r from-[#c4a882]/8 via-white to-[#8c6e52]/8 border-b border-white/60">
        <div className="absolute inset-0 opacity-40">
          <div className="absolute top-0 right-1/4 w-72 h-72 bg-gradient-to-br from-[#c4a882]/15 to-transparent rounded-full blur-3xl" />
        </div>
        <div className="relative max-w-7xl mx-auto px-6 py-8">
          <div className="flex items-center gap-2 mb-2">
            <span className="px-3 py-1 rounded-full bg-gradient-to-r from-[#c4a882]/10 to-[#8c6e52]/10 border border-[#c4a882]/20 text-[#8c6e52] text-xs">
              ✦ Phân Tích Hoàn Tất
            </span>
          </div>
          <h1 className="text-3xl text-[#2a2a2a]">Báo Cáo Làn Da Của Bạn</h1>
          <p className="text-[#6b7280] text-sm mt-1">
            AI đã phân tích{" "}
            <span className="text-[#c4a882]">47 chỉ số sinh học</span> từ ảnh
            da của bạn — Cập nhật lúc hôm nay
          </p>
        </div>
      </div>

      {/* Main Split Layout */}
      <div className="max-w-7xl mx-auto px-6 py-8">
        <div className="grid lg:grid-cols-5 gap-8 items-start">
          {/* ── LEFT: Face Visualization ── */}
          <div className="lg:col-span-2">
            <div className="relative">
              {/* Glow Aura */}
              <div className="absolute -inset-4 bg-gradient-to-br from-[#c4a882]/20 via-[#8c6e52]/10 to-[#e8d5b7]/30 rounded-[3rem] blur-2xl" />

              <div className="relative bg-gradient-to-b from-[#0f0f1a] to-[#1a1a2e] rounded-3xl overflow-hidden border border-white/10 shadow-2xl">
                {/* Face Image Container */}
                <div className="relative aspect-[3/4]">
                  <ImageWithFallback
                    src="https://images.unsplash.com/photo-1759334509972-53f70f5f2a69?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmYWNlJTIwc2tpbiUyMGFuYWx5c2lzJTIwZ2xvdyUyMG5lb24lMjBibHVlJTIwc2NpZW5jZSUyMGJlYXV0eXxlbnwxfHx8fDE3NzQwMTMwMTZ8MA&ixlib=rb-4.1.0&q=80&w=1080"
                    alt="AI Face Analysis"
                    className="w-full h-full object-cover object-top opacity-85 mix-blend-luminosity"
                  />

                  {/* Dark sci-fi overlay */}
                  <div className="absolute inset-0 bg-gradient-to-b from-[#c4a882]/20 via-transparent to-[#0f0f1a]/70" />

                  {/* Wireframe Grid Effect */}
                  <div className="absolute inset-0 opacity-15"
                    style={{
                      backgroundImage: "linear-gradient(rgba(196,168,130,0.4) 1px, transparent 1px), linear-gradient(90deg, rgba(196,168,130,0.4) 1px, transparent 1px)",
                      backgroundSize: "30px 30px",
                    }}
                  />

                  {/* Scanning Line Animation */}
                  <div
                    className="absolute left-0 right-0 h-0.5 bg-gradient-to-r from-transparent via-[#e8d5b7] to-transparent opacity-60"
                    style={{ animation: "scanline 3s ease-in-out infinite", top: "40%" }}
                  />

                  {/* Analysis Points */}
                  {issuePoints.map((point, i) => (
                    <div
                      key={i}
                      className="absolute -translate-x-1/2 -translate-y-1/2 group"
                      style={{ top: point.top, left: point.left }}
                    >
                      {/* Ripple */}
                      <div
                        className="absolute inset-0 rounded-full animate-ping opacity-40"
                        style={{ backgroundColor: point.color, width: 20, height: 20, margin: -4 }}
                      />
                      <div
                        className="w-3 h-3 rounded-full border-2 border-white shadow-lg relative z-10"
                        style={{ backgroundColor: point.color }}
                      />
                      {/* Tooltip */}
                      <div className="absolute left-4 top-1/2 -translate-y-1/2 bg-black/70 backdrop-blur-sm text-white text-[10px] px-2 py-1 rounded-lg whitespace-nowrap opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none">
                        {point.label}
                      </div>
                    </div>
                  ))}

                  {/* AI Scan Badge */}
                  <div className="absolute top-4 left-4 flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#c4a882]/30 backdrop-blur-md border border-[#c4a882]/40">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#e8d5b7] animate-pulse" />
                    <span className="text-[#d4f4f4] text-xs">AI Đang Phân Tích</span>
                  </div>

                  {/* Score Badge */}
                  <div className="absolute bottom-4 left-1/2 -translate-x-1/2">
                    <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl px-6 py-3 text-center shadow-xl">
                      <div className="text-[#d4f4f4] text-xs mb-1">Điểm Tổng Quan</div>
                      <div className="text-4xl text-white">
                        85
                        <span className="text-xl text-white/50">/100</span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Metrics Bar */}
                <div className="px-5 py-4 grid grid-cols-2 gap-3">
                  {skinMetrics.map((m) => (
                    <div key={m.label} className="bg-white/5 rounded-xl p-3">
                      <div className="flex items-center justify-between mb-1.5">
                        <div className="flex items-center gap-1" style={{ color: m.color }}>
                          {m.icon}
                          <span className="text-[10px] text-white/60">{m.label}</span>
                        </div>
                        <span className="text-xs" style={{ color: m.color }}>{m.value}%</span>
                      </div>
                      <div className="h-1 bg-white/10 rounded-full overflow-hidden">
                        <div
                          className="h-full rounded-full"
                          style={{ width: `${m.value}%`, backgroundColor: m.color }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>

          {/* ── RIGHT: Data & Analysis ── */}
          <div className="lg:col-span-3 flex flex-col gap-5">
            {/* Score + Skin Type Row */}
            <div className="grid grid-cols-2 gap-4">
              {/* Score Card */}
              <div className="col-span-2 sm:col-span-1 bg-gradient-to-br from-[#c4a882] to-[#8c6e52] rounded-3xl p-5 text-white shadow-lg shadow-[#c4a882]/20">
                <div className="text-white/70 text-xs mb-2">Điểm Tổng Quan</div>
                <div className="text-5xl mb-2">
                  85
                  <span className="text-2xl text-white/60">/100</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-[#d4f4f4] animate-pulse" />
                  <span className="text-white/80 text-xs">Da khỏe mạnh — Cần cải thiện nhẹ</span>
                </div>
                {/* Score arc visual */}
                <div className="mt-3 h-1.5 bg-white/20 rounded-full overflow-hidden">
                  <div className="h-full w-[85%] bg-white/80 rounded-full" />
                </div>
              </div>

              {/* Skin Type Card */}
              <div className="col-span-2 sm:col-span-1 bg-white/80 backdrop-blur-md rounded-3xl p-5 border border-white/80 shadow-sm">
                <div className="text-[#6b7280] text-xs mb-2">Loại Da Được Xác Định</div>
                <div className="text-2xl text-[#2a2a2a] mb-3">
                  Da Hỗn Hợp
                </div>
                <div className="flex gap-2 flex-wrap">
                  {["Vùng T Dầu", "Má Khô", "Nhạy Cảm Nhẹ"].map((tag) => (
                    <span key={tag} className="px-2.5 py-1 rounded-full bg-[#d4f4f4]/60 text-[#0891b2] text-xs">
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
            </div>

            {/* Main Issues Card */}
            <div className="bg-white/80 backdrop-blur-md rounded-3xl p-5 border border-white/80 shadow-sm">
              <div className="flex items-center gap-2 mb-4">
                <AlertCircle className="w-4 h-4 text-[#f59e0b]" />
                <h3 className="text-[#2a2a2a]">Vấn Đề Chính Được Phát Hiện</h3>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                {[
                  { issue: "Mụn", area: "Vùng Má & Cằm", level: "Mức Vừa", color: "#8c6e52", icon: "🔴", pct: 65 },
                  { issue: "Lỗ Chân Lông To", area: "Vùng Mũi & Trán", level: "Rõ Rệt", color: "#c4a882", icon: "🟡", pct: 72 },
                  { issue: "Thâm / Đốm Nâu", area: "Toàn Mặt", level: "Nhẹ", color: "#10b981", icon: "🟤", pct: 40 },
                ].map((item) => (
                  <div
                    key={item.issue}
                    className="rounded-2xl p-3 border border-gray-100 bg-[#fafafa]"
                  >
                    <div className="text-xl mb-2">{item.icon}</div>
                    <div className="text-sm text-[#2a2a2a] mb-0.5">{item.issue}</div>
                    <div className="text-xs text-[#6b7280] mb-2">{item.area}</div>
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-xs" style={{ color: item.color }}>{item.level}</span>
                      <span className="text-xs text-[#9ca3af]">{item.pct}%</span>
                    </div>
                    <div className="h-1 bg-gray-100 rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full"
                        style={{ width: `${item.pct}%`, backgroundColor: item.color }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* AI Diagnosis Box — Glowing Border */}
            <div className="relative rounded-3xl p-5 overflow-hidden">
              {/* Animated gradient border */}
              <div className="absolute inset-0 rounded-3xl bg-gradient-to-r from-[#c4a882] via-[#8c6e52] to-[#c4a882] opacity-60 blur-[1px]" style={{ padding: 1 }}>
                <div className="absolute inset-[1px] rounded-3xl bg-white" />
              </div>
              {/* Glow effect */}
              <div className="absolute inset-0 rounded-3xl bg-gradient-to-br from-[#c4a882]/5 via-transparent to-[#8c6e52]/5" />

              <div className="relative z-10">
                <div className="flex items-center gap-2.5 mb-4">
                  <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-[#c4a882] to-[#8c6e52] flex items-center justify-center shadow-lg shadow-[#c4a882]/30">
                    <Sparkles className="w-4 h-4 text-white" />
                  </div>
                  <div>
                    <h3 className="text-[#2a2a2a]">Chẩn Đoán Từ AI</h3>
                    <span className="text-xs text-[#c4a882]">Phân tích chuyên sâu · Tin cậy 94%</span>
                  </div>
                </div>

                <div className="space-y-3 text-sm text-[#4b5563] leading-relaxed">
                  <p>
                    🔬 <strong className="text-[#2a2a2a]">Nguyên Nhân Gốc Rễ:</strong> Da bạn đang ở trạng thái mất cân bằng bã nhờn do
                    {" "}<span className="text-[#c4a882]">tuyến bã hoạt động quá mức ở vùng T</span>, trong khi
                    vùng má thiếu độ ẩm, kích hoạt cơ chế bù trừ dầu.
                  </p>
                  <p>
                    🧬 <strong className="text-[#2a2a2a]">Yếu Tố Tác Động:</strong> Hàng rào bảo vệ da (skin barrier) đang{" "}
                    <span className="text-[#8c6e52]">bị tổn thương nhẹ</span>, khiến vi khuẩn P.acnes dễ xâm nhập gây mụn.
                    Lỗ chân lông to là hệ quả của{" "}
                    <span className="text-[#c4a882]">thiếu collagen và làm sạch chưa đúng cách</span>.
                  </p>
                  <p>
                    ✅ <strong className="text-[#2a2a2a]">Dự Báo:</strong> Với lộ trình AI đề xuất, da bạn có thể cải thiện{" "}
                    <span className="text-emerald-600">60-80% các vấn đề trên trong 4-6 tuần</span>.
                  </p>
                </div>

                {/* Confidence tags */}
                <div className="flex flex-wrap gap-2 mt-4">
                  {[
                    "Mụn Nội Tiết",
                    "Da Hỗn Hợp Nghiêng Dầu",
                    "Barrier Yếu",
                    "Cần Serum Niacinamide",
                  ].map((tag) => (
                    <span
                      key={tag}
                      className="px-2.5 py-1 rounded-full text-xs bg-gradient-to-r from-[#c4a882]/10 to-[#8c6e52]/10 border border-[#c4a882]/20 text-[#8c6e52]"
                    >
                      {tag}
                    </span>
                  ))}
                </div>
              </div>
            </div>

            {/* Secondary Metrics */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              {[
                { label: "Tuổi Da", value: "24", unit: "tuổi", icon: "🧬" },
                { label: "Tốc Độ Phục Hồi", value: "Tốt", unit: "", icon: "⚡" },
                { label: "Nguy Cơ Lão Hóa", value: "Thấp", unit: "", icon: "🛡️" },
                { label: "Độ Nhạy UV", value: "Vừa", unit: "", icon: "☀️" },
              ].map((stat) => (
                <div
                  key={stat.label}
                  className="bg-white/70 backdrop-blur-sm rounded-2xl p-3 border border-white/80 text-center"
                >
                  <div className="text-xl mb-1">{stat.icon}</div>
                  <div className="text-[#2a2a2a]">{stat.value}<span className="text-xs text-[#9ca3af]">{stat.unit}</span></div>
                  <div className="text-xs text-[#6b7280]">{stat.label}</div>
                </div>
              ))}
            </div>

            {/* CTA Button */}
            <button
              onClick={() => navigate("/routine")}
              className="group w-full py-4 rounded-2xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white flex items-center justify-center gap-3 shadow-xl shadow-[#c4a882]/25 hover:shadow-[#c4a882]/40 hover:scale-[1.02] transition-all duration-300"
            >
              <Sparkles className="w-5 h-5" />
              <span>Xem Lộ Trình Đề Xuất</span>
              <ChevronRight className="w-5 h-5 group-hover:translate-x-1 transition-transform" />
            </button>

            <p className="text-center text-xs text-[#9ca3af]">
              Lộ trình được cá nhân hóa 100% dựa trên kết quả phân tích của bạn
            </p>
          </div>
        </div>
      </div>

      <style>{`
        @keyframes scanline {
          0% { top: 10%; opacity: 0; }
          20% { opacity: 0.6; }
          80% { opacity: 0.6; }
          100% { top: 85%; opacity: 0; }
        }
      `}</style>
    </div>
  );
}