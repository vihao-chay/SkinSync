import { useState, useRef, useEffect } from "react";
import { Link, useLocation, useNavigate } from "react-router";
import {
  LayoutDashboard,
  Package,
  Users,
  Bot,
  ChevronRight,
  LogOut,
  UserCircle,
} from "lucide-react";
import { ImageWithFallback } from "./figma/ImageWithFallback";
import { useAuth } from "../contexts/AuthContext";
import { resolveUserAvatar } from "../utils/avatar";
import { BrandLogo } from "./BrandLogo";

const sidebarLinks = [
  { label: "Tổng Quan",  to: "/admin",             icon: <LayoutDashboard className="w-4 h-4" /> },
  { label: "Người Dùng", to: "/admin/users",        icon: <Users className="w-4 h-4" /> },
  { label: "Sản Phẩm",   to: "/admin/products",     icon: <Package className="w-4 h-4" /> },
  { label: "Cấu Hình AI",to: "/admin/ai-config",    icon: <Bot className="w-4 h-4" /> },
];

interface AdminLayoutProps {
  children: React.ReactNode;
  title?: string;
}

export function AdminLayout({ children, title }: AdminLayoutProps) {
  const location  = useLocation();
  const navigate  = useNavigate();
  const { user, logout } = useAuth();
  const [showPopup, setShowPopup] = useState(false);
  const popupRef  = useRef<HTMLDivElement>(null);

  const isActive = (path: string) =>
    path === "/admin"
      ? location.pathname === "/admin"
      : location.pathname.startsWith(path);

  // Close popup when clicking outside
  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (popupRef.current && !popupRef.current.contains(e.target as Node)) {
        setShowPopup(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const handleLogout = async () => {
    await logout();
    setShowPopup(false);
    navigate("/login", { replace: true });
  };

  const displayName = user?.fullName ?? "Admin";
  const displayEmail = user?.email ?? "";
  const avatarUrl = resolveUserAvatar(user);

  return (
    <div className="min-h-screen bg-[#f4f5f7] flex">
      {/* ── Sidebar ── */}
      <aside className="w-60 flex-shrink-0 bg-[#1c1208] flex flex-col min-h-screen fixed left-0 top-0 bottom-0 z-40">
        {/* Logo */}
        <div className="px-5 py-5 border-b border-white/8">
          <Link to="/" className="flex items-center gap-2.5">
            <BrandLogo className="w-9 h-9 rounded-xl border border-white/15 shadow-lg shadow-[#c4a882]/20" />
            <div>
              <div className="text-white text-sm" style={{ fontWeight: 600 }}>SkinSync</div>
              <div className="text-[10px] text-white/40 tracking-wider uppercase">Admin Panel</div>
            </div>
          </Link>
        </div>

        {/* Nav */}
        <nav className="flex-1 px-3 py-4 flex flex-col gap-1">
          <p className="text-[10px] text-white/30 tracking-widest uppercase px-3 mb-2">Điều Hướng</p>
          {sidebarLinks.map((link) => {
            const active = isActive(link.to);
            return (
              <Link
                key={link.to}
                to={link.to}
                className={`flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm transition-all group relative ${
                  active
                    ? "bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white shadow-md shadow-[#c4a882]/25"
                    : "text-white/50 hover:text-white hover:bg-white/8"
                }`}
              >
                <span className={active ? "text-white" : "text-white/40 group-hover:text-white/70"}>
                  {link.icon}
                </span>
                <span>{link.label}</span>
                {active && <ChevronRight className="w-3.5 h-3.5 ml-auto opacity-60" />}
              </Link>
            );
          })}
        </nav>

        {/* Bottom — Avatar + Logout */}
        <div className="px-3 py-4 border-t border-white/8 relative" ref={popupRef}>
          {/* Popup */}
          {showPopup && (
            <div className="absolute bottom-full left-3 right-3 mb-2 bg-[#2a1e0e] border border-white/10 rounded-2xl overflow-hidden shadow-2xl">
              <button
                onClick={() => { navigate("/admin/profile"); setShowPopup(false); }}
                className="w-full flex items-center gap-2.5 px-4 py-3 text-white/70 hover:text-white hover:bg-white/8 transition-all text-sm"
              >
                <UserCircle className="w-4 h-4" />
                Hồ Sơ Của Tôi
              </button>
              <div className="h-px bg-white/8 mx-3" />
              <button
                type="button"
                onClick={handleLogout}
                className="flex items-center gap-2.5 px-4 py-3 text-white/40 hover:text-white/70 hover:bg-white/5 transition-all text-sm"
              >
                <LogOut className="w-4 h-4" />
                Đăng Xuất
              </button>
            </div>
          )}

          {/* Avatar row — clickable */}
          <button
            onClick={() => setShowPopup((v) => !v)}
            className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-xl transition-all group ${
              showPopup ? "bg-white/10" : "hover:bg-white/8"
            }`}
          >
            <div className="w-8 h-8 rounded-full overflow-hidden ring-2 ring-[#c4a882]/40 flex-shrink-0">
              <ImageWithFallback
                src={avatarUrl}
                alt="Admin"
                className="w-full h-full object-cover object-top"
              />
            </div>
            <div className="flex-1 min-w-0 text-left">
              <p className="text-xs text-white truncate" style={{ fontWeight: 500 }}>{displayName}</p>
              <p className="text-[10px] text-white/35 truncate">{displayEmail}</p>
            </div>
            <ChevronRight
              className={`w-3.5 h-3.5 text-white/30 transition-transform ${showPopup ? "-rotate-90" : "rotate-90"}`}
            />
          </button>
        </div>
      </aside>

      {/* ── Main ── */}
      <div className="flex-1 ml-60 flex flex-col min-h-screen">
        {/* Top bar — chỉ còn tiêu đề */}
        <header className="sticky top-0 z-30 bg-white/90 backdrop-blur-xl border-b border-[#e8d5b7]/60 px-8 h-14 flex items-center shadow-sm shadow-black/[0.03]">
          {title && (
            <h1 className="text-[#1a1a2e]" style={{ fontWeight: 600, fontSize: "1.05rem" }}>
              {title}
            </h1>
          )}
        </header>

        {/* Content */}
        <main className="flex-1 px-8 py-7">
          {children}
        </main>
      </div>
    </div>
  );
}
