import { useState, useRef } from "react";
import { Link, useNavigate } from "react-router";
import {
  ArrowLeft,
  Camera,
  Upload,
  CheckCircle2,
  Flame,
  Sparkles,
  X,
  Sun,
  Moon,
} from "lucide-react";

type RoutineDone = "yes" | "no" | null;
type SkinCondition = "better" | "normal" | "worse" | null;
type Irritation = "yes" | "no" | null;

const streakDays = [
  { day: "T2", done: true },
  { day: "T3", done: true },
  { day: "T4", done: true },
  { day: "T5", done: true },
  { day: "T6", done: true },
  { day: "T7", done: true },
  { day: "CN", done: false },
];

export function CheckInPage() {
  const navigate = useNavigate();
  const fileRef = useRef<HTMLInputElement>(null);

  const [routineDone, setRoutineDone] = useState<RoutineDone>(null);
  const [skinCondition, setSkinCondition] = useState<SkinCondition>(null);
  const [irritation, setIrritation] = useState<Irritation>(null);
  const [irritationNote, setIrritationNote] = useState("");
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);
  const [notes, setNotes] = useState("");
  const [submitted, setSubmitted] = useState(false);
  const [activeRoutine, setActiveRoutine] = useState<"morning" | "evening">("morning");

  const morningChecks = ["Sữa Rửa Mặt", "Toner", "Serum Vitamin C", "Kem Chống Nắng"];
  const eveningChecks = ["Tẩy Trang", "Sữa Rửa Mặt", "Serum Niacinamide", "Kem Dưỡng Đêm"];
  const [morningDone, setMorningDone] = useState<boolean[]>([false, false, false, false]);
  const [eveningDone, setEveningDone] = useState<boolean[]>([false, false, false, false]);

  const isComplete =
    routineDone !== null && skinCondition !== null && irritation !== null;

  const handlePhoto = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      const url = URL.createObjectURL(file);
      setPhotoPreview(url);
    }
  };

  const handleSubmit = () => {
    if (!isComplete) return;
    setSubmitted(true);
    setTimeout(() => navigate("/progress"), 2000);
  };

  const toggleMorning = (i: number) =>
    setMorningDone((prev) => prev.map((v, idx) => (idx === i ? !v : v)));
  const toggleEvening = (i: number) =>
    setEveningDone((prev) => prev.map((v, idx) => (idx === i ? !v : v)));

  const currentChecks = activeRoutine === "morning" ? morningChecks : eveningChecks;
  const currentDone = activeRoutine === "morning" ? morningDone : eveningDone;
  const toggleCurrent = activeRoutine === "morning" ? toggleMorning : toggleEvening;

  if (submitted) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-[#f5f0e8] via-white to-[#e8d5b7]/30 flex items-center justify-center pt-20 px-6">
        <div className="text-center max-w-sm">
          <div className="w-20 h-20 rounded-full bg-gradient-to-br from-emerald-400 to-teal-500 flex items-center justify-center mx-auto mb-5 shadow-xl shadow-emerald-200 animate-bounce">
            <CheckCircle2 className="w-10 h-10 text-white" />
          </div>
          <h2 className="text-2xl text-[#2a2a2a] mb-2">Đã Cập Nhật!</h2>
          <p className="text-[#6b7280] text-sm mb-4">
            AI đang phân tích dữ liệu hôm nay của bạn…
          </p>
          <div className="flex items-center justify-center gap-2 px-4 py-2.5 rounded-full bg-gradient-to-r from-[#c4a882]/10 to-[#8c6e52]/10 border border-[#c4a882]/20 text-[#8c6e52] text-sm">
            <Flame className="w-4 h-4 text-orange-500" />
            Chuỗi ngày: <span style={{ fontWeight: 600 }}>14 ngày 🔥</span>
          </div>
          <p className="text-xs text-[#9ca3af] mt-4">Đang chuyển về Bảng Tiến Độ…</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#f5f0e8] via-white to-[#e8d5b7]/20 pt-20 pb-12">
      {/* Page Top Bar */}
      <div className="bg-white/80 backdrop-blur-md border-b border-[#e8d5b7]/60">
        <div className="max-w-2xl mx-auto px-6 py-4 flex items-center justify-between">
          <Link
            to="/progress"
            className="flex items-center gap-1.5 text-sm text-[#6b7280] hover:text-[#c4a882] transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            Trở Về
          </Link>
          <div className="text-center">
            <p className="text-xs text-[#9ca3af]">Thứ Hai, 20/03/2026</p>
          </div>
          {/* Streak Badge */}
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-orange-50 border border-orange-100">
            <Flame className="w-3.5 h-3.5 text-orange-500" />
            <span className="text-xs text-orange-600">13 ngày</span>
          </div>
        </div>
      </div>

      <div className="max-w-2xl mx-auto px-6 pt-8 flex flex-col gap-5">
        {/* Header */}
        <div className="text-center mb-2">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-gradient-to-r from-[#c4a882]/10 to-[#8c6e52]/10 border border-[#c4a882]/20 mb-4">
            <Sparkles className="w-3.5 h-3.5 text-[#c4a882]" />
            <span className="text-xs text-[#c4a882]">Nhật Ký Hàng Ngày</span>
          </div>
          <h1 className="text-3xl text-[#2a2a2a] mb-2">Nhật Ký Làn Da Hôm Nay</h1>
          <p className="text-[#6b7280] text-sm">
            Chỉ mất <span className="text-[#c4a882]">60 giây</span> — AI sẽ tự động điều chỉnh lộ trình cho bạn
          </p>
        </div>

        {/* Streak Week View */}
        <div className="bg-white/80 backdrop-blur-md rounded-3xl border border-white/80 shadow-sm p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-sm text-[#2a2a2a]">Chuỗi Ngày Tuần Này</h3>
            <span className="text-xs text-[#c4a882]">6/7 ngày ✦</span>
          </div>
          <div className="grid grid-cols-7 gap-2">
            {streakDays.map((d) => (
              <div key={d.day} className="flex flex-col items-center gap-1.5">
                <span className="text-[10px] text-[#9ca3af]">{d.day}</span>
                <div
                  className={`w-9 h-9 rounded-xl flex items-center justify-center transition-all ${
                    d.done
                      ? "bg-gradient-to-br from-[#c4a882] to-[#8c6e52] shadow-sm shadow-[#c4a882]/20"
                      : "bg-[#f5f0e8] border-2 border-dashed border-[#e8d5b7]"
                  }`}
                >
                  {d.done ? (
                    <CheckCircle2 className="w-4 h-4 text-white" />
                  ) : (
                    <span className="w-2 h-2 rounded-full bg-[#d1c4b0]" />
                  )}
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* ── Q1: Routine Completion ── */}
        <div className="bg-white/80 backdrop-blur-md rounded-3xl border border-white/80 shadow-sm p-6">
          <div className="flex items-center gap-2 mb-5">
            <div className="w-6 h-6 rounded-full bg-gradient-to-br from-[#c4a882] to-[#8c6e52] text-white text-xs flex items-center justify-center">1</div>
            <h3 className="text-[#2a2a2a]">Bạn đã hoàn thành Lộ trình chưa?</h3>
          </div>

          {/* Morning / Evening Toggle */}
          <div className="flex gap-2 p-1 bg-[#f5f0e8] rounded-full mb-4">
            {(["morning", "evening"] as const).map((tab) => (
              <button
                key={tab}
                onClick={() => setActiveRoutine(tab)}
                className={`flex-1 flex items-center justify-center gap-2 py-2.5 rounded-full text-sm transition-all ${
                  activeRoutine === tab
                    ? "bg-white shadow-sm text-[#2a2a2a]"
                    : "text-[#6b7280]"
                }`}
              >
                {tab === "morning" ? <Sun className="w-3.5 h-3.5 text-amber-500" /> : <Moon className="w-3.5 h-3.5 text-[#c4a882]" />}
                {tab === "morning" ? "Buổi Sáng" : "Buổi Tối"}
              </button>
            ))}
          </div>

          {/* Step Checklist */}
          <div className="grid grid-cols-2 gap-2 mb-5">
            {currentChecks.map((step, i) => (
              <button
                key={step}
                onClick={() => toggleCurrent(i)}
                className={`flex items-center gap-2.5 p-3 rounded-2xl border text-left transition-all ${
                  currentDone[i]
                    ? "border-[#c4a882]/30 bg-gradient-to-r from-[#c4a882]/8 to-[#8c6e52]/8"
                    : "border-[#f0ebe3] bg-[#faf7f2] hover:border-[#c4a882]/20"
                }`}
              >
                <div
                  className={`w-5 h-5 rounded-full flex items-center justify-center flex-shrink-0 transition-all ${
                    currentDone[i]
                      ? "bg-gradient-to-br from-[#c4a882] to-[#8c6e52]"
                      : "border-2 border-[#e8d5b7]"
                  }`}
                >
                  {currentDone[i] && <CheckCircle2 className="w-3 h-3 text-white" />}
                </div>
                <span className={`text-sm ${currentDone[i] ? "text-[#8c6e52]" : "text-[#4b5563]"}`}>{step}</span>
              </button>
            ))}
          </div>

          {/* Overall Yes/No */}
          <p className="text-xs text-[#9ca3af] mb-3">Hoặc đánh dấu nhanh toàn bộ:</p>
          <div className="flex gap-3">
            {[
              { val: "yes" as RoutineDone, label: "✅  Rồi, xong hết!", active: "from-emerald-400 to-teal-500" },
              { val: "no" as RoutineDone, label: "❌  Chưa hết", active: "from-[#f59e0b] to-orange-400" },
            ].map((opt) => (
              <button
                key={opt.val}
                onClick={() => setRoutineDone(opt.val)}
                className={`flex-1 py-3 rounded-2xl border-2 text-sm transition-all ${
                  routineDone === opt.val
                    ? `bg-gradient-to-r ${opt.active} text-white border-transparent shadow-md`
                    : "border-[#f0ebe3] text-[#4b5563] hover:border-[#c4a882]/30 bg-white"
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </div>

        {/* ── Q2: Skin Condition ── */}
        <div className="bg-white/80 backdrop-blur-md rounded-3xl border border-white/80 shadow-sm p-6">
          <div className="flex items-center gap-2 mb-5">
            <div className="w-6 h-6 rounded-full bg-gradient-to-br from-[#c4a882] to-[#8c6e52] text-white text-xs flex items-center justify-center">2</div>
            <h3 className="text-[#2a2a2a]">Tình trạng da hôm nay thế nào?</h3>
          </div>

          <div className="grid grid-cols-3 gap-3">
            {[
              { val: "better" as SkinCondition, emoji: "🌟", label: "Tốt hơn", sub: "Da cải thiện rõ", color: "#10b981", bg: "from-emerald-50 to-teal-50", border: "border-emerald-200" },
              { val: "normal" as SkinCondition, emoji: "🌤️", label: "Bình thường", sub: "Không đổi nhiều", color: "#f59e0b", bg: "from-amber-50 to-yellow-50", border: "border-amber-200" },
              { val: "worse" as SkinCondition, emoji: "🌧️", label: "Tệ hơn", sub: "Có vẻ xấu đi", color: "#ef4444", bg: "from-red-50 to-pink-50", border: "border-red-200" },
            ].map((opt) => (
              <button
                key={opt.val}
                onClick={() => setSkinCondition(opt.val)}
                className={`flex flex-col items-center gap-2 py-4 px-3 rounded-2xl border-2 transition-all ${
                  skinCondition === opt.val
                    ? `bg-gradient-to-b ${opt.bg} ${opt.border} shadow-md scale-[1.03]`
                    : "border-[#f0ebe3] bg-[#faf7f2] hover:border-[#e8d5b7]"
                }`}
              >
                <span className="text-2xl">{opt.emoji}</span>
                <span className="text-sm text-[#2a2a2a]">{opt.label}</span>
                <span className="text-[10px] text-[#9ca3af]">{opt.sub}</span>
              </button>
            ))}
          </div>
        </div>

        {/* ── Q3: Irritation ── */}
        <div className="bg-white/80 backdrop-blur-md rounded-3xl border border-white/80 shadow-sm p-6">
          <div className="flex items-center gap-2 mb-5">
            <div className="w-6 h-6 rounded-full bg-gradient-to-br from-[#c4a882] to-[#8c6e52] text-white text-xs flex items-center justify-center">3</div>
            <h3 className="text-[#2a2a2a]">Bạn có bị kích ứng không?</h3>
          </div>

          <div className="flex gap-3 mb-4">
            {[
              { val: "yes" as Irritation, label: "🔴  Có, bị kích ứng" },
              { val: "no" as Irritation, label: "🟢  Không, ổn hết" },
            ].map((opt) => (
              <button
                key={opt.val}
                onClick={() => setIrritation(opt.val)}
                className={`flex-1 py-3 rounded-2xl border-2 text-sm transition-all ${
                  irritation === opt.val
                    ? opt.val === "yes"
                      ? "bg-red-50 border-red-200 text-red-700 shadow-sm"
                      : "bg-emerald-50 border-emerald-200 text-emerald-700 shadow-sm"
                    : "border-[#f0ebe3] text-[#4b5563] hover:border-[#c4a882]/20 bg-white"
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>

          {irritation === "yes" && (
            <div className="animate-in slide-in-from-top-2 duration-200">
              <textarea
                value={irritationNote}
                onChange={(e) => setIrritationNote(e.target.value)}
                placeholder="Mô tả ngắn (vd: đỏ vùng má, nổi mẩn…)"
                className="w-full rounded-2xl border border-red-200 bg-red-50/50 px-4 py-3 text-sm text-[#4b5563] placeholder:text-[#d1d5db] resize-none focus:outline-none focus:border-red-300 transition-colors"
                rows={2}
              />
            </div>
          )}
        </div>

        {/* ── Optional Note ── */}
        <div className="bg-white/80 backdrop-blur-md rounded-3xl border border-white/80 shadow-sm p-6">
          <div className="flex items-center gap-2 mb-4">
            <div className="w-6 h-6 rounded-full bg-[#f5f0e8] text-[#8c6e52] text-xs flex items-center justify-center">4</div>
            <h3 className="text-[#2a2a2a]">Ghi Chú Thêm</h3>
            <span className="text-xs text-[#9ca3af] ml-auto">Tùy chọn</span>
          </div>
          <textarea
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            placeholder="Hôm nay thức khuya, ăn nhiều đồ ngọt, thay đổi thời tiết…"
            className="w-full rounded-2xl border border-[#f0ebe3] bg-[#faf7f2] px-4 py-3 text-sm text-[#4b5563] placeholder:text-[#d1d5db] resize-none focus:outline-none focus:border-[#c4a882]/30 transition-colors"
            rows={2}
          />
        </div>

        {/* ── Photo Upload ── */}
        <div className="bg-white/80 backdrop-blur-md rounded-3xl border border-white/80 shadow-sm p-6">
          <div className="flex items-center gap-2 mb-4">
            <div className="w-6 h-6 rounded-full bg-[#f5f0e8] text-[#8c6e52] text-xs flex items-center justify-center">5</div>
            <h3 className="text-[#2a2a2a]">Tải Ảnh Da Hôm Nay</h3>
            <span className="text-xs text-[#9ca3af] ml-auto">Tùy chọn</span>
          </div>

          <input
            ref={fileRef}
            type="file"
            accept="image/*"
            capture="user"
            className="hidden"
            onChange={handlePhoto}
          />

          {photoPreview ? (
            <div className="relative rounded-2xl overflow-hidden aspect-[4/3]">
              <img src={photoPreview} alt="Preview" className="w-full h-full object-cover" />
              <button
                onClick={() => setPhotoPreview(null)}
                className="absolute top-3 right-3 w-8 h-8 rounded-full bg-black/50 backdrop-blur-sm flex items-center justify-center text-white hover:bg-black/70 transition-colors"
              >
                <X className="w-4 h-4" />
              </button>
              <div className="absolute bottom-3 left-3 px-3 py-1 rounded-full bg-emerald-500/80 backdrop-blur-sm text-white text-xs flex items-center gap-1.5">
                <CheckCircle2 className="w-3 h-3" />
                Ảnh đã tải lên
              </div>
            </div>
          ) : (
            <button
              onClick={() => fileRef.current?.click()}
              className="w-full aspect-[16/7] rounded-2xl border-2 border-dashed border-[#e8d5b7] bg-gradient-to-br from-[#f5f0e8]/50 to-[#f5e6d3]/30 flex flex-col items-center justify-center gap-3 hover:border-[#c4a882]/50 hover:from-[#c4a882]/5 hover:to-[#8c6e52]/5 transition-all group cursor-pointer"
            >
              <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#e8d5b7] to-[#f5e6d3] flex items-center justify-center group-hover:scale-110 transition-transform shadow-sm">
                <Camera className="w-6 h-6 text-[#8c6e52]" />
              </div>
              <div className="text-center">
                <p className="text-sm text-[#4b5563] mb-0.5">Tải Ảnh Da Hôm Nay</p>
                <p className="text-xs text-[#9ca3af]">
                  Chụp ảnh hoặc chọn từ thư viện · JPG, PNG
                </p>
              </div>
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/80 border border-white/80 shadow-sm text-xs text-[#c4a882]">
                <Upload className="w-3 h-3" />
                Tải lên
              </div>
            </button>
          )}

          <p className="text-xs text-[#9ca3af] mt-3 text-center">
            📸 AI sử dụng ảnh để so sánh tiến trình theo từng tuần
          </p>
        </div>

        {/* ── Submit Button ── */}
        <div className="relative">
          <div
            className={`absolute -inset-3 rounded-3xl blur-2xl transition-opacity duration-500 ${
              isComplete ? "opacity-100 bg-gradient-to-r from-[#c4a882]/30 to-[#8c6e52]/30" : "opacity-0"
            }`}
          />
          <button
            onClick={handleSubmit}
            disabled={!isComplete}
            className={`relative w-full py-4 rounded-2xl text-white flex items-center justify-center gap-3 transition-all duration-300 ${
              isComplete
                ? "bg-gradient-to-r from-[#c4a882] to-[#8c6e52] shadow-xl shadow-[#c4a882]/25 hover:scale-[1.02] hover:shadow-[#c4a882]/40"
                : "bg-[#e5e7eb] text-[#9ca3af] cursor-not-allowed"
            }`}
          >
            <Sparkles className={`w-5 h-5 ${isComplete ? "text-white" : "text-[#9ca3af]"}`} />
            <span>Cập Nhật Dữ Liệu</span>
          </button>

          {!isComplete && (
            <p className="text-center text-xs text-[#9ca3af] mt-3">
              Trả lời 3 câu hỏi để tiếp tục ↑
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
