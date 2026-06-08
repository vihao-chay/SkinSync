import { useEffect, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router";
import { AlertCircle, ArrowRight, Droplets, RefreshCw, Shield, Sparkles, Zap } from "lucide-react";
import { analyzeSkinApi, type SkinAnalyzeResponse } from "../services/analysisService";
import { getSurveyApi } from "../services/surveyService";

const ANALYSIS_CACHE_KEY = "skinsync_latest_skin_analysis";
const ANALYSIS_IMAGE_KEY = "skinsync_latest_skin_image";

type AnalysisView = SkinAnalyzeResponse & {
  imageUrl: string;
};

const defaultMetrics = [
  { label: "Độ ẩm", value: 68, color: "#c4a882", icon: <Droplets className="w-3.5 h-3.5" /> },
  { label: "Nhạy cảm", value: 35, color: "#f59e0b", icon: <Zap className="w-3.5 h-3.5" /> },
  { label: "Hàng rào da", value: 80, color: "#10b981", icon: <Shield className="w-3.5 h-3.5" /> },
];

export function SkinAnalysisPage() {
  const navigate = useNavigate();
  const location = useLocation();
  const [analysis, setAnalysis] = useState<AnalysisView | null>(null);
  const [skinType, setSkinType] = useState("Da hỗn hợp");
  const [isLoading, setIsLoading] = useState(true);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  useEffect(() => {
    let active = true;

    const load = async () => {
      setIsLoading(true);
      setErrorMessage(null);

      const cachedAnalysis = sessionStorage.getItem(ANALYSIS_CACHE_KEY);
      const cachedImage = sessionStorage.getItem(ANALYSIS_IMAGE_KEY);

      if (cachedAnalysis && cachedImage) {
        try {
          const parsed = JSON.parse(cachedAnalysis) as SkinAnalyzeResponse;
          if (active) {
            setAnalysis({ ...parsed, imageUrl: cachedImage });
            setIsLoading(false);
          }
          return;
        } catch {
          sessionStorage.removeItem(ANALYSIS_CACHE_KEY);
          sessionStorage.removeItem(ANALYSIS_IMAGE_KEY);
        }
      }

      const [surveyResult] = await Promise.all([getSurveyApi()]);

      if (!active) {
        return;
      }

      if (surveyResult.success && surveyResult.content?.skinType) {
        setSkinType(surveyResult.content.skinType);
      }

      setErrorMessage("Chưa có kết quả phân tích mới. Hãy tải ảnh và chạy phân tích trước.");
      setIsLoading(false);
    };

    void load();
    return () => {
      active = false;
    };
  }, [location.key]);

  const rerunWithSample = async () => {
    setIsLoading(true);
    setErrorMessage(null);

    const sampleImage =
      "https://images.unsplash.com/photo-1759334509972-53f70f5f2a69?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080";
    const result = await analyzeSkinApi({ imageUrl: sampleImage });
    if (result.success && result.content) {
      const nextAnalysis = { ...result.content, imageUrl: sampleImage };
      setAnalysis(nextAnalysis);
      sessionStorage.setItem(ANALYSIS_CACHE_KEY, JSON.stringify(result.content));
      sessionStorage.setItem(ANALYSIS_IMAGE_KEY, sampleImage);
      setIsLoading(false);
      return;
    }

    setErrorMessage(result.message || "Không thể chạy lại phân tích.");
    setIsLoading(false);
  };

  const score = analysis ? Math.max(0, 100 - analysis.acneScore / 2 - analysis.oilinessScore / 4) : 0;

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#f5f5f0] via-white to-[#d4f4f4]/20 pt-20">
      <div className="relative overflow-hidden bg-gradient-to-r from-[#c4a882]/8 via-white to-[#8c6e52]/8 border-b border-white/60">
        <div className="absolute inset-0 opacity-40">
          <div className="absolute top-0 right-1/4 w-72 h-72 bg-gradient-to-br from-[#c4a882]/15 to-transparent rounded-full blur-3xl" />
        </div>
        <div className="relative max-w-7xl mx-auto px-6 py-8">
          <div className="flex items-center gap-2 mb-2">
            <span className="px-3 py-1 rounded-full bg-gradient-to-r from-[#c4a882]/10 to-[#8c6e52]/10 border border-[#c4a882]/20 text-[#8c6e52] text-xs">
              ✦ Phân tích da bằng AI
            </span>
          </div>
          <h1 className="text-3xl text-[#2a2a2a]">Báo cáo làn da của bạn</h1>
          <p className="text-[#6b7280] text-sm mt-1">
            Kết quả phân tích được tạo bằng GPT-4o Vision, hiển thị ngay sau khi tải ảnh.
          </p>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-8">
        {errorMessage && (
          <div className="mb-6 flex items-start gap-3 rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800">
            <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
            <span>{errorMessage}</span>
          </div>
        )}

        <div className="grid lg:grid-cols-5 gap-8 items-start">
          <div className="lg:col-span-2">
            <div className="relative">
              <div className="absolute -inset-4 bg-gradient-to-br from-[#c4a882]/20 via-[#8c6e52]/10 to-[#e8d5b7]/30 rounded-[3rem] blur-2xl" />
              <div className="relative bg-gradient-to-b from-[#0f0f1a] to-[#1a1a2e] rounded-3xl overflow-hidden border border-white/10 shadow-2xl min-h-[520px] flex items-center justify-center">
                {isLoading ? (
                  <div className="text-center text-white/80">
                    <div className="w-10 h-10 mx-auto mb-4 border-2 border-white/25 border-t-white rounded-full animate-spin" />
                    <p>Đang tải kết quả phân tích...</p>
                  </div>
                ) : analysis ? (
                  <div className="relative w-full h-full">
                    <img
                      src={analysis.imageUrl}
                      alt="AI Face Analysis"
                      className="w-full h-full object-cover object-top opacity-85 mix-blend-luminosity"
                    />
                    <div className="absolute inset-0 bg-gradient-to-b from-[#c4a882]/20 via-transparent to-[#0f0f1a]/70" />
                    <div className="absolute top-4 left-4 flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#c4a882]/30 backdrop-blur-md border border-[#c4a882]/40">
                      <span className="w-1.5 h-1.5 rounded-full bg-[#e8d5b7] animate-pulse" />
                      <span className="text-[#d4f4f4] text-xs">AI đã phân tích</span>
                    </div>
                    <div className="absolute bottom-4 left-1/2 -translate-x-1/2">
                      <div className="bg-white/10 backdrop-blur-xl border border-white/20 rounded-2xl px-6 py-3 text-center shadow-xl">
                        <div className="text-[#d4f4f4] text-xs mb-1">Điểm tổng quan</div>
                        <div className="text-4xl text-white">
                          {Math.round(score)}
                          <span className="text-xl text-white/50">/100</span>
                        </div>
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="text-center text-white/80 px-6">
                    <Sparkles className="w-10 h-10 mx-auto mb-4 text-[#e8d5b7]" />
                    <p>Chưa có ảnh phân tích. Hãy quay lại trang tải ảnh để chạy AI.</p>
                  </div>
                )}
              </div>
            </div>
          </div>

          <div className="lg:col-span-3 flex flex-col gap-5">
            <div className="grid grid-cols-2 gap-4">
              <div className="col-span-2 sm:col-span-1 bg-gradient-to-br from-[#c4a882] to-[#8c6e52] rounded-3xl p-5 text-white shadow-lg shadow-[#c4a882]/20">
                <div className="text-white/70 text-xs mb-2">Loại da</div>
                <div className="text-4xl mb-2">{analysis?.skinType ?? skinType}</div>
                <div className="text-white/80 text-xs">Được xác định từ ảnh và hồ sơ người dùng</div>
              </div>

              <div className="col-span-2 sm:col-span-1 bg-white/80 backdrop-blur-md rounded-3xl p-5 border border-white/80 shadow-sm">
                <div className="text-[#6b7280] text-xs mb-2">Chỉ số chính</div>
                <div className="space-y-2 text-sm text-[#2a2a2a]">
                  <p>Acne: {analysis?.acneScore ?? "N/A"}</p>
                  <p>Oiliness: {analysis?.oilinessScore ?? "N/A"}</p>
                  <p>Redness: {analysis?.rednessScore ?? "N/A"}</p>
                  <p>Pigmentation: {analysis?.pigmentationScore ?? "N/A"}</p>
                </div>
              </div>
            </div>

            <div className="bg-white/80 backdrop-blur-md rounded-3xl p-5 border border-white/80 shadow-sm">
              <div className="flex items-center gap-2 mb-4">
                <AlertCircle className="w-4 h-4 text-[#f59e0b]" />
                <h3 className="text-[#2a2a2a]">Vấn đề chính được phát hiện</h3>
              </div>
              <div className="flex flex-wrap gap-2">
                {(analysis?.concerns?.length ? analysis.concerns : ["pores", "oiliness", "redness"]).map((item) => (
                  <span key={item} className="px-3 py-1.5 rounded-full bg-[#d4f4f4]/60 text-[#0891b2] text-xs">
                    {item}
                  </span>
                ))}
              </div>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {defaultMetrics.map((metric) => (
                <div key={metric.label} className="bg-white/70 backdrop-blur-sm rounded-2xl p-3 border border-white/80 text-center">
                  <div className="text-xl mb-1">{metric.icon}</div>
                  <div className="text-[#2a2a2a]">
                    {metric.value}<span className="text-xs text-[#9ca3af]">%</span>
                  </div>
                  <div className="text-xs text-[#6b7280]">{metric.label}</div>
                </div>
              ))}
            </div>

            <div className="flex gap-3 flex-col sm:flex-row">
              <button
                type="button"
                onClick={() => void rerunWithSample()}
                className="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-2xl bg-white border border-[#e8d5b7] text-[#8c6e52] hover:bg-[#faf7f2] transition-colors"
              >
                <RefreshCw className="w-4 h-4" />
                Chạy thử với ảnh mẫu
              </button>
              <button
                type="button"
                onClick={() => navigate("/routine")}
                className="inline-flex items-center justify-center gap-2 px-5 py-3 rounded-2xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white hover:opacity-95 transition-opacity"
              >
                Xem lộ trình đề xuất
                <ArrowRight className="w-4 h-4" />
              </button>
            </div>

            <p className="text-xs text-[#9ca3af]">
              Kết quả này chỉ phục vụ mục đích tham khảo và giáo dục, không thay thế tư vấn y khoa.
            </p>

            <div className="text-sm text-[#6b7280]">
              <Link to="/upload" className="text-[#8c6e52] hover:underline">
                Quay lại tải ảnh
              </Link>
              {" · "}
              <Link to="/dashboard" className="text-[#8c6e52] hover:underline">
                Về dashboard
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
