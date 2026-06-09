import { useState, useEffect, useRef } from "react";
import { Link } from "react-router";
import {
  Sparkles,
  Target,
  TrendingUp,
  Shield,
  ArrowRight,
  Star,
  CheckCircle2,
  Zap,
  Leaf,
  FlaskConical,
  Brain,
  ChevronRight,
  Play,
  Users,
  Award,
  Clock,
} from "lucide-react";
import { BrandMark } from "../components/BrandMark";
import { SkinAiChatBox } from "../components/SkinAiChatBox";

/* ─── tiny hook: animate number up ─── */
function useCountUp(target: number, duration = 1800, start = false) {
  const [val, setVal] = useState(0);
  useEffect(() => {
    if (!start) return;
    let startTime: number | null = null;
    const step = (ts: number) => {
      if (!startTime) startTime = ts;
      const progress = Math.min((ts - startTime) / duration, 1);
      setVal(Math.floor(progress * target));
      if (progress < 1) requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  }, [start, target, duration]);
  return val;
}

const testimonials = [
  {
    name: "Nguyễn Thị Lan",
    role: "Kỹ sư phần mềm",
    avatar: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=80&h=80&fit=crop&crop=face",
    text: "Sau 6 tuần theo lộ trình AI, mụn đầu đen giảm 80%! Chưa bao giờ dùng sản phẩm nào phù hợp đến vậy.",
    rating: 5,
    skin: "Da dầu mụn",
  },
  {
    name: "Trần Minh Châu",
    role: "Kiến trúc sư",
    avatar: "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=80&h=80&fit=crop&crop=face",
    text: "AI phân tích đúng ngay lần đầu — da tôi nhạy cảm với hương liệu. Lộ trình cực kỳ chính xác và an toàn.",
    rating: 5,
    skin: "Da nhạy cảm",
  },
  {
    name: "Phạm Thu Hương",
    role: "Bác sĩ nội trú",
    avatar: "https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=80&h=80&fit=crop&crop=face",
    text: "Tôi đã thử hàng chục app skincare nhưng đây là cái đầu tiên cho tôi thấy kết quả thực sự.",
    rating: 5,
    skin: "Da hỗn hợp",
  },
];

const skinTypes = [
  { icon: "💧", label: "Da Dầu", sub: "Kiểm soát bã nhờn tối ưu", color: "from-sky-50 to-blue-50", border: "border-sky-100" },
  { icon: "🌸", label: "Da Khô", sub: "Phục hồi độ ẩm sâu", color: "from-rose-50 to-pink-50", border: "border-rose-100" },
  { icon: "🌿", label: "Da Hỗn Hợp", sub: "Cân bằng toàn diện", color: "from-emerald-50 to-teal-50", border: "border-emerald-100" },
  { icon: "🌺", label: "Da Nhạy Cảm", sub: "Bảo vệ nhẹ nhàng", color: "from-amber-50 to-orange-50", border: "border-amber-100" },
];

const features = [
  {
    icon: Brain,
    title: "AI Phân Tích Sâu",
    desc: "Công nghệ Computer Vision phân tích 47 chỉ số da trong vòng 30 giây với độ chính xác 98%.",
    tag: "Công nghệ",
    gradient: "from-[#c4a882]/15 to-[#f5e6d3]/30",
    iconBg: "from-[#c4a882] to-[#8c6e52]",
  },
  {
    icon: Target,
    title: "Cá Nhân Hóa 100%",
    desc: "Lộ trình chăm sóc riêng biệt dựa trên DNA làn da, lối sống và mục tiêu của bạn.",
    tag: "Chính xác",
    gradient: "from-[#f5e6d3]/30 to-[#e8d5b7]/20",
    iconBg: "from-[#8c6e52] to-[#c4a882]",
  },
  {
    icon: TrendingUp,
    title: "Theo Dõi Tiến Trình",
    desc: "Biểu đồ trực quan so sánh da theo tuần/tháng. AI tự điều chỉnh lộ trình khi cần thiết.",
    tag: "Thông minh",
    gradient: "from-[#e8d5b7]/20 to-[#f5f0e8]/40",
    iconBg: "from-[#c4a882] to-[#8c6e52]",
  },
  {
    icon: Shield,
    title: "An Toàn Tuyệt Đối",
    desc: "Mọi gợi ý đều được kiểm duyệt bởi bác sĩ da liễu. Không có thành phần độc hại.",
    tag: "Bảo mật",
    gradient: "from-[#f5f0e8]/40 to-[#c4a882]/10",
    iconBg: "from-[#8c6e52] to-[#c4a882]",
  },
];

export function LandingPage() {
  const [statsVisible, setStatsVisible] = useState(false);
  const statsRef = useRef<HTMLDivElement>(null);
  const accuracy = useCountUp(98, 1500, statsVisible);
  const users = useCountUp(50, 1800, statsVisible);
  const products = useCountUp(2400, 2000, statsVisible);

  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => { if (entry.isIntersecting) setStatsVisible(true); },
      { threshold: 0.3 }
    );
    if (statsRef.current) observer.observe(statsRef.current);
    return () => observer.disconnect();
  }, []);

  return (
    <div className="min-h-screen bg-[#faf7f2] overflow-x-hidden">
      <SkinAiChatBox />

      {/* ══════════════════════════════════════════
          HERO SECTION
      ══════════════════════════════════════════ */}
      <section className="relative min-h-screen flex items-center pt-20 overflow-hidden">
        {/* Background layers */}
        <div className="absolute inset-0 bg-gradient-to-br from-[#faf7f2] via-[#f5f0e8] to-[#faf7f2]" />
        <div className="absolute top-0 right-0 w-[60%] h-full bg-gradient-to-l from-[#e8d5b7]/25 to-transparent" />
        <div className="absolute bottom-0 left-0 w-96 h-96 bg-[#c4a882]/8 rounded-full blur-3xl" />
        <div className="absolute top-24 left-[40%] w-72 h-72 bg-[#f5e6d3]/40 rounded-full blur-3xl" />

        {/* Decorative circles */}
        <div className="absolute top-32 right-[35%] w-3 h-3 rounded-full bg-[#c4a882]/40" />
        <div className="absolute top-48 right-[28%] w-1.5 h-1.5 rounded-full bg-[#8c6e52]/30" />
        <div className="absolute bottom-40 left-16 w-2 h-2 rounded-full bg-[#c4a882]/50" />

        <div className="relative max-w-7xl mx-auto px-6 lg:px-12 w-full py-20">
          <div className="grid lg:grid-cols-2 gap-16 items-center">

            {/* LEFT: Text */}
            <div className="space-y-8 z-10">
              {/* Pill badge */}
              <div className="inline-flex items-center gap-2.5 px-4 py-2 bg-white/70 backdrop-blur-sm rounded-full border border-[#e8d5b7]/80 shadow-sm">
                <span className="w-2 h-2 rounded-full bg-[#c4a882] animate-pulse" />
                <span className="text-sm text-[#8c6e52]">✦ Công nghệ AI tiên tiến nhất Việt Nam</span>
              </div>

              {/* Headline */}
              <div className="space-y-3">
                <h1 className="text-5xl lg:text-[64px] text-[#1a1410] leading-[1.1] tracking-tight">
                  Làn Da Hoàn Hảo
                  <br />
                  <span className="relative inline-block">
                    <span className="bg-gradient-to-r from-[#c4a882] via-[#b8956e] to-[#8c6e52] bg-clip-text text-transparent">
                      Bắt Đầu Từ AI
                    </span>
                    {/* underline accent */}
                    <svg className="absolute -bottom-1 left-0 w-full" height="6" viewBox="0 0 300 6" fill="none" preserveAspectRatio="none">
                      <path d="M0 4 Q75 1 150 4 Q225 7 300 4" stroke="url(#uGrad)" strokeWidth="2.5" strokeLinecap="round" fill="none"/>
                      <defs>
                        <linearGradient id="uGrad" x1="0" y1="0" x2="300" y2="0">
                          <stop offset="0%" stopColor="#c4a882" stopOpacity="0.6"/>
                          <stop offset="100%" stopColor="#8c6e52" stopOpacity="0.3"/>
                        </linearGradient>
                      </defs>
                    </svg>
                  </span>
                </h1>
                <p className="text-lg text-[#6b7280] leading-relaxed max-w-lg">
                  Phân tích chuyên sâu, cá nhân hóa lộ trình, và theo dõi tiến trình mỗi ngày — tất cả trong một nền tảng thông minh duy nhất.
                </p>
              </div>

              {/* CTA Buttons */}
              <div className="flex flex-wrap gap-4 items-center">
                <Link
                  to="/quiz"
                  className="group flex items-center gap-2.5 px-7 py-3.5 bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white rounded-full shadow-lg shadow-[#c4a882]/30 hover:shadow-xl hover:shadow-[#c4a882]/40 hover:scale-[1.03] transition-all duration-300"
                >
                  <Sparkles className="w-4 h-4" />
                  <span>Phân Tích Da Miễn Phí</span>
                  <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
                </Link>
                <Link
                  to="/analysis"
                  className="flex items-center gap-2 px-6 py-3.5 bg-white/80 backdrop-blur-sm text-[#4b5563] rounded-full border border-[#e8d5b7]/80 hover:border-[#c4a882]/40 hover:bg-white transition-all duration-300 shadow-sm"
                >
                  <Play className="w-3.5 h-3.5 text-[#c4a882]" />
                  <span className="text-sm">Xem Demo</span>
                </Link>
              </div>

              {/* Social proof micro row */}
              <div className="flex items-center gap-6 pt-2">
                <div className="flex -space-x-2.5">
                  {[
                    "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=40&h=40&fit=crop&crop=face",
                    "https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=40&h=40&fit=crop&crop=face",
                    "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=40&h=40&fit=crop&crop=face",
                    "https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=40&h=40&fit=crop&crop=face",
                  ].map((src, i) => (
                    <img key={i} src={src} alt="" className="w-9 h-9 rounded-full border-2 border-white object-cover" />
                  ))}
                </div>
                <div>
                  <div className="flex items-center gap-1 mb-0.5">
                    {Array(5).fill(0).map((_, i) => (
                      <Star key={i} className="w-3.5 h-3.5 fill-[#f59e0b] text-[#f59e0b]" />
                    ))}
                    <span className="text-sm text-[#4b5563] ml-1">4.9</span>
                  </div>
                  <p className="text-xs text-[#9ca3af]">Hơn 50,000 người dùng tin tưởng</p>
                </div>
              </div>
            </div>

            {/* RIGHT: Hero Image with floating cards */}
            <div className="relative z-10 hidden lg:block">
              {/* Main image container */}
              <div className="relative rounded-[2.5rem] overflow-hidden shadow-2xl shadow-[#8c6e52]/15">
                <img
                  src="https://images.unsplash.com/photo-1590110348915-993aca51ea03?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxsdXh1cnklMjBza2luY2FyZSUyMHdvbWFuJTIwZ2xvd2luZyUyMHNraW4lMjBjbG9zZSUyMHVwfGVufDF8fHx8MTc3NDA4MjI3MHww&ixlib=rb-4.1.0&q=80&w=1080"
                  alt="AI Skincare Analysis"
                  className="w-full h-[560px] object-cover"
                />
                {/* Gradient overlay bottom */}
                <div className="absolute inset-0 bg-gradient-to-t from-[#2a1a0a]/20 via-transparent to-transparent" />

                {/* Scan overlay lines */}
                <div className="absolute inset-0">
                  <div className="absolute top-[28%] left-[18%] w-8 h-8">
                    <div className="absolute top-0 left-0 w-3 h-3 border-t-2 border-l-2 border-[#c4a882]/70" />
                  </div>
                  <div className="absolute top-[28%] right-[18%] w-8 h-8">
                    <div className="absolute top-0 right-0 w-3 h-3 border-t-2 border-r-2 border-[#c4a882]/70" />
                  </div>
                  <div className="absolute bottom-[28%] left-[18%] w-8 h-8">
                    <div className="absolute bottom-0 left-0 w-3 h-3 border-b-2 border-l-2 border-[#c4a882]/70" />
                  </div>
                  <div className="absolute bottom-[28%] right-[18%] w-8 h-8">
                    <div className="absolute bottom-0 right-0 w-3 h-3 border-b-2 border-r-2 border-[#c4a882]/70" />
                  </div>
                  {/* scan line */}
                  <div className="absolute left-[18%] right-[18%] top-1/2 h-[1px] bg-gradient-to-r from-transparent via-[#c4a882]/50 to-transparent" />
                </div>
              </div>

              {/* Floating card — Skin Score */}
              <div className="absolute -left-8 top-12 bg-white/90 backdrop-blur-md rounded-2xl shadow-xl shadow-[#8c6e52]/10 p-4 border border-[#e8d5b7]/60 min-w-[160px]">
                <div className="flex items-center gap-2.5 mb-2.5">
                  <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-[#c4a882] to-[#8c6e52] flex items-center justify-center">
                    <Sparkles className="w-4 h-4 text-white" />
                  </div>
                  <div>
                    <p className="text-[11px] text-[#9ca3af]">Điểm Da</p>
                    <p className="text-lg text-[#2a2a2a]" style={{ fontWeight: 600 }}>87/100</p>
                  </div>
                </div>
                <div className="h-1.5 bg-[#f5f0e8] rounded-full overflow-hidden">
                  <div className="h-full w-[87%] bg-gradient-to-r from-[#c4a882] to-[#8c6e52] rounded-full" />
                </div>
              </div>

              {/* Floating card — AI Result */}
              <div className="absolute -right-6 bottom-20 bg-white/90 backdrop-blur-md rounded-2xl shadow-xl shadow-[#8c6e52]/10 p-4 border border-[#e8d5b7]/60 min-w-[180px]">
                <p className="text-[11px] text-[#9ca3af] mb-2">✦ Phân tích AI</p>
                <div className="space-y-1.5">
                  {[
                    { label: "Độ ẩm", val: 72, color: "from-sky-400 to-blue-500" },
                    { label: "Dầu", val: 45, color: "from-amber-400 to-orange-500" },
                    { label: "Độ đều màu", val: 83, color: "from-[#c4a882] to-[#8c6e52]" },
                  ].map((item) => (
                    <div key={item.label} className="flex items-center gap-2">
                      <span className="text-[10px] text-[#6b7280] w-16">{item.label}</span>
                      <div className="flex-1 h-1.5 bg-[#f5f0e8] rounded-full overflow-hidden">
                        <div className={`h-full bg-gradient-to-r ${item.color} rounded-full`} style={{ width: `${item.val}%` }} />
                      </div>
                      <span className="text-[10px] text-[#9ca3af] w-6 text-right">{item.val}</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Floating badge — instant */}
              <div className="absolute left-4 bottom-8 flex items-center gap-2 px-3.5 py-2 bg-[#1a1410]/80 backdrop-blur-sm rounded-full text-white text-xs shadow-lg">
                <Zap className="w-3.5 h-3.5 text-[#c4a882]" />
                Phân tích trong 30 giây
              </div>
            </div>
          </div>
        </div>

        {/* Bottom wave */}
        <div className="absolute bottom-0 left-0 right-0">
          <svg viewBox="0 0 1440 60" fill="none" xmlns="http://www.w3.org/2000/svg" className="w-full">
            <path d="M0 60V30 Q360 0 720 30 Q1080 60 1440 30V60H0Z" fill="white" fillOpacity="0.5"/>
          </svg>
        </div>
      </section>

      {/* ══════════════════════════════════════════
          STATS BAR
      ══════════════════════════════════════════ */}
      <section ref={statsRef} className="relative py-12 bg-white border-y border-[#e8d5b7]/40">
        <div className="max-w-5xl mx-auto px-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 text-center">
            {[
              { value: `${accuracy}%`, label: "Độ chính xác AI", icon: Brain },
              { value: `${users}K+`, label: "Người dùng tin tưởng", icon: Users },
              { value: `${products}+`, label: "Sản phẩm được kiểm duyệt", icon: Award },
              { value: "4.9★", label: "Đánh giá trung bình", icon: Star },
            ].map((stat, i) => (
              <div key={i} className="group flex flex-col items-center gap-1.5 py-4 px-3 rounded-2xl hover:bg-[#faf7f2] transition-colors">
                <stat.icon className="w-5 h-5 text-[#c4a882] mb-1" />
                <div className="text-3xl text-[#1a1410]" style={{ fontWeight: 700 }}>{stat.value}</div>
                <div className="text-sm text-[#6b7280]">{stat.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════
          BRAND PHILOSOPHY (Nature · Science · AI)
      ══════════════════════════════════════════ */}
      <section className="py-24 px-6 bg-[#faf7f2]">
        <div className="max-w-7xl mx-auto">
          <div className="grid lg:grid-cols-2 gap-16 items-center">
            {/* Images mosaic */}
            <div className="relative grid grid-cols-2 gap-4 h-[480px]">
              <div className="col-span-1 space-y-4">
                <div className="rounded-3xl overflow-hidden h-56 shadow-lg">
                  <img
                    src="https://images.unsplash.com/photo-1760860991924-237b4160efbd?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxuYXR1cmFsJTIwYm90YW5pY2FsJTIwaW5ncmVkaWVudHMlMjBza2luY2FyZSUyMHNlcnVtJTIwYm90dGxlfGVufDF8fHx8MTc3NDA4MjI3MHww&ixlib=rb-4.1.0&q=80&w=600"
                    alt="Natural ingredients"
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="rounded-3xl overflow-hidden h-40 shadow-lg">
                  <img
                    src="https://images.unsplash.com/photo-1749137315928-bc96451fa4c0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxtaW5pbWFsaXN0JTIwc2tpbmNhcmUlMjBwcm9kdWN0cyUyMGZsYXQlMjBsYXklMjBiZWlnZXxlbnwxfHx8fDE3NzQwODIyNzB8MA&ixlib=rb-4.1.0&q=80&w=600"
                    alt="Skincare products"
                    className="w-full h-full object-cover"
                  />
                </div>
              </div>
              <div className="col-span-1 pt-10 space-y-4">
                <div className="rounded-3xl overflow-hidden h-40 shadow-lg">
                  <img
                    src="https://images.unsplash.com/photo-1663229049147-30f47be043ea?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxBSSUyMHRlY2hub2xvZ3klMjBza2luJTIwYW5hbHlzaXMlMjBmYWNlJTIwc2NhbnxlbnwxfHx8fDE3NzQwODIyNzN8MA&ixlib=rb-4.1.0&q=80&w=600"
                    alt="AI skin scan"
                    className="w-full h-full object-cover"
                  />
                </div>
                <div className="rounded-3xl overflow-hidden h-56 shadow-lg">
                  <img
                    src="https://images.unsplash.com/photo-1693004923522-806dafe5a1a0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3b21hbiUyMGFwcGx5aW5nJTIwc2VydW0lMjBtb2lzdHVyaXplciUyMGx1eHVyeSUyMHNwYXxlbnwxfHx8fDE3NzQwODIyNzN8MA&ixlib=rb-4.1.0&q=80&w=600"
                    alt="Woman applying serum"
                    className="w-full h-full object-cover"
                  />
                </div>
              </div>
              {/* Badge over images */}
              <div className="absolute bottom-4 left-4 right-4 bg-white/90 backdrop-blur-md rounded-2xl p-4 border border-[#e8d5b7]/60 shadow-lg flex items-center gap-4">
                <div className="flex -space-x-1">
                  {["🌿", "🔬", "🤖"].map((e, i) => (
                    <div key={i} className="w-9 h-9 rounded-full bg-gradient-to-br from-[#f5f0e8] to-[#e8d5b7] flex items-center justify-center text-base border-2 border-white">
                      {e}
                    </div>
                  ))}
                </div>
                <div>
                  <p className="text-sm text-[#2a2a2a]" style={{ fontWeight: 600 }}>Thiên Nhiên · Khoa Học · AI</p>
                  <p className="text-xs text-[#9ca3af]">Ba trụ cột của làn da khỏe mạnh</p>
                </div>
              </div>
            </div>

            {/* Text */}
            <div className="space-y-8">
              <div className="inline-flex items-center gap-2 px-3.5 py-1.5 bg-[#f5f0e8] rounded-full border border-[#e8d5b7]/60">
                <Leaf className="w-3.5 h-3.5 text-[#8c6e52]" />
                <span className="text-xs text-[#8c6e52]">Triết lý của chúng tôi</span>
              </div>
              <h2 className="text-4xl lg:text-5xl text-[#1a1410] leading-tight">
                Nơi Thiên Nhiên<br />
                Gặp Khoa Học &<br />
                <span className="text-[#c4a882]">Trí Tuệ AI</span>
              </h2>
              <p className="text-[#6b7280] leading-relaxed">
                Chúng tôi tin rằng mỗi làn da là duy nhất. Bằng cách kết hợp thành phần thiên nhiên thuần khiết, nghiên cứu khoa học tiên tiến và sức mạnh của AI, chúng tôi tạo ra lộ trình chăm sóc da thực sự phù hợp với bạn.
              </p>
              <div className="space-y-4">
                {[
                  { icon: Leaf, text: "Thành phần thiên nhiên được chứng nhận quốc tế", color: "text-emerald-600 bg-emerald-50" },
                  { icon: FlaskConical, text: "Nghiên cứu lâm sàng với hơn 10,000 đối tượng da", color: "text-blue-600 bg-blue-50" },
                  { icon: Brain, text: "Mô hình AI được huấn luyện trên 5 triệu ảnh da", color: "text-[#8c6e52] bg-[#f5f0e8]" },
                ].map((item, i) => (
                  <div key={i} className="flex items-center gap-3.5">
                    <div className={`w-9 h-9 rounded-xl ${item.color} flex items-center justify-center flex-shrink-0`}>
                      <item.icon className="w-4 h-4" />
                    </div>
                    <span className="text-sm text-[#4b5563]">{item.text}</span>
                  </div>
                ))}
              </div>
              <Link
                to="/quiz"
                className="inline-flex items-center gap-2 text-[#c4a882] hover:text-[#8c6e52] transition-colors group"
              >
                <span className="text-sm" style={{ fontWeight: 500 }}>Khám phá công nghệ</span>
                <ChevronRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════
          FEATURES
      ══════════════════════════════════════════ */}
      <section className="py-24 px-6 bg-white">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 bg-[#f5f0e8] rounded-full border border-[#e8d5b7]/60 mb-4">
              <Zap className="w-3.5 h-3.5 text-[#c4a882]" />
              <span className="text-xs text-[#8c6e52]">Tính năng nổi bật</span>
            </div>
            <h2 className="text-4xl lg:text-5xl text-[#1a1410] mb-4">
              Tại Sao Chọn <span className="text-[#c4a882]">SkinSync</span>
            </h2>
            <p className="text-[#6b7280] max-w-xl mx-auto">
              Nền tảng kết hợp công nghệ AI tiên tiến với kiến thức chuyên sâu về da liễu để mang lại kết quả thực sự.
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-5">
            {features.map((f, i) => (
              <div
                key={i}
                className={`group relative p-6 rounded-3xl bg-gradient-to-br ${f.gradient} border border-[#e8d5b7]/40 hover:border-[#c4a882]/30 hover:shadow-lg hover:shadow-[#c4a882]/8 transition-all duration-300 cursor-default`}
              >
                <div className="mb-5">
                  <div className={`w-11 h-11 rounded-2xl bg-gradient-to-br ${f.iconBg} flex items-center justify-center shadow-md mb-4`}>
                    <f.icon className="w-5 h-5 text-white" />
                  </div>
                  <span className="text-[10px] text-[#c4a882] bg-[#f5f0e8] px-2.5 py-0.5 rounded-full border border-[#e8d5b7]/60">
                    {f.tag}
                  </span>
                </div>
                <h3 className="text-[#1a1410] mb-2">{f.title}</h3>
                <p className="text-sm text-[#6b7280] leading-relaxed">{f.desc}</p>
                <div className="absolute bottom-5 right-5 opacity-0 group-hover:opacity-100 transition-opacity">
                  <ArrowRight className="w-4 h-4 text-[#c4a882]" />
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════
          HOW IT WORKS
      ══════════════════════════════════════════ */}
      <section className="py-24 px-6 bg-[#faf7f2]">
        <div className="max-w-5xl mx-auto">
          <div className="text-center mb-16">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 bg-white rounded-full border border-[#e8d5b7]/60 mb-4 shadow-sm">
              <Clock className="w-3.5 h-3.5 text-[#c4a882]" />
              <span className="text-xs text-[#8c6e52]">Chỉ 3 bước đơn giản</span>
            </div>
            <h2 className="text-4xl lg:text-5xl text-[#1a1410] mb-4">
              Quy Trình <span className="text-[#c4a882]">Hoạt Động</span>
            </h2>
            <p className="text-[#6b7280]">Từ lần đầu đăng ký đến lộ trình cá nhân hóa — chỉ trong vài phút</p>
          </div>

          <div className="relative">
            {/* Connecting line (desktop) */}
            <div className="hidden md:block absolute top-10 left-[16%] right-[16%] h-[2px] bg-gradient-to-r from-[#e8d5b7] via-[#c4a882]/40 to-[#e8d5b7]" />

            <div className="grid md:grid-cols-3 gap-10">
              {[
                {
                  step: "01",
                  icon: "📋",
                  title: "Khảo Sát Nhanh",
                  desc: "Trả lời 12 câu hỏi về lối sống, môi trường sống và mục tiêu làn da của bạn.",
                  time: "~3 phút",
                  link: "/quiz",
                },
                {
                  step: "02",
                  icon: "📸",
                  title: "Tải Ảnh & AI Phân Tích",
                  desc: "Upload một ảnh tự chụp. AI sẽ quét và phân tích 47 chỉ số da chỉ trong 30 giây.",
                  time: "~30 giây",
                  link: "/upload",
                },
                {
                  step: "03",
                  icon: "✨",
                  title: "Nhận Lộ Trình Riêng",
                  desc: "Lộ trình sáng-tối cá nhân hóa cùng gợi ý sản phẩm phù hợp được cập nhật liên tục.",
                  time: "Trọn đời",
                  link: "/routine",
                },
              ].map((s, i) => (
                <div key={i} className="flex flex-col items-center text-center group">
                  {/* Step circle */}
                  <div className="relative w-20 h-20 mb-6">
                    <div className="absolute inset-0 rounded-full bg-gradient-to-br from-[#c4a882]/20 to-[#8c6e52]/10 group-hover:scale-110 transition-transform duration-300" />
                    <div className="absolute inset-2 rounded-full bg-white shadow-md flex items-center justify-center text-2xl">
                      {s.icon}
                    </div>
                    <div className="absolute -top-1 -right-1 w-6 h-6 rounded-full bg-gradient-to-br from-[#c4a882] to-[#8c6e52] flex items-center justify-center shadow-sm">
                      <span className="text-[9px] text-white" style={{ fontWeight: 700 }}>{s.step}</span>
                    </div>
                  </div>
                  <h3 className="text-[#1a1410] mb-2">{s.title}</h3>
                  <p className="text-sm text-[#6b7280] leading-relaxed mb-4">{s.desc}</p>
                  <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#f5f0e8] border border-[#e8d5b7]/60">
                    <Clock className="w-3 h-3 text-[#c4a882]" />
                    <span className="text-xs text-[#8c6e52]">{s.time}</span>
                  </div>
                </div>
              ))}
            </div>

            <div className="text-center mt-14">
              <Link
                to="/quiz"
                className="inline-flex items-center gap-2.5 px-8 py-4 bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white rounded-full shadow-lg shadow-[#c4a882]/25 hover:scale-[1.03] hover:shadow-xl hover:shadow-[#c4a882]/35 transition-all duration-300"
              >
                <Sparkles className="w-4 h-4" />
                Bắt Đầu Ngay — Miễn Phí
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════
          SKIN TYPES
      ══════════════════════════════════════════ */}
      <section className="py-24 px-6 bg-white">
        <div className="max-w-5xl mx-auto text-center">
          <h2 className="text-4xl text-[#1a1410] mb-3">AI Hỗ Trợ Mọi Loại Da</h2>
          <p className="text-[#6b7280] mb-12">Dù bạn có loại da nào, AI đều tìm ra giải pháp tối ưu.</p>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-5">
            {skinTypes.map((type, i) => (
              <div
                key={i}
                className={`group p-6 rounded-3xl bg-gradient-to-b ${type.color} border ${type.border} hover:scale-[1.04] hover:shadow-md transition-all duration-300 cursor-default`}
              >
                <div className="text-4xl mb-4 group-hover:scale-110 transition-transform duration-300">{type.icon}</div>
                <h3 className="text-[#1a1410] mb-1.5">{type.label}</h3>
                <p className="text-xs text-[#6b7280]">{type.sub}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════
          TESTIMONIALS
      ══════════════════════════════════════════ */}
      <section className="py-24 px-6 bg-[#faf7f2]">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-16">
            <div className="inline-flex items-center gap-2 px-3.5 py-1.5 bg-white rounded-full border border-[#e8d5b7]/60 mb-4 shadow-sm">
              <Star className="w-3.5 h-3.5 fill-[#f59e0b] text-[#f59e0b]" />
              <span className="text-xs text-[#8c6e52]">Câu chuyện thực tế</span>
            </div>
            <h2 className="text-4xl lg:text-5xl text-[#1a1410] mb-3">
              Khách Hàng Nói Gì <span className="text-[#c4a882]">Về Chúng Tôi</span>
            </h2>
            <p className="text-[#6b7280]">Hơn 50,000 người dùng đã tin tưởng và thay đổi làn da của mình</p>
          </div>

          <div className="grid md:grid-cols-3 gap-6">
            {testimonials.map((t, i) => (
              <div
                key={i}
                className="group bg-white rounded-3xl p-6 border border-[#e8d5b7]/40 hover:border-[#c4a882]/30 hover:shadow-xl hover:shadow-[#c4a882]/8 transition-all duration-300"
              >
                {/* Stars */}
                <div className="flex items-center gap-0.5 mb-4">
                  {Array(t.rating).fill(0).map((_, j) => (
                    <Star key={j} className="w-4 h-4 fill-[#f59e0b] text-[#f59e0b]" />
                  ))}
                </div>
                <p className="text-sm text-[#4b5563] leading-relaxed mb-5 italic">"{t.text}"</p>
                <div className="flex items-center gap-3 pt-4 border-t border-[#f5f0e8]">
                  <img src={t.avatar} alt={t.name} className="w-10 h-10 rounded-full object-cover border-2 border-[#e8d5b7]/60" />
                  <div className="flex-1">
                    <p className="text-sm text-[#2a2a2a]" style={{ fontWeight: 600 }}>{t.name}</p>
                    <p className="text-xs text-[#9ca3af]">{t.role}</p>
                  </div>
                  <span className="text-xs px-2.5 py-1 rounded-full bg-[#f5f0e8] text-[#8c6e52] border border-[#e8d5b7]/60">
                    {t.skin}
                  </span>
                </div>
              </div>
            ))}
          </div>

          {/* Trust badges */}
          <div className="mt-12 flex flex-wrap justify-center gap-6 items-center">
            {[
              { icon: Shield, text: "Kiểm duyệt bởi bác sĩ da liễu" },
              { icon: Award, text: "Giải thưởng Healthtech 2025" },
              { icon: CheckCircle2, text: "Chứng nhận ISO 27001" },
              { icon: Users, text: "Cộng đồng 50K+ thành viên" },
            ].map((b, i) => (
              <div key={i} className="flex items-center gap-2 px-4 py-2 bg-white rounded-full border border-[#e8d5b7]/60 shadow-sm">
                <b.icon className="w-3.5 h-3.5 text-[#c4a882]" />
                <span className="text-xs text-[#4b5563]">{b.text}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════
          FINAL CTA
      ══════════════════════════════════════════ */}
      <section className="relative py-28 px-6 overflow-hidden">
        {/* Background */}
        <div className="absolute inset-0 bg-gradient-to-br from-[#2a1a0a] via-[#3d2a14] to-[#1a1410]" />
        <div className="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHZpZXdCb3g9IjAgMCA2MCA2MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZyBmaWxsPSJub25lIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiPjxnIGZpbGw9IiNjNGE4ODIiIGZpbGwtb3BhY2l0eT0iMC4wNCI+PHBhdGggZD0iTTM2IDM0djZoNnYtNmgtNnptMC0zMHY2aDZ2LTZoLTZ6Ii8+PC9nPjwvZz48L3N2Zz4=')] opacity-40" />
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-[#c4a882]/10 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-1/4 w-72 h-72 bg-[#8c6e52]/15 rounded-full blur-3xl" />

        <div className="relative max-w-4xl mx-auto text-center">
          <div className="inline-flex items-center gap-2 px-4 py-2 bg-white/10 backdrop-blur-sm rounded-full border border-white/20 mb-6">
            <Sparkles className="w-3.5 h-3.5 text-[#c4a882]" />
            <span className="text-xs text-[#e8d5b7]">Bắt đầu hành trình ngay hôm nay</span>
          </div>
          <h2 className="text-5xl lg:text-6xl text-white mb-5 leading-tight">
            Sẵn Sàng Cho<br />
            <span className="text-[#c4a882]">Làn Da Hoàn Hảo?</span>
          </h2>
          <p className="text-[#d4b896] text-lg mb-10 max-w-xl mx-auto leading-relaxed">
            Tham gia cùng 50,000+ người đã biến đổi làn da nhờ AI. Phân tích miễn phí — không cần thẻ tín dụng.
          </p>
          <div className="flex flex-wrap justify-center gap-4">
            <Link
              to="/quiz"
              className="group flex items-center gap-2.5 px-8 py-4 bg-gradient-to-r from-[#c4a882] to-[#b8956e] text-white rounded-full shadow-xl shadow-[#c4a882]/30 hover:shadow-2xl hover:shadow-[#c4a882]/40 hover:scale-[1.04] transition-all duration-300"
            >
              <Sparkles className="w-4 h-4" />
              Phân Tích Da Miễn Phí
              <ArrowRight className="w-4 h-4 group-hover:translate-x-1 transition-transform" />
            </Link>
            <Link
              to="/login"
              className="flex items-center gap-2 px-7 py-4 bg-white/10 backdrop-blur-sm text-white rounded-full border border-white/20 hover:bg-white/20 transition-all duration-300"
            >
              Đăng Nhập
            </Link>
          </div>
          {/* micro reassurances */}
          <div className="flex flex-wrap justify-center gap-6 mt-10">
            {["✓ Miễn phí mãi mãi", "✓ Không cần thẻ ngân hàng", "✓ Bảo mật dữ liệu 100%"].map((t) => (
              <span key={t} className="text-sm text-[#a08060]">{t}</span>
            ))}
          </div>
        </div>
      </section>

      {/* ══════════════════════════════════════════
          FOOTER MINI
      ══════════════════════════════════════════ */}
      <footer className="py-8 px-6 bg-[#1a1410] border-t border-white/5">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <BrandMark className="w-8 h-8 rounded-lg ring-1 ring-white/10" />
            <span className="text-[#e8d5b7] text-sm" style={{ fontWeight: 600 }}>SkinSync</span>
          </div>
          <p className="text-xs text-[#6b5540]">© 2026 SkinSync. Mọi quyền được bảo lưu.</p>
          <div className="flex items-center gap-5">
            {["Chính sách", "Điều khoản", "Liên hệ"].map((item) => (
              <a key={item} href="#" className="text-xs text-[#6b5540] hover:text-[#c4a882] transition-colors">
                {item}
              </a>
            ))}
          </div>
        </div>
      </footer>
    </div>
  );
}
