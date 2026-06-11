import { Link } from "react-router";
import { ArrowRight, Cloud, Fingerprint, ShieldCheck, Trash2 } from "lucide-react";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";

// [CẬP NHẬT]: Tách các điều khoản bảo mật thành từng khối nội dung để người dùng đọc nhanh và hiểu rõ quyền của mình.
const privacySections = [
  {
    icon: Fingerprint,
    title: "Thu thập dữ liệu ảnh khuôn mặt",
    text:
      "SkinSync chỉ sử dụng ảnh khuôn mặt hoặc ảnh sản phẩm để AI phân tích tình trạng da và tạo lộ trình cá nhân hóa. Hệ thống không dùng dữ liệu này để nhận diện danh tính cá nhân.",
  },
  {
    icon: Cloud,
    title: "Lưu trữ đám mây bảo mật",
    text:
      "Dữ liệu được lưu trữ trong môi trường đám mây có kiểm soát truy cập, mã hóa khi truyền tải và tổ chức theo nguyên tắc tối thiểu hóa dữ liệu cần thiết.",
  },
  {
    icon: Trash2,
    title: "Quyền yêu cầu xóa dữ liệu",
    text:
      "Người dùng có thể yêu cầu xóa dữ liệu hình ảnh, lịch sử phân tích hoặc hồ sơ liên quan bất cứ lúc nào thông qua kênh hỗ trợ chính thức.",
  },
];

// [CẬP NHẬT]: Khởi tạo trang Chính sách bảo mật theo phong cách văn bản pháp lý, có callout và các khối nội dung rõ ràng.
function ChinhSachBaoMatPage() {
  return (
    <main className="min-h-screen bg-skin-base text-skin-textMain">
      <header className="border-b border-[#eee7ff] bg-white/85 px-5 py-4 backdrop-blur-xl">
        <div className="mx-auto flex max-w-7xl items-center justify-between gap-4">
          <Link to="/" className="flex items-center gap-3">
            <span className="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-[#b9b6ff] to-[#8ea7ff] text-sm font-black text-white shadow-lg shadow-[#8ea7ff]/20">
              SS
            </span>
            <div>
              <p className="font-serif text-sm font-semibold uppercase tracking-[0.24em] text-skin-textMain">SKINSYNC</p>
              <p className="text-xs text-skin-textMuted">Chính sách bảo mật</p>
            </div>
          </Link>

          <Button asChild variant="outline" className="rounded-full border-[#ece5ff] bg-white text-[#5f6884] hover:bg-[#f8f6ff]">
            <Link to="/dieu-khoan-su-dung">
              Điều khoản sử dụng <ArrowRight className="h-4 w-4" />
            </Link>
          </Button>
        </div>
      </header>

      <section className="px-5 py-14 md:py-18">
        <div className="mx-auto max-w-7xl">
          <div className="max-w-3xl">
            <p className="mb-4 inline-flex items-center gap-2 rounded-full border border-skin-border bg-skin-surface px-4 py-2 text-xs font-medium uppercase tracking-[0.2em] text-skin-gold shadow-soft-gold">
              <ShieldCheck className="h-4 w-4" />
              Chính sách bảo mật
            </p>
            <h1 className="text-4xl font-black leading-tight md:text-6xl">
              Cam kết bảo vệ dữ liệu người dùng theo cách minh bạch và có kiểm soát.
            </h1>
            <p className="mt-5 max-w-2xl text-lg leading-8 text-[#5f6884]">
              Tài liệu này mô tả cách SkinSync xử lý hình ảnh, lưu trữ dữ liệu và cách người dùng có thể chủ động yêu cầu
              xóa thông tin cá nhân khỏi hệ thống.
            </p>
          </div>

          <div className="mt-10 rounded-[1.75rem] border border-skin-border bg-[linear-gradient(135deg,#ffffff_0%,#fbf8f2_100%)] p-6 shadow-soft-gold md:p-8">
            <p className="text-sm font-medium uppercase tracking-[0.22em] text-skin-gold">Điểm nhấn chính</p>
            <p className="mt-3 max-w-4xl text-base leading-8 text-skin-textMuted">
              Ảnh khuôn mặt chỉ được dùng để AI phân tích và tạo lộ trình chăm sóc da cá nhân hóa. Dữ liệu được bảo vệ
              trong môi trường đám mây an toàn và người dùng có thể yêu cầu xóa dữ liệu khi cần.
            </p>
          </div>
        </div>
      </section>

      <section className="px-5 pb-20">
        <div className="mx-auto grid max-w-7xl gap-5 lg:grid-cols-3">
          {privacySections.map((section) => (
            <Card key={section.title} className="rounded-[1.75rem] border-skin-border bg-skin-surface shadow-soft-gold">
              <CardContent className="space-y-4 p-6 md:p-8">
                <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-stone-100 text-skin-gold">
                  <section.icon className="h-5 w-5" />
                </span>
                <h2 className="font-serif text-2xl font-semibold text-skin-textMain">{section.title}</h2>
                <p className="text-sm leading-7 text-skin-textMuted">{section.text}</p>
              </CardContent>
            </Card>
          ))}
        </div>
      </section>
    </main>
  );
}

export { ChinhSachBaoMatPage };
