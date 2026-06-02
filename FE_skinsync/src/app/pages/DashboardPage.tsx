import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router";
import {
  ArrowUpRight,
  CalendarDays,
  Camera,
  CheckCircle2,
  ChevronRight,
  ClipboardList,
  Droplets,
  History,
  LineChart,
  ShieldCheck,
  Sparkles,
  Sun,
  Target,
  UserRound,
} from "lucide-react";
import { ImageWithFallback } from "../components/figma/ImageWithFallback";
import { useAuth } from "../contexts/AuthContext";
import {
  getAnalysisHistoryApi,
  getLatestAnalysisApi,
  type AnalysisDetail,
  type AnalysisHistoryItem,
} from "../services/analysisService";
import { getProgressOverviewApi, type ProgressOverview } from "../services/progressService";
import { getCurrentRegimenApi, type CurrentRegimenResponse, type RegimenProduct } from "../services/regimenService";
import { getSurveyApi, type SurveyResponse } from "../services/surveyService";

export function DashboardPage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [latestAnalysis, setLatestAnalysis] = useState<AnalysisDetail | null>(null);
  const [history, setHistory] = useState<AnalysisHistoryItem[]>([]);
  const [progress, setProgress] = useState<ProgressOverview | null>(null);
  const [regimen, setRegimen] = useState<CurrentRegimenResponse | null>(null);
  const [survey, setSurvey] = useState<SurveyResponse | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let isMounted = true;

    async function loadDashboard() {
      const [latestResult, historyResult, progressResult, regimenResult, surveyResult] = await Promise.all([
        getLatestAnalysisApi(),
        getAnalysisHistoryApi(1, 5),
        getProgressOverviewApi(),
        getCurrentRegimenApi(),
        getSurveyApi(),
      ]);

      if (!isMounted) {
        return;
      }

      if (latestResult.success && latestResult.content) {
        setLatestAnalysis(latestResult.content);
      }

      if (historyResult.success && historyResult.content) {
        setHistory(historyResult.content.items);
      }

      if (progressResult.success && progressResult.content) {
        setProgress(progressResult.content);
      }

      if (regimenResult.success && regimenResult.content) {
        setRegimen(regimenResult.content);
      }

      if (surveyResult.success && surveyResult.content) {
        setSurvey(surveyResult.content);
      }

      setIsLoading(false);
    }

    void loadDashboard();
    return () => {
      isMounted = false;
    };
  }, []);

  const routineSteps = useMemo(() => {
    if (!regimen) {
      return [];
    }

    return [...regimen.morning.slice(0, 3), ...regimen.evening.slice(0, 3)];
  }, [regimen]);

  const completionRate = progress ? Math.round(progress.completionRateLast28) : 0;
  const overallScore = latestAnalysis?.overallScore ?? progress?.currentScore ?? null;
  const routineStepCount = (regimen?.morning.length ?? 0) + (regimen?.evening.length ?? 0);

  return (
    <div className="min-h-screen bg-[#faf7f2] pt-20 pb-12">
      <div className="border-b border-[#e8d5b7]/40 bg-white/75 backdrop-blur-xl">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-7">
          <div className="flex flex-col lg:flex-row lg:items-end lg:justify-between gap-5">
            <div>
              <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#e8d5b7]/40 text-[#8c6e52] text-xs mb-3">
                <Sparkles className="w-3.5 h-3.5" />
                Tổng quan cá nhân
              </div>
              <h1 className="text-3xl text-[#2a2a2a]">Chào {firstName(user?.fullName)}</h1>
              <p className="text-sm text-[#6b7280] mt-1">
                Theo dõi phân tích da, routine AI và tiến trình chăm sóc trong một màn hình.
              </p>
            </div>

            <div className="flex flex-wrap gap-3">
              <button
                type="button"
                onClick={() => navigate("/upload")}
                className="inline-flex items-center gap-2 px-5 py-3 rounded-xl bg-[#c4a882] text-white hover:bg-[#8c6e52] transition-colors"
              >
                <Camera className="w-4 h-4" />
                Phân tích ảnh
              </button>
              <Link
                to="/routine"
                className="inline-flex items-center gap-2 px-5 py-3 rounded-xl border border-[#e8d5b7] bg-white text-[#8c6e52] hover:bg-[#f5f0e8] transition-colors"
              >
                <ClipboardList className="w-4 h-4" />
                Xem routine
              </Link>
            </div>
          </div>
        </div>
      </div>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid sm:grid-cols-2 xl:grid-cols-4 gap-4 mb-6">
          <MetricCard
            icon={<Sparkles className="w-4 h-4" />}
            label="Điểm da hiện tại"
            value={overallScore ? `${overallScore}/100` : "--"}
            helper={latestAnalysis ? formatDate(latestAnalysis.createdAt) : "Chưa có phân tích"}
          />
          <MetricCard
            icon={<CheckCircle2 className="w-4 h-4" />}
            label="Hoàn thành 28 ngày"
            value={`${completionRate}%`}
            helper={`${progress?.completedDaysLast28 ?? 0} ngày đã ghi nhận`}
          />
          <MetricCard
            icon={<Target className="w-4 h-4" />}
            label="Streak hiện tại"
            value={`${progress?.currentStreak ?? 0} ngày`}
            helper="Duy trì routine đều đặn"
          />
          <MetricCard
            icon={<ClipboardList className="w-4 h-4" />}
            label="Bước routine"
            value={`${routineStepCount}`}
            helper={regimen?.name ?? "Chưa có routine"}
          />
        </div>

        <div className="grid lg:grid-cols-[1.25fr_0.75fr] gap-6">
          <section className="space-y-6">
            <div className="rounded-2xl border border-[#e8d5b7]/40 bg-white/80 backdrop-blur-xl shadow-sm overflow-hidden">
              <div className="grid md:grid-cols-[280px_1fr]">
                <div className="relative min-h-[260px] bg-[#f5f0e8]">
                  {latestAnalysis ? (
                    <ImageWithFallback
                      src={resolveMediaUrl(latestAnalysis.imageUrl)}
                      alt="Ảnh phân tích da mới nhất"
                      className="absolute inset-0 w-full h-full object-cover object-top"
                    />
                  ) : (
                    <div className="absolute inset-0 flex items-center justify-center">
                      <div className="w-16 h-16 rounded-2xl bg-white/80 flex items-center justify-center">
                        <Camera className="w-8 h-8 text-[#c4a882]" />
                      </div>
                    </div>
                  )}
                  <div className="absolute inset-x-0 bottom-0 p-4 bg-gradient-to-t from-black/45 to-transparent">
                    <span className="inline-flex items-center gap-2 rounded-full bg-white/90 backdrop-blur-xl px-3 py-1.5 text-xs text-[#8c6e52]">
                      <LineChart className="w-3.5 h-3.5" />
                      {latestAnalysis ? "Phân tích mới nhất" : "Chưa có dữ liệu"}
                    </span>
                  </div>
                </div>

                <div className="p-6">
                  <div className="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mb-5">
                    <div>
                      <h2 className="text-xl text-[#2a2a2a]">Tình trạng da</h2>
                      <p className="text-sm text-[#6b7280] mt-1">
                        {latestAnalysis
                          ? `Cập nhật ${formatDate(latestAnalysis.createdAt)}`
                          : "Tải ảnh đầu tiên để tạo báo cáo AI."}
                      </p>
                    </div>
                    <Link
                      to={latestAnalysis ? "/analysis" : "/upload"}
                      className="inline-flex items-center gap-2 text-sm text-[#8c6e52] hover:text-[#c4a882] transition-colors"
                    >
                      {latestAnalysis ? "Xem báo cáo" : "Tải ảnh"}
                      <ChevronRight className="w-4 h-4" />
                    </Link>
                  </div>

                  {latestAnalysis ? (
                    <div className="space-y-4">
                      <div className="grid sm:grid-cols-4 gap-3">
                        {[
                          { label: "Điểm tổng", value: latestAnalysis.overallScore, unit: "/100" },
                          { label: "Tuổi da", value: latestAnalysis.skinAge, unit: " tuổi" },
                          { label: "Phục hồi", value: latestAnalysis.recoveryCapacity, unit: "%" },
                          { label: "UV", value: latestAnalysis.uvDamage, unit: "%" },
                        ].map((item) => (
                          <div key={item.label} className="rounded-2xl border border-[#e8d5b7]/35 bg-[#faf7f2] p-3">
                            <p className="text-xs text-[#6b7280] mb-2">{item.label}</p>
                            <p className="text-xl text-[#8c6e52]">
                              {item.value}
                              <span className="text-xs text-[#9ca3af]">{item.unit}</span>
                            </p>
                          </div>
                        ))}
                      </div>

                      <div className="rounded-2xl border border-[#e8d5b7]/35 bg-[#faf7f2] p-4">
                        <p className="text-xs text-[#6b7280] mb-2">Nhận định AI</p>
                        <p className="text-sm text-[#4b5563] leading-relaxed line-clamp-3">
                          {latestAnalysis.rootCauses || "AI đã tạo phân tích cơ bản và routine phù hợp với hồ sơ da của bạn."}
                        </p>
                      </div>
                    </div>
                  ) : (
                    <div className="rounded-2xl border border-dashed border-[#e8d5b7] bg-[#faf7f2] p-6 text-center">
                      <Sparkles className="w-8 h-8 text-[#c4a882] mx-auto mb-3" />
                      <p className="text-sm text-[#6b7280] mb-4">
                        Chưa có ảnh phân tích. Bắt đầu scan để SkinSync tạo routine AI và đề xuất sản phẩm.
                      </p>
                      <Link
                        to="/upload"
                        className="inline-flex items-center gap-2 px-5 py-3 rounded-xl bg-[#c4a882] text-white hover:bg-[#8c6e52] transition-colors"
                      >
                        <Camera className="w-4 h-4" />
                        Tải ảnh ngay
                      </Link>
                    </div>
                  )}
                </div>
              </div>
            </div>

            <div className="rounded-2xl border border-[#e8d5b7]/40 bg-white/80 backdrop-blur-xl p-5 shadow-sm">
              <div className="flex items-center justify-between gap-3 mb-4">
                <div className="flex items-center gap-2">
                  <History className="w-4 h-4 text-[#8c6e52]" />
                  <h2 className="text-lg text-[#2a2a2a]">Lịch sử phân tích</h2>
                </div>
                <Link to="/analysis" className="text-sm text-[#8c6e52] hover:text-[#c4a882] transition-colors">
                  Chi tiết
                </Link>
              </div>

              <div className="space-y-3">
                {history.length > 0 ? history.map((item) => (
                  <div key={item.id} className="flex items-center gap-3 rounded-2xl border border-[#e8d5b7]/35 bg-[#faf7f2] px-4 py-3">
                    <div className="w-10 h-10 rounded-xl bg-white flex items-center justify-center text-[#8c6e52]">
                      <CalendarDays className="w-4 h-4" />
                    </div>
                    <div className="min-w-0 flex-1">
                      <p className="text-sm text-[#2a2a2a]">Điểm da {item.overallScore}/100</p>
                      <p className="text-xs text-[#6b7280]">{formatDate(item.createdAt)}</p>
                    </div>
                    <span className="text-xs px-2.5 py-1 rounded-full bg-[#e8d5b7]/40 text-[#8c6e52]">
                      Tuổi da {item.skinAge}
                    </span>
                  </div>
                )) : (
                  <EmptyLine text={isLoading ? "Đang tải lịch sử phân tích..." : "Chưa có lịch sử phân tích."} />
                )}
              </div>
            </div>
          </section>

          <aside className="space-y-6">
            <div className="rounded-2xl border border-[#e8d5b7]/40 bg-white/80 backdrop-blur-xl p-5 shadow-sm">
              <div className="flex items-center gap-2 mb-4">
                <UserRound className="w-4 h-4 text-[#8c6e52]" />
                <h2 className="text-lg text-[#2a2a2a]">Hồ sơ da</h2>
              </div>
              <div className="space-y-4">
                <InfoRow label="Loại da" value={survey?.skinType ?? "Chưa cập nhật"} />
                <InfoRow label="Ngân sách" value={survey?.monthlyBudget ?? "Chưa cập nhật"} />
                <div>
                  <p className="text-xs text-[#6b7280] mb-2">Mối quan tâm</p>
                  <div className="flex flex-wrap gap-2">
                    {(survey?.skinConcerns?.length ? survey.skinConcerns : ["Chưa cập nhật"]).map((concern) => (
                      <span key={concern} className="px-2.5 py-1 rounded-full bg-[#e8d5b7]/40 text-[#8c6e52] text-xs">
                        {concern}
                      </span>
                    ))}
                  </div>
                </div>
                <Link
                  to="/quiz"
                  className="inline-flex items-center gap-2 text-sm text-[#8c6e52] hover:text-[#c4a882] transition-colors"
                >
                  Cập nhật khảo sát
                  <ArrowUpRight className="w-4 h-4" />
                </Link>
              </div>
            </div>

            <div className="rounded-2xl border border-[#e8d5b7]/40 bg-white/80 backdrop-blur-xl p-5 shadow-sm">
              <div className="flex items-center gap-2 mb-4">
                <ShieldCheck className="w-4 h-4 text-[#8c6e52]" />
                <h2 className="text-lg text-[#2a2a2a]">Routine AI hiện tại</h2>
              </div>

              {regimen ? (
                <div className="space-y-3">
                  <div className="rounded-2xl border border-[#e8d5b7]/35 bg-[#faf7f2] p-4">
                    <p className="text-sm text-[#2a2a2a]">{regimen.name}</p>
                    <p className="text-xs text-[#6b7280] mt-1">
                      {regimen.morning.length} bước sáng, {regimen.evening.length} bước tối
                    </p>
                  </div>
                  {routineSteps.map((step) => (
                    <RoutineStepPreview key={`${step.stepId}-${step.name}`} step={step} />
                  ))}
                  <Link
                    to="/routine"
                    className="inline-flex items-center justify-center gap-2 w-full px-4 py-3 rounded-xl bg-[#c4a882] text-white hover:bg-[#8c6e52] transition-colors"
                  >
                    Xem và chỉnh routine
                    <ChevronRight className="w-4 h-4" />
                  </Link>
                </div>
              ) : (
                <div className="rounded-2xl border border-dashed border-[#e8d5b7] bg-[#faf7f2] p-5 text-center">
                  <ClipboardList className="w-8 h-8 text-[#c4a882] mx-auto mb-3" />
                  <p className="text-sm text-[#6b7280] mb-4">
                    Chưa có routine AI. Routine sẽ được tạo sau khi bạn phân tích ảnh.
                  </p>
                  <Link
                    to="/upload"
                    className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl border border-[#e8d5b7] text-[#8c6e52] hover:bg-white transition-colors"
                  >
                    Tạo routine
                  </Link>
                </div>
              )}
            </div>

            <div className="rounded-2xl border border-[#e8d5b7]/40 bg-gradient-to-br from-[#f5f0e8] to-[#faf7f2] p-5">
              <div className="flex items-start gap-3">
                <div className="w-10 h-10 rounded-xl bg-white flex items-center justify-center text-[#8c6e52]">
                  <Droplets className="w-4 h-4" />
                </div>
                <div>
                  <h2 className="text-lg text-[#2a2a2a] mb-1">Gợi ý hôm nay</h2>
                  <p className="text-sm text-[#6b7280] leading-relaxed">
                    Ưu tiên làm sạch dịu nhẹ, dưỡng ẩm đủ và thoa lại chống nắng nếu ra ngoài hơn 2 giờ.
                  </p>
                </div>
              </div>
            </div>
          </aside>
        </div>
      </main>
    </div>
  );
}

function MetricCard({
  icon,
  label,
  value,
  helper,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  helper: string;
}) {
  return (
    <div className="rounded-2xl border border-[#e8d5b7]/40 bg-white/80 backdrop-blur-xl p-5 shadow-sm">
      <div className="flex items-center gap-2 text-[#8c6e52] mb-3">
        {icon}
        <span className="text-xs text-[#6b7280]">{label}</span>
      </div>
      <p className="text-2xl text-[#2a2a2a]">{value}</p>
      <p className="text-xs text-[#9ca3af] mt-1 truncate">{helper}</p>
    </div>
  );
}

function InfoRow({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex items-center justify-between gap-4 rounded-2xl border border-[#e8d5b7]/35 bg-[#faf7f2] px-4 py-3">
      <span className="text-xs text-[#6b7280]">{label}</span>
      <span className="text-sm text-[#2a2a2a] text-right">{value}</span>
    </div>
  );
}

function RoutineStepPreview({ step }: { step: RegimenProduct }) {
  return (
    <div className="flex items-center gap-3 rounded-2xl border border-[#e8d5b7]/35 bg-white px-3 py-2.5">
      <div className="w-9 h-9 rounded-xl bg-[#f5f0e8] flex items-center justify-center text-[#8c6e52]">
        <Sun className="w-4 h-4" />
      </div>
      <div className="min-w-0 flex-1">
        <p className="text-sm text-[#2a2a2a] truncate">{step.name}</p>
        <p className="text-xs text-[#6b7280] truncate">{step.brand} · {step.category}</p>
      </div>
    </div>
  );
}

function EmptyLine({ text }: { text: string }) {
  return (
    <div className="rounded-2xl border border-dashed border-[#e8d5b7] bg-[#faf7f2] px-4 py-5 text-center text-sm text-[#6b7280]">
      {text}
    </div>
  );
}

function firstName(name?: string | null): string {
  return name?.trim().split(/\s+/)[0] || "bạn";
}

function formatDate(value: string): string {
  return new Intl.DateTimeFormat("vi-VN", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(new Date(value));
}

function resolveMediaUrl(url: string): string {
  if (/^https?:\/\//i.test(url)) {
    return url;
  }

  const base = (import.meta.env.VITE_API_BASE_URL ?? "/api").replace(/\/api\/?$/i, "");
  return `${base}${url}`;
}
