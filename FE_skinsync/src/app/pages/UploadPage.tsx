import { useState, type ChangeEvent, type DragEvent } from "react";
import { Link, useNavigate } from "react-router";
import { AlertCircle, ArrowLeft, Camera, ImagePlus, Sparkles, Upload, X } from "lucide-react";
import { analyzeSkinApi } from "../services/analysisService";

const maxImageSize = 10 * 1024 * 1024;
const ANALYSIS_CACHE_KEY = "skinsync_latest_skin_analysis";
const ANALYSIS_IMAGE_KEY = "skinsync_latest_skin_image";

export function UploadPage() {
  const navigate = useNavigate();
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [dataUrl, setDataUrl] = useState<string | null>(null);
  const [selectedFileName, setSelectedFileName] = useState<string | null>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const previewFile = (file: File) => {
    setErrorMessage(null);

    if (!file.type.startsWith("image/")) {
      setErrorMessage("Vui lòng chọn đúng định dạng ảnh.");
      return;
    }

    if (file.size > maxImageSize) {
      setErrorMessage("Ảnh cần nhỏ hơn 10MB để phân tích ổn định.");
      return;
    }

    const reader = new FileReader();
    reader.onload = (event) => {
      const result = event.target?.result;
      if (typeof result !== "string") {
        setErrorMessage("Không thể đọc ảnh đã chọn.");
        return;
      }

      setPreviewUrl(result);
      setDataUrl(result);
      setSelectedFileName(file.name);
    };
    reader.readAsDataURL(file);
  };

  const handleFileChange = (event: ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (file) {
      previewFile(file);
    }
  };

  const handleDragOver = (event: DragEvent<HTMLDivElement>) => {
    event.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleDrop = (event: DragEvent<HTMLDivElement>) => {
    event.preventDefault();
    setIsDragging(false);

    const file = event.dataTransfer.files?.[0];
    if (file) {
      previewFile(file);
    }
  };

  const clearImage = () => {
    setPreviewUrl(null);
    setDataUrl(null);
    setSelectedFileName(null);
    setErrorMessage(null);
  };

  const handleAnalyze = async () => {
    if (!dataUrl) {
      setErrorMessage("Hãy chọn một ảnh da mặt trước khi phân tích.");
      return;
    }

    setIsAnalyzing(true);
    setErrorMessage(null);

    const result = await analyzeSkinApi({ imageUrl: dataUrl });
    if (result.success && result.content) {
      sessionStorage.setItem(ANALYSIS_CACHE_KEY, JSON.stringify(result.content));
      sessionStorage.setItem(ANALYSIS_IMAGE_KEY, dataUrl);
      navigate("/analysis");
      return;
    }

    setErrorMessage(result.message || "Không thể phân tích ảnh lúc này. Vui lòng thử lại.");
    setIsAnalyzing(false);
  };

  return (
    <div className="min-h-screen bg-[#faf7f2] pt-24 pb-12 px-4 sm:px-6">
      <div className="max-w-4xl mx-auto">
        <div className="mb-8">
          <Link to="/quiz" className="inline-flex items-center gap-2 text-sm text-[#6b7280] hover:text-[#8c6e52] transition-colors mb-4">
            <ArrowLeft className="w-4 h-4" />
            Trở lại khảo sát
          </Link>

          <div className="h-2 bg-[#f5f0e8] rounded-full overflow-hidden mb-3">
            <div className="h-full w-[40%] bg-gradient-to-r from-[#c4a882] to-[#8c6e52] transition-all duration-500" />
          </div>
          <p className="text-sm text-[#6b7280]">Bước 2 / 5</p>
        </div>

        <section className="bg-white/85 backdrop-blur-xl border border-[#e8d5b7]/40 rounded-2xl shadow-sm overflow-hidden">
          <div className="grid lg:grid-cols-[1fr_320px]">
            <div className="p-6 sm:p-8 lg:p-10">
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e8d5b7]/40 text-[#8c6e52] text-xs mb-4">
                <Sparkles className="w-3.5 h-3.5" />
                AI phân tích da
              </div>
              <h1 className="text-3xl text-[#2a2a2a] mb-3">Tải ảnh da mặt</h1>
              <p className="text-sm text-[#6b7280] leading-relaxed mb-8">
                Ảnh rõ nét giúp hệ thống tạo báo cáo da và đề xuất routine chính xác hơn.
              </p>

              {!previewUrl ? (
                <div
                  onDragOver={handleDragOver}
                  onDragLeave={handleDragLeave}
                  onDrop={handleDrop}
                  className={`relative border-2 border-dashed rounded-2xl p-8 sm:p-12 text-center transition-all ${
                    isDragging
                      ? "border-[#c4a882] bg-[#f5f0e8]"
                      : "border-[#e8d5b7] bg-[#faf7f2] hover:border-[#c4a882]"
                  }`}
                >
                  <div className="w-16 h-16 mx-auto mb-5 rounded-2xl bg-gradient-to-br from-[#f5f0e8] to-[#f5e6d3] border border-[#e8d5b7]/60 flex items-center justify-center">
                    <Camera className="w-8 h-8 text-[#8c6e52]" />
                  </div>
                  <h2 className="text-xl text-[#2a2a2a] mb-2">Kéo thả ảnh vào đây</h2>
                  <p className="text-sm text-[#6b7280] mb-6">hoặc chọn ảnh từ thiết bị của bạn</p>

                  <label className="inline-flex items-center gap-2 px-6 py-3 bg-[#c4a882] hover:bg-[#8c6e52] text-white rounded-xl cursor-pointer transition-colors">
                    <Upload className="w-4 h-4" />
                    Chọn ảnh
                    <input type="file" accept="image/*" onChange={handleFileChange} className="hidden" />
                  </label>

                  <p className="text-xs text-[#9ca3af] mt-5">Hỗ trợ JPG, PNG, HEIC. Tối đa 10MB.</p>
                </div>
              ) : (
                <div>
                  <div className="relative rounded-2xl overflow-hidden border border-[#c4a882]/50 mb-5 bg-[#f5f0e8]">
                    <img src={previewUrl} alt="Ảnh da mặt đã tải lên" className="w-full h-[360px] object-cover" />
                    <button
                      type="button"
                      onClick={clearImage}
                      className="absolute top-4 right-4 w-10 h-10 bg-white/90 backdrop-blur-xl rounded-xl flex items-center justify-center hover:bg-white transition-colors"
                      aria-label="Xóa ảnh đã chọn"
                    >
                      <X className="w-5 h-5 text-[#6b7280]" />
                    </button>
                    <div className="absolute inset-x-0 bottom-0 p-4 bg-gradient-to-t from-black/45 to-transparent">
                      <div className="inline-flex items-center gap-2 rounded-full bg-white/90 backdrop-blur-xl px-3 py-1.5 text-xs text-[#8c6e52]">
                        <ImagePlus className="w-3.5 h-3.5" />
                        {selectedFileName ?? "Ảnh đã sẵn sàng để phân tích"}
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {errorMessage && (
                <div className="mt-5 flex items-start gap-3 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
                  <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
                  <span>{errorMessage}</span>
                </div>
              )}

              <div className="mt-8 flex flex-col sm:flex-row gap-3">
                <button
                  type="button"
                  onClick={() => navigate("/dashboard")}
                  disabled={isAnalyzing}
                  className="flex-1 px-6 py-3 rounded-xl border border-[#e8d5b7] text-[#8c6e52] hover:bg-[#f5f0e8] disabled:opacity-60 transition-colors"
                >
                  Bỏ qua
                </button>
                <button
                  type="button"
                  onClick={() => void handleAnalyze()}
                  disabled={isAnalyzing || !dataUrl}
                  className="flex-1 inline-flex items-center justify-center gap-2 px-6 py-3 rounded-xl bg-[#c4a882] text-white hover:bg-[#8c6e52] disabled:opacity-60 disabled:cursor-not-allowed transition-colors"
                >
                  {isAnalyzing ? (
                    <>
                      <span className="w-4 h-4 border-2 border-white/40 border-t-white rounded-full animate-spin" />
                      Đang phân tích
                    </>
                  ) : (
                    <>
                      <Sparkles className="w-4 h-4" />
                      Phân tích ảnh
                    </>
                  )}
                </button>
              </div>
            </div>

            <aside className="border-t lg:border-t-0 lg:border-l border-[#e8d5b7]/35 bg-[#faf7f2]/80 p-6 sm:p-8">
              <h2 className="text-lg text-[#2a2a2a] mb-4">Gợi ý để ảnh rõ hơn</h2>
              <div className="space-y-3">
                {[
                  "Chụp trong ánh sáng tự nhiên hoặc ánh sáng đều.",
                  "Giữ mặt nhìn thẳng, không che vùng trán và má.",
                  "Tẩy trang nhẹ trước khi chụp nếu có thể.",
                ].map((tip, index) => (
                  <div key={tip} className="flex gap-3 rounded-2xl border border-[#e8d5b7]/40 bg-white/80 px-4 py-3">
                    <span className="w-7 h-7 rounded-xl bg-[#e8d5b7]/45 text-[#8c6e52] flex items-center justify-center text-sm flex-shrink-0">
                      {index + 1}
                    </span>
                    <p className="text-sm text-[#4b5563] leading-relaxed">{tip}</p>
                  </div>
                ))}
              </div>
            </aside>
          </div>
        </section>
      </div>
    </div>
  );
}
