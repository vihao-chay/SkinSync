import { Link } from "react-router";
import { ArrowRight, Copyright, Scale, ShieldAlert, Sparkles, Users } from "lucide-react";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";

// [CẬP NHẬT]: Tách các điều khoản chính thành cụm nội dung để người dùng hiểu nhanh phạm vi sử dụng ứng dụng.
const termsSections = [
  {
    icon: Users,
    title: "Giới hạn độ tuổi 13+",
    text:
      "Người dùng cần đủ 13 tuổi trở lên để sử dụng SkinSync. Nếu người dùng chưa đủ tuổi quy định, cần có sự giám sát và đồng ý của người giám hộ hợp pháp.",
  },
  {
    icon: Copyright,
    title: "Quyền sở hữu trí tuệ",
    text:
      "Giao diện, nội dung, logo, dữ liệu mô hình và tài liệu của SkinSync đều thuộc quyền sở hữu của SkinSync hoặc đối tác được cấp phép sử dụng hợp lệ.",
  },
  {
    icon: ShieldAlert,
    title: "Trách nhiệm người dùng",
    text:
      "Người dùng cần cung cấp thông tin chính xác, tuân thủ pháp luật hiện hành và không sử dụng hệ thống cho mục đích gây hại hoặc sai lệch thông tin y tế.",
  },
];

// [CẬP NHẬT]: Khởi tạo trang Điều khoản sử dụng với khối cảnh báo y tế nổi bật và các điều khoản nền tảng.
function DieuKhoanSuDungPage() {
  return (
    <main className="min-h-screen bg-[#fbfaf7] text-[#151827]">
      <header className="border-b border-[#eee7ff] bg-white/85 px-5 py-4 backdrop-blur-xl">
        <div className="mx-auto flex max-w-7xl items-center justify-between gap-4">
          <Link to="/" className="flex items-center gap-3">
            <span className="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-[#b9b6ff] to-[#8ea7ff] text-sm font-black text-white shadow-lg shadow-[#8ea7ff]/20">
              SS
            </span>
            <div>
              <p className="text-sm font-black uppercase tracking-[0.24em] text-[#151827]">SKINSYNC</p>
              <p className="text-xs text-[#7d86a4]">Điều khoản sử dụng</p>
            </div>
          </Link>

          <Button asChild variant="outline" className="rounded-full border-[#ece5ff] bg-white text-[#5f6884] hover:bg-[#f8f6ff]">
            <Link to="/blog">
              Đọc Blog <ArrowRight className="h-4 w-4" />
            </Link>
          </Button>
        </div>
      </header>

      <section className="px-5 py-14 md:py-18">
        <div className="mx-auto max-w-7xl">
          <div className="max-w-3xl">
            <p className="mb-4 inline-flex items-center gap-2 rounded-full border border-white/70 bg-white px-4 py-2 text-xs font-black uppercase tracking-[0.2em] text-[#6d63ff] shadow-lg shadow-[#9aa6ff]/10">
              <Scale className="h-4 w-4" />
              Điều khoản sử dụng
            </p>
            <h1 className="text-4xl font-black leading-tight md:text-6xl">
              Điều khoản rõ ràng, dễ đọc và phù hợp với một sản phẩm AI chăm sóc da.
            </h1>
            <p className="mt-5 max-w-2xl text-lg leading-8 text-[#5f6884]">
              Trang này mô tả những nguyên tắc sử dụng nền tảng, phạm vi trách nhiệm và giới hạn khi tiếp cận nội dung
              phân tích được tạo bởi AI.
            </p>
          </div>

          <div className="mt-10 rounded-[1.75rem] border border-[#f3d7d9] bg-[#fff7f8] p-6 shadow-xl shadow-[#f0a7b5]/10 md:p-8">
            <div className="flex items-start gap-4">
              <span className="flex h-12 w-12 shrink-0 items-center justify-center rounded-2xl bg-white text-[#d54b63] shadow-lg shadow-[#f0a7b5]/15">
                <Sparkles className="h-5 w-5" />
              </span>
              <div>
                <p className="text-sm font-black uppercase tracking-[0.22em] text-[#d54b63]">Medical Disclaimer</p>
                <p className="mt-3 text-lg font-semibold leading-8 text-[#151827]">
                  “SkinSync là ứng dụng hỗ trợ phân tích bằng AI mang tính chất tham khảo, không thay thế cho việc chẩn
                  đoán hay điều trị từ bác sĩ da liễu.”
                </p>
                <p className="mt-3 text-sm leading-7 text-[#5f6884]">
                  Các kết quả, gợi ý thành phần và routine chỉ nên được dùng như công cụ tham khảo để hỗ trợ lựa chọn
                  chăm sóc da thông minh hơn.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="px-5 pb-20">
        <div className="mx-auto grid max-w-7xl gap-5 lg:grid-cols-3">
          {termsSections.map((section) => (
            <Card key={section.title} className="rounded-[1.75rem] border-white/70 bg-white shadow-lg shadow-[#9aa6ff]/10">
              <CardContent className="space-y-4 p-6 md:p-8">
                <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-[#f7f2ff] to-[#dff9ee] text-[#6d63ff]">
                  <section.icon className="h-5 w-5" />
                </span>
                <h2 className="text-2xl font-black">{section.title}</h2>
                <p className="text-sm leading-7 text-[#5f6884]">{section.text}</p>
              </CardContent>
            </Card>
          ))}
        </div>
      </section>
    </main>
  );
}

export { DieuKhoanSuDungPage };
