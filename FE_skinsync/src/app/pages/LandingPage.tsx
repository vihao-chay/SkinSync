import { Link } from "react-router";
import { motion } from "motion/react";
import {
  ArrowRight,
  Camera,
  Check,
  FlaskConical,
  MessageCircle,
  Microscope,
  ListChecks,
  ScanLine,
  Sparkles,
  Star,
  TrendingUp,
  WalletCards,
} from "lucide-react";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";
import { Footer } from "../components/SiteFooter";

// [CẬP NHẬT]: Cấu hình menu "Về ứng dụng" để render dropdown con trong navbar.
const aboutAppLinks = [
  { label: "Tính năng AI", href: "#features" },
  { label: "Lộ trình cá nhân", href: "#journey" },
  { label: "Đội ngũ chuyên gia", href: "#experts" },
];

// [CẬP NHẬT]: Khai báo link điều hướng sang các trang độc lập để dùng trong Navbar và Footer.
const resourceLinks = [
  { label: "Bảng giá", href: "/subscription" },
  { label: "Blog", href: "/blog" },
  { label: "Trung tâm hỗ trợ", href: "/tro-giup" },
  { label: "Chính sách bảo mật", href: "/chinh-sach-bao-mat" },
  { label: "Điều khoản sử dụng", href: "/dieu-khoan-su-dung" },
];

const featureChips = [
  { label: "PHÂN TÍCH LỘ TRÌNH", icon: Sparkles },
  { label: "KÍNH QUÉT THÀNH PHẦN", icon: ScanLine },
  { label: "CHAT CHUYÊN GIA", icon: MessageCircle },
  { label: "THEO DÕI DA", icon: Camera },
];

const featureCards = [
  {
    title: "LỘ TRÌNH HỢP TÚI TIỀN",
    description: "SkinSync tự động tạo chu trình chăm sóc da hiệu quả, hợp túi tiền.",
    icon: WalletCards,
    image: "https://images.unsplash.com/photo-1620916566398-39f1143ab7be?auto=format&fit=crop&w=700&q=90",
    className: "md:col-span-2 md:row-span-2",
  },
  {
    title: "QUÉT DA AI",
    description: "Nhận diện tình trạng da, điểm phục hồi và dấu hiệu cần chú ý chỉ trong vài giây.",
    icon: Microscope,
    image: "https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?auto=format&fit=crop&w=700&q=90",
  },
  {
    title: "KIỂM TRA THÀNH PHẦN",
    description: "Đọc bảng thành phần mỹ phẩm và cảnh báo xung đột trong routine hiện tại.",
    icon: FlaskConical,
    image: "https://images.unsplash.com/photo-1612817288484-6f916006741a?auto=format&fit=crop&w=700&q=90",
  },
  {
    title: "CHAT CHUYÊN GIA",
    description: "Hỏi đáp nhanh với trợ lý AI chăm sóc da, có ngữ cảnh hồ sơ da của bạn.",
    icon: MessageCircle,
    image: "https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=700&q=90",
  },
];

// [CẬP NHẬT]: Đổi icon timeline sang 4 biểu tượng khác nhau để tránh lặp lại và rõ ý nghĩa từng bước.
const journeySteps = [
  { title: "CHỤP ẢNH / QUÉT MỸ PHẨM", icon: Camera },
  { title: "AI PHÂN TÍCH", icon: Sparkles },
  { title: "NHẬN LỘ TRÌNH", icon: ListChecks },
  { title: "THEO DÕI CẢI THIỆN", icon: TrendingUp },
];

const testimonials = [
  {
    name: "Minh Anh",
    image: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=360&q=90",
    review: "Routine tuyệt vời, da cải thiện rõ rệt!",
  },
  {
    name: "Khánh Linh",
    image: "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=360&q=90",
    review: "App hiểu da mình hơn cả lúc tự mua mỹ phẩm.",
  },
  {
    name: "Phương Thảo",
    image: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=360&q=90",
    review: "Quét thành phần rất tiện, mình tránh được nhiều sản phẩm không hợp.",
  },
];

function QrCode() {
  const cells = Array.from({ length: 121 }, (_, index) => {
    const row = Math.floor(index / 11);
    const col = index % 11;
    const finder =
      (row < 3 && col < 3) ||
      (row < 3 && col > 7) ||
      (row > 7 && col < 3);
    const active = finder || (row * 7 + col * 5 + row * col) % 4 === 0;
    return <span key={index} className={active ? "bg-skin-gold" : "bg-transparent"} />;
  });

  return (
    <div className="w-32 h-32 rounded-[1.4rem] bg-skin-surface p-3 shadow-soft-gold ring-1 ring-skin-border">
      <div className="grid h-full w-full grid-cols-11 gap-1">{cells}</div>
    </div>
  );
}

// [CẬP NHẬT]: Thay CTA download khối vuông bằng badge chuẩn App Store để hero trông cao cấp hơn.
function AppStoreBadge() {
  return (
    <a
      href="#download"
      className="flex min-w-[200px] items-center gap-3 rounded-2xl bg-skin-textMain px-4 py-3.5 text-white shadow-soft-gold transition hover:-translate-y-0.5 hover:bg-[#413a33]"
    >
      <svg viewBox="0 0 24 24" className="h-8 w-8 shrink-0 fill-current" aria-hidden="true">
        <path d="M16.365 1.43c0 1.14-.45 2.2-1.17 3.02-.84.97-2.2 1.72-3.54 1.62-.17-1.12.4-2.28 1.1-3.03.83-.91 2.26-1.57 3.61-1.61zM20.54 17.5c-.54 1.2-.81 1.74-1.51 2.83-.97 1.48-2.34 3.32-4.03 3.34-1.5.02-1.88-.99-3.9-.98-2.02.01-2.44 1-3.94.98-1.68-.02-2.97-1.66-3.94-3.14C1.82 17.97.82 14.46 2.35 11.94c1.06-1.74 2.98-2.84 5.07-2.87 1.58-.03 3.07 1.08 3.9 1.08.82 0 2.58-1.34 4.36-1.14.74.03 2.81.3 4.14 2.26-.11.07-2.47 1.45-2.45 4.23.03 3.32 2.91 4.42 2.17 5.99z" />
      </svg>
      <span className="leading-tight">
        <span className="block text-[10px] font-semibold uppercase tracking-[0.18em] text-white/60">Download on the</span>
        <span className="block text-sm font-semibold">App Store</span>
      </span>
    </a>
  );
}

// [CẬP NHẬT]: Thay CTA download khối vuông bằng badge chuẩn Google Play để đồng bộ style mobile app.
function GooglePlayBadge() {
  return (
    <a
      href="#download"
      className="flex min-w-[200px] items-center gap-3 rounded-2xl bg-skin-surface px-4 py-3.5 text-skin-textMain shadow-soft-gold ring-1 ring-skin-border transition hover:-translate-y-0.5 hover:bg-[#faf8f3]"
    >
      <svg viewBox="0 0 24 24" className="h-8 w-8 shrink-0" aria-hidden="true">
        <defs>
          <linearGradient id="gpGreen" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#34d399" />
            <stop offset="100%" stopColor="#0ea5e9" />
          </linearGradient>
          <linearGradient id="gpOrange" x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor="#f59e0b" />
            <stop offset="100%" stopColor="#ef4444" />
          </linearGradient>
        </defs>
        <path d="M3.8 2.8c-.6.4-1 1.1-1 1.9v14.6c0 .8.4 1.5 1 1.9l8.6-8.7L3.8 2.8z" fill="url(#gpGreen)" />
        <path d="M13.6 11.5 17 8.1l3.2 1.8c.8.4 1.3 1.2 1.3 2.1s-.5 1.7-1.3 2.1L17 15.9l-3.4-4.4z" fill="url(#gpOrange)" />
        <path d="m12.4 12.4 1.1-1 3.2 4.5-4.3 2.5c-.4.2-.8.3-1.2.3V12.4z" fill="#8b5cf6" />
        <path d="M12.4 11.6V2.8c.4 0 .8.1 1.2.3L17 5.6l-4.6 6z" fill="#22c55e" />
      </svg>
      <span className="leading-tight">
        <span className="block text-[10px] font-semibold uppercase tracking-[0.18em] text-skin-textMuted">GET IT ON</span>
        <span className="block text-sm font-semibold">Google Play</span>
      </span>
    </a>
  );
}

// [CẬP NHẬT]: Tăng chiều sâu 3D cho mockup điện thoại bằng rotate nhẹ, shadow sâu và hover trả về trạng thái thẳng.
function PhoneMockup() {
  return (
    <motion.div
      initial={{ opacity: 0, y: 28, rotate: -2 }}
      animate={{ opacity: 1, y: 0, rotate: -2 }}
      whileHover={{ rotate: 0, y: -6 }}
      transition={{ duration: 0.8, ease: "easeOut" }}
      className="relative mx-auto h-[630px] w-[316px] rounded-[3.2rem] bg-[#191b26] p-3 drop-shadow-2xl shadow-[0_44px_110px_rgba(93,108,214,0.34)] ring-1 ring-white/40 transition-transform duration-500 lg:ml-auto"
    >
      <div className="absolute left-1/2 top-4 z-20 h-6 w-28 -translate-x-1/2 rounded-full bg-[#11131b]" />
      <div className="relative h-full overflow-hidden rounded-[2.55rem] bg-[#f7f8ff]">
        <img
          src="https://images.unsplash.com/photo-1590110348915-993aca51ea03?auto=format&fit=crop&w=720&q=90"
          alt="Ứng dụng SkinSync đang phân tích da"
          className="absolute inset-0 h-full w-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-b from-[#eef1ff]/40 via-white/5 to-[#111827]/70" />
        <div className="absolute inset-x-5 top-14 rounded-3xl border border-white/50 bg-white/60 p-4 shadow-xl shadow-[#6875e8]/15 backdrop-blur-2xl">
          <div className="mb-3 flex items-center justify-between">
            <span className="text-[11px] font-semibold tracking-[0.22em] text-skin-gold">MAGIC MOMENT</span>
            <span className="rounded-full bg-[#d7fbeb] px-2.5 py-1 text-[10px] font-semibold text-[#189966]">LIVE</span>
          </div>
          <div className="space-y-2">
            {["Niacinamide", "Vitamin C", "BHA 2%"].map((item, index) => (
              <div key={item} className="flex items-center justify-between rounded-2xl bg-skin-surface/80 px-3 py-2">
                <span className="text-xs font-medium text-skin-textMain">{item}</span>
                <span className="text-xs font-semibold text-skin-gold">{index === 1 ? "92%" : "Phù hợp"}</span>
              </div>
            ))}
          </div>
        </div>
        <motion.div
          animate={{ y: [0, 245, 0] }}
          transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
          className="absolute left-8 right-8 top-48 h-[2px] bg-gradient-to-r from-transparent via-[#8ff4d1] to-transparent shadow-[0_0_28px_rgba(143,244,209,0.9)]"
        />
        <div className="absolute inset-x-5 bottom-7 rounded-[2rem] border border-white/40 bg-white/75 p-4 shadow-2xl shadow-[#111827]/20 backdrop-blur-2xl">
          <div className="mb-4 flex items-center justify-between">
            <div>
              <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-skin-textMuted">Điểm tương thích</p>
              <p className="font-serif text-4xl font-semibold text-skin-textMain">94</p>
            </div>
            <div className="flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-[#b7b9ff] to-[#7e8bff] text-white shadow-lg shadow-[#7e8bff]/30">
              <Sparkles className="h-7 w-7" />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-2">
            {["Ít kích ứng", "Sáng da", "Cấp ẩm", "Dùng tối"].map((item) => (
              <div key={item} className="rounded-2xl bg-[#f4f6ff] px-3 py-2 text-xs font-semibold text-[#4d5578]">
                {item}
              </div>
            ))}
          </div>
        </div>
      </div>
      <div className="absolute -bottom-8 left-10 right-10 h-9 rounded-full bg-[#5e6dde]/30 blur-2xl" />
    </motion.div>
  );
}

// [CẬP NHẬT]: Tách navbar thành component riêng và thêm dropdown hover cho mục "Về ứng dụng".
function Navbar() {
  return (
    <header className="fixed left-0 right-0 top-0 z-50 px-4 py-4">
      <nav className="mx-auto flex max-w-7xl items-center justify-between rounded-full border border-skin-border bg-skin-surface/80 px-4 py-3 shadow-soft-gold backdrop-blur-2xl">
        <Link to="/" className="flex items-center gap-3">
          <span className="flex h-11 w-11 items-center justify-center rounded-full bg-[#C2A67D] text-sm font-black text-white shadow-soft-gold">
            SS
          </span>
          <span className="font-serif text-lg font-semibold tracking-[0.18em] text-skin-textMain">SKINSYNC</span>
        </Link>

        <div className="hidden items-center gap-8 text-sm font-medium text-skin-textMuted md:flex">
          <a href="#features" className="transition hover:text-skin-gold">Tính Năng</a>
          <Link to="/subscription" className="transition hover:text-skin-gold">Bảng Giá</Link>

          <div className="group relative py-2">
            <button type="button" className="flex items-center gap-1 transition hover:text-skin-gold">
              Về ứng dụng
              <ArrowRight className="h-3.5 w-3.5 rotate-90" />
            </button>

            <div className="invisible absolute left-1/2 top-full w-72 -translate-x-1/2 translate-y-2 opacity-0 transition-all duration-200 group-hover:visible group-hover:translate-y-0 group-hover:opacity-100">
              <div className="overflow-hidden rounded-[1.5rem] border border-skin-border bg-skin-surface/95 p-2 shadow-soft-gold backdrop-blur-2xl">
                {aboutAppLinks.map((item) => (
                  <a
                    key={item.label}
                    href={item.href}
                    className="flex items-center justify-between rounded-2xl px-4 py-3 text-sm text-skin-textMain transition hover:bg-stone-100 hover:text-skin-gold"
                  >
                    <span>{item.label}</span>
                    <ArrowRight className="h-4 w-4" />
                  </a>
                ))}
              </div>
            </div>
          </div>

          <div className="group relative py-2">
            <button type="button" className="flex items-center gap-1 transition hover:text-skin-gold">
              Tài nguyên
              <ArrowRight className="h-3.5 w-3.5 rotate-90" />
            </button>

            <div className="invisible absolute left-1/2 top-full w-72 -translate-x-1/2 translate-y-2 opacity-0 transition-all duration-200 group-hover:visible group-hover:translate-y-0 group-hover:opacity-100">
              <div className="overflow-hidden rounded-[1.5rem] border border-skin-border bg-skin-surface/95 p-2 shadow-soft-gold backdrop-blur-2xl">
                {resourceLinks.map((item) => (
                  <Link
                    key={item.label}
                    to={item.href}
                    className="flex items-center justify-between rounded-2xl px-4 py-3 text-sm text-skin-textMain transition hover:bg-stone-100 hover:text-skin-gold"
                  >
                    <span>{item.label}</span>
                    <ArrowRight className="h-4 w-4" />
                  </Link>
                ))}
              </div>
            </div>
          </div>

          <a href="#journey" className="transition hover:text-skin-gold">Lộ Trình</a>
          <a href="#experts" className="transition hover:text-skin-gold">Chuyên Gia</a>
        </div>

        <div className="flex items-center gap-3">
          <Button
            asChild
            variant="outline"
            className="hidden h-12 rounded-full border-skin-border bg-skin-surface/90 px-5 text-xs font-semibold tracking-[0.14em] text-skin-textMain shadow-soft-gold hover:bg-[#faf8f3] md:inline-flex"
          >
            <Link to="/login">ĐĂNG NHẬP</Link>
          </Button>
          <Button asChild className="h-12 rounded-full bg-skin-gold px-6 text-xs font-semibold tracking-[0.16em] text-white shadow-soft-gold hover:bg-skin-goldHover">
            <a href="#download">TẢI APP NGAY</a>
          </Button>
        </div>
      </nav>
    </header>
  );
}

// [CẬP NHẬT]: Tách hero thành component riêng, thay CTA cũ bằng badge App Store/Google Play và giữ QR download area.
function Hero() {
  return (
    <section className="relative min-h-screen bg-skin-base">
      <div className="mx-auto grid max-w-7xl gap-12 px-5 pb-20 pt-32 lg:grid-cols-[1.04fr_0.96fr] lg:px-8 lg:pb-24 lg:pt-36">
        <motion.div
          initial={{ opacity: 0, y: 24 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.7, ease: "easeOut" }}
          className="flex flex-col justify-center"
        >
          <div className="mb-7 inline-flex w-fit items-center gap-2 rounded-full border border-skin-border bg-skin-surface/80 px-4 py-2 text-xs font-medium uppercase tracking-[0.18em] text-skin-gold shadow-soft-gold backdrop-blur-xl">
            <Sparkles className="h-4 w-4" />
            AI dermatology-tech cho thế hệ mới
          </div>
          <h1 className="max-w-3xl font-serif text-5xl font-semibold leading-[1.04] tracking-normal text-skin-textMain md:text-6xl xl:text-[72px]">
            AI CHĂM SÓC DA CÁ NHÂN: ĐỒNG BỘ CÙNG LÀN DA BẠN
          </h1>
          <p className="mt-7 max-w-xl text-xl font-normal leading-8 text-skin-textMuted">
            Tối ưu ngân sách, Hiểu làn da, Đẹp mỗi ngày
          </p>

          <div className="mt-7 flex flex-wrap items-center gap-3">
            <Button
              asChild
              variant="outline"
              className="h-12 rounded-full border-skin-border bg-skin-surface/85 px-6 text-sm font-semibold tracking-[0.12em] text-skin-textMain shadow-soft-gold hover:bg-[#faf8f3]"
            >
              <Link to="/login">Đăng nhập để tiếp tục</Link>
            </Button>
            <Link to="/register" className="text-sm font-medium text-skin-textMuted transition hover:text-skin-gold">
              Chưa có tài khoản? Tạo tài khoản
            </Link>
          </div>

          <div id="download" className="mt-10 grid max-w-2xl gap-5 rounded-[2rem] border border-skin-border bg-skin-surface/80 p-5 shadow-soft-gold backdrop-blur-2xl sm:grid-cols-[auto_1fr] scroll-mt-28">
            <div className="flex flex-col items-center gap-3">
              <QrCode />
              <span className="text-sm font-medium text-skin-textMuted">Quét mã để tải</span>
            </div>
            <div className="flex flex-col justify-center gap-3">
              <div className="flex flex-wrap gap-3">
                <AppStoreBadge />
                <GooglePlayBadge />
              </div>
              <p className="max-w-md text-sm leading-6 text-skin-textMuted">
                Trải nghiệm ứng dụng AI skincare cá nhân hóa với giao diện mobile mượt, phân tích tức thì và lộ trình được đồng bộ mỗi ngày.
              </p>
            </div>
          </div>
        </motion.div>

        <div className="relative min-h-[680px]">
          <img
            src="https://images.unsplash.com/photo-1617897903246-719242758050?auto=format&fit=crop&w=460&q=90"
            alt="Sản phẩm chăm sóc da cao cấp"
            className="absolute right-0 top-10 hidden h-36 w-36 rotate-6 rounded-[2rem] object-cover shadow-soft-gold ring-1 ring-skin-border lg:block"
          />
          <img
            src="https://images.unsplash.com/photo-1556228578-8c89e6adf883?auto=format&fit=crop&w=460&q=90"
            alt="Kết cấu mỹ phẩm trong studio"
            className="absolute bottom-14 left-0 hidden h-40 w-40 -rotate-6 rounded-[2rem] object-cover shadow-soft-gold ring-1 ring-skin-border lg:block"
          />
          <PhoneMockup />
        </div>
      </div>

      <div className="mx-auto grid max-w-5xl grid-cols-2 gap-3 px-5 pb-16 md:grid-cols-4">
        {featureChips.map((feature) => (
          <div key={feature.label} className="flex items-center gap-3 rounded-2xl border border-skin-border bg-skin-surface/75 p-4 shadow-soft-gold backdrop-blur-xl">
            <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-stone-100 text-skin-gold">
              <feature.icon className="h-5 w-5" />
            </span>
            <span className="text-xs font-medium leading-5 tracking-[0.12em] text-skin-textMain">{feature.label}</span>
          </div>
        ))}
      </div>
    </section>
  );
}

// [CẬP NHẬT]: Tách timeline thành component riêng, đổi icon từng bước và đưa CTA xuống chính giữa bên dưới lưới.
function Timeline() {
  return (
    <section id="journey" className="bg-skin-base px-5 py-24 scroll-mt-28">
      <div className="mx-auto max-w-7xl">
        <div className="mb-14 flex flex-col gap-5 md:flex-row md:items-end md:justify-between">
          <div>
            <p className="mb-3 text-sm font-medium uppercase tracking-[0.22em] text-skin-gold">Lộ trình người dùng</p>
            <h2 className="max-w-3xl font-serif text-4xl font-semibold tracking-normal text-skin-textMain md:text-5xl">Từ ảnh chụp đến routine cá nhân chỉ trong một hành trình mượt mà.</h2>
          </div>
        </div>

        <div className="relative grid gap-5 md:grid-cols-4">
          <div className="absolute left-[12%] right-[12%] top-16 hidden h-px bg-gradient-to-r from-skin-border via-skin-gold to-skin-border md:block" />
          {journeySteps.map((step, index) => (
            <motion.div
              key={step.title}
              whileHover={{ y: -6 }}
              className="relative rounded-[2rem] border border-skin-border bg-skin-surface/80 p-5 shadow-soft-gold backdrop-blur-xl"
            >
              <div className="mb-5 flex h-24 items-center justify-center rounded-[1.5rem] bg-stone-50">
                <div className="flex h-16 w-16 items-center justify-center rounded-[1.5rem] bg-skin-surface shadow-soft-gold">
                  <step.icon className="h-7 w-7 text-skin-gold" />
                </div>
              </div>
              <div className="mb-4 flex items-center gap-3">
                <span className="font-serif text-xs font-semibold text-skin-textMuted">0{index + 1}</span>
              </div>
              <h3 className="text-base font-semibold leading-6 tracking-[0.04em] text-skin-textMain">{step.title}</h3>
            </motion.div>
          ))}
        </div>

        <div className="mt-10 flex justify-center">
          <Button asChild className="h-12 w-fit rounded-full bg-skin-gold px-6 font-semibold text-white shadow-soft-gold hover:bg-skin-goldHover">
            <Link to="/quiz">Bắt đầu phân tích <ArrowRight className="h-4 w-4" /></Link>
          </Button>
        </div>
      </div>
    </section>
  );
}

export function LandingPage() {
  return (
    <main className="min-h-screen overflow-hidden bg-skin-base text-skin-textMain">
      {/* [CẬP NHẬT]: Thay toàn bộ hero/nav cũ bằng các component tái cấu trúc Navbar + Hero. */}
      <Navbar />
      <Hero />

      <section id="features" className="bg-white px-5 py-24 scroll-mt-28">
        <div className="mx-auto max-w-7xl">
          <div className="mb-12 max-w-2xl">
            <p className="mb-3 text-sm font-medium uppercase tracking-[0.22em] text-skin-gold">Tính năng nổi bật</p>
            <h2 className="font-serif text-4xl font-semibold tracking-normal text-skin-textMain md:text-5xl">Một hệ sinh thái chăm sóc da thông minh, đẹp và có căn cứ khoa học.</h2>
          </div>
          <div className="grid auto-rows-[260px] gap-5 md:grid-cols-4">
            {featureCards.map((feature, index) => (
              <motion.div
                key={feature.title}
                initial={{ opacity: 0, y: 22 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, amount: 0.25 }}
                transition={{ duration: 0.55, delay: index * 0.06 }}
                className={feature.className}
              >
                <Card className="group h-full overflow-hidden rounded-[2rem] border-skin-border bg-skin-surface shadow-soft-gold transition hover:-translate-y-1 hover:shadow-soft-gold">
                  <CardContent className="relative h-full p-0">
                    <img src={feature.image} alt={feature.title} className="absolute inset-0 h-full w-full object-cover transition duration-700 group-hover:scale-105" />
                    <div className="absolute inset-0 bg-gradient-to-br from-white/92 via-white/75 to-[#f6efe4]/25" />
                    <div className="relative flex h-full flex-col justify-between p-7">
                      <div className="flex h-16 w-16 items-center justify-center rounded-[1.4rem] bg-stone-100 text-skin-gold shadow-soft-gold">
                        <feature.icon className="h-7 w-7" />
                      </div>
                      <div>
                        <h3 className="max-w-md font-serif text-2xl font-semibold tracking-normal text-skin-textMain">{feature.title}</h3>
                        <p className="mt-3 max-w-md text-sm font-normal leading-6 text-skin-textMuted">{feature.description}</p>
                      </div>
                    </div>
                  </CardContent>
                </Card>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* [CẬP NHẬT]: Thay timeline cũ bằng component Timeline để dùng icon mới và CTA nằm giữa bên dưới lưới. */}
      <Timeline />

      <section id="experts" className="bg-white px-5 py-24 scroll-mt-28">
        <div className="mx-auto max-w-7xl">
          <div className="mb-12 text-center">
            <p className="mb-3 text-sm font-medium uppercase tracking-[0.22em] text-skin-gold">Người dùng tin tưởng</p>
            <h2 className="font-serif text-4xl font-semibold tracking-normal text-skin-textMain md:text-5xl">Kết quả rõ ràng, trải nghiệm rất riêng.</h2>
          </div>
          <div className="flex gap-5 overflow-x-auto pb-4 [scrollbar-width:none]">
            {testimonials.map((item) => (
              <Card key={item.name} className="min-w-[320px] flex-1 rounded-[2rem] border-skin-border bg-skin-surface shadow-soft-gold">
                <CardContent className="p-6">
                  <div className="mb-5 flex items-center gap-4">
                    <img src={item.image} alt={item.name} className="h-16 w-16 rounded-2xl object-cover" />
                    <div>
                      <p className="font-serif text-lg font-semibold text-skin-textMain">{item.name}</p>
                      <div className="mt-1 flex items-center gap-1">
                        {Array.from({ length: 5 }).map((_, index) => (
                          <Star key={index} className="h-4 w-4 fill-[#ffbd5c] text-[#ffbd5c]" />
                        ))}
                        <span className="ml-2 text-sm font-medium text-skin-textMuted">4.9/5</span>
                      </div>
                    </div>
                  </div>
                  <p className="text-lg font-normal leading-8 text-skin-textMain">"{item.review}"</p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      <section className="px-5 py-20">
        <div className="relative mx-auto max-w-7xl overflow-hidden rounded-[2.5rem] bg-[linear-gradient(135deg,#f2eadf_0%,#d9c1a2_100%)] px-6 py-16 text-center shadow-soft-gold md:px-12 md:py-24">
          <img
            src="https://images.unsplash.com/photo-1608248543803-ba4f8c70ae0b?auto=format&fit=crop&w=500&q=90"
            alt="Kết cấu kem dưỡng cao cấp"
            className="absolute -left-8 top-10 hidden h-40 w-40 -rotate-12 rounded-[2rem] object-cover opacity-85 shadow-2xl md:block"
          />
          <img
            src="https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=500&q=90"
            alt="Mỹ phẩm trong ánh sáng studio"
            className="absolute -right-6 bottom-8 hidden h-44 w-44 rotate-12 rounded-[2rem] object-cover opacity-90 shadow-2xl md:block"
          />
          <div className="relative mx-auto max-w-3xl">
            <div className="mx-auto mb-6 flex h-14 w-14 items-center justify-center rounded-2xl bg-white/30 text-white backdrop-blur-xl">
              <Check className="h-7 w-7" />
            </div>
            <h2 className="font-serif text-4xl font-semibold leading-tight tracking-normal text-white md:text-6xl">
              BẮT ĐẦU HÀNH TRÌNH CHĂM SÓC DA CÙNG SKINSYNC
            </h2>
            <p className="mx-auto mt-6 max-w-xl text-lg font-normal leading-8 text-white/82">
              Tải ứng dụng, quét làn da và nhận lộ trình cá nhân hóa ngay hôm nay.
            </p>
            <div className="mt-9 flex flex-wrap justify-center gap-3">
              <Button asChild className="h-14 rounded-full bg-white px-9 text-sm font-semibold tracking-[0.16em] text-skin-gold shadow-soft-gold hover:bg-[#f6f7ff]">
                <a href="#download">TẢI NGAY SKINSYNC</a>
              </Button>
              <Button asChild variant="outline" className="h-14 rounded-full border-white/70 bg-white/10 px-9 text-sm font-semibold tracking-[0.16em] text-white hover:bg-white/20 hover:text-white">
                <Link to="/subscription">XEM BẢNG GIÁ</Link>
              </Button>
            </div>
          </div>
        </div>
      </section>

      {/* [CẬP NHẬT]: Thay footer cũ bằng Footer 6 cột, đồng bộ link sang các trang độc lập và giữ copyright ở đáy. */}
      <Footer />
    </main>
  );
}
