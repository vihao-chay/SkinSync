import { useState, useRef } from "react";
import { Link, useNavigate } from "react-router";
import {
  ArrowLeft,
  ArrowRight,
  Droplets,
  Wind,
  Blend,
  AlertCircle,
  Sparkles,
  Camera,
  Upload,
  X,
  CheckCircle2,
  Sun,
  Leaf,
} from "lucide-react";

type Step = 1 | 2 | 3 | 4;

const skinTypes = [
  {
    id: "oily",
    label: "Da Dầu",
    sub: "Bóng nhờn, lỗ chân lông to, dễ nổi mụn",
    icon: <Droplets className="w-7 h-7" />,
    emoji: "💧",
  },
  {
    id: "dry",
    label: "Da Khô",
    sub: "Khô ráp, bong tróc, căng sau rửa mặt",
    icon: <Wind className="w-7 h-7" />,
    emoji: "🍂",
  },
  {
    id: "combination",
    label: "Da Hỗn Hợp",
    sub: "Vùng T dầu, má khô hoặc thường",
    icon: <Blend className="w-7 h-7" />,
    emoji: "☯️",
  },
  {
    id: "sensitive",
    label: "Da Nhạy Cảm",
    sub: "Dễ kích ứng, đỏ, phản ứng với nhiều sản phẩm",
    icon: <AlertCircle className="w-7 h-7" />,
    emoji: "🌸",
  },
  {
    id: "normal",
    label: "Da Thường",
    sub: "Cân bằng, ít vấn đề, dễ chăm sóc",
    icon: <Leaf className="w-7 h-7" />,
    emoji: "🌿",
  },
  {
    id: "mature",
    label: "Da Lão Hóa",
    sub: "Nếp nhăn, chảy xệ, mất độ đàn hồi",
    icon: <Sun className="w-7 h-7" />,
    emoji: "✨",
  },
];

const concerns = [
  { id: "acne", label: "Mụn", emoji: "🔴", desc: "Mụn đầu đen, đầu trắng, viêm" },
  { id: "pigmentation", label: "Thâm Nám", emoji: "🟤", desc: "Đốm nâu, sắc tố không đều" },
  { id: "pores", label: "Lỗ Chân Lông", emoji: "🟡", desc: "Lỗ chân lông to, rõ" },
  { id: "aging", label: "Lão Hóa", emoji: "⏳", desc: "Nếp nhăn, da chảy xệ" },
  { id: "scars", label: "Sẹo Rỗ", emoji: "🔵", desc: "Sẹo lõm sau mụn" },
  { id: "wrinkles", label: "Nếp Nhăn", emoji: "〰️", desc: "Đường nhăn mịn hoặc sâu" },
  { id: "dull", label: "Da Xỉn Màu", emoji: "🌫️", desc: "Da tối, thiếu sức sống" },
  { id: "dry_patches", label: "Vùng Khô", emoji: "🏜️", desc: "Khô cục bộ, bong tróc" },
  { id: "redness", label: "Đỏ Da", emoji: "🌹", desc: "Ửng đỏ, mao mạch nổi" },
];

const budgetOptions = [
  {
    id: "low",
    label: "Hợp Lý",
    range: "< 500.000đ/tháng",
    desc: "Sản phẩm bình dân, hiệu quả tốt",
    icon: "💚",
    examples: ["The Ordinary", "CeraVe", "Neutrogena"],
  },
  {
    id: "mid",
    label: "Trung Bình",
    range: "500k – 1.5 triệu/tháng",
    desc: "Cân bằng chất lượng và giá cả",
    icon: "💙",
    examples: ["La Roche-Posay", "Paula's Choice", "Kiehl's"],
  },
  {
    id: "high",
    label: "Cao Cấp",
    range: "> 1.5 triệu/tháng",
    desc: "Sản phẩm premium, công nghệ tiên tiến",
    icon: "💜",
    examples: ["SK-II", "Estée Lauder", "La Mer"],
  },
];

const stepLabels = [
  { step: 1, label: "Loại Da" },
  { step: 2, label: "Vấn Đề Chính" },
  { step: 3, label: "Ngân Sách" },
  { step: 4, label: "Tải Ảnh" },
];

export function QuizPage() {
  const navigate = useNavigate();
  const fileRef = useRef<HTMLInputElement>(null);

  const [currentStep, setCurrentStep] = useState<Step>(1);
  const [skinType, setSkinType] = useState("");
  const [selectedConcerns, setSelectedConcerns] = useState<string[]>([]);
  const [budget, setBudget] = useState("");
  const [photoPreview, setPhotoPreview] = useState<string | null>(null);

  const toggleConcern = (id: string) => {
    setSelectedConcerns((prev) =>
      prev.includes(id) ? prev.filter((c) => c !== id) : [...prev, id]
    );
  };

  const handlePhoto = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) setPhotoPreview(URL.createObjectURL(file));
  };

  const canNext = () => {
    if (currentStep === 1) return !!skinType;
    if (currentStep === 2) return selectedConcerns.length > 0;
    if (currentStep === 3) return !!budget;
    return true;
  };

  const handleNext = () => {
    if (currentStep < 4) setCurrentStep((currentStep + 1) as Step);
    else navigate("/analysis");
  };

  const handleBack = () => {
    if (currentStep > 1) setCurrentStep((currentStep - 1) as Step);
  };

  const progress = ((currentStep - 1) / 3) * 100;

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#f5f5f0] via-white to-[#d4f4f4]/20 pt-20 pb-16 px-4">
      <div className="max-w-2xl mx-auto">
        {/* Back link */}
        <div className="mb-6 pt-4">
          {currentStep === 1 ? (
            <Link
              to="/"
              className="inline-flex items-center gap-2 text-sm text-[#6b7280] hover:text-[#c4a882] transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              Trở Lại
            </Link>
          ) : (
            <button
              onClick={handleBack}
              className="inline-flex items-center gap-2 text-sm text-[#6b7280] hover:text-[#c4a882] transition-colors"
            >
              <ArrowLeft className="w-4 h-4" />
              Quay Lại
            </button>
          )}
        </div>

        {/* Step indicator + progress */}
        <div className="mb-8">
          {/* Step dots */}
          <div className="flex items-center justify-between mb-4">
            {stepLabels.map(({ step, label }) => (
              <div key={step} className="flex flex-col items-center gap-1.5 flex-1">
                <div className="flex items-center w-full">
                  {step > 1 && (
                    <div
                      className="flex-1 h-0.5 transition-all duration-500"
                      style={{
                        background:
                          currentStep >= step
                            ? "linear-gradient(to right, #c4a882, #8c6e52)"
                            : "#e5e7eb",
                      }}
                    />
                  )}
                  <div
                    className={`w-9 h-9 rounded-full flex items-center justify-center text-sm flex-shrink-0 transition-all duration-300 ${
                      currentStep > step
                        ? "bg-gradient-to-br from-[#c4a882] to-[#8c6e52] text-white shadow-sm shadow-[#c4a882]/25"
                        : currentStep === step
                        ? "bg-gradient-to-br from-[#c4a882] to-[#8c6e52] text-white shadow-md shadow-[#c4a882]/30 scale-110"
                        : "bg-white border-2 border-[#e5e7eb] text-[#9ca3af]"
                    }`}
                  >
                    {currentStep > step ? <CheckCircle2 className="w-4 h-4" /> : step}
                  </div>
                  {step < 4 && (
                    <div
                      className="flex-1 h-0.5 transition-all duration-500"
                      style={{
                        background:
                          currentStep > step
                            ? "linear-gradient(to right, #c4a882, #8c6e52)"
                            : "#e5e7eb",
                      }}
                    />
                  )}
                </div>
                <span
                  className={`text-xs transition-colors ${
                    currentStep === step ? "text-[#c4a882]" : "text-[#9ca3af]"
                  }`}
                >
                  {label}
                </span>
              </div>
            ))}
          </div>

          {/* Thin progress bar */}
          <div className="h-1 bg-[#e5e7eb] rounded-full overflow-hidden">
            <div
              className="h-full rounded-full bg-gradient-to-r from-[#c4a882] to-[#8c6e52] transition-all duration-500"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>

        {/* Card */}
        <div className="bg-white/90 backdrop-blur-md rounded-3xl shadow-xl border border-white/80 p-7 md:p-10">
          {/* ── STEP 1: Loại Da ── */}
          {currentStep === 1 && (
            <div>
              <div className="mb-6">
                <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-gradient-to-r from-[#c4a882]/10 to-[#8c6e52]/10 border border-[#c4a882]/20 mb-3">
                  <Sparkles className="w-3.5 h-3.5 text-[#c4a882]" />
                  <span className="text-xs text-[#c4a882]">Bước 1 / 4</span>
                </div>
                <h1 className="text-3xl text-[#2a2a2a] mb-2">
                  Loại Da Của Bạn Là Gì?
                </h1>
                <p className="text-sm text-[#6b7280]">
                  AI sẽ dựa vào loại da để lựa chọn nguyên liệu và công thức phù hợp nhất
                </p>
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                {skinTypes.map((type) => (
                  <button
                    key={type.id}
                    onClick={() => setSkinType(type.id)}
                    className={`group flex flex-col items-start gap-3 p-4 rounded-2xl border-2 text-left transition-all duration-200 ${
                      skinType === type.id
                        ? "border-[#c4a882] bg-gradient-to-br from-[#c4a882]/8 to-[#8c6e52]/8 shadow-md shadow-[#c4a882]/10"
                        : "border-[#f0f0ec] hover:border-[#c4a882]/30 hover:bg-[#fafafa]"
                    }`}
                  >
                    <div className="text-2xl">{type.emoji}</div>
                    <div>
                      <div
                        className={`text-sm mb-0.5 ${
                          skinType === type.id ? "text-[#c4a882]" : "text-[#2a2a2a]"
                        }`}
                      >
                        {type.label}
                      </div>
                      <div className="text-xs text-[#9ca3af] leading-relaxed">{type.sub}</div>
                    </div>
                    {skinType === type.id && (
                      <div className="ml-auto self-end">
                        <CheckCircle2 className="w-4 h-4 text-[#c4a882]" />
                      </div>
                    )}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* ── STEP 2: Vấn Đề Chính ── */}
          {currentStep === 2 && (
            <div>
              <div className="mb-6">
                <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-gradient-to-r from-[#c4a882]/10 to-[#8c6e52]/10 border border-[#c4a882]/20 mb-3">
                  <Sparkles className="w-3.5 h-3.5 text-[#c4a882]" />
                  <span className="text-xs text-[#c4a882]">Bước 2 / 4</span>
                </div>
                <h1 className="text-3xl text-[#2a2a2a] mb-2">
                  Vấn Đề Da Bạn Đang Gặp?
                </h1>
                <p className="text-sm text-[#6b7280]">
                  Chọn một hoặc nhiều vấn đề — AI sẽ ưu tiên giải quyết theo thứ tự
                </p>
              </div>

              <div className="grid grid-cols-3 gap-3 mb-4">
                {concerns.map((c) => {
                  const isSelected = selectedConcerns.includes(c.id);
                  return (
                    <button
                      key={c.id}
                      onClick={() => toggleConcern(c.id)}
                      className={`flex flex-col items-center gap-2 py-4 px-2 rounded-2xl border-2 text-center transition-all duration-200 ${
                        isSelected
                          ? "border-[#c4a882] bg-gradient-to-br from-[#c4a882]/8 to-[#8c6e52]/8 shadow-sm"
                          : "border-[#f0f0ec] hover:border-[#c4a882]/30 hover:bg-[#fafafa]"
                      }`}
                    >
                      <span className="text-2xl">{c.emoji}</span>
                      <span
                        className={`text-sm ${isSelected ? "text-[#c4a882]" : "text-[#2a2a2a]"}`}
                      >
                        {c.label}
                      </span>
                      <span className="text-[10px] text-[#9ca3af] leading-tight">{c.desc}</span>
                      {isSelected && (
                        <div className="w-4 h-4 rounded-full bg-gradient-to-br from-[#c4a882] to-[#8c6e52] flex items-center justify-center">
                          <CheckCircle2 className="w-2.5 h-2.5 text-white" />
                        </div>
                      )}
                    </button>
                  );
                })}
              </div>

              {selectedConcerns.length > 0 && (
                <div className="flex flex-wrap gap-2 p-3 rounded-2xl bg-[#f5f5f0]">
                  <span className="text-xs text-[#6b7280] self-center mr-1">Đã chọn:</span>
                  {selectedConcerns.map((id) => {
                    const c = concerns.find((x) => x.id === id)!;
                    return (
                      <button
                        key={id}
                        onClick={() => toggleConcern(id)}
                        className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white text-xs"
                      >
                        {c.emoji} {c.label}
                        <X className="w-3 h-3" />
                      </button>
                    );
                  })}
                </div>
              )}
            </div>
          )}

          {/* ── STEP 3: Ngân Sách ── */}
          {currentStep === 3 && (
            <div>
              <div className="mb-6">
                <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-gradient-to-r from-[#c4a882]/10 to-[#8c6e52]/10 border border-[#c4a882]/20 mb-3">
                  <Sparkles className="w-3.5 h-3.5 text-[#c4a882]" />
                  <span className="text-xs text-[#c4a882]">Bước 3 / 4</span>
                </div>
                <h1 className="text-3xl text-[#2a2a2a] mb-2">
                  Ngân Sách Skincare Mỗi Tháng?
                </h1>
                <p className="text-sm text-[#6b7280]">
                  AI sẽ đề xuất sản phẩm phù hợp với mức chi tiêu bạn có thể thoải mái
                </p>
              </div>

              <div className="flex flex-col gap-4">
                {budgetOptions.map((opt) => (
                  <button
                    key={opt.id}
                    onClick={() => setBudget(opt.id)}
                    className={`flex items-center gap-5 p-5 rounded-2xl border-2 text-left transition-all duration-200 ${
                      budget === opt.id
                        ? "border-[#c4a882] bg-gradient-to-r from-[#c4a882]/8 to-[#8c6e52]/8 shadow-md shadow-[#c4a882]/10"
                        : "border-[#f0f0ec] hover:border-[#c4a882]/30 hover:bg-[#fafafa]"
                    }`}
                  >
                    <span className="text-3xl flex-shrink-0">{opt.icon}</span>
                    <div className="flex-1">
                      <div className="flex items-center justify-between mb-1">
                        <span
                          className={`${budget === opt.id ? "text-[#c4a882]" : "text-[#2a2a2a]"}`}
                        >
                          {opt.label}
                        </span>
                        <span
                          className={`text-sm px-2.5 py-0.5 rounded-full ${
                            budget === opt.id
                              ? "bg-[#c4a882]/10 text-[#c4a882]"
                              : "bg-[#f0f0ec] text-[#6b7280]"
                          }`}
                        >
                          {opt.range}
                        </span>
                      </div>
                      <p className="text-sm text-[#6b7280] mb-2">{opt.desc}</p>
                      <div className="flex flex-wrap gap-1.5">
                        {opt.examples.map((ex) => (
                          <span
                            key={ex}
                            className="text-xs px-2 py-0.5 rounded-full bg-white border border-[#e5e7eb] text-[#6b7280]"
                          >
                            {ex}
                          </span>
                        ))}
                      </div>
                    </div>
                    {budget === opt.id && (
                      <CheckCircle2 className="w-5 h-5 text-[#c4a882] flex-shrink-0" />
                    )}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* ── STEP 4: Tải Ảnh ── */}
          {currentStep === 4 && (
            <div>
              <div className="mb-6">
                <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-gradient-to-r from-[#c4a882]/10 to-[#8c6e52]/10 border border-[#c4a882]/20 mb-3">
                  <Sparkles className="w-3.5 h-3.5 text-[#c4a882]" />
                  <span className="text-xs text-[#c4a882]">Bước 4 / 4</span>
                </div>
                <h1 className="text-3xl text-[#2a2a2a] mb-2">
                  Cho AI Nhìn Thấy Da Bạn
                </h1>
                <p className="text-sm text-[#6b7280]">
                  Ảnh chụp mặt giúp AI phân tích chính xác hơn 3x so với chỉ dùng câu hỏi. Hoàn toàn{" "}
                  <span className="text-[#c4a882]">riêng tư & bảo mật</span>.
                </p>
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
                <div className="mb-5">
                  <div className="relative rounded-2xl overflow-hidden aspect-[4/3] mb-3">
                    <img
                      src={photoPreview}
                      alt="Preview"
                      className="w-full h-full object-cover object-top"
                    />
                    <button
                      onClick={() => setPhotoPreview(null)}
                      className="absolute top-3 right-3 w-9 h-9 rounded-full bg-black/50 backdrop-blur-sm flex items-center justify-center text-white hover:bg-black/70 transition-colors"
                    >
                      <X className="w-4 h-4" />
                    </button>
                    <div className="absolute bottom-0 inset-x-0 bg-gradient-to-t from-black/60 to-transparent p-4">
                      <div className="flex items-center gap-2 text-white text-sm">
                        <CheckCircle2 className="w-4 h-4 text-emerald-400" />
                        Ảnh đã tải lên — AI sẵn sàng phân tích
                      </div>
                    </div>
                  </div>
                  <button
                    onClick={() => fileRef.current?.click()}
                    className="w-full py-3 rounded-xl border border-[#c4a882]/30 text-[#c4a882] text-sm hover:bg-[#c4a882]/5 transition-colors flex items-center justify-center gap-2"
                  >
                    <Camera className="w-4 h-4" />
                    Chụp Lại / Đổi Ảnh
                  </button>
                </div>
              ) : (
                <div className="mb-5">
                  <button
                    onClick={() => fileRef.current?.click()}
                    className="w-full aspect-[4/3] rounded-2xl border-2 border-dashed border-[#e8d5b7] bg-gradient-to-br from-[#f5f0e8]/50 to-[#f5e6d3]/30 flex flex-col items-center justify-center gap-4 hover:border-[#c4a882]/40 hover:from-[#c4a882]/5 hover:to-[#8c6e52]/5 transition-all cursor-pointer group mb-3"
                  >
                    <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-[#d4f4f4] to-[#fce7f3] flex items-center justify-center group-hover:scale-110 transition-transform shadow-sm">
                      <Camera className="w-8 h-8 text-[#c4a882]" />
                    </div>
                    <div className="text-center">
                      <p className="text-[#2a2a2a] mb-1">Chụp Ảnh Mặt</p>
                      <p className="text-sm text-[#9ca3af]">
                        Ánh sáng tự nhiên, không trang điểm · JPG, PNG
                      </p>
                    </div>
                    <div className="flex items-center gap-1.5 px-4 py-2 rounded-full bg-white/80 border border-white shadow-sm text-[#c4a882] text-sm">
                      <Upload className="w-4 h-4" />
                      Tải Ảnh Lên
                    </div>
                  </button>

                  {/* Skip option */}
                  <p className="text-center text-xs text-[#9ca3af]">
                    Hoặc{" "}
                    <button
                      onClick={() => navigate("/analysis")}
                      className="text-[#c4a882] hover:text-[#8c6e52] underline-offset-2 underline transition-colors"
                    >
                      bỏ qua bước này
                    </button>{" "}
                    — AI sẽ dùng câu trả lời của bạn thay thế
                  </p>
                </div>
              )}

              {/* Tips */}
              <div className="bg-gradient-to-r from-[#d4f4f4]/40 to-[#fce7f3]/30 rounded-2xl p-4 border border-white/80">
                <p className="text-xs text-[#6b7280] mb-2">📸 Mẹo chụp ảnh đạt chuẩn AI:</p>
                <ul className="space-y-1.5 text-xs text-[#6b7280]">
                  {[
                    "Đứng gần cửa sổ, ánh sáng tự nhiên đều",
                    "Không trang điểm, không filter",
                    "Chụp thẳng mặt, khoảng cách 30–40cm",
                    "Tóc ra sau để thấy rõ toàn bộ mặt",
                  ].map((tip, i) => (
                    <li key={i} className="flex items-start gap-2">
                      <span className="text-[#c4a882] flex-shrink-0">✓</span>
                      {tip}
                    </li>
                  ))}
                </ul>
              </div>
            </div>
          )}

          {/* Navigation Buttons */}
          <div className="flex gap-3 mt-8">
            {currentStep > 1 && (
              <button
                onClick={handleBack}
                className="flex items-center gap-2 px-6 py-3.5 rounded-2xl border-2 border-[#e5e7eb] text-[#6b7280] hover:border-[#c4a882]/30 hover:text-[#c4a882] transition-all"
              >
                <ArrowLeft className="w-4 h-4" />
                Quay Lại
              </button>
            )}

            <button
              onClick={handleNext}
              disabled={currentStep < 4 && !canNext()}
              className={`flex-1 flex items-center justify-center gap-2 py-3.5 rounded-2xl transition-all duration-300 ${
                canNext()
                  ? "bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white shadow-lg shadow-[#c4a882]/20 hover:shadow-[#c4a882]/35 hover:scale-[1.01]"
                  : "bg-[#e5e7eb] text-[#9ca3af] cursor-not-allowed"
              }`}
            >
              {currentStep === 4 ? (
                <>
                  <Sparkles className="w-5 h-5" />
                  Phân Tích Ngay
                </>
              ) : (
                <>
                  Tiếp Theo
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </div>
        </div>

        {/* Bottom summary (steps 2+) */}
        {currentStep > 1 && (
          <div className="mt-4 px-2 flex flex-wrap gap-3">
            {skinType && (
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/70 border border-white/80 shadow-sm text-xs text-[#6b7280]">
                <span>{skinTypes.find((t) => t.id === skinType)?.emoji}</span>
                <span>{skinTypes.find((t) => t.id === skinType)?.label}</span>
              </div>
            )}
            {currentStep > 2 && selectedConcerns.length > 0 && (
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/70 border border-white/80 shadow-sm text-xs text-[#6b7280]">
                🎯 {selectedConcerns.length} vấn đề
              </div>
            )}
            {currentStep > 3 && budget && (
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-white/70 border border-white/80 shadow-sm text-xs text-[#6b7280]">
                {budgetOptions.find((b) => b.id === budget)?.icon}{" "}
                {budgetOptions.find((b) => b.id === budget)?.label}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}