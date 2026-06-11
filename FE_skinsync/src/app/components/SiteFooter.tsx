import type { ReactNode } from "react";
import { Link } from "react-router";
import { Facebook, Instagram, ArrowRight } from "lucide-react";

// [CẬP NHẬT]: Khai báo dữ liệu cho 6 cột footer để phần điều hướng và nội dung được tách bạch rõ ràng.
const footerColumns = [
  {
    title: "Về ứng dụng",
    items: [
      { label: "Chu trình chăm sóc da", href: "/quiz" },
      { label: "Nhật ký chăm sóc da", href: "/progress" },
      { label: "Đặt lịch với chuyên gia", href: "/tro-giup" },
      { label: "Bảo mật thông tin", href: "/chinh-sach-bao-mat" },
      { label: "Câu hỏi thường gặp", href: "/tro-giup" },
    ],
  },
  {
    title: "Về chúng tôi",
    items: [
      { label: "Giới thiệu về chúng tôi", href: "#features" },
      { label: "Nghiệp vụ da liễu", href: "/blog" },
      { label: "Cộng đồng SkinSync", href: "/tro-giup" },
      { label: "Liên hệ", href: "/tro-giup" },
    ],
  },
  {
    title: "Insight từ SkinSync",
    items: [
      { label: "Chăm sóc da 101", href: "/blog" },
      { label: "Tra cứu sản phẩm", href: "/quiz" },
      { label: "Tư vấn chăm sóc da", href: "/tro-giup" },
      { label: "Trung tâm hỗ trợ và trợ giúp", href: "/tro-giup" },
    ],
  },
  {
    title: "Chính sách và điều khoản",
    items: [
      { label: "Chính sách bảo mật", href: "/chinh-sach-bao-mat" },
      { label: "Điều khoản sử dụng", href: "/dieu-khoan-su-dung" },
    ],
  },
  {
    title: "Công nghệ của SkinSync",
    items: [
      { label: "Computer Vision AI", href: "#features" },
      { label: "Machine Learning & Generative AI", href: "#features" },
    ],
  },
];

function FooterLink({ href, children }: { href: string; children: ReactNode }) {
  return href.startsWith("/") ? (
    <Link to={href} className="inline-flex items-center gap-2 transition hover:text-[#6d63ff]">
      {children}
      <ArrowRight className="h-3.5 w-3.5" />
    </Link>
  ) : (
    <a href={href} className="inline-flex items-center gap-2 transition hover:text-[#6d63ff]">
      {children}
      <ArrowRight className="h-3.5 w-3.5" />
    </a>
  );
}

function TikTokIcon() {
  return (
    <svg viewBox="0 0 24 24" aria-hidden="true" className="h-4 w-4 fill-current">
      <path d="M16.5 3c.5 2.8 2.1 4.5 4.5 4.8v3.2c-1.6.1-3.2-.4-4.5-1.3v6.4c0 3.7-3 6.7-6.7 6.7S3 19.8 3 16.1s3-6.7 6.7-6.7c.4 0 .8 0 1.2.1v3.4a3.2 3.2 0 0 0-1.2-.2 3.3 3.3 0 1 0 3.3 3.3V3h3.5Z" />
    </svg>
  );
}

// [CẬP NHẬT]: Tạo Footer 6 cột với nền sáng tím nhạt, link route thật và copyright căn giữa ở đáy.
function Footer() {
  return (
    <footer className="border-t border-skin-border bg-[linear-gradient(180deg,#ffffff_0%,#fbf8f2_100%)] px-5">
      <div className="mx-auto max-w-7xl py-14">
        <div className="mb-10 flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div className="flex items-center gap-3">
            <span className="flex h-11 w-11 items-center justify-center rounded-full bg-[#C2A67D] text-sm font-black text-white shadow-soft-gold">
              SS
            </span>
            <div>
              <p className="font-serif text-sm font-semibold uppercase tracking-[0.22em] text-skin-textMain">SKINSYNC</p>
              <p className="mt-1 max-w-xl text-sm leading-6 text-skin-textMuted">
                Nền tảng AI skincare giúp cá nhân hóa lộ trình, giải thích thành phần và đồng hành cùng làn da của bạn.
              </p>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-8 text-sm text-skin-textMuted md:grid-cols-6">
          {footerColumns.map((column) => (
            <div key={column.title} className="space-y-4">
              <h3 className="font-serif text-sm font-semibold uppercase tracking-[0.18em] text-skin-textMain">
                {column.title}
              </h3>
              <ul className="space-y-3">
                {column.items.map((item) => (
                  <li key={item.label}>
                    <FooterLink href={item.href}>{item.label}</FooterLink>
                  </li>
                ))}
              </ul>
            </div>
          ))}

          <div className="space-y-4">
            <h3 className="font-serif text-sm font-semibold uppercase tracking-[0.18em] text-skin-textMain">
              Kết nối với chúng tôi
            </h3>
            <div className="space-y-3">
              <a
                href="https://facebook.com"
                target="_blank"
                rel="noreferrer"
                className="flex items-center gap-3 transition hover:text-skin-gold"
              >
                <Facebook className="h-4 w-4" />
                <span>Facebook</span>
              </a>
              <a
                href="https://instagram.com"
                target="_blank"
                rel="noreferrer"
                className="flex items-center gap-3 transition hover:text-skin-gold"
              >
                <Instagram className="h-4 w-4" />
                <span>Instagram</span>
              </a>
              <a
                href="https://www.tiktok.com"
                target="_blank"
                rel="noreferrer"
                className="flex items-center gap-3 transition hover:text-skin-gold"
              >
                <TikTokIcon />
                <span>Tiktok</span>
              </a>
            </div>
          </div>
        </div>

        {/* [CẬP NHẬT]: Thêm đường kẻ mảnh và dòng bản quyền căn giữa ở đáy footer. */}
        <div className="mt-12 border-t border-skin-border pt-5 text-center text-sm text-skin-textMuted">
          Copyright @ 2026 by SkinSync. All Rights Reserved.
        </div>
      </div>
    </footer>
  );
}

export { Footer };
