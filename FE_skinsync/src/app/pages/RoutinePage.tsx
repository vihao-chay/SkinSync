import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router";
import {
  Sun,
  Moon,
  Sparkles,
  ArrowLeft,
  ShoppingBag,
  Info,
  CheckCircle2,
  Star,
  ChevronRight,
} from "lucide-react";
import { ImageWithFallback } from "../components/figma/ImageWithFallback";
import { getCurrentRegimenApi } from "../services/regimenService";

interface StepItem {
  step: number;
  name: string;
  product: string;
  brand: string;
  price: string;
  aiReason: string;
  duration: string;
  image: string;
  tag: string;
  tagColor: string;
}

interface ProductItem {
  name: string;
  price: string;
  cat: string;
  stars: number;
  img: string;
}

const morningSteps = [
  {
    step: 1,
    name: "Sữa Rửa Mặt",
    product: "Gentle Hydrating Cleanser",
    brand: "CeraVe",
    price: "320.000đ",
    aiReason: "pH cân bằng 5.5, không làm tổn thương hàng rào da nhạy cảm của bạn",
    duration: "60 giây",
    image: "https://images.unsplash.com/photo-1685052388326-b6383ec2d524?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMGNsZWFuc2VyJTIwZm9hbSUyMHByb2R1Y3QlMjBlbGVnYW50fGVufDF8fHx8MTc3NDAxMzAxN3ww&ixlib=rb-4.1.0&q=80&w=400",
    tag: "Thiết Yếu",
    tagColor: "#c4a882",
  },
  {
    step: 2,
    name: "Toner",
    product: "Balancing & Hydrating Toner",
    brand: "Some By Mi",
    price: "280.000đ",
    aiReason: "Cân bằng pH sau rửa mặt, chuẩn bị da hấp thụ dưỡng chất tốt hơn",
    duration: "30 giây",
    image: "https://images.unsplash.com/photo-1664165786318-9af861f2a9c3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMHRvbmVyJTIwZXNzZW5jZSUyMGJvdHRsZSUyMHBhc3RlbHxlbnwxfHx8fDE3NzQwMTMwMTl8MA&ixlib=rb-4.1.0&q=80&w=400",
    tag: "Dưỡng Ẩm",
    tagColor: "#0891b2",
  },
  {
    step: 3,
    name: "Serum Vitamin C",
    product: "10% Vitamin C + Ferulic",
    brand: "The Ordinary",
    price: "450.000đ",
    aiReason: "Làm sáng thâm, chống oxy hóa — Phù hợp cho làn da hỗn hợp đang bị thâm của bạn",
    duration: "Thoa nhẹ",
    image: "https://images.unsplash.com/photo-1770048792339-d8f8d8d2dbeb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMHNlcnVtJTIwYm90dGxlJTIwcHJvZHVjdCUyMG1pbmltYWxpc3QlMjB3aGl0ZXxlbnwxfHx8fDE3NzQwMTMwMTd8MA&ixlib=rb-4.1.0&q=80&w=400",
    tag: "AI Đề Xuất",
    tagColor: "#8c6e52",  // AI Đề Xuất serum tag
  },
  {
    step: 4,
    name: "Kem Chống Nắng",
    product: "UV Master SPF 50+ PA++++",
    brand: "La Roche-Posay",
    price: "485.000đ",
    aiReason: "Bảo vệ toàn diện UVA/UVB, ngăn thâm nặng thêm — Bước quan trọng nhất ban ngày",
    duration: "2 ngón tay",
    image: "https://images.unsplash.com/photo-1594332322527-08753d4473c1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzdW5zY3JlZW4lMjBtb2lzdHVyaXplciUyMHNraW5jYXJlJTIwdHViZSUyMHByb2R1Y3R8ZW58MXx8fHwxNzc0MDEzMDE4fDA&ixlib=rb-4.1.0&q=80&w=400",
    tag: "Bắt Buộc",
    tagColor: "#f59e0b",
  },
];

const eveningSteps = [
  {
    step: 1,
    name: "Tẩy Trang",
    product: "Cleansing Oil — Double Cleanse",
    brand: "DHC",
    price: "350.000đ",
    aiReason: "Loại bỏ kem chống nắng và bụi bẩn triệt để — Bước đầu tiên không thể bỏ qua",
    duration: "90 giây",
    image: "https://images.unsplash.com/photo-1709477542153-5bedab2b5657?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMGNsZWFuc2luZyUyMG9pbCUyMG1ha2V1cCUyMHJlbW92ZXIlMjBlbGVnYW50fGVufDF8fHx8MTc3NDAxMzAyMnww&ixlib=rb-4.1.0&q=80&w=400",
    tag: "Thiết Yếu",
    tagColor: "#c4a882",
  },
  {
    step: 2,
    name: "Sữa Rửa Mặt",
    product: "Gentle Foam Cleanser",
    brand: "CeraVe",
    price: "320.000đ",
    aiReason: "Làm sạch sâu lần 2, loại bỏ cặn dầu sau bước tẩy trang",
    duration: "60 giây",
    image: "https://images.unsplash.com/photo-1685052388326-b6383ec2d524?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMGNsZWFuc2VyJTIwZm9hbSUyMHByb2R1Y3QlMjBlbGVnYW50fGVufDF8fHx8MTc3NDAxMzAxN3ww&ixlib=rb-4.1.0&q=80&w=400",
    tag: "Làm Sạch",
    tagColor: "#0891b2",
  },
  {
    step: 3,
    name: "Serum Trị Liệu",
    product: "Niacinamide 10% + Zinc 1%",
    brand: "The Ordinary",
    price: "180.000đ",
    aiReason: "Thu nhỏ lỗ chân lông, giảm bã nhờn và mụn — Phù hợp đặc biệt với vùng T của bạn",
    duration: "Thoa toàn mặt",
    image: "https://images.unsplash.com/photo-1770048792339-d8f8d8d2dbeb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMHNlcnVtJTIwYm90dGxlJTIwcHJvZHVjdCUyMG1pbmltYWxpc3QlMjB3aGl0ZXxlbnwxfHx8fDE3NzQwMTMwMTd8MA&ixlib=rb-4.1.0&q=80&w=400",
    tag: "Trị Liệu",
    tagColor: "#8c6e52",  // Trị Liệu serum tag
  },
  {
    step: 4,
    name: "Kem Dưỡng Đêm",
    product: "Barrier Repair Night Cream",
    brand: "Klairs",
    price: "520.000đ",
    aiReason: "Phục hồi hàng rào da qua đêm, cấp ẩm sâu — Da yếu nhất khi ngủ, đây là lúc kem dưỡng hiệu quả nhất",
    duration: "Thoa đều",
    image: "https://images.unsplash.com/photo-1767360963892-3353defd6584?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMG5pZ2h0JTIwY3JlYW0lMjBtb2lzdHVyaXplciUyMGx1eHVyeSUyMGphcnxlbnwxfHx8fDE3NzQwMTMwMjF8MA&ixlib=rb-4.1.0&q=80&w=400",
    tag: "Phục Hồi",
    tagColor: "#8c6e52",
  },
];

const products = [
  { name: "CeraVe Cleanser", price: "320.000đ", cat: "Sữa Rửa Mặt", stars: 4.8, img: "https://images.unsplash.com/photo-1685052388326-b6383ec2d524?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMGNsZWFuc2VyJTIwZm9hbSUyMHByb2R1Y3QlMjBlbGVnYW50fGVufDF8fHx8MTc3NDAxMzAxN3ww&ixlib=rb-4.1.0&q=80&w=200" },
  { name: "The Ordinary Niacinamide", price: "180.000đ", cat: "Serum", stars: 4.9, img: "https://images.unsplash.com/photo-1770048792339-d8f8d8d2dbeb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMHNlcnVtJTIwYm90dGxlJTIwcHJvZHVjdCUyMG1pbmltYWxpc3QlMjB3aGl0ZXxlbnwxfHx8fDE3NzQwMTMwMTd8MA&ixlib=rb-4.1.0&q=80&w=200" },
  { name: "Some By Mi Toner", price: "280.000đ", cat: "Toner", stars: 4.7, img: "https://images.unsplash.com/photo-1664165786318-9af861f2a9c3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMHRvbmVyJTIwZXNzZW5jZSUyMGJvdHRsZSUyMHBhc3RlbHxlbnwxfHx8fDE3NzQwMTMwMTl8MA&ixlib=rb-4.1.0&q=80&w=200" },
  { name: "La Roche-Posay SPF 50", price: "485.000đ", cat: "Chống Nắng", stars: 4.9, img: "https://images.unsplash.com/photo-1594332322527-08753d4473c1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzdW5zY3JlZW4lMjBtb2lzdHVyaXplciUyMHNraW5jYXJlJTIwdHViZSUyMHByb2R1Y3R8ZW58MXx8fHwxNzc0MDEzMDE4fDA&ixlib=rb-4.1.0&q=80&w=200" },
  { name: "Klairs Night Cream", price: "520.000đ", cat: "Dưỡng Đêm", stars: 4.8, img: "https://images.unsplash.com/photo-1767360963892-3353defd6584?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMG5pZ2h0JTIwY3JlYW0lMjBtb2lzdHVyaXplciUyMGx1eHVyeSUyMGphcnxlbnwxfHx8fDE3NzQwMTMwMjF8MA&ixlib=rb-4.1.0&q=80&w=200" },
];

function StepCard({ item, index }: { item: StepItem; index: number }) {
  const [showReason, setShowReason] = useState(false);

  return (
    <div className="relative group">
      {/* Connector line */}
      {index < 3 && (
        <div className="absolute left-[30px] top-full w-0.5 h-4 bg-gradient-to-b from-[#c4a882]/30 to-transparent z-10" />
      )}

      <div className="flex gap-4 p-4 rounded-2xl bg-white/80 backdrop-blur-sm border border-white/80 shadow-sm hover:shadow-md hover:border-[#c4a882]/20 transition-all">
        {/* Step Number + Image */}
        <div className="flex-shrink-0 relative">
          <div className="w-14 h-14 rounded-xl overflow-hidden border border-gray-100">
            <ImageWithFallback
              src={item.image}
              alt={item.name}
              className="w-full h-full object-cover"
            />
          </div>
          <div className="absolute -top-2 -left-2 w-5 h-5 rounded-full bg-gradient-to-br from-[#c4a882] to-[#8c6e52] text-white text-[10px] flex items-center justify-center shadow-sm">
            {item.step}
          </div>
        </div>

        {/* Info */}
        <div className="flex-1 min-w-0">
          <div className="flex items-start justify-between gap-2 mb-1">
            <div>
              <div className="flex items-center gap-2 flex-wrap">
                <span className="text-sm text-[#2a2a2a]">{item.name}</span>
                <span
                  className="px-2 py-0.5 rounded-full text-[10px]"
                  style={{ backgroundColor: `${item.tagColor}15`, color: item.tagColor }}
                >
                  {item.tag}
                </span>
              </div>
              <p className="text-xs text-[#6b7280]">{item.brand} · {item.product}</p>
            </div>
            <div className="text-sm text-[#c4a882] whitespace-nowrap flex-shrink-0">{item.price}</div>
          </div>

          <div className="flex items-center justify-between">
            <span className="text-xs text-[#9ca3af]">⏱ {item.duration}</span>
            <button
              onClick={() => setShowReason(!showReason)}
              className="flex items-center gap-1 text-xs text-[#c4a882] hover:text-[#8c6e52] transition-colors"
            >
              <Info className="w-3 h-3" />
              AI Lý Do
            </button>
          </div>

          {/* AI Reason Dropdown */}
          {showReason && (
            <div className="mt-2 p-2.5 rounded-xl bg-gradient-to-r from-[#c4a882]/8 to-[#8c6e52]/8 border border-[#c4a882]/15">
              <p className="text-xs text-[#4b5563] leading-relaxed">
                <span className="text-[#c4a882]">🤖 </span>
                {item.aiReason}
              </p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

export function RoutinePage() {
  const navigate = useNavigate();
  const [started, setStarted] = useState(false);
  const [displayMorning, setDisplayMorning] = useState<StepItem[]>(morningSteps);
  const [displayEvening, setDisplayEvening] = useState<StepItem[]>(eveningSteps);
  const [displayProducts, setDisplayProducts] = useState<ProductItem[]>(products);
  const [apiTotalCost, setApiTotalCost] = useState<number | null>(null);
  const [regimenMessage, setRegimenMessage] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;

    const loadRegimen = async () => {
      const result = await getCurrentRegimenApi();
      if (!isMounted || !result.success || !result.content) {
        if (isMounted && result.message) {
          setRegimenMessage(result.message);
        }

        return;
      }

      const mappedMorning = result.content.morning.map((item, index) => mapRegimenToStepItem(item, index));
      const mappedEvening = result.content.evening.map((item, index) => mapRegimenToStepItem(item, index));
      const productMap = [...result.content.morning, ...result.content.evening].map((item) => ({
        name: item.name,
        price: formatCurrency(item.price),
        cat: item.category,
        stars: 4.7,
        img: resolveMediaUrl(item.imageUrl),
      }));

      setDisplayMorning(mappedMorning.length > 0 ? mappedMorning : morningSteps);
      setDisplayEvening(mappedEvening.length > 0 ? mappedEvening : eveningSteps);
      setDisplayProducts(productMap.length > 0 ? productMap : products);
      setApiTotalCost(result.content.totalEstimatedCost);
    };

    void loadRegimen();

    return () => {
      isMounted = false;
    };
  }, []);

  const fallbackTotalCost = displayProducts.reduce((sum, p) => {
    return sum + parseInt(p.price.replace(/\./g, "").replace("đ", ""));
  }, 0);
  const totalCost = apiTotalCost !== null ? apiTotalCost : fallbackTotalCost;

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#f5f5f0] via-white to-[#fce7f3]/20 pt-20">
      {/* Header */}
      <div className="relative overflow-hidden bg-white/70 backdrop-blur-md border-b border-white/60">
        <div className="absolute inset-0 opacity-30">
          <div className="absolute top-0 left-0 w-80 h-40 bg-gradient-to-br from-[#d4f4f4]/60 to-transparent rounded-full blur-3xl" />
        </div>
        <div className="relative max-w-7xl mx-auto px-6 py-6">
          <div className="flex items-center justify-between flex-wrap gap-3">
            <div>
              <Link
                to="/analysis"
                className="flex items-center gap-1.5 text-sm text-[#6b7280] hover:text-[#c4a882] transition-colors mb-2"
              >
                <ArrowLeft className="w-3.5 h-3.5" />
                Quay Lại Báo Cáo
              </Link>
              <h1 className="text-3xl text-[#2a2a2a]">Lộ Trình Dành Riêng Cho Bạn</h1>
              <p className="text-[#6b7280] text-sm mt-1">
                Được AI thiết kế dựa trên{" "}
                <span className="text-[#8c6e52]">Da Hỗn Hợp · Điểm 85/100</span>
              </p>
            </div>

            <div className="flex items-center gap-3">
              <div className="text-right">
                <div className="text-xs text-[#6b7280]">Tổng Chi Phí Ước Tính</div>
                <div className="text-[#c4a882]">
                  {(totalCost / 1000).toFixed(0)}.000đ/tháng
                </div>
              </div>
              <div className="w-10 h-10 rounded-full bg-gradient-to-br from-[#c4a882] to-[#8c6e52] flex items-center justify-center">
                <ShoppingBag className="w-5 h-5 text-white" />
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto px-6 py-8">
        <div className="grid lg:grid-cols-3 gap-7">
          {/* ── MAIN CONTENT: Routines ── */}
          <div className="lg:col-span-2 flex flex-col gap-7">
            {/* Morning Routine */}
            <div className="bg-white/60 backdrop-blur-md rounded-3xl border border-white/80 shadow-sm overflow-hidden">
              <div className="flex items-center gap-3 px-6 py-4 bg-gradient-to-r from-amber-50/80 to-orange-50/50 border-b border-amber-100/60">
                <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-amber-400 to-orange-400 flex items-center justify-center shadow-sm">
                  <Sun className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h2 className="text-[#2a2a2a]">Quy Trình Buổi Sáng</h2>
                  <p className="text-xs text-[#6b7280]">4 bước · ~8 phút</p>
                </div>
                <div className="ml-auto px-3 py-1 rounded-full bg-amber-100/80 text-amber-700 text-xs">
                  07:00 – 07:10
                </div>
              </div>

              <div className="p-5 flex flex-col gap-3">
                {displayMorning.map((item, index) => (
                  <StepCard key={item.step} item={item} index={index} />
                ))}
              </div>
            </div>

            {/* Evening Routine */}
            <div className="bg-white/60 backdrop-blur-md rounded-3xl border border-white/80 shadow-sm overflow-hidden">
              <div className="flex items-center gap-3 px-6 py-4 bg-gradient-to-r from-indigo-50/80 to-purple-50/50 border-b border-indigo-100/60">
                <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[#c4a882] to-[#8c6e52] flex items-center justify-center shadow-sm">
                  <Moon className="w-5 h-5 text-white" />
                </div>
                <div>
                  <h2 className="text-[#2a2a2a]">Quy Trình Buổi Tối</h2>
                  <p className="text-xs text-[#6b7280]">4 bước · ~10 phút</p>
                </div>
                <div className="ml-auto px-3 py-1 rounded-full bg-[#c4a882]/10 text-[#c4a882] text-xs">
                  21:00 – 21:10
                </div>
              </div>

              <div className="p-5 flex flex-col gap-3">
                {displayEvening.map((item, index) => (
                  <StepCard key={item.step} item={item} index={index} />
                ))}
              </div>
            </div>

            {/* Tips */}
            <div className="bg-gradient-to-r from-[#d4f4f4]/50 to-[#fce7f3]/50 rounded-2xl p-5 border border-white/80">
              <h3 className="text-sm text-[#2a2a2a] mb-3">💡 Lời Khuyên Từ AI</h3>
              <div className="grid sm:grid-cols-3 gap-3">
                {[
                  { icon: "💧", tip: "Uống 2L nước/ngày để tăng hiệu quả dưỡng ẩm lên 30%" },
                  { icon: "🌙", tip: "Thay vỏ gối mỗi 3 ngày giúp giảm vi khuẩn gây mụn" },
                  { icon: "🚿", tip: "Rửa mặt bằng nước ấm (không nóng) để tránh mất dầu tự nhiên" },
                ].map((t, i) => (
                  <div key={i} className="bg-white/60 rounded-xl p-3 text-sm text-[#4b5563]">
                    <span className="text-base mr-2">{t.icon}</span>
                    {t.tip}
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* ── SIDEBAR: Products ── */}
          <div className="flex flex-col gap-5">
            {/* Products Panel */}
            <div className="bg-white/80 backdrop-blur-md rounded-3xl border border-white/80 shadow-sm p-5 sticky top-24">
              <div className="flex items-center gap-2 mb-4">
                <ShoppingBag className="w-4 h-4 text-[#c4a882]" />
                <h3 className="text-[#2a2a2a]">Sản Phẩm Cần Chuẩn Bị</h3>
              </div>
              <p className="text-xs text-[#6b7280] mb-4">
                Được AI lựa chọn cho <span className="text-[#c4a882]">da hỗn hợp</span> · Ngân sách trung bình
              </p>

              <div className="flex flex-col gap-3">
                {displayProducts.map((p) => (
                  <div
                    key={p.name}
                    className="flex items-center gap-3 p-3 rounded-xl hover:bg-[#f9fafb] transition-colors border border-transparent hover:border-gray-100 cursor-pointer group"
                  >
                    <div className="w-12 h-12 rounded-xl overflow-hidden flex-shrink-0 border border-gray-100">
                      <ImageWithFallback
                        src={p.img}
                        alt={p.name}
                        className="w-full h-full object-cover"
                      />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-sm text-[#2a2a2a] truncate">{p.name}</p>
                      <p className="text-xs text-[#9ca3af]">{p.cat}</p>
                      <div className="flex items-center gap-1 mt-0.5">
                        <Star className="w-2.5 h-2.5 fill-amber-400 text-amber-400" />
                        <span className="text-[10px] text-[#6b7280]">{p.stars}</span>
                      </div>
                    </div>
                    <div className="text-right flex-shrink-0">
                      <div className="text-sm text-[#c4a882]">{p.price}</div>
                      <ChevronRight className="w-3.5 h-3.5 text-[#9ca3af] group-hover:text-[#c4a882] transition-colors ml-auto" />
                    </div>
                  </div>
                ))}
              </div>

              {regimenMessage && (
                <p className="text-xs text-amber-600 mt-3">{regimenMessage}</p>
              )}

              {/* Total */}
              <div className="mt-4 pt-4 border-t border-gray-100">
                <div className="flex justify-between items-center mb-3">
                  <span className="text-sm text-[#6b7280]">Tổng Cộng</span>
                  <span className="text-[#6366f1]">
                    {(totalCost / 1000).toFixed(0)}.000đ
                  </span>
                </div>
                <button className="w-full py-2.5 rounded-xl border border-[#c4a882]/30 text-[#c4a882] text-sm hover:bg-[#c4a882]/5 transition-colors">
                  Xem Tất Cả Sản Phẩm
                </button>
              </div>
            </div>

            {/* Routine Summary */}
            <div className="bg-gradient-to-br from-[#c4a882]/8 to-[#8c6e52]/8 rounded-2xl p-4 border border-[#c4a882]/15">
              <h4 className="text-sm text-[#2a2a2a] mb-3">📊 Tóm Tắt Lộ Trình</h4>
              <div className="space-y-2 text-sm text-[#4b5563]">
                <div className="flex justify-between">
                  <span>Tổng số bước</span>
                  <span className="text-[#c4a882]">8 bước/ngày</span>
                </div>
                <div className="flex justify-between">
                  <span>Thời gian</span>
                  <span className="text-[#c4a882]">~18 phút/ngày</span>
                </div>
                <div className="flex justify-between">
                  <span>Kết quả dự kiến</span>
                  <span className="text-emerald-600">4–6 tuần</span>
                </div>
                <div className="flex justify-between">
                  <span>Mức độ khó</span>
                  <span className="text-[#f59e0b]">Trung Bình</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* ── BIG CTA BUTTON ── */}
        <div className="mt-10 flex flex-col items-center gap-3">
          {/* Glow background */}
          <div className="relative">
            <div className="absolute -inset-4 bg-gradient-to-r from-[#c4a882]/30 to-[#8c6e52]/30 rounded-full blur-2xl" />
            <button
              onClick={() => {
                setStarted(true);
                setTimeout(() => navigate("/progress"), 800);
              }}
              className={`relative px-16 py-5 rounded-2xl text-white flex items-center gap-3 transition-all duration-300 ${
                started
                  ? "bg-gradient-to-r from-emerald-400 to-teal-500 scale-95"
                  : "bg-gradient-to-r from-[#c4a882] to-[#8c6e52] hover:scale-105 hover:shadow-2xl hover:shadow-[#c4a882]/40 shadow-xl shadow-[#c4a882]/25"
              }`}
            >
              {started ? (
                <>
                  <CheckCircle2 className="w-6 h-6" />
                  <span>Đã Bắt Đầu! Chuyển sang Tiến Trình...</span>
                </>
              ) : (
                <>
                  <Sparkles className="w-6 h-6" />
                  <span>Bắt Đầu Lộ Trình Này</span>
                  <div className="w-2 h-2 rounded-full bg-white/60 animate-pulse" />
                </>
              )}
            </button>
          </div>
          <p className="text-xs text-[#9ca3af]">
            Lộ trình sẽ được lưu vào hồ sơ của bạn · Miễn phí thay đổi bất kỳ lúc nào
          </p>
        </div>
      </div>
    </div>
  );
}

function mapRegimenToStepItem(
  item: { name: string; category: string; price: number; imageUrl?: string | null },
  index: number
): StepItem {
  return {
    step: index + 1,
    name: item.category,
    product: item.name,
    brand: "AI Selected",
    price: formatCurrency(item.price),
    aiReason: `Sản phẩm được gợi ý cho bước ${item.category.toLowerCase()} trong lộ trình cá nhân hóa.`,
    duration: "Theo hướng dẫn",
    image: resolveMediaUrl(item.imageUrl),
    tag: "AI Đề Xuất",
    tagColor: "#8c6e52",
  };
}

function formatCurrency(value: number): string {
  const rounded = Math.round(value).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ".");
  return `${rounded}đ`;
}

function resolveMediaUrl(url?: string | null): string {
  if (!url) {
    return "https://images.unsplash.com/photo-1685052388326-b6383ec2d524?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400";
  }

  if (/^https?:\/\//i.test(url)) {
    return url;
  }

  const base = (import.meta.env.VITE_API_BASE_URL ?? "/api").replace(/\/api\/?$/i, "");
  return `${base}${url}`;
}