import { useState } from "react";
import { Link } from "react-router";
import { BadgePercent, Check, Clock3, CreditCard, ShieldCheck, Sparkles } from "lucide-react";
import { Button } from "./ui/button";
import { Card, CardContent } from "./ui/card";

// [FIXED]: Giữ dữ liệu gói cước gọn và ổn định để tập trung xử lý bố cục và typography.
const basicFeatures = [
  "Quét da AI cơ bản (3 lần/tuần)",
  "Nhật ký chăm sóc da 7 ngày",
  "Theo dõi lộ trình",
];

// [FIXED]: Giữ danh sách Premium theo đúng nội dung gốc nhưng tách hiển thị giá ra thành 2 dòng rõ hơn.
const premiumFeatures = [
  "Quét da AI chuyên sâu không giới hạn",
  "Lộ trình cá nhân hóa tự động",
  "Quét thành phần mỹ phẩm tức thì",
  "Trò chuyện 1-1 với trợ lý AI",
  "Lưu trữ nhật ký vĩnh viễn",
];

// [FIXED]: Bổ sung khoảng thở phía trên để badge tiêu đề không bị cắt xén khi component được nhúng vào page.
function Subscription() {
  const [billingCycle, setBillingCycle] = useState<"monthly" | "yearly">("monthly");
  const isYearly = billingCycle === "yearly";

  return (
    <section className="bg-skin-base px-5 py-20 pt-24 text-skin-textMain md:py-24 md:pt-28">
      <div className="mx-auto max-w-6xl">
        <div className="mx-auto max-w-3xl text-center">
          {/* [FIXED]: Tăng khoảng đệm trên cùng để badge đầu trang không bị dính sát mép và nhìn thoáng hơn. */}
          <div className="inline-flex items-center gap-2 rounded-full bg-[#C5A880]/10 px-4 py-2 text-xs font-semibold tracking-[0.24em] text-[#C5A880]">
            <Sparkles className="h-4 w-4" />
            NÂNG CẤP TRẢI NGHIỆM
          </div>
          <h2 className="mt-5 font-serif text-4xl font-semibold tracking-tight text-[#332F2A] md:text-5xl">
            Đầu tư cho làn da, tối ưu cho ví tiền
          </h2>
          <p className="mt-4 text-base leading-7 text-skin-textMuted md:text-lg">
            Chọn gói phù hợp nhất với hành trình chăm sóc da của bạn. Hủy bất cứ lúc nào.
          </p>
        </div>

        {/* [FIXED]: Giữ billing toggle gọn hơn và đảm bảo khoảng cách đứng độc lập với phần card bên dưới. */}
        <div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row">
          <div className="w-full max-w-[520px] rounded-full bg-white p-1 shadow-[0_4px_20px_rgba(197,168,128,0.1)]">
            {/* [FIXED]: Cho hai nút toggle chia đều chiều rộng để luôn thẳng hàng và không bị lệch bởi độ dài chữ. */}
            <div className="flex w-full items-center gap-1">
              <button
                type="button"
                onClick={() => setBillingCycle("monthly")}
                className={`flex-1 rounded-full px-4 py-2 text-sm font-medium transition ${
                  !isYearly ? "bg-[#C5A880] text-white" : "bg-transparent text-skin-textMuted hover:text-skin-textMain"
                }`}
              >
                Thanh toán hàng tháng
              </button>
              <button
                type="button"
                onClick={() => setBillingCycle("yearly")}
                className={`flex-1 rounded-full px-4 py-2 text-sm font-medium transition ${
                  isYearly ? "bg-[#C5A880] text-white" : "bg-transparent text-skin-textMuted hover:text-skin-textMain"
                }`}
              >
                Thanh toán hàng năm
              </button>
            </div>
          </div>

          {isYearly ? (
            <span className="inline-flex items-center gap-2 rounded-full bg-[#C5A880]/10 px-3 py-1 text-xs font-semibold text-[#C5A880]">
              <BadgePercent className="h-3.5 w-3.5" />
              Tiết kiệm 20%
            </span>
          ) : null}
        </div>

        <div className="mt-12 grid gap-6 md:grid-cols-2">
          {/* [FIXED]: Basic card chỉ giữ typography đơn giản, bỏ icon góc trên phải và tăng độ đậm cho button outline. */}
          <Card className="rounded-2xl border-0 bg-white shadow-[0_4px_20px_rgba(197,168,128,0.1)]">
            <CardContent className="p-6 md:p-8">
              <div>
                <p className="text-sm font-semibold uppercase tracking-[0.18em] text-skin-textMuted">Basic</p>
                <div className="mt-3 flex items-end gap-2">
                  <span className="font-serif text-4xl font-semibold text-[#332F2A]">0đ</span>
                  <span className="pb-1 text-sm text-skin-textMuted">/ tháng</span>
                </div>
              </div>

              <p className="mt-4 text-sm leading-6 text-skin-textMuted">Dành cho người mới bắt đầu.</p>

              <ul className="mt-6 space-y-3">
                {basicFeatures.map((feature) => (
                  <li key={feature} className="flex items-start gap-3 text-sm leading-6 text-skin-textMain">
                    {/* [FIXED]: Làm dấu tick đậm và dễ đọc hơn bằng strokeWidth cao hơn và màu gold đậm hơn. */}
                    <Check className="mt-0.5 h-4 w-4 shrink-0 text-skin-goldHover" strokeWidth={2.25} />
                    <span>{feature}</span>
                  </li>
                ))}
              </ul>

              {/* [FIXED]: Nút Basic tăng border-2, font-semibold và py-3 để trông cứng cáp hơn. */}
              <Button
                asChild
                variant="outline"
                className="mt-8 h-12 w-full rounded-full border-2 border-[#C5A880] bg-transparent py-3 text-[#C5A880] font-semibold hover:bg-[#C5A880]/5 hover:text-[#C5A880]"
              >
                <Link to="/register">Bắt đầu miễn phí</Link>
              </Button>
            </CardContent>
          </Card>

          {/* [FIXED]: Premium card đưa badge ra vắt ngang mép trên, tách giá chính và giá thanh toán năm thành hai dòng rõ ràng. */}
          <Card className="relative rounded-2xl border border-[#C5A880] bg-white shadow-[0_4px_20px_rgba(197,168,128,0.1)]">
            <div className="absolute -top-3 right-6 rounded-full bg-[#C5A880] px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.2em] text-white shadow-[0_4px_20px_rgba(197,168,128,0.15)]">
              PHỔ BIẾN NHẤT
            </div>
            <CardContent className="p-6 pt-8 md:p-8 md:pt-9">
              <div>
                <p className="text-sm font-semibold uppercase tracking-[0.18em] text-skin-textMuted">Premium</p>
                <div className="mt-3">
                  <div className="flex items-end gap-2">
                    <span className="font-serif text-4xl font-semibold text-[#332F2A]">
                      {isYearly ? "470.000đ" : "49.000đ"}
                    </span>
                    <span className="pb-1 text-sm text-skin-textMuted">{isYearly ? "/ năm" : "/ tháng"}</span>
                  </div>
                  <p className="mt-1 text-sm text-skin-textMuted">
                    (hoặc 470.000đ thanh toán hàng năm)
                  </p>
                </div>
              </div>

              <p className="mt-4 text-sm leading-6 text-skin-textMuted">
                Mở khóa toàn bộ sức mạnh AI chuyên sâu.
              </p>

              <ul className="mt-6 space-y-3">
                {premiumFeatures.map((feature) => (
                  <li key={feature} className="flex items-start gap-3 text-sm leading-6 text-skin-textMain">
                    {/* [FIXED]: Làm dấu tick đậm và đồng bộ với tone gold của pricing. */}
                    <Check className="mt-0.5 h-4 w-4 shrink-0 text-skin-goldHover" strokeWidth={2.25} />
                    <span>{feature}</span>
                  </li>
                ))}
              </ul>

              {/* [FIXED]: Nút Premium cũng được nới py-3 để cùng nhịp với nút Basic. */}
              <Button asChild className="mt-8 h-12 w-full rounded-full bg-[#C5A880] py-3 text-white font-semibold hover:bg-[#b99666]">
                <Link to="/register">Nâng cấp Premium ngay</Link>
              </Button>
            </CardContent>
          </Card>
        </div>

        {/* [FIXED]: Trust signals giữ nguyên nhưng dùng tone ấm hơn để khớp với phần pricing mới. */}
        <div className="mt-10 flex flex-wrap items-center justify-center gap-x-4 gap-y-2 text-sm text-skin-textMuted">
          <span className="inline-flex items-center gap-2">
            <ShieldCheck className="h-4 w-4 text-[#C5A880]" />
            Bảo mật thanh toán 100%
          </span>
          <span className="hidden text-stone-300 sm:inline">|</span>
          <span className="inline-flex items-center gap-2">
            <Clock3 className="h-4 w-4 text-[#C5A880]" />
            Hủy gia hạn bất kỳ lúc nào
          </span>
          <span className="hidden text-stone-300 sm:inline">|</span>
          <span className="inline-flex items-center gap-2">
            <CreditCard className="h-4 w-4 text-[#C5A880]" />
            Không có phí ẩn
          </span>
        </div>
      </div>
    </section>
  );
}

export { Subscription };
