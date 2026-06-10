import { Link } from "react-router";
import { ArrowRight, Clock3, Sparkles, FlaskConical, LayoutGrid } from "lucide-react";
import { Button } from "../components/ui/button";
import { Card, CardContent } from "../components/ui/card";

// [CẬP NHẬT]: Khai báo các chuyên mục blog để tạo thanh phân loại rõ ràng và có tính điều hướng.
const blogCategories = [
  "Chăm sóc da 101",
  "Giải mã thành phần",
  "Giải pháp da",
  "Góc SkinSync",
];

// [CẬP NHẬT]: Tạo dữ liệu bài viết mẫu để trang Blog luôn có lưới nội dung và không bị trống.
const blogPosts = [
  {
    category: "Chăm sóc da 101",
    title: "Xây dựng routine sáng - tối cho làn da bận rộn",
    excerpt: "Một lộ trình tối giản nhưng đủ lớp, giúp bạn bắt đầu đúng cách mà không bị quá tải bởi quá nhiều bước.",
    readTime: "6 phút đọc",
  },
  {
    category: "Giải mã thành phần",
    title: "Niacinamide có thật sự phù hợp với mọi loại da?",
    excerpt: "SkinSync giải thích cách kết hợp Niacinamide, BHA và Vitamin C để giảm kích ứng và tăng hiệu quả.",
    readTime: "5 phút đọc",
  },
  {
    category: "Giải pháp da",
    title: "Xử lý mụn ẩn: nên bắt đầu từ đâu?",
    excerpt: "Phân tích nguyên nhân, dấu hiệu và cách ưu tiên sản phẩm theo tình trạng da thay vì chạy theo trend.",
    readTime: "7 phút đọc",
  },
  {
    category: "Góc SkinSync",
    title: "AI của SkinSync tạo lộ trình cá nhân như thế nào?",
    excerpt: "Từ ảnh chụp và bảng thành phần, hệ thống gợi ý giải pháp phù hợp với ngân sách và thói quen thực tế.",
    readTime: "4 phút đọc",
  },
];

// [CẬP NHẬT]: Khởi tạo trang Blog với hero, thanh chuyên mục và lưới bài viết có bố cục rõ ràng.
function BlogPage() {
  return (
    <main className="min-h-screen bg-[#fbfaf7] text-[#151827]">
      <header className="border-b border-[#eee7ff] bg-white/85 px-5 py-4 backdrop-blur-xl">
        <div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-4">
          <Link to="/" className="flex items-center gap-3">
            <span className="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-[#b9b6ff] to-[#8ea7ff] text-sm font-black text-white shadow-lg shadow-[#8ea7ff]/20">
              SS
            </span>
            <div>
              <p className="text-sm font-black uppercase tracking-[0.24em] text-[#151827]">SKINSYNC</p>
              <p className="text-xs text-[#7d86a4]">Blog / kiến thức chăm sóc da</p>
            </div>
          </Link>

          <nav className="flex flex-wrap items-center gap-4 text-sm font-semibold text-[#5f6884]">
            <Link to="/tro-giup" className="transition hover:text-[#6d63ff]">
              Trung tâm hỗ trợ
            </Link>
            <Link to="/chinh-sach-bao-mat" className="transition hover:text-[#6d63ff]">
              Chính sách
            </Link>
            <Link to="/dieu-khoan-su-dung" className="transition hover:text-[#6d63ff]">
              Điều khoản
            </Link>
          </nav>
        </div>
      </header>

      <section className="px-5 py-14 md:py-18">
        <div className="mx-auto grid max-w-7xl gap-8 lg:grid-cols-[1.05fr_0.95fr]">
          <div>
            <p className="mb-4 inline-flex items-center gap-2 rounded-full border border-white/70 bg-white px-4 py-2 text-xs font-black uppercase tracking-[0.2em] text-[#6d63ff] shadow-lg shadow-[#9aa6ff]/10">
              <Sparkles className="h-4 w-4" />
              Góc kiến thức SkinSync
            </p>
            <h1 className="max-w-3xl text-4xl font-black leading-tight md:text-6xl">
              Blog chăm sóc da dành cho những routine có căn cứ và dễ áp dụng.
            </h1>
            <p className="mt-5 max-w-2xl text-lg leading-8 text-[#5f6884]">
              Khám phá nội dung dễ đọc, thực tế và bám sát các vấn đề thường gặp như mụn, kích ứng, phục hồi hàng rào da
              và cách hiểu bảng thành phần mỹ phẩm.
            </p>
          </div>

          <Card className="rounded-[2rem] border-white/70 bg-white shadow-xl shadow-[#9aa6ff]/10">
            <CardContent className="p-6 md:p-8">
              <div className="mb-6 flex items-center gap-3">
                <span className="flex h-12 w-12 items-center justify-center rounded-2xl bg-gradient-to-br from-[#f7f2ff] to-[#dff9ee] text-[#6d63ff]">
                  <LayoutGrid className="h-5 w-5" />
                </span>
                <div>
                  <p className="text-sm font-black uppercase tracking-[0.18em] text-[#151827]">Chuyên mục nổi bật</p>
                  <p className="text-sm text-[#7d86a4]">4 nhóm nội dung cốt lõi trên SkinSync</p>
                </div>
              </div>

              <div className="flex flex-wrap gap-3">
                {blogCategories.map((category) => (
                  <span
                    key={category}
                    className="rounded-full border border-[#ece5ff] bg-[#faf8ff] px-4 py-2 text-sm font-semibold text-[#5f6884]"
                  >
                    {category}
                  </span>
                ))}
              </div>

              <div className="mt-6 rounded-[1.5rem] bg-[linear-gradient(135deg,#c9b8ff_0%,#9eaaff_100%)] p-6 text-white">
                <p className="text-xs font-black uppercase tracking-[0.22em] text-white/80">Bài đọc đề xuất</p>
                <h2 className="mt-3 text-2xl font-black leading-tight">
                  Niacinamide, BHA và cách phối hợp để không làm da quá tải
                </h2>
                <p className="mt-3 text-sm leading-6 text-white/85">
                  Bài viết mở đầu dễ hiểu, phù hợp cho người mới bắt đầu hoặc đang tối ưu lại routine theo hướng tối giản.
                </p>
                <Button asChild className="mt-6 h-11 rounded-full bg-white px-5 text-sm font-bold text-[#6d63ff] hover:bg-[#f6f7ff]">
                  <Link to="/tro-giup">
                    Xem bài liên quan <ArrowRight className="h-4 w-4" />
                  </Link>
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      </section>

      <section className="px-5 pb-20">
        <div className="mx-auto max-w-7xl">
          <div className="mb-8 flex items-center justify-between gap-4">
            <div>
              <p className="text-sm font-black uppercase tracking-[0.22em] text-[#6d63ff]">Bài viết mới</p>
              <h2 className="mt-2 text-3xl font-black md:text-4xl">Lưới bài viết theo chủ đề SkinSync</h2>
            </div>
            <div className="hidden items-center gap-2 rounded-full border border-[#ece5ff] bg-white px-4 py-2 text-sm font-semibold text-[#5f6884] md:flex">
              <Clock3 className="h-4 w-4" />
              Cập nhật hàng tuần
            </div>
          </div>

          <div className="grid gap-5 md:grid-cols-2 xl:grid-cols-4">
            {blogPosts.map((post) => (
              <Card key={post.title} className="overflow-hidden rounded-[1.75rem] border-white/70 bg-white shadow-lg shadow-[#9aa6ff]/10">
                <CardContent className="p-0">
                  <div className="relative h-44 bg-[linear-gradient(135deg,#f5f1ff_0%,#eef3ff_52%,#f7fff9_100%)] p-5">
                    <div className="inline-flex items-center gap-2 rounded-full bg-white/80 px-3 py-1 text-xs font-black uppercase tracking-[0.18em] text-[#6d63ff]">
                      {post.category}
                    </div>
                    <div className="absolute bottom-5 right-5 flex h-12 w-12 items-center justify-center rounded-2xl bg-white/80 text-[#6d63ff] shadow-lg shadow-white/20">
                      <FlaskConical className="h-5 w-5" />
                    </div>
                  </div>
                  <div className="space-y-3 p-5">
                    <h3 className="text-xl font-black leading-snug text-[#151827]">{post.title}</h3>
                    <p className="text-sm leading-6 text-[#5f6884]">{post.excerpt}</p>
                    <div className="flex items-center justify-between gap-3 pt-2 text-sm font-semibold text-[#7d86a4]">
                      <span>{post.readTime}</span>
                      <Link to="/tro-giup" className="inline-flex items-center gap-1 text-[#6d63ff]">
                        Đọc thêm <ArrowRight className="h-4 w-4" />
                      </Link>
                    </div>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>
    </main>
  );
}

export { BlogPage };
