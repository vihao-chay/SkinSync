import { useEffect, useRef, useState } from "react";
import { Link } from "react-router";
import { AdminLayout } from "../../components/AdminSidebar";
import { Camera, Save, Eye, EyeOff, User, Mail, Phone, Lock, CheckCircle2, AlertCircle, ShieldCheck } from "lucide-react";
import { ImageWithFallback } from "../../components/figma/ImageWithFallback";
import { useAuth } from "../../contexts/AuthContext";
import { changePasswordApi, getAuthProvider, updateAvatarApi, updateProfileApi } from "../../services/authService";
import { resolveUserAvatar } from "../../utils/avatar";

function StrengthBar({ password }: { password: string }) {
  const getStrength = () => {
    if (!password) return 0;
    let s = 0;
    if (password.length >= 8) s++;
    if (/[A-Z]/.test(password)) s++;
    if (/[0-9]/.test(password)) s++;
    if (/[^A-Za-z0-9]/.test(password)) s++;
    return s;
  };

  const strength = getStrength();
  const labels = ["", "Yếu", "Trung bình", "Mạnh", "Rất mạnh"];
  const colors = ["", "#ef4444", "#f59e0b", "#10b981", "#059669"];
  if (!password) return null;

  return (
    <div className="mt-2">
      <div className="flex gap-1 mb-1">
        {[1, 2, 3, 4].map((i) => (
          <div
            key={i}
            className="flex-1 h-1 rounded-full transition-all duration-300"
            style={{ backgroundColor: i <= strength ? colors[strength] : "#e5e7eb" }}
          />
        ))}
      </div>
      <p className="text-xs" style={{ color: colors[strength] }}>
        Độ mạnh: {labels[strength]}
      </p>
    </div>
  );
}

function PasswordGuide({ password }: { password: string }) {
  const rules = [
    { label: "Ít nhất 8 ký tự", valid: password.length >= 8 },
    { label: "Có chữ in hoa (A-Z)", valid: /[A-Z]/.test(password) },
    { label: "Có chữ thường (a-z)", valid: /[a-z]/.test(password) },
    { label: "Có số (0-9)", valid: /[0-9]/.test(password) },
    { label: "Có ký tự đặc biệt (!@#$...)", valid: /[^A-Za-z0-9]/.test(password) },
  ];

  return (
    <div className="mt-2 rounded-xl border border-[#efe7dc] bg-[#fdf8f2] px-3.5 py-3">
      <p className="text-xs text-[#7c6b58] mb-2">Mật khẩu mạnh nên có:</p>
      <ul className="space-y-1.5">
        {rules.map((rule) => (
          <li key={rule.label} className="flex items-center gap-2">
            <span
              className={`inline-block w-1.5 h-1.5 rounded-full ${rule.valid ? "bg-emerald-500" : "bg-[#cbbca9]"}`}
            />
            <span className={`text-xs ${rule.valid ? "text-emerald-700" : "text-[#9b8d7a]"}`}>
              {rule.label}
            </span>
          </li>
        ))}
      </ul>
    </div>
  );
}

export function AdminProfilePage() {
  const { user, isInitializing, refreshCurrentUser, setCurrentUser } = useAuth();
  const isGoogleUser = getAuthProvider() === "google";
  const [avatarUrl, setAvatarUrl] = useState(resolveUserAvatar(user));
  const avatarInputRef = useRef<HTMLInputElement>(null);

  const [name, setName] = useState(user?.fullName ?? "");
  const [email, setEmail] = useState(user?.email ?? "");
  const [phone, setPhone] = useState(user?.phone ?? "");
  const [currentPw, setCurrentPw] = useState("");
  const [newPw, setNewPw] = useState("");
  const [confirmPw, setConfirmPw] = useState("");

  const [showCurrentPw, setShowCurrentPw] = useState(false);
  const [showNewPw, setShowNewPw] = useState(false);
  const [showConfirmPw, setShowConfirmPw] = useState(false);

  const [saved, setSaved] = useState(false);
  const [pwSaved, setPwSaved] = useState(false);
  const [profileSaving, setProfileSaving] = useState(false);
  const [avatarSaving, setAvatarSaving] = useState(false);
  const [pwSaving, setPwSaving] = useState(false);
  const [infoError, setInfoError] = useState<string | null>(null);
  const [avatarError, setAvatarError] = useState<string | null>(null);
  const [pwError, setPwError] = useState("");

  useEffect(() => {
    setName(user?.fullName ?? "");
    setEmail(user?.email ?? "");
    setPhone(user?.phone ?? "");
    setAvatarUrl(resolveUserAvatar(user));
  }, [user]);

  useEffect(() => {
    void refreshCurrentUser();
  }, [refreshCurrentUser]);

  const handleAvatarChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) {
      return;
    }

    setAvatarError(null);
    setAvatarSaving(true);

    try {
      const result = await updateAvatarApi(file);
      if (!result.success || !result.content) {
        setAvatarError(result.message || "Không thể cập nhật ảnh đại diện.");
        return;
      }

      setCurrentUser(result.content);
      setAvatarUrl(resolveUserAvatar(result.content));
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    } finally {
      setAvatarSaving(false);
      e.target.value = "";
    }
  };

  const handleSaveInfo = async (e: React.FormEvent) => {
    e.preventDefault();
    setInfoError(null);

    if (!name.trim()) {
      setInfoError("Vui lòng nhập họ và tên.");
      return;
    }

    setProfileSaving(true);

    try {
      const result = await updateProfileApi(name.trim(), phone.trim());
      if (!result.success || !result.content) {
        setInfoError(result.message || "Không thể cập nhật thông tin tài khoản.");
        return;
      }

      setCurrentUser(result.content);
      await refreshCurrentUser();
      setSaved(true);
      setTimeout(() => setSaved(false), 2500);
    } finally {
      setProfileSaving(false);
    }
  };

  const handleSavePassword = async (e: React.FormEvent) => {
    e.preventDefault();
    setPwError("");
    if (!canSubmitPw) {
      return;
    }

    setPwSaving(true);

    try {
      const result = await changePasswordApi(currentPw, newPw);
      if (!result.success) {
        setPwError(result.message || "Không thể đổi mật khẩu. Vui lòng thử lại.");
        return;
      }

      setPwSaved(true);
      setCurrentPw("");
      setNewPw("");
      setConfirmPw("");
      setTimeout(() => setPwSaved(false), 2500);
    } finally {
      setPwSaving(false);
    }
  };

  const pwMatch = newPw && confirmPw && newPw === confirmPw;
  const canSubmitPw = currentPw && newPw.length >= 8 && !!pwMatch;

  const showInitialSkeleton = isInitializing && !user;

  if (showInitialSkeleton) {
    return (
      <AdminLayout title="Hồ Sơ Admin">
        <div className="max-w-2xl mx-auto flex flex-col gap-6 py-2 animate-pulse">
          <div className="bg-white rounded-2xl border border-[#ede8e0] shadow-sm p-6 flex items-center gap-6">
            <div className="w-20 h-20 rounded-full bg-[#f1e9de]" />
            <div className="flex-1">
              <div className="h-4 w-40 rounded bg-[#f1e9de]" />
              <div className="h-3 w-56 rounded bg-[#f3eee7] mt-3" />
              <div className="h-3 w-24 rounded bg-[#f3eee7] mt-4" />
            </div>
          </div>

          <div className="bg-white rounded-2xl border border-[#ede8e0] shadow-sm p-6 flex flex-col gap-5">
            <div className="h-5 w-36 rounded bg-[#f1e9de]" />
            <div className="space-y-2">
              <div className="h-3 w-24 rounded bg-[#f3eee7]" />
              <div className="h-10 w-full rounded-xl bg-[#f7f3ec]" />
            </div>
            <div className="space-y-2">
              <div className="h-3 w-16 rounded bg-[#f3eee7]" />
              <div className="h-10 w-full rounded-xl bg-[#f7f3ec]" />
            </div>
            <div className="space-y-2">
              <div className="h-3 w-28 rounded bg-[#f3eee7]" />
              <div className="h-10 w-full rounded-xl bg-[#f7f3ec]" />
            </div>
            <div className="h-10 w-36 rounded-xl bg-[#f1e9de] self-end" />
          </div>

          <div className="bg-white rounded-2xl border border-[#ede8e0] shadow-sm p-6 flex flex-col gap-5">
            <div className="h-5 w-32 rounded bg-[#f1e9de]" />
            <div className="space-y-2">
              <div className="h-3 w-32 rounded bg-[#f3eee7]" />
              <div className="h-10 w-full rounded-xl bg-[#f7f3ec]" />
            </div>
            <div className="space-y-2">
              <div className="h-3 w-24 rounded bg-[#f3eee7]" />
              <div className="h-10 w-full rounded-xl bg-[#f7f3ec]" />
            </div>
            <div className="space-y-2">
              <div className="h-3 w-44 rounded bg-[#f3eee7]" />
              <div className="h-10 w-full rounded-xl bg-[#f7f3ec]" />
            </div>
            <div className="h-10 w-44 rounded-xl bg-[#f1e9de] self-end" />
          </div>
        </div>
      </AdminLayout>
    );
  }

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
              disabled={avatarSaving}
              className="absolute -bottom-1 -right-1 w-7 h-7 rounded-full bg-gradient-to-br from-[#c4a882] to-[#8c6e52] border-2 border-white flex items-center justify-center shadow-md hover:opacity-90 transition-opacity"
            >
              {avatarSaving ? (
                <div className="w-3 h-3 border border-white/40 border-t-white rounded-full animate-spin" />
              ) : (
                <Camera className="w-3 h-3 text-white" />
              )}
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
            {avatarError && <p className="mt-2 text-xs text-red-500">{avatarError}</p>}
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
              readOnly
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

          {infoError && <p className="text-xs text-red-500">{infoError}</p>}

          <button
            type="submit"
            disabled={profileSaving}
            className="self-end flex items-center gap-2 px-5 py-2.5 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white text-sm shadow-sm hover:opacity-90 transition-opacity disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Save className="w-4 h-4" />
            {profileSaving ? "Đang lưu..." : "Lưu Thay Đổi"}
          </button>
        </form>

        {!isGoogleUser && (
        <>
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
            <div className="text-right">
              <Link
                to="/forgot-password"
                className="text-xs text-[#c4a882] hover:text-[#8c6e52] transition-colors"
              >
                Quên mật khẩu?
              </Link>
            </div>
          </div>

          {/* New password */}
          <div className="flex flex-col gap-1.5">
            <PasswordGuide password={newPw} />
            <label className="text-xs text-[#6b7280] flex items-center gap-1.5">
              <ShieldCheck className="w-3.5 h-3.5" /> Mật Khẩu Mới
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
            <StrengthBar password={newPw} />
          </div>

          {/* Confirm password */}
          <div className="flex flex-col gap-1.5">
            <label className="text-xs text-[#6b7280] flex items-center gap-1.5">
              <ShieldCheck className="w-3.5 h-3.5" /> Xác Nhận Mật Khẩu Mới
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
              <p className="text-xs text-red-500 flex items-center gap-1">
                <AlertCircle className="w-3 h-3" /> Mật khẩu xác nhận không khớp
              </p>
            )}
            {pwMatch && (
              <p className="text-xs text-emerald-600 flex items-center gap-1">
                <CheckCircle2 className="w-3 h-3" /> Mật khẩu khớp
              </p>
            )}
          </div>

          {pwError && (
            <div className="flex items-center gap-2.5 px-4 py-3 rounded-xl bg-red-50 border border-red-100">
              <AlertCircle className="w-4 h-4 text-red-500 flex-shrink-0" />
              <p className="text-sm text-red-600">{pwError}</p>
            </div>
          )}

          <button
            type="submit"
            disabled={!canSubmitPw || pwSaving}
            className="self-end flex items-center gap-2 px-5 py-2.5 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white text-sm shadow-sm hover:opacity-90 transition-opacity disabled:opacity-40 disabled:cursor-not-allowed"
          >
            <Save className="w-4 h-4" />
            {pwSaving ? "Đang cập nhật..." : "Cập Nhật Mật Khẩu"}
          </button>
        </form>
        </>
        )}

      </div>
    </AdminLayout>
  );
}
