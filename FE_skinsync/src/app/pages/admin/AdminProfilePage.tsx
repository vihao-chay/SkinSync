import { useState, useRef } from "react";
import { AdminLayout } from "../../components/AdminSidebar";
import { Camera, Save, Eye, EyeOff, User, Mail, Phone, Lock, CheckCircle2 } from "lucide-react";
import { ImageWithFallback } from "../../components/figma/ImageWithFallback";

export function AdminProfilePage() {
  const [avatarUrl, setAvatarUrl] = useState(
    "https://images.unsplash.com/photo-1739208885492-6e202b6f86f0?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx3b21hbiUyMHBvcnRyYWl0JTIwYXZhdGFyJTIwcHJvZmlsZSUyMHBob3RvJTIwYmVhdXR5fGVufDF8fHx8MTc3NDAxNjIwOHww&ixlib=rb-4.1.0&q=80&w=400"
  );
  const avatarInputRef = useRef<HTMLInputElement>(null);

  const [name, setName]       = useState("Admin Chính");
  const [email, setEmail]     = useState("admin@skincare.ai");
  const [phone, setPhone]     = useState("0901 234 567");
  const [currentPw, setCurrentPw]   = useState("");
  const [newPw, setNewPw]           = useState("");
  const [confirmPw, setConfirmPw]   = useState("");

  const [showCurrentPw, setShowCurrentPw]   = useState(false);
  const [showNewPw, setShowNewPw]           = useState(false);
  const [showConfirmPw, setShowConfirmPw]   = useState(false);

  const [saved, setSaved] = useState(false);
  const [pwSaved, setPwSaved] = useState(false);

  const handleAvatarChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) setAvatarUrl(URL.createObjectURL(file));
  };

  const handleSaveInfo = (e: React.FormEvent) => {
    e.preventDefault();
    setSaved(true);
    setTimeout(() => setSaved(false), 2500);
  };

  const handleSavePassword = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPw || newPw !== confirmPw) return;
    setPwSaved(true);
    setCurrentPw(""); setNewPw(""); setConfirmPw("");
    setTimeout(() => setPwSaved(false), 2500);
  };

  const pwMatch = newPw && confirmPw && newPw === confirmPw;

  return (
    <AdminLayout title="Hồ Sơ Admin">
      <div className="max-w-2xl mx-auto flex flex-col gap-6 py-2">

        {/* ── Avatar Card ── */}
        <div className="bg-white rounded-2xl border border-[#ede8e0] shadow-sm p-6 flex items-center gap-6">
          <div className="relative flex-shrink-0">
            <div className="w-20 h-20 rounded-full overflow-hidden ring-4 ring-[#c4a882]/30">
              <ImageWithFallback
                src={avatarUrl}
                alt="Admin Avatar"
                className="w-full h-full object-cover object-top"
              />
            </div>
            <input
              ref={avatarInputRef}
              type="file"
              accept="image/*"
              className="hidden"
              onChange={handleAvatarChange}
            />
            <button
              onClick={() => avatarInputRef.current?.click()}
              className="absolute -bottom-1 -right-1 w-7 h-7 rounded-full bg-gradient-to-br from-[#c4a882] to-[#8c6e52] border-2 border-white flex items-center justify-center shadow-md hover:opacity-90 transition-opacity"
            >
              <Camera className="w-3 h-3 text-white" />
            </button>
          </div>
          <div>
            <p className="text-[#2a2a2a] mb-0.5">{name}</p>
            <p className="text-sm text-[#9ca3af]">{email}</p>
            <button
              onClick={() => avatarInputRef.current?.click()}
              className="mt-2 text-xs text-[#c4a882] hover:text-[#8c6e52] transition-colors"
            >
              Đổi ảnh đại diện
            </button>
          </div>
        </div>

        {/* ── Thông Tin Cá Nhân ── */}
        <form onSubmit={handleSaveInfo} className="bg-white rounded-2xl border border-[#ede8e0] shadow-sm p-6 flex flex-col gap-5">
          <div className="flex items-center justify-between">
            <h2 className="text-[#2a2a2a]">Thông Tin Cá Nhân</h2>
            {saved && (
              <span className="flex items-center gap-1.5 text-xs text-emerald-600">
                <CheckCircle2 className="w-3.5 h-3.5" /> Đã lưu
              </span>
            )}
          </div>

          {/* Name */}
          <div className="flex flex-col gap-1.5">
            <label className="text-xs text-[#6b7280] flex items-center gap-1.5">
              <User className="w-3.5 h-3.5" /> Họ và Tên
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl border border-[#e8d5b7] bg-[#fdf8f2] text-sm text-[#2a2a2a] focus:outline-none focus:ring-2 focus:ring-[#c4a882]/40 focus:border-[#c4a882] transition-all"
              placeholder="Nhập họ và tên"
            />
          </div>

          {/* Email */}
          <div className="flex flex-col gap-1.5">
            <label className="text-xs text-[#6b7280] flex items-center gap-1.5">
              <Mail className="w-3.5 h-3.5" /> Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl border border-[#e8d5b7] bg-[#fdf8f2] text-sm text-[#2a2a2a] focus:outline-none focus:ring-2 focus:ring-[#c4a882]/40 focus:border-[#c4a882] transition-all"
              placeholder="Nhập email"
            />
          </div>

          {/* Phone */}
          <div className="flex flex-col gap-1.5">
            <label className="text-xs text-[#6b7280] flex items-center gap-1.5">
              <Phone className="w-3.5 h-3.5" /> Số Điện Thoại
            </label>
            <input
              type="tel"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className="w-full px-4 py-2.5 rounded-xl border border-[#e8d5b7] bg-[#fdf8f2] text-sm text-[#2a2a2a] focus:outline-none focus:ring-2 focus:ring-[#c4a882]/40 focus:border-[#c4a882] transition-all"
              placeholder="Nhập số điện thoại"
            />
          </div>

          <button
            type="submit"
            className="self-end flex items-center gap-2 px-5 py-2.5 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white text-sm shadow-sm hover:opacity-90 transition-opacity"
          >
            <Save className="w-4 h-4" />
            Lưu Thay Đổi
          </button>
        </form>

        {/* ── Đổi Mật Khẩu ── */}
        <form onSubmit={handleSavePassword} className="bg-white rounded-2xl border border-[#ede8e0] shadow-sm p-6 flex flex-col gap-5">
          <div className="flex items-center justify-between">
            <h2 className="text-[#2a2a2a]">Đổi Mật Khẩu</h2>
            {pwSaved && (
              <span className="flex items-center gap-1.5 text-xs text-emerald-600">
                <CheckCircle2 className="w-3.5 h-3.5" /> Đã cập nhật
              </span>
            )}
          </div>

          {/* Current password */}
          <div className="flex flex-col gap-1.5">
            <label className="text-xs text-[#6b7280] flex items-center gap-1.5">
              <Lock className="w-3.5 h-3.5" /> Mật Khẩu Hiện Tại
            </label>
            <div className="relative">
              <input
                type={showCurrentPw ? "text" : "password"}
                value={currentPw}
                onChange={(e) => setCurrentPw(e.target.value)}
                className="w-full px-4 py-2.5 pr-10 rounded-xl border border-[#e8d5b7] bg-[#fdf8f2] text-sm text-[#2a2a2a] focus:outline-none focus:ring-2 focus:ring-[#c4a882]/40 focus:border-[#c4a882] transition-all"
                placeholder="••••••••"
              />
              <button
                type="button"
                onClick={() => setShowCurrentPw(!showCurrentPw)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-[#9ca3af] hover:text-[#6b7280] transition-colors"
              >
                {showCurrentPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          {/* New password */}
          <div className="flex flex-col gap-1.5">
            <label className="text-xs text-[#6b7280] flex items-center gap-1.5">
              <Lock className="w-3.5 h-3.5" /> Mật Khẩu Mới
            </label>
            <div className="relative">
              <input
                type={showNewPw ? "text" : "password"}
                value={newPw}
                onChange={(e) => setNewPw(e.target.value)}
                className="w-full px-4 py-2.5 pr-10 rounded-xl border border-[#e8d5b7] bg-[#fdf8f2] text-sm text-[#2a2a2a] focus:outline-none focus:ring-2 focus:ring-[#c4a882]/40 focus:border-[#c4a882] transition-all"
                placeholder="••••••••"
              />
              <button
                type="button"
                onClick={() => setShowNewPw(!showNewPw)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-[#9ca3af] hover:text-[#6b7280] transition-colors"
              >
                {showNewPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
          </div>

          {/* Confirm password */}
          <div className="flex flex-col gap-1.5">
            <label className="text-xs text-[#6b7280] flex items-center gap-1.5">
              <Lock className="w-3.5 h-3.5" /> Xác Nhận Mật Khẩu Mới
            </label>
            <div className="relative">
              <input
                type={showConfirmPw ? "text" : "password"}
                value={confirmPw}
                onChange={(e) => setConfirmPw(e.target.value)}
                className={`w-full px-4 py-2.5 pr-10 rounded-xl border bg-[#fdf8f2] text-sm text-[#2a2a2a] focus:outline-none focus:ring-2 transition-all ${
                  confirmPw && !pwMatch
                    ? "border-red-300 focus:ring-red-200 focus:border-red-400"
                    : pwMatch
                    ? "border-emerald-300 focus:ring-emerald-200 focus:border-emerald-400"
                    : "border-[#e8d5b7] focus:ring-[#c4a882]/40 focus:border-[#c4a882]"
                }`}
                placeholder="••••••••"
              />
              <button
                type="button"
                onClick={() => setShowConfirmPw(!showConfirmPw)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-[#9ca3af] hover:text-[#6b7280] transition-colors"
              >
                {showConfirmPw ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              </button>
            </div>
            {confirmPw && !pwMatch && (
              <p className="text-xs text-red-500">Mật khẩu xác nhận không khớp.</p>
            )}
            {pwMatch && (
              <p className="text-xs text-emerald-600 flex items-center gap-1">
                <CheckCircle2 className="w-3 h-3" /> Mật khẩu khớp
              </p>
            )}
          </div>

          <button
            type="submit"
            disabled={!currentPw || !pwMatch}
            className="self-end flex items-center gap-2 px-5 py-2.5 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white text-sm shadow-sm hover:opacity-90 transition-opacity disabled:opacity-40 disabled:cursor-not-allowed"
          >
            <Save className="w-4 h-4" />
            Cập Nhật Mật Khẩu
          </button>
        </form>

      </div>
    </AdminLayout>
  );
}
