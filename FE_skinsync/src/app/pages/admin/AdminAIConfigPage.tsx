import { useState } from "react";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from "recharts";
import {
  Bot,
  Zap,
  FlaskConical,
  ToggleLeft,
  ToggleRight,
  Plus,
  Pencil,
  Trash2,
  ChevronRight,
  RefreshCw,
  AlertTriangle,
  CheckCircle2,
  Sparkles,
} from "lucide-react";
import { AdminLayout } from "../../components/AdminSidebar";
import { ImageWithFallback } from "../../components/figma/ImageWithFallback";

// ── Data ──────────────────────────────────────────────
const accuracyData = [
  { concern: "Mụn Viêm", accuracy: 94, color: "#c4a882" },
  { concern: "Thâm Nám", accuracy: 89, color: "#8c6e52" },
  { concern: "Lão Hóa", accuracy: 87, color: "#10b981" },
  { concern: "Nhạy Cảm", accuracy: 91, color: "#e8d5b7" },
  { concern: "Sẹo Rỗ", accuracy: 82, color: "#f59e0b" },
  { concern: "Khô Da", accuracy: 96, color: "#06b6d4" },
];

const detections = [
  { label: "Mụn Viêm", confidence: 92, color: "#c4a882", severity: "Trung Bình" },
  { label: "Lỗ Chân Lông", confidence: 85, color: "#8c6e52", severity: "Nhẹ" },
  { label: "Thâm Mắt", confidence: 78, color: "#06b6d4", severity: "Nhẹ" },
  { label: "Vùng Dầu T", confidence: 88, color: "#10b981", severity: "Cao" },
];

interface Rule {
  id: number;
  if_cond: string;
  and_cond?: string;
  then: string;
  enabled: boolean;
  priority: "high" | "medium" | "low";
}

const initialRules: Rule[] = [
  { id: 1, if_cond: "Da Dầu", and_cond: "Mụn Nhẹ", then: "Salicylic Acid 2%", enabled: true, priority: "high" },
  { id: 2, if_cond: "Da Khô", and_cond: "Thiếu Ẩm", then: "Hyaluronic Acid + Ceramide", enabled: true, priority: "high" },
  { id: 3, if_cond: "Da Nhạy Cảm", and_cond: "Kích Ứng", then: "Centella Asiatica + Tránh Retinol", enabled: true, priority: "high" },
  { id: 4, if_cond: "Thâm Nám", and_cond: undefined, then: "Vitamin C 15% + Niacinamide 5%", enabled: true, priority: "medium" },
  { id: 5, if_cond: "Lão Hóa", and_cond: "Nếp Nhăn Sâu", then: "Retinol 0.5% + Peptide", enabled: false, priority: "medium" },
  { id: 6, if_cond: "Mụn Nặng", and_cond: undefined, then: "Benzoyl Peroxide 5% + Tư Vấn Bác Sĩ", enabled: true, priority: "low" },
  { id: 7, if_cond: "Da Hỗn Hợp", and_cond: "Vùng T Dầu", then: "BHA Nhẹ Buổi Tối + HA Buổi Sáng", enabled: false, priority: "low" },
];

const priorityStyle: Record<string, string> = {
  high: "bg-[#6366f1]/8 text-[#6366f1] border border-[#6366f1]/20",
  medium: "bg-amber-50 text-amber-600 border border-amber-100",
  low: "bg-[#f3f4f6] text-[#6b7280] border border-[#e5e7eb]",
};
const priorityLabel: Record<string, string> = {
  high: "Cao",
  medium: "Trung Bình",
  low: "Thấp",
};

const AccuracyTooltip = ({ active, payload, label }: any) => {
  if (active && payload?.length) {
    return (
      <div className="bg-white border border-[#e5e7eb] rounded-xl px-4 py-3 shadow-xl text-sm">
        <p className="text-[#6b7280] text-xs mb-1">{label}</p>
        <p className="text-[#c4a882]">Phân tích: <span style={{ fontWeight: 600 }}>{payload[0]?.value}%</span></p>
      </div>
    );
  }
  return null;
};

export function AdminAIConfigPage() {
  const [rules, setRules] = useState<Rule[]>(initialRules);
  const [modelVersion] = useState("v3.2.1");
  const [isRetraining, setIsRetraining] = useState(false);

  const toggleRule = (id: number) => {
    setRules((prev) => prev.map((r) => (r.id === id ? { ...r, enabled: !r.enabled } : r)));
  };

  const deleteRule = (id: number) => {
    setRules((prev) => prev.filter((r) => r.id !== id));
  };

  const handleRetrain = () => {
    setIsRetraining(true);
    setTimeout(() => setIsRetraining(false), 3000);
  };

  const enabledCount = rules.filter((r) => r.enabled).length;

  return (
    <AdminLayout title="Cấu Hình AI">
      {/* Model Status Bar */}
      <div className="flex flex-wrap items-center gap-4 mb-6 p-4 bg-gradient-to-r from-[#1a1a2e] to-[#2d1b69] rounded-2xl shadow-lg shadow-[#6366f1]/10">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[#6366f1] to-[#a855f7] flex items-center justify-center shadow-md shadow-[#6366f1]/30">
            <Bot className="w-4 h-4 text-white" />
          </div>
          <div>
            <p className="text-white text-sm" style={{ fontWeight: 600 }}>AI Model Skincare {modelVersion}</p>
            <div className="flex items-center gap-1.5">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
              <span className="text-white/50 text-xs">Đang hoạt động · Cập nhật lúc 03:00 sáng nay</span>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-3 ml-auto flex-wrap">
          {[
            { label: "Độ chính xác", value: "94%", color: "text-emerald-400" },
            { label: "Quy tắc hoạt động", value: `${enabledCount}/${rules.length}`, color: "text-[#c4a882]" },
            { label: "Yêu cầu/giây", value: "28.4", color: "text-[#8c6e52]" },
          ].map((s) => (
            <div key={s.label} className="text-center px-4 py-2 rounded-xl bg-white/8 border border-white/10">
              <div className={`text-base ${s.color}`} style={{ fontWeight: 700 }}>{s.value}</div>
              <div className="text-white/40 text-xs">{s.label}</div>
            </div>
          ))}
          <button
            onClick={handleRetrain}
            disabled={isRetraining}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white text-sm hover:shadow-lg hover:shadow-[#c4a882]/30 transition-all disabled:opacity-60"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${isRetraining ? "animate-spin" : ""}`} />
            {isRetraining ? "Đang Huấn Luyện..." : "Huấn Luyện Lại"}
          </button>
        </div>
      </div>

      <div className="grid lg:grid-cols-2 gap-6">
        {/* ── LEFT: AI Vision Accuracy ── */}
        <div className="flex flex-col gap-5">
          {/* Face Scan Card */}
          <div className="bg-white rounded-2xl border border-[#e5e7eb] shadow-sm overflow-hidden">
            <div className="flex items-center gap-3 px-5 py-4 border-b border-[#f3f4f6]">
              <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-[#6366f1]/10 to-[#a855f7]/10 flex items-center justify-center">
                <Sparkles className="w-4 h-4 text-[#6366f1]" />
              </div>
              <div>
                <h2 className="text-[#1a1a2e] text-sm" style={{ fontWeight: 600 }}>Theo Dõi Nhận Diện Ảnh</h2>
                <p className="text-xs text-[#9ca3af]">Kết quả phân tích mẫu thời gian thực</p>
              </div>
            </div>

            <div className="p-5">
              {/* Image + Detection Overlay */}
              <div className="relative rounded-2xl overflow-hidden aspect-[4/3] mb-4">
                <ImageWithFallback
                  src="https://images.unsplash.com/photo-1584800526920-35d8a0409deb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxmYWNlJTIwc2tpbiUyMGFuYWx5c2lzJTIwQUklMjB0ZWNobm9sb2d5JTIwY2xvc2UlMjB1cCUyMHBvcnRyYWl0fGVufDF8fHx8MTc3NDA2NDU0Mnww&ixlib=rb-4.1.0&q=80&w=800"
                  alt="AI Face Scan"
                  className="w-full h-full object-cover object-top"
                />
                {/* Dark overlay */}
                <div className="absolute inset-0 bg-gradient-to-t from-[#0f0c29]/70 via-transparent to-transparent" />

                {/* Scanning line animation */}
                <div className="absolute inset-x-0 top-0 h-0.5 bg-gradient-to-r from-transparent via-[#6366f1] to-transparent animate-pulse" style={{ animationDuration: "2s" }} />

                {/* Detection boxes simulation */}
                <div className="absolute top-12 left-8 border-2 border-[#6366f1] rounded-xl w-16 h-16 flex items-end justify-end">
                  <div className="absolute -top-6 left-0 px-2 py-0.5 rounded-md bg-[#6366f1]/90 backdrop-blur-sm text-white text-[10px] whitespace-nowrap">
                    Mụn Viêm 92%
                  </div>
                </div>
                <div className="absolute top-28 right-12 border-2 border-[#a855f7] rounded-xl w-20 h-12 flex items-end justify-end">
                  <div className="absolute -top-6 left-0 px-2 py-0.5 rounded-md bg-[#a855f7]/90 backdrop-blur-sm text-white text-[10px] whitespace-nowrap">
                    Lỗ Chân Lông 85%
                  </div>
                </div>

                {/* Status badge */}
                <div className="absolute top-3 right-3 flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-black/50 backdrop-blur-md text-white text-xs">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                  LIVE · Đang Phân Tích
                </div>

                {/* Bottom info */}
                <div className="absolute bottom-0 inset-x-0 p-4">
                  <div className="grid grid-cols-2 gap-2">
                    {detections.map((d) => (
                      <div key={d.label} className="bg-white/10 backdrop-blur-md rounded-xl px-3 py-2 border border-white/20">
                        <div className="flex items-center justify-between mb-1">
                          <span className="text-white text-[11px]">{d.label}</span>
                          <span className="text-[11px]" style={{ color: d.color }}>{d.confidence}%</span>
                        </div>
                        <div className="h-1 bg-white/20 rounded-full overflow-hidden">
                          <div className="h-full rounded-full" style={{ width: `${d.confidence}%`, backgroundColor: d.color }} />
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Overall Confidence */}
              <div className="flex items-center gap-3 p-3.5 rounded-xl bg-gradient-to-r from-[#c4a882]/8 to-[#8c6e52]/8 border border-[#c4a882]/15">
                <CheckCircle2 className="w-4 h-4 text-[#c4a882]" />
                <div className="flex-1">
                  <p className="text-sm text-[#1a1a2e]" style={{ fontWeight: 500 }}>Độ tin cậy tổng thể</p>
                  <p className="text-xs text-[#6b7280]">Mô hình phân tích ảnh thành công</p>
                </div>
                <span className="text-xl text-[#c4a882]" style={{ fontWeight: 700 }}>94%</span>
              </div>
            </div>
          </div>

          {/* Accuracy Bar Chart */}
          <div className="bg-white rounded-2xl border border-[#e5e7eb] shadow-sm p-5">
            <div className="flex items-center gap-3 mb-5">
              <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-[#10b981]/10 to-[#06b6d4]/10 flex items-center justify-center">
                <FlaskConical className="w-4 h-4 text-[#10b981]" />
              </div>
              <div>
                <h2 className="text-[#1a1a2e] text-sm" style={{ fontWeight: 600 }}>Độ Chính Xác Theo Vấn Đề Da</h2>
                <p className="text-xs text-[#9ca3af]">Cập nhật từ 10,000 ảnh phân tích gần nhất</p>
              </div>
            </div>
            <div className="h-52">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart id="admin-ai-accuracy-bar" data={accuracyData} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" vertical={false} />
                  <XAxis
                    dataKey="concern"
                    axisLine={false}
                    tickLine={false}
                    tick={{ fill: "#9ca3af", fontSize: 10 }}
                  />
                  <YAxis
                    domain={[70, 100]}
                    axisLine={false}
                    tickLine={false}
                    tick={{ fill: "#9ca3af", fontSize: 10 }}
                    tickFormatter={(v) => `${v}%`}
                  />
                  <Tooltip content={<AccuracyTooltip />} />
                  <Bar dataKey="accuracy" radius={[6, 6, 0, 0]}>
                    {accuracyData.map((entry, index) => (
                      <Cell
                        key={`cell-${index}`}
                        fill={entry.color}
                        fillOpacity={entry.color === "#d4f4f4" ? 1 : 0.85}
                        stroke={entry.color === "#d4f4f4" ? "#9ca3af" : "none"}
                        strokeWidth={entry.color === "#d4f4f4" ? 0.5 : 0}
                      />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>

        {/* ── RIGHT: Rules Engine ── */}
        <div className="bg-white rounded-2xl border border-[#e5e7eb] shadow-sm overflow-hidden flex flex-col">
          <div className="flex items-center justify-between px-5 py-4 border-b border-[#f3f4f6]">
            <div className="flex items-center gap-3">
              <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-[#8c6e52]/10 to-[#c4a882]/10 flex items-center justify-center">
                <Zap className="w-4 h-4 text-[#8c6e52]" />
              </div>
              <div>
                <h2 className="text-[#1a1a2e] text-sm" style={{ fontWeight: 600 }}>Quy Tắc Gợi Ý Lộ Trình</h2>
                <p className="text-xs text-[#9ca3af]">
                  {enabledCount} quy tắc đang hoạt động · {rules.length - enabledCount} bị tắt
                </p>
              </div>
            </div>
            <button className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white text-xs shadow-sm shadow-[#c4a882]/20 hover:shadow-[#c4a882]/30 transition-all">
              <Plus className="w-3.5 h-3.5" />
              Thêm Quy Tắc
            </button>
          </div>

          {/* Rules List */}
          <div className="flex-1 overflow-y-auto divide-y divide-[#f3f4f6]">
            {rules.map((rule, i) => (
              <div
                key={rule.id}
                className={`px-5 py-4 transition-all ${
                  rule.enabled ? "" : "opacity-50"
                } hover:bg-[#fafafa]`}
              >
                {/* Rule Header */}
                <div className="flex items-center justify-between mb-2.5">
                  <div className="flex items-center gap-2">
                    <span className="w-5 h-5 rounded-lg bg-[#f4f5f7] text-[#9ca3af] text-[10px] flex items-center justify-center" style={{ fontWeight: 600 }}>
                      {i + 1}
                    </span>
                    <span className={`px-2 py-0.5 rounded-full text-[10px] ${priorityStyle[rule.priority]}`}>
                      Ưu Tiên: {priorityLabel[rule.priority]}
                    </span>
                    {!rule.enabled && (
                      <span className="flex items-center gap-1 text-[10px] text-amber-500">
                        <AlertTriangle className="w-3 h-3" /> Đã tắt
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-1.5">
                    <button className="w-7 h-7 rounded-lg hover:bg-[#f4f5f7] text-[#9ca3af] hover:text-[#6366f1] flex items-center justify-center transition-colors">
                      <Pencil className="w-3 h-3" />
                    </button>
                    <button
                      onClick={() => deleteRule(rule.id)}
                      className="w-7 h-7 rounded-lg hover:bg-red-50 text-[#9ca3af] hover:text-red-400 flex items-center justify-center transition-colors"
                    >
                      <Trash2 className="w-3 h-3" />
                    </button>
                    {/* Toggle */}
                    <button
                      onClick={() => toggleRule(rule.id)}
                      className={`transition-colors ${rule.enabled ? "text-[#6366f1]" : "text-[#d1d5db]"}`}
                    >
                      {rule.enabled
                        ? <ToggleRight className="w-8 h-8" />
                        : <ToggleLeft className="w-8 h-8" />
                      }
                    </button>
                  </div>
                </div>

                {/* IF → THEN Visual */}
                <div className="flex items-center gap-2 flex-wrap">
                  {/* IF */}
                  <div className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl bg-[#c4a882]/8 border border-[#c4a882]/15">
                    <span className="text-[10px] text-[#c4a882]/60 uppercase tracking-wide">NẾU</span>
                    <span className="text-xs text-[#c4a882]" style={{ fontWeight: 500 }}>{rule.if_cond}</span>
                  </div>

                  {/* AND */}
                  {rule.and_cond && (
                    <>
                      <span className="text-[10px] text-[#9ca3af] uppercase">VÀ</span>
                      <div className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl bg-[#8c6e52]/8 border border-[#8c6e52]/15">
                        <span className="text-xs text-[#8c6e52]" style={{ fontWeight: 500 }}>{rule.and_cond}</span>
                      </div>
                    </>
                  )}

                  {/* Arrow */}
                  <ChevronRight className="w-4 h-4 text-[#d1d5db]" />

                  {/* THEN */}
                  <div className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl bg-emerald-50 border border-emerald-100">
                    <span className="text-[10px] text-emerald-600/60 uppercase tracking-wide">GỢI Ý</span>
                    <span className="text-xs text-emerald-700" style={{ fontWeight: 500 }}>{rule.then}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Footer */}
          <div className="px-5 py-4 border-t border-[#f3f4f6] bg-[#fafafa] flex items-center justify-between">
            <div className="flex items-center gap-2 text-xs text-[#6b7280]">
              <Bot className="w-3.5 h-3.5 text-[#c4a882]" />
              AI áp dụng quy tắc theo thứ tự ưu tiên
            </div>
            <button className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl border border-[#c4a882]/30 text-[#c4a882] text-xs hover:bg-[#c4a882]/5 transition-colors">
              <RefreshCw className="w-3.5 h-3.5" />
              Đồng Bộ Model
            </button>
          </div>
        </div>
      </div>
    </AdminLayout>
  );
}