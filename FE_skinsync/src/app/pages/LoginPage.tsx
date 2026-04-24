import { useState } from "react";
import { Link, useNavigate } from "react-router";
import { Eye, EyeOff, Mail, Lock, ArrowRight, Sparkles, User, Phone, CheckCircle, AlertCircle } from "lucide-react";
import { ImageWithFallback } from "../components/figma/ImageWithFallback";
import {
  registerApi,
  startSupabaseOAuth,
  type SocialAuthProvider,
} from "../services/authService";
import { useAuth } from "../contexts/AuthContext";

type AuthMode = "login" | "register";

interface FormErrors {
  name?: string;
  email?: string;
  phone?: string;
  password?: string;
  confirmPassword?: string;
}

export function LoginPage() {
  const navigate = useNavigate();
  const { login } = useAuth();
  const [mode, setMode] = useState<AuthMode>("login");
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmPassword, setShowConfirmPassword] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [name, setName] = useState("");
  const [phone, setPhone] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isGoogleLoading, setIsGoogleLoading] = useState(false);
  const [isFacebookLoading, setIsFacebookLoading] = useState(false);
  const [apiError, setApiError] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [formErrors, setFormErrors] = useState<FormErrors>({});

  // ─── Validation ─────────────────────────────────────────────────────
  function validateForm(): boolean {
    const errors: FormErrors = {};

    if (mode === "register") {
      if (!name.trim()) errors.name = "Vui lòng nhập họ và tên";
      if (name.trim().length > 120) errors.name = "Họ tên không quá 120 ký tự";
    }

    if (!email.trim()) {
      errors.email = "Vui lòng nhập email";
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      errors.email = "Email không hợp lệ";
    }

    if (!password) {
      errors.password = "Vui lòng nhập mật khẩu";
    } else if (mode === "register" && password.length < 8) {
      errors.password = "Mật khẩu phải có ít nhất 8 ký tự";
    }

    if (mode === "register") {
      if (!confirmPassword) {
        errors.confirmPassword = "Vui lòng xác nhận mật khẩu";
      } else if (password !== confirmPassword) {
        errors.confirmPassword = "Mật khẩu xác nhận không khớp";
      }
    }

    setFormErrors(errors);
    return Object.keys(errors).length === 0;
  }

  // ─── Login Handler ──────────────────────────────────────────────────
  async function handleLogin() {
    try {
      const result = await login(email.trim(), password);

      if (result.success) {
        setSuccessMessage("Đăng nhập thành công! Đang chuyển hướng...");
        setApiError(null);

        setTimeout(() => {
          if (result.user?.role === "admin") {
            navigate("/admin", { replace: true });
          } else {
            navigate("/", { replace: true });
          }
        }, 800);
      } else {
        setApiError(result.message || "Email hoặc mật khẩu không đúng.");
      }
    } catch {
      setApiError("Không thể kết nối đến server. Vui lòng thử lại sau.");
    }
  }

  // ─── Register Handler ───────────────────────────────────────────────
  async function handleRegister() {
    try {
      const result = await registerApi(
        name.trim(),
        email.trim(),
        phone.trim(),
        password
      );

      if (result.success) {
        setSuccessMessage("Đăng ký thành công! Vui lòng đăng nhập.");
        setApiError(null);

        // Auto-switch to login mode after short delay
        setTimeout(() => {
          setMode("login");
          setSuccessMessage(null);
          setPassword("");
          setConfirmPassword("");
        }, 1500);
      } else {
        setApiError(result.message || "Đăng ký thất bại. Vui lòng thử lại.");
      }
    } catch {
      setApiError("Không thể kết nối đến server. Vui lòng thử lại sau.");
    }
  }

  // ─── Form Submit ────────────────────────────────────────────────────
  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setApiError(null);
    setSuccessMessage(null);

    if (!validateForm()) return;

    setIsLoading(true);

    if (mode === "login") {
      await handleLogin();
    } else {
      await handleRegister();
    }

    setIsLoading(false);
  }

  // ─── Social Login Handler ───────────────────────────────────────────
  async function handleSocialLogin(provider: SocialAuthProvider) {
    const setLoading = provider === "google" ? setIsGoogleLoading : setIsFacebookLoading;
    setLoading(true);
    setApiError(null);

    try {
      const redirectTo = `${window.location.origin}/auth/callback?provider=${provider}`;
      const authUrl = await startSupabaseOAuth(provider, redirectTo);
      window.location.href = authUrl;
    } catch (err: any) {
      setApiError(err?.message || `Không thể kết nối ${provider === "google" ? "Google" : "Facebook"}. Vui lòng thử lại.`);
      setLoading(false);
    }
  }

  // ─── Mode Switch ────────────────────────────────────────────────────
  function switchMode(newMode: AuthMode) {
    setMode(newMode);
    setApiError(null);
    setSuccessMessage(null);
    setFormErrors({});
    setPassword("");
    setConfirmPassword("");
  }

  return (
    <div className="min-h-screen flex flex-col">
      {/* Minimal Navigation */}
      <nav className="absolute top-0 left-0 right-0 z-50">
        <div className="px-12 py-5">
          <div className="flex items-center justify-between">
            <Link to="/" className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#c4a882] to-[#8c6e52]" />
              <span className="text-white/90 text-lg" style={{ textShadow: "0 1px 4px rgba(0,0,0,0.3)" }}>
                SkinSync
              </span>
            </Link>
          </div>
        </div>
      </nav>

      {/* Split Screen Layout */}
      <div className="flex-1 flex min-h-screen">
        {/* Left Side - Visual */}
        <div className="hidden lg:flex lg:w-1/2 relative overflow-hidden">
          {/* Background Image */}
          <ImageWithFallback
            src="https://images.unsplash.com/photo-1665454486608-5c2f3f5ede35?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxib3RhbmljYWwlMjBsZWF2ZXMlMjBzb2Z0JTIwcGFzdGVsJTIwc2tpbmNhcmUlMjBiYWNrZ3JvdW5kfGVufDF8fHx8MTc3NDAwNjkzNHww&ixlib=rb-4.1.0&q=80&w=1080"
            alt="SkinSync Visual"
            className="absolute inset-0 w-full h-full object-cover object-center"
          />

          {/* Layered Overlays */}
          <div className="absolute inset-0 bg-gradient-to-br from-[#c4a882]/60 via-[#8c6e52]/40 to-[#e8d5b7]/30" />
          <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-black/20" />

          {/* AI Mesh Network overlay */}
          <div className="absolute inset-0 opacity-20">
            <svg width="100%" height="100%" viewBox="0 0 600 800" fill="none">
              {[
                [100, 150], [300, 200], [500, 100], [200, 350],
                [450, 380], [150, 500], [380, 550], [520, 450],
                [80, 680], [320, 700], [480, 650],
              ].map(([x, y], i) => (
                <g key={i}>
                  <circle cx={x} cy={y} r="3" fill="#6ee7f7" opacity="0.8" />
                  {i < 8 && (
                    <line
                      x1={x} y1={y}
                      x2={[100, 300, 500, 200, 450, 150, 380, 520, 80, 320][i + 1] ?? x + 80}
                      y2={[150, 200, 100, 350, 380, 500, 550, 450, 680, 700][i + 1] ?? y + 60}
                      stroke="#6ee7f7" strokeWidth="0.5" opacity="0.4"
                    />
                  )}
                </g>
              ))}
            </svg>
          </div>

          {/* Frosted Glass Cards */}
          <div className="absolute inset-0 flex flex-col justify-between p-12 pointer-events-none">
            {/* Top - Brand Tag */}
            <div className="mt-16">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/15 backdrop-blur-md border border-white/25">
                <Sparkles className="w-4 h-4 text-[#d4f4f4]" />
                <span className="text-white/90 text-sm">Phân Tích Da Bằng AI</span>
              </div>
            </div>

            {/* Middle - Headline */}
            <div className="text-center">
              <h2 className="text-5xl text-white mb-4" style={{ textShadow: "0 2px 20px rgba(0,0,0,0.3)" }}>
                Làn Da Hoàn Hảo
                <br />
                <span className="text-[#d4f4f4]">Bắt Đầu Từ Đây</span>
              </h2>
              <p className="text-white/75 text-lg max-w-xs mx-auto leading-relaxed">
                Lộ trình dưỡng da cá nhân hóa được tạo riêng bởi trí tuệ nhân tạo
              </p>
            </div>

            {/* Bottom - Stats Glass Card */}
            <div className="grid grid-cols-3 gap-3 pb-4">
              {[
                { value: "50K+", label: "Người Dùng" },
                { value: "98%", label: "Hài Lòng" },
                { value: "4.9★", label: "Đánh Giá" },
              ].map((stat) => (
                <div
                  key={stat.label}
                  className="bg-white/10 backdrop-blur-md rounded-2xl p-4 text-center border border-white/20"
                >
                  <div className="text-white text-xl mb-1">{stat.value}</div>
                  <div className="text-white/60 text-xs">{stat.label}</div>
                </div>
              ))}
            </div>
          </div>

          {/* Dewy Skin Preview */}
          <div className="absolute bottom-52 right-8">
            <div className="w-24 h-24 rounded-full overflow-hidden border-2 border-white/40 shadow-2xl">
              <ImageWithFallback
                src="https://images.unsplash.com/photo-1767884139060-458f00bb75b1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxkZXd5JTIwZ2xvd2luZyUyMHNraW4lMjBtYWNybyUyMGNsb3NlJTIwdXAlMjBldGhlcmVhbHxlbnwxfHx8fDE3NzQwMDY5MzN8MA&ixlib=rb-4.1.0&q=80&w=400"
                alt="Glowing Skin"
                className="w-full h-full object-cover"
              />
            </div>
          </div>
        </div>

        {/* Right Side - Form */}
        <div className="w-full lg:w-1/2 flex items-center justify-center bg-white px-6 py-16">
          <div className="w-full max-w-md">
            {/* Mode Toggle */}
            <div className="flex items-center bg-[#f5f5f0] rounded-2xl p-1 mb-8">
              {(["login", "register"] as AuthMode[]).map((m) => (
                <button
                  key={m}
                  onClick={() => switchMode(m)}
                  className={`flex-1 py-3 rounded-xl text-sm transition-all duration-300 ${mode === m
                    ? "bg-white shadow-sm text-[#8c6e52]"
                    : "text-[#6b7280] hover:text-[#2a2a2a]"
                    }`}
                >
                  {m === "login" ? "Đăng Nhập" : "Đăng Ký"}
                </button>
              ))}
            </div>

            {/* Header */}
            <div className="mb-8">
              <h1 className="text-3xl text-[#2a2a2a] mb-2">
                {mode === "login" ? "Chào Mừng Trở Lại 👋" : "Tạo Tài Khoản Mới ✨"}
              </h1>
              <p className="text-[#6b7280] text-sm">
                {mode === "login"
                  ? "Đăng nhập để tiếp tục lộ trình dưỡng da của bạn"
                  : "Bắt đầu hành trình chăm sóc da cá nhân hóa với AI"}
              </p>
            </div>

            {/* Success Message */}
            {successMessage && (
              <div className="mb-4 flex items-center gap-2 px-4 py-3 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-700 text-sm animate-in fade-in duration-300">
                <CheckCircle className="w-4 h-4 shrink-0" />
                <span>{successMessage}</span>
              </div>
            )}

            {/* Error Message */}
            {apiError && (
              <div className="mb-4 flex items-center gap-2 px-4 py-3 rounded-xl bg-red-50 border border-red-200 text-red-600 text-sm animate-in fade-in duration-300">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>{apiError}</span>
              </div>
            )}

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-4">
              {/* Name field (register only) */}
              {mode === "register" && (
                <div className="space-y-1.5">
                  <label className="text-sm text-[#4b5563]">Họ và Tên</label>
                  <div className="relative">
                    <User className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#9ca3af]" />
                    <input
                      type="text"
                      value={name}
                      onChange={(e) => { setName(e.target.value); setFormErrors((p) => ({ ...p, name: undefined })); }}
                      placeholder="Nguyễn Thị Lan"
                      className={`w-full pl-11 pr-4 py-3.5 rounded-xl border ${formErrors.name ? "border-red-400 focus:border-red-400 focus:ring-red-400/10" : "border-[#e5e7eb] focus:border-[#c4a882] focus:ring-[#c4a882]/10"} bg-[#fafafa] text-[#2a2a2a] placeholder-[#d1d5db] focus:outline-none focus:ring-2 transition-all`}
                    />
                  </div>
                  {formErrors.name && <p className="text-xs text-red-500 mt-0.5">{formErrors.name}</p>}
                </div>
              )}

              {/* Email */}
              <div className="space-y-1.5">
                <label className="text-sm text-[#4b5563]">Email</label>
                <div className="relative">
                  <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#9ca3af]" />
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => { setEmail(e.target.value); setFormErrors((p) => ({ ...p, email: undefined })); }}
                    placeholder="hello@example.com"
                    className={`w-full pl-11 pr-4 py-3.5 rounded-xl border ${formErrors.email ? "border-red-400 focus:border-red-400 focus:ring-red-400/10" : "border-[#e5e7eb] focus:border-[#c4a882] focus:ring-[#c4a882]/10"} bg-[#fafafa] text-[#2a2a2a] placeholder-[#d1d5db] focus:outline-none focus:ring-2 transition-all`}
                  />
                </div>
                {formErrors.email && <p className="text-xs text-red-500 mt-0.5">{formErrors.email}</p>}
              </div>

              {/* Phone (register only) */}
              {mode === "register" && (
                <div className="space-y-1.5">
                  <label className="text-sm text-[#4b5563]">Số Điện Thoại</label>
                  <div className="relative">
                    <Phone className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#9ca3af]" />
                    <input
                      type="tel"
                      value={phone}
                      onChange={(e) => setPhone(e.target.value)}
                      placeholder="0901 234 567"
                      className="w-full pl-11 pr-4 py-3.5 rounded-xl border border-[#e5e7eb] bg-[#fafafa] text-[#2a2a2a] placeholder-[#d1d5db] focus:outline-none focus:border-[#c4a882] focus:ring-2 focus:ring-[#c4a882]/10 transition-all"
                    />
                  </div>
                </div>
              )}

              {/* Password */}
              <div className="space-y-1.5">
                <label className="text-sm text-[#4b5563]">Mật Khẩu</label>
                <div className="relative">
                  <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#9ca3af]" />
                  <input
                    type={showPassword ? "text" : "password"}
                    value={password}
                    onChange={(e) => { setPassword(e.target.value); setFormErrors((p) => ({ ...p, password: undefined })); }}
                    placeholder="••••••••"
                    className={`w-full pl-11 pr-11 py-3.5 rounded-xl border ${formErrors.password ? "border-red-400 focus:border-red-400 focus:ring-red-400/10" : "border-[#e5e7eb] focus:border-[#c4a882] focus:ring-[#c4a882]/10"} bg-[#fafafa] text-[#2a2a2a] placeholder-[#d1d5db] focus:outline-none focus:ring-2 transition-all`}
                  />
                  <button
                    type="button"
                    onClick={() => setShowPassword(!showPassword)}
                    className="absolute right-4 top-1/2 -translate-y-1/2 text-[#9ca3af] hover:text-[#c4a882] transition-colors"
                  >
                    {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  </button>
                </div>
                {formErrors.password && <p className="text-xs text-red-500 mt-0.5">{formErrors.password}</p>}
                {mode === "login" && (
                  <div className="text-right">
                    <Link to="/forgot-password" className="text-xs text-[#c4a882] hover:text-[#8c6e52] transition-colors">
                      Quên mật khẩu?
                    </Link>
                  </div>
                )}
              </div>

              {/* Confirm Password (register only) */}
              {mode === "register" && (
                <div className="space-y-1.5">
                  <label className="text-sm text-[#4b5563]">Xác Nhận Mật Khẩu</label>
                  <div className="relative">
                    <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#9ca3af]" />
                    <input
                      type={showConfirmPassword ? "text" : "password"}
                      value={confirmPassword}
                      onChange={(e) => { setConfirmPassword(e.target.value); setFormErrors((p) => ({ ...p, confirmPassword: undefined })); }}
                      placeholder="••••••••"
                      className={`w-full pl-11 pr-11 py-3.5 rounded-xl border ${formErrors.confirmPassword ? "border-red-400 focus:border-red-400 focus:ring-red-400/10" : "border-[#e5e7eb] focus:border-[#c4a882] focus:ring-[#c4a882]/10"} bg-[#fafafa] text-[#2a2a2a] placeholder-[#d1d5db] focus:outline-none focus:ring-2 transition-all`}
                    />
                    <button
                      type="button"
                      onClick={() => setShowConfirmPassword(!showConfirmPassword)}
                      className="absolute right-4 top-1/2 -translate-y-1/2 text-[#9ca3af] hover:text-[#c4a882] transition-colors"
                    >
                      {showConfirmPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                  </div>
                  {formErrors.confirmPassword && <p className="text-xs text-red-500 mt-0.5">{formErrors.confirmPassword}</p>}
                </div>
              )}

              {/* Terms checkbox (register only) */}
              {mode === "register" && (
                <div className="flex items-start gap-3">
                  <input
                    type="checkbox"
                    id="terms"
                    className="mt-0.5 w-4 h-4 rounded border-[#e5e7eb] accent-[#c4a882]"
                  />
                  <label htmlFor="terms" className="text-xs text-[#6b7280] leading-relaxed">
                    Tôi đồng ý với{" "}
                    <a href="#" className="text-[#c4a882] hover:underline">
                      Điều khoản dịch vụ
                    </a>{" "}
                    và{" "}
                    <a href="#" className="text-[#c4a882] hover:underline">
                      Chính sách bảo mật
                    </a>
                  </label>
                </div>
              )}

              {/* CTA Button */}
              <button
                type="submit"
                disabled={isLoading}
                className="w-full py-3.5 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white flex items-center justify-center gap-2 hover:opacity-90 hover:shadow-lg hover:shadow-[#c4a882]/25 transition-all duration-300 disabled:opacity-70 mt-2"
              >
                {isLoading ? (
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                ) : (
                  <>
                    <span>{mode === "login" ? "Đăng Nhập" : "Tạo Tài Khoản"}</span>
                    <ArrowRight className="w-4 h-4" />
                  </>
                )}
              </button>
            </form>

            {/* Divider */}
            <div className="flex items-center gap-4 my-6">
              <div className="flex-1 h-px bg-[#e5e7eb]" />
              <span className="text-sm text-[#9ca3af]">Hoặc</span>
              <div className="flex-1 h-px bg-[#e5e7eb]" />
            </div>

            {/* Social Login - Google */}
            <div className="space-y-3">
              <button
                type="button"
                onClick={() => void handleSocialLogin("google")}
                disabled={isGoogleLoading || isFacebookLoading}
                className="w-full py-3 rounded-xl border border-[#e5e7eb] bg-white hover:bg-[#fafafa] hover:border-[#d1d5db] flex items-center justify-center gap-3 transition-all group shadow-sm disabled:opacity-70"
              >
                {isGoogleLoading ? (
                  <div className="w-5 h-5 border-2 border-[#c4a882]/30 border-t-[#c4a882] rounded-full animate-spin" />
                ) : (
                  <>
                    <svg className="w-5 h-5" viewBox="0 0 24 24">
                      <path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92c-.26 1.37-1.04 2.53-2.21 3.31v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.09z" />
                      <path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" />
                      <path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" />
                      <path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" />
                    </svg>
                    <span className="text-sm text-[#4b5563] group-hover:text-[#2a2a2a] transition-colors">
                      Tiếp tục với Google
                    </span>
                  </>
                )}
              </button>

              <button
                type="button"
                onClick={() => void handleSocialLogin("facebook")}
                disabled={isGoogleLoading || isFacebookLoading}
                className="w-full py-3 rounded-xl border border-[#e5e7eb] bg-white hover:bg-[#f0f4ff] hover:border-[#1877F2]/30 flex items-center justify-center gap-3 transition-all group shadow-sm disabled:opacity-70"
              >
                {isFacebookLoading ? (
                  <div className="w-5 h-5 border-2 border-[#1877F2]/30 border-t-[#1877F2] rounded-full animate-spin" />
                ) : (
                  <>
                    <svg className="w-5 h-5" viewBox="0 0 24 24" fill="none" aria-hidden="true">
                      <rect width="24" height="24" rx="4" fill="#1877F2" />
                      <path d="M16.5 12H14V10.5C14 9.948 14.448 9.5 15 9.5H16.5V7H14.5C12.567 7 11 8.567 11 10.5V12H9V14.5H11V21H14V14.5H16L16.5 12Z" fill="white" />
                    </svg>
                    <span className="text-sm text-[#4b5563] group-hover:text-[#1877F2] transition-colors">
                      Tiếp tục với Facebook
                    </span>
                  </>
                )}
              </button>
            </div>

            {/* Switch Mode */}
            <p className="text-center text-sm text-[#6b7280] mt-6">
              {mode === "login" ? "Chưa có tài khoản?" : "Đã có tài khoản?"}{" "}
              <button
                onClick={() => switchMode(mode === "login" ? "register" : "login")}
                className="text-[#c4a882] hover:text-[#8c6e52] transition-colors"
              >
                {mode === "login" ? "Đăng ký ngay" : "Đăng nhập"}
              </button>
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}