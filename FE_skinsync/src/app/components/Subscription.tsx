import { useState } from "react";
import { Link } from "react-router";
import { Check, Sparkles, ShieldCheck, Clock3, CreditCard, BadgePercent } from "lucide-react";
import { Button } from "./ui/button";
import { Card, CardContent } from "./ui/card";

// [CẬP NHẬT]: Khai báo dữ liệu gói cước để component có thể hiển thị gọn, rõ và dễ điều chỉnh sau này.
const basicFeatures = [
  "Quét da AI cơ bản (3 lần/tuần)",
  "Nhật ký chăm sóc da 7 ngày",
  "Theo dõi lộ trình",
];

// [CẬP NHẬT]: Khai báo danh sách tính năng Premium theo đúng yêu cầu để thẻ nổi bật có nội dung đầy đủ.
const premiumFeatures = [
  "Quét da AI chuyên sâu không giới hạn",
  "Lộ trình cá nhân hóa tự động",
  "Quét thành phần mỹ phẩm tức thì",
  "Trò chuyện 1-1 với trợ lý AI",
  "Lưu trữ nhật ký vĩnh viễn",
];

// [CẬP NHẬT]: Tạo component Subscription với layout responsive, bảng màu đất ấm và toggle billing có trạng thái thật.
function Subscription() {
  const [billingCycle, setBillingCycle] = useState<"monthly" | "yearly">("monthly");
  const isYearly = billingCycle === "yearly";
  const premiumPrice = isYearly ? "470.000đ" : "49.000đ";

  return (
    <section className="bg-skin-base px-5 py-16 text-skin-textMain md:py-20">
      <div className="mx-auto max-w-6xl">
        <div className="mx-auto max-w-3xl text-center">
          {/* [CẬP NHẬT]: Header block theo yêu cầu, dùng badge muted gold và heading serif cho cảm giác thanh lịch. */}
          <div className="inline-flex items-center gap-2 rounded-full bg-[#C5A880]/10 px-4 py-2 text-xs font-semibold tracking-[0.24em] text-[#C5A880]">
            <Sparkles className="h-4 w-4" />
            NÂNG CẤP TRẢI NGHIỆM
          </div>
          <h2 className="mt-5 font-serif text-4xl font-semibold tracking-tight text-[#332F2A] md:text-5xl">
            Đầu tư cho làn da, tối ưu cho ví tiền
          </h2>
          <p className="mt-4 text-base leading-7 text-stone-600 md:text-lg">
            Chọn gói phù hợp nhất với hành trình chăm sóc da của bạn. Hủy bất cứ lúc nào.
          </p>
        </div>

        {/* [CẬP NHẬT]: Billing toggle có trạng thái thật để đổi giá giữa tháng/năm và hiển thị badge tiết kiệm khi chọn năm. */}
        <div className="mt-10 flex flex-col items-center justify-center gap-3 sm:flex-row">
          <div className="rounded-full bg-white p-1 shadow-[0_4px_20px_rgba(197,168,128,0.1)]">
            <div className="flex items-center gap-1">
              <button
                type="button"
                onClick={() => setBillingCycle("monthly")}
                className={`rounded-full px-4 py-2 text-sm font-medium transition ${
                  !isYearly ? "bg-[#C5A880] text-white" : "bg-transparent text-stone-500 hover:text-stone-700"
                }`}
              >
                Thanh toán hàng tháng
              </button>
              <button
                type="button"
                onClick={() => setBillingCycle("yearly")}
                className={`rounded-full px-4 py-2 text-sm font-medium transition ${
                  isYearly ? "bg-[#C5A880] text-white" : "bg-transparent text-stone-500 hover:text-stone-700"
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
          {/* [CẬP NHẬT]: Thẻ Basic tối giản, nền trắng, viền mềm và CTA outline đúng theo yêu cầu. */}
          <Card className="rounded-2xl border-0 bg-white shadow-[0_4px_20px_rgba(197,168,128,0.1)]">
            <CardContent className="p-6 md:p-8">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="text-sm font-semibold uppercase tracking-[0.18em] text-stone-500">Basic</p>
                  <div className="mt-3 flex items-end gap-2">
                    <span className="font-serif text-4xl font-semibold text-[#332F2A]">0đ</span>
                    <span className="pb-1 text-sm text-stone-500">/ tháng</span>
                  </div>
                </div>
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-stone-50 text-[#C5A880]">
                  <CreditCard className="h-5 w-5" />
                </div>
              </div>

              <p className="mt-4 text-sm leading-6 text-stone-600">Dành cho người mới bắt đầu.</p>

              <ul className="mt-6 space-y-3">
                {basicFeatures.map((feature) => (
                  <li key={feature} className="flex items-start gap-3 text-sm leading-6 text-stone-700">
                    <Check className="mt-0.5 h-4 w-4 shrink-0 text-stone-400" />
                    <span>{feature}</span>
                  </li>
                ))}
              </ul>

              <Button
                asChild
                variant="outline"
                className="mt-8 h-12 w-full rounded-full border-[#C5A880] bg-transparent text-[#C5A880] hover:bg-[#C5A880]/5 hover:text-[#C5A880]"
              >
                <Link to="/register">Bắt đầu miễn phí</Link>
              </Button>
            </CardContent>
          </Card>

          {/* [CẬP NHẬT]: Thẻ Premium nổi bật hơn với viền muted gold, tag phổ biến nhất và CTA đặc theo yêu cầu. */}
          <Card className="relative rounded-2xl border border-[#C5A880] bg-white shadow-[0_4px_20px_rgba(197,168,128,0.1)]">
            <div className="absolute right-5 top-5 rounded-full bg-[#C5A880] px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.2em] text-white">
              PHỔ BIẾN NHẤT
            </div>
            <CardContent className="p-6 md:p-8">
              <div className="flex items-start justify-between gap-4">
                <div>
                  <p className="text-sm font-semibold uppercase tracking-[0.18em] text-stone-500">Premium</p>
                  <div className="mt-3 flex flex-wrap items-end gap-x-3 gap-y-1">
                    <span className="font-serif text-4xl font-semibold text-[#332F2A]">{premiumPrice}</span>
                    <span className="pb-1 text-sm text-stone-500">{isYearly ? "/ năm" : "/ tháng"}</span>
                    <span className="pb-1 text-sm text-stone-400">
                      {isYearly ? "tương đương 49.000đ / tháng" : "hoặc 470.000đ / năm"}
                    </span>
                  </div>
                </div>
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#C5A880]/10 text-[#C5A880]">
                  <Sparkles className="h-5 w-5" />
                </div>
              </div>

              <p className="mt-4 text-sm leading-6 text-stone-600">Mở khóa toàn bộ sức mạnh AI chuyên sâu.</p>

              <ul className="mt-6 space-y-3">
                {premiumFeatures.map((feature) => (
                  <li key={feature} className="flex items-start gap-3 text-sm leading-6 text-stone-700">
                    <Check className="mt-0.5 h-4 w-4 shrink-0 text-[#C5A880]" />
                    <span>{feature}</span>
                  </li>
                ))}
              </ul>

              <Button asChild className="mt-8 h-12 w-full rounded-full bg-[#C5A880] text-white hover:bg-[#b99666]">
                <Link to="/register">Nâng cấp Premium ngay</Link>
              </Button>
            </CardContent>
          </Card>
        </div>

        {/* [CẬP NHẬT]: Thêm trust signals căn giữa bằng icon nhỏ và text stone-500 để tăng độ tin cậy. */}
        <div className="mt-10 flex flex-wrap items-center justify-center gap-x-4 gap-y-2 text-sm text-stone-500">
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
