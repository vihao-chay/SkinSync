import { Link, useLocation, useNavigate } from "react-router";
import { User, Bell, ChevronDown, LogOut, ChevronRight } from "lucide-react";
import { useState, useRef, useEffect } from "react";
import { ImageWithFallback } from "./figma/ImageWithFallback";
import { useAuth } from "../contexts/AuthContext";
import { resolveUserAvatar } from "../utils/avatar";
import { BrandLogo } from "./BrandLogo";

export function Navigation() {
  const location = useLocation();
  const navigate = useNavigate();
  const { user, logout } = useAuth();
  const [resultsOpen, setResultsOpen] = useState(false);
  const [avatarOpen, setAvatarOpen] = useState(false);
  const avatarRef = useRef<HTMLDivElement>(null);
  const resultsRef = useRef<HTMLDivElement>(null);

  const isActive = (path: string) => location.pathname === path;
  const isResultActive = ["/analysis", "/routine"].includes(location.pathname);

  useEffect(() => {
    const handler = (e: MouseEvent) => {
      if (avatarRef.current && !avatarRef.current.contains(e.target as Node)) {
        setAvatarOpen(false);
      }
      if (resultsRef.current && !resultsRef.current.contains(e.target as Node)) {
        setResultsOpen(false);
      }
    };
    document.addEventListener("mousedown", handler);
    return () => document.removeEventListener("mousedown", handler);
  }, []);

  const navLinks = [
    { label: "Trang Chủ", to: "/" },
    { label: "Khảo Sát", to: "/quiz" },
    {
      label: "Kết Quả",
      to: "/analysis",
      children: [
        { label: "Phân Tích Da", to: "/analysis" },
        { label: "Lộ Trình", to: "/routine" },
      ],
    },
    { label: "Tiến Trình", to: "/progress" },
  ];

  const displayName = user?.fullName ?? "Người dùng";
  const displayEmail = user?.email ?? "";
  const avatarSrc = resolveUserAvatar(user);

  return (
    <nav className="fixed top-0 left-0 right-0 z-50 bg-white/85 backdrop-blur-xl border-b border-[#e8d5b7]/60 shadow-sm shadow-black/[0.04]">
      <div className="max-w-7xl mx-auto px-6 py-0">
        <div className="flex items-center justify-between h-16">

          {/* ── Logo ── */}
          <Link to="/" className="flex items-center gap-2.5 flex-shrink-0">
            <BrandLogo className="w-9 h-9 rounded-xl border border-[#e8d5b7]/70 shadow-sm shadow-[#c4a882]/20" />
            <span className="text-[#1c1008] tracking-tight" style={{ fontWeight: 600, fontSize: "1.05rem" }}>
              SkinSync
            </span>
          </Link>

          {/* ── Nav Links (center) ── */}
          <div className="hidden md:flex items-center gap-1">
            {navLinks.map((link) =>
              link.children ? (
                <div key={link.label} className="relative" ref={resultsRef}>
                  <button
                    onClick={() => setResultsOpen((v) => !v)}
                    className={`flex items-center gap-1 px-4 py-2 rounded-full text-sm transition-all ${
                      isResultActive
                        ? "text-[#8c6e52] bg-[#c4a882]/10"
                        : "text-[#4b5563] hover:text-[#8c6e52] hover:bg-[#c4a882]/8"
                    }`}
                  >
                    {link.label}
                    <ChevronDown
                      className={`w-3.5 h-3.5 transition-transform duration-200 ${resultsOpen ? "rotate-180" : ""}`}
                    />
                  </button>

                  {resultsOpen && (
                    <div className="absolute top-[calc(100%+8px)] left-1/2 -translate-x-1/2 w-48 bg-white/95 backdrop-blur-2xl border border-[#e8d5b7]/80 rounded-2xl shadow-xl shadow-black/8 overflow-hidden py-1.5 animate-in fade-in slide-in-from-top-2 duration-150">
                      {link.children.map((child) => (
                        <Link
                          key={child.to}
                          to={child.to}
                          onClick={() => setResultsOpen(false)}
                          className={`flex items-center justify-between px-4 py-2.5 text-sm transition-colors ${
                            isActive(child.to)
                              ? "text-[#8c6e52] bg-[#c4a882]/8"
                              : "text-[#4b5563] hover:text-[#8c6e52] hover:bg-[#c4a882]/6"
                          }`}
                        >
                          {child.label}
                          <ChevronRight className="w-3.5 h-3.5 opacity-40" />
                        </Link>
                      ))}
                    </div>
                  )}
                </div>
              ) : (
                <Link
                  key={link.label}
                  to={link.to}
                  className={`px-4 py-2 rounded-full text-sm transition-all ${
                    isActive(link.to)
                      ? "text-[#8c6e52] bg-[#c4a882]/10"
                      : "text-[#4b5563] hover:text-[#8c6e52] hover:bg-[#c4a882]/8"
                  }`}
                >
                  {link.label}
                </Link>
              )
            )}
          </div>

          {/* ── Right Side ── */}
          <div className="flex items-center gap-2">
            <button className="relative p-2.5 rounded-full hover:bg-[#f5f0e8] transition-colors">
              <Bell className="w-[18px] h-[18px] text-[#6b7280]" />
              <span className="absolute top-2 right-2 w-2 h-2 rounded-full bg-[#c4a882] ring-[1.5px] ring-white" />
            </button>

            {/* ── Avatar Dropdown ── */}
            <div className="relative" ref={avatarRef}>
              <button
                onClick={() => setAvatarOpen((v) => !v)}
                className={`flex items-center gap-2 pl-1 pr-3 py-1 rounded-full border transition-all duration-200 ${
                  avatarOpen
                    ? "border-[#c4a882]/40 bg-[#c4a882]/6 shadow-sm"
                    : "border-transparent hover:border-[#e8d5b7] hover:bg-[#faf7f2]"
                }`}
              >
                <div className="relative w-8 h-8 rounded-full overflow-hidden ring-2 ring-white shadow-sm flex-shrink-0">
                  <ImageWithFallback
                    src={avatarSrc}
                    alt="Avatar"
                    className="w-full h-full object-cover object-top"
                  />
                  <span className="absolute bottom-0 right-0 w-2.5 h-2.5 rounded-full bg-emerald-400 ring-[1.5px] ring-white" />
                </div>
                <ChevronDown
                  className={`w-3.5 h-3.5 text-[#6b7280] transition-transform duration-200 ${
                    avatarOpen ? "rotate-180" : ""
                  }`}
                />
              </button>

              {avatarOpen && (
                <div
                  className="absolute top-[calc(100%+10px)] right-0 w-56 animate-in fade-in slide-in-from-top-2 duration-150"
                  style={{ filter: "drop-shadow(0 8px 24px rgba(0,0,0,0.10))" }}
                >
                  <div className="bg-white/96 backdrop-blur-2xl border border-[#e8d5b7]/80 rounded-2xl overflow-hidden"
                    style={{ boxShadow: "0 4px 32px rgba(196,168,130,0.10), 0 1px 4px rgba(0,0,0,0.06)" }}
                  >
                    <div className="flex items-center gap-3 px-4 pt-4 pb-3.5 border-b border-[#f5f0e8]">
                      <div className="w-10 h-10 rounded-xl overflow-hidden ring-2 ring-[#c4a882]/20 flex-shrink-0">
                        <ImageWithFallback
                          src={avatarSrc}
                          alt="Avatar"
                          className="w-full h-full object-cover object-top"
                        />
                      </div>
                      <div className="min-w-0">
                        <p className="text-sm text-[#1c1008] truncate" style={{ fontWeight: 600 }}>
                          {displayName}
                        </p>
                        <p className="text-xs text-[#9ca3af] truncate">{displayEmail}</p>
                      </div>
                    </div>

                    <div className="py-1.5">
                      <Link
                        to="/profile"
                        onClick={() => setAvatarOpen(false)}
                        className="flex items-center gap-3 px-4 py-2.5 text-sm text-[#374151] hover:text-[#8c6e52] hover:bg-[#c4a882]/6 transition-colors"
                      >
                        <div className="w-8 h-8 rounded-xl bg-gradient-to-br from-[#f5f0e8] to-[#f5e6d3] flex items-center justify-center flex-shrink-0">
                          <User className="w-3.5 h-3.5 text-[#8c6e52]" />
                        </div>
                        Hồ Sơ
                      </Link>

                      <div className="mx-4 my-1 h-px bg-[#f5f0e8]" />

                      <button
                        onClick={async () => {
                          setAvatarOpen(false);
                          await logout();
                          navigate("/login", { replace: true });
                        }}
                        className="w-full flex items-center gap-3 px-4 py-2.5 text-sm text-[#f43f5e]/80 hover:text-[#f43f5e] hover:bg-[#f43f5e]/5 transition-colors"
                      >
                        <div className="w-8 h-8 rounded-xl bg-[#fef2f4] flex items-center justify-center flex-shrink-0">
                          <LogOut className="w-3.5 h-3.5 text-[#f43f5e]" />
                        </div>
                        Đăng Xuất
                      </button>
                    </div>

                    <div className="h-0.5 bg-gradient-to-r from-[#c4a882]/40 via-[#8c6e52]/30 to-[#e8d5b7]/50" />
                  </div>
                </div>
              )}
            </div>
          </div>

        </div>
      </div>
    </nav>
  );
}
