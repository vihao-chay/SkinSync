import { Link } from "react-router";
import {
  ArrowRight,
  Camera,
  CircleHelp,
  Mail,
  Package,
  Paperclip,
  Sparkles,
  ShieldAlert,
} from "lucide-react";
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "../components/ui/accordion";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";
import { Input } from "../components/ui/input";
import { Textarea } from "../components/ui/textarea";

// [CẬP NHẬT]: Nhóm câu hỏi thường gặp theo từng chủ đề để FAQ có cấu trúc rõ ràng và dễ mở rộng.
const faqGroups = [
  {
    title: "Tài khoản",
    icon: CircleHelp,
    items: [
      {
        question: "Tôi có thể đổi email đăng nhập không?",
        answer: "Có. Bạn có thể cập nhật email trong phần hồ sơ hoặc liên hệ đội ngũ hỗ trợ nếu cần xác minh bổ sung.",
      },
      {
        question: "Mật khẩu bị quên thì xử lý thế nào?",
        answer: "Dùng chức năng quên mật khẩu để nhận liên kết đặt lại qua email, sau đó đăng nhập lại bằng mật khẩu mới.",
      },
    ],
  },
  {
    title: "AI quét da / thành phần",
    icon: Sparkles,
    items: [
      {
        question: "AI quét da hoạt động như thế nào?",
        answer: "SkinSync phân tích bề mặt da, dấu hiệu phục hồi và ngữ cảnh routine để gợi ý lộ trình phù hợp hơn.",
      },
      {
        question: "Quét bảng thành phần có hỗ trợ cảnh báo xung đột không?",
        answer: "Có. Hệ thống sẽ đánh dấu nhóm thành phần cần lưu ý và đề xuất cách phối hợp an toàn hơn cho routine.",
      },
    ],
  },
  {
    title: "Lỗi camera / ảnh tải lên",
    icon: Camera,
    items: [
      {
        question: "Nếu camera không mở được thì nên làm gì?",
        answer: "Hãy cấp quyền camera cho trình duyệt, kiểm tra lại môi trường ánh sáng và thử tải lại trang trước khi chụp.",
      },
      {
        question: "Ảnh mờ có ảnh hưởng đến kết quả phân tích không?",
        answer: "Có. Ảnh rõ nét, đủ sáng và chụp thẳng sẽ giúp AI nhận diện chính xác hơn và đưa ra lộ trình tin cậy hơn.",
      },
    ],
  },
  {
    title: "Quản lý gói",
    icon: Package,
    items: [
      {
        question: "Làm sao xem trạng thái gói hiện tại?",
        answer: "Trạng thái gói sẽ hiển thị trong khu vực tài khoản hoặc ngay trên màn hình quản lý dịch vụ của bạn.",
      },
      {
        question: "Tôi có thể nâng cấp hoặc hủy gói ở đâu?",
        answer: "Bạn có thể liên hệ trung tâm hỗ trợ hoặc quản lý trực tiếp trong phần tài khoản nếu gói của bạn đã được kích hoạt.",
      },
    ],
  },
];

// [CẬP NHẬT]: Khởi tạo trang trợ giúp với FAQ dạng accordion và form liên hệ đặt cạnh nhau.
function TroGiupPage() {
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
              <p className="text-xs text-skin-textMuted">Trung tâm hỗ trợ</p>
            </div>
          </Link>

          <Button asChild variant="outline" className="rounded-full border-[#ece5ff] bg-white text-[#5f6884] hover:bg-[#f8f6ff]">
            <Link to="/blog">
              Đi tới Blog <ArrowRight className="h-4 w-4" />
            </Link>
          </Button>
        </div>
      </header>

      <section className="px-5 py-14 md:py-18">
        <div className="mx-auto max-w-7xl">
          <div className="max-w-3xl">
            <p className="mb-4 inline-flex items-center gap-2 rounded-full border border-skin-border bg-skin-surface px-4 py-2 text-xs font-medium uppercase tracking-[0.2em] text-skin-gold shadow-soft-gold">
              <CircleHelp className="h-4 w-4" />
              Trung tâm hỗ trợ
            </p>
            <h1 className="text-4xl font-black leading-tight md:text-6xl">
              FAQ, hướng dẫn và kênh liên hệ dành cho mọi câu hỏi về SkinSync.
            </h1>
            <p className="mt-5 max-w-2xl text-lg leading-8 text-[#5f6884]">
              Gặp lỗi camera, muốn hiểu rõ AI quét da, hay cần hỗ trợ gói dịch vụ? Mọi thứ được gom lại trong một trang
              để người dùng tìm thấy câu trả lời nhanh hơn.
            </p>
          </div>
        </div>
      </section>

      <section className="px-5 pb-20">
        <div className="mx-auto grid max-w-7xl gap-6 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="space-y-5">
            {faqGroups.map((group) => (
              <Card key={group.title} className="rounded-[1.75rem] border-skin-border bg-skin-surface shadow-soft-gold">
                <CardContent className="p-6 md:p-8">
                  <div className="mb-5 flex items-center gap-3">
                    <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-stone-100 text-skin-gold">
                      <group.icon className="h-5 w-5" />
                    </span>
                    <div>
                      <h2 className="font-serif text-xl font-semibold text-skin-textMain">{group.title}</h2>
                      <p className="text-sm text-skin-textMuted">Các câu hỏi phổ biến nhất trong nhóm này</p>
                    </div>
                  </div>

                  <Accordion type="single" collapsible className="w-full">
                    {group.items.map((item, index) => (
                      <AccordionItem key={item.question} value={`${group.title}-${index}`}>
                        <AccordionTrigger className="text-left text-base font-medium text-skin-textMain hover:no-underline">
                          {item.question}
                        </AccordionTrigger>
                        <AccordionContent className="text-sm leading-7 text-skin-textMuted">
                          {item.answer}
                        </AccordionContent>
                      </AccordionItem>
                    ))}
                  </Accordion>
                </CardContent>
              </Card>
            ))}
          </div>

          <Card className="h-fit rounded-[1.75rem] border-skin-border bg-skin-surface shadow-soft-gold">
            <CardContent className="space-y-6 p-6 md:p-8">
              <div>
                <p className="text-sm font-medium uppercase tracking-[0.22em] text-skin-gold">Liên hệ hỗ trợ</p>
                <h2 className="mt-2 font-serif text-2xl font-semibold text-skin-textMain">Gửi câu hỏi để đội ngũ SkinSync phản hồi</h2>
              </div>

              <form className="space-y-4">
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-[#5f6884]" htmlFor="support-name">
                    Họ tên
                  </label>
                  <Input id="support-name" placeholder="Nguyễn Minh Anh" />
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-semibold text-[#5f6884]" htmlFor="support-email">
                    Email
                  </label>
                  <Input id="support-email" type="email" placeholder="ban@example.com" />
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-semibold text-[#5f6884]" htmlFor="support-message">
                    Nội dung
                  </label>
                  <Textarea id="support-message" placeholder="Mô tả ngắn gọn vấn đề bạn đang gặp phải..." className="min-h-40" />
                </div>

                <div className="space-y-2">
                  <label className="text-sm font-semibold text-[#5f6884]" htmlFor="support-attachment">
                    Đính kèm ảnh
                  </label>
                  <label
                    htmlFor="support-attachment"
                    className="flex cursor-pointer items-center justify-between rounded-md border border-dashed border-[#dcd4ff] bg-[#faf8ff] px-4 py-3 text-sm text-[#5f6884]"
                  >
                    <span className="inline-flex items-center gap-2">
                      <Paperclip className="h-4 w-4" />
                      Chọn ảnh hoặc ảnh chụp màn hình
                    </span>
                    <span className="text-xs font-semibold uppercase tracking-[0.18em] text-skin-gold">Upload</span>
                  </label>
                  <input id="support-attachment" type="file" className="hidden" />
                </div>

                <Button className="h-12 w-full rounded-full bg-skin-gold text-sm font-semibold text-white hover:bg-skin-goldHover">
                  Gửi yêu cầu <Mail className="h-4 w-4" />
                </Button>
              </form>

              <div className="rounded-[1.5rem] bg-[linear-gradient(135deg,#f5f1ff_0%,#eef3ff_100%)] p-5 text-sm leading-7 text-[#5f6884]">
                <p className="font-medium uppercase tracking-[0.18em] text-skin-textMain">Kỳ vọng phản hồi</p>
                <p className="mt-2">
                  Đội ngũ hỗ trợ thường phản hồi trong vòng 1-2 ngày làm việc, đặc biệt với lỗi camera, lỗi tải ảnh hoặc
                  các câu hỏi liên quan đến gói dịch vụ.
                </p>
              </div>
            </CardContent>
          </Card>
        </div>
      </section>
    </main>
  );
}

export { TroGiupPage };
