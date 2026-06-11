import { Link } from "react-router";
import { ArrowLeft } from "lucide-react";
import { Subscription } from "../components/Subscription";
import { Button } from "../components/ui/button";

// [CẬP NHẬT]: Tạo trang Bảng giá riêng để component Subscription có nơi hiển thị rõ ràng và có thể truy cập trực tiếp.
function SubscriptionPage() {
  return (
    <main className="min-h-screen bg-skin-base text-skin-textMain">
      {/* [CẬP NHẬT]: Thêm header tối giản để người dùng có thể quay lại landing page từ trang bảng giá. */}
      <header className="border-b border-[#ece5ff] bg-white/85 px-5 py-4 backdrop-blur-xl">
        <div className="mx-auto flex max-w-7xl items-center justify-between gap-4">
          <Link to="/" className="flex items-center gap-3">
            <span className="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-[#b9b6ff] to-[#8ea7ff] text-sm font-black text-white shadow-lg shadow-[#8ea7ff]/20">
              SS
            </span>
            <div>
              <p className="font-serif text-sm font-semibold uppercase tracking-[0.24em] text-skin-textMain">SKINSYNC</p>
              <p className="text-xs text-skin-textMuted">Bảng giá</p>
            </div>
          </Link>

          <Button asChild variant="outline" className="rounded-full border-skin-border bg-skin-surface text-skin-textMuted hover:bg-stone-100">
            <Link to="/">
              <ArrowLeft className="h-4 w-4" />
              Về trang chủ
            </Link>
          </Button>
        </div>
      </header>

      {/* [CẬP NHẬT]: Render nguyên component Subscription để trang riêng hiển thị đầy đủ giao diện gói cước. */}
      <Subscription />
    </main>
  );
}

export { SubscriptionPage };
