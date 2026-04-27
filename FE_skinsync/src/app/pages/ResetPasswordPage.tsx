import { useMemo, useState } from "react";
import { Link, useNavigate } from "react-router";
import { Lock, Eye, EyeOff, ArrowLeft, Sparkles, ShieldCheck, CheckCircle2 } from "lucide-react";
import { ImageWithFallback } from "../components/figma/ImageWithFallback";
import { resetPasswordApi } from "../services/authService";
import { useAuth } from "../contexts/AuthContext";

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
      {password && (
        <p className="text-xs" style={{ color: colors[strength] }}>
          {labels[strength]}
        </p>
      )}
    </div>
  );
}

export function ResetPasswordPage() {
  const navigate = useNavigate();
  const { isAuthenticated, user } = useAuth();
  const [newPw, setNewPw] = useState("");
  const [confirmPw, setConfirmPw] = useState("");
  const [showNew, setShowNew] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);
  const [isLoading, setIsLoading] = useState(false);
  const [isDone, setIsDone] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const accessToken = useMemo(() => {
    const searchParams = new URLSearchParams(window.location.search);
    const tokenFromQuery = searchParams.get("access_token") ?? searchParams.get("token");
    if (tokenFromQuery) {
      return tokenFromQuery;
    }

    const hashParams = new URLSearchParams(window.location.hash.replace(/^#/, ""));
    return hashParams.get("access_token") ?? hashParams.get("token");
  }, []);

  const pwMatch = newPw && confirmPw && newPw === confirmPw;
  const canSubmit = newPw.length >= 8 && !!pwMatch && Boolean(accessToken);
  const backTo = isAuthenticated
    ? (user?.role === "admin" ? "/admin/profile" : "/settings/security")
    : "/login";
  const backLabel = isAuthenticated ? "Quay lại cài đặt bảo mật" : "Quay lại đăng nhập";

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!canSubmit) return;

    setError(null);
    setIsLoading(true);

    try {
      const result = await resetPasswordApi(accessToken ?? "", newPw);
      if (!result.success) {
        setError(result.message || "Không thể đặt lại mật khẩu.");
        return;
      }

      setIsLoading(false);
      setIsDone(true);
    } catch {
      setError("Không thể kết nối đến server. Vui lòng thử lại sau.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col">
      {/* Nav */}
      <nav className="absolute top-0 left-0 right-0 z-50">
        <div className="px-12 py-5">
          <Link to="/" className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-full bg-gradient-to-br from-[#c4a882] to-[#8c6e52]" />
            <span className="text-white/90 text-lg" style={{ textShadow: "0 1px 4px rgba(0,0,0,0.3)" }}>
              SkinSync
            </span>
          </Link>
        </div>
      </nav>

      <div className="flex-1 flex min-h-screen">
        {/* Left — visual */}
        <div className="hidden lg:flex lg:w-1/2 relative overflow-hidden">
          <ImageWithFallback
            src="https://images.unsplash.com/photo-1596178065887-1198b6148b2b?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxza2luY2FyZSUyMGxhYiUyMHNjaWVuY2UlMjBib3RhbmljYWwlMjBuYXR1cmFsJTIwYmVhdXR5fGVufDF8fHx8MTc3NDAwNjkzNHww&ixlib=rb-4.1.0&q=80&w=1080"
            alt="Reset Visual"
            className="absolute inset-0 w-full h-full object-cover object-center"
          />
          <div className="absolute inset-0 bg-gradient-to-br from-[#8c6e52]/65 via-[#c4a882]/45 to-[#e8d5b7]/30" />
          <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-black/20" />

          <div className="absolute inset-0 flex flex-col justify-between p-12 pointer-events-none">
            <div className="mt-16">
              <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/15 backdrop-blur-md border border-white/25">
                <ShieldCheck className="w-4 h-4 text-[#d4f4f4]" />
                <span className="text-white/90 text-sm">Bảo Mật Tài Khoản</span>
              </div>
            </div>
            <div className="text-center">
              <h2 className="text-5xl text-white mb-4" style={{ textShadow: "0 2px 20px rgba(0,0,0,0.3)" }}>
                Tạo Mật Khẩu
                <br />
                <span className="text-[#e8d5b7]">Mới An Toàn</span>
              </h2>
              <p className="text-white/75 text-lg max-w-xs mx-auto leading-relaxed">
                Hãy chọn mật khẩu mạnh để bảo vệ tài khoản của bạn
              </p>
            </div>
            {/* Tips */}
            <div className="pb-4 space-y-2">
              {[
                "Ít nhất 8 ký tự",
                "Kết hợp chữ hoa và chữ thường",
                "Có ít nhất một ký tự số",
                "Thêm ký tự đặc biệt (@, #, !…)",
              ].map((tip) => (
                <div key={tip} className="flex items-center gap-2 bg-white/10 backdrop-blur-sm rounded-xl px-3 py-2 border border-white/15">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-300 flex-shrink-0" />
                  <span className="text-white/80 text-xs">{tip}</span>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Right — form */}
        <div className="w-full lg:w-1/2 flex items-center justify-center bg-white px-6 py-16">
          <div className="w-full max-w-md">
            <Link
              to={backTo}
              className="inline-flex items-center gap-2 text-sm text-[#9ca3af] hover:text-[#c4a882] transition-colors mb-8"
            >
              <ArrowLeft className="w-4 h-4" />
              {backLabel}
            </Link>

            {!isDone ? (
              <>
                <div className="mb-8">
                  <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-[#c4a882]/15 to-[#8c6e52]/10 border border-[#e8d5b7] flex items-center justify-center mb-5">
                    <Lock className="w-6 h-6 text-[#c4a882]" />
                  </div>
                  <h1 className="text-3xl text-[#2a2a2a] mb-2">Đặt Lại Mật Khẩu</h1>
                  <p className="text-[#6b7280] text-sm leading-relaxed">
                    Nhập mật khẩu mới cho tài khoản của bạn. Đảm bảo mật khẩu đủ mạnh.
                  </p>
                </div>

                <form onSubmit={handleSubmit} className="space-y-5">
                  {!accessToken && (
                    <div className="px-4 py-3 rounded-xl border border-red-200 bg-red-50 text-sm text-red-600">
                      Link đặt lại mật khẩu không hợp lệ hoặc đã hết hạn.
                    </div>
                  )}

                  {error && (
                    <div className="px-4 py-3 rounded-xl border border-red-200 bg-red-50 text-sm text-red-600">
                      {error}
                    </div>
                  )}

                  {/* New password */}
                  <div className="space-y-1.5">
                    <label className="text-sm text-[#4b5563]">Mật Khẩu Mới</label>
                    <div className="relative">
                      <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#9ca3af]" />
                      <input
                        type={showNew ? "text" : "password"}
                        value={newPw}
                        onChange={(e) => setNewPw(e.target.value)}
                        placeholder="••••••••"
                        required
                        className="w-full pl-11 pr-11 py-3.5 rounded-xl border border-[#e5e7eb] bg-[#fafafa] text-[#2a2a2a] placeholder-[#d1d5db] focus:outline-none focus:border-[#c4a882] focus:ring-2 focus:ring-[#c4a882]/10 transition-all"
                      />
                      <button
                        type="button"
                        onClick={() => setShowNew(!showNew)}
                        className="absolute right-4 top-1/2 -translate-y-1/2 text-[#9ca3af] hover:text-[#c4a882] transition-colors"
                      >
                        {showNew ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                      </button>
                    </div>
                    <StrengthBar password={newPw} />
                  </div>

                  {/* Confirm password */}
                  <div className="space-y-1.5">
                    <label className="text-sm text-[#4b5563]">Xác Nhận Mật Khẩu Mới</label>
                    <div className="relative">
                      <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#9ca3af]" />
                      <input
                        type={showConfirm ? "text" : "password"}
                        value={confirmPw}
                        onChange={(e) => setConfirmPw(e.target.value)}
                        placeholder="••••••••"
                        required
                        className={`w-full pl-11 pr-11 py-3.5 rounded-xl border bg-[#fafafa] text-[#2a2a2a] placeholder-[#d1d5db] focus:outline-none focus:ring-2 transition-all ${
                          confirmPw && !pwMatch
                            ? "border-red-300 focus:ring-red-100 focus:border-red-400"
                            : pwMatch
                            ? "border-emerald-300 focus:ring-emerald-100 focus:border-emerald-400"
                            : "border-[#e5e7eb] focus:border-[#c4a882] focus:ring-[#c4a882]/10"
                        }`}
                      />
                      <button
                        type="button"
                        onClick={() => setShowConfirm(!showConfirm)}
                        className="absolute right-4 top-1/2 -translate-y-1/2 text-[#9ca3af] hover:text-[#c4a882] transition-colors"
                      >
                        {showConfirm ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
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
                    disabled={!canSubmit || isLoading}
                    className="w-full py-3.5 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white flex items-center justify-center gap-2 shadow-lg shadow-[#c4a882]/25 hover:opacity-95 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isLoading ? (
                      <>
                        <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none">
                          <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                          <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                        </svg>
                        Đang cập nhật...
                      </>
                    ) : (
                      <>
                        <ShieldCheck className="w-4 h-4" />
                        Cập Nhật Mật Khẩu
                      </>
                    )}
                  </button>
                </form>
              </>
            ) : (
              /* Success */
              <div className="text-center">
                <div className="w-20 h-20 rounded-full bg-gradient-to-br from-emerald-50 to-teal-50 border-2 border-emerald-200 flex items-center justify-center mx-auto mb-6">
                  <ShieldCheck className="w-10 h-10 text-emerald-500" />
                </div>
                <h2 className="text-2xl text-[#2a2a2a] mb-3">Mật Khẩu Đã Được Cập Nhật!</h2>
                <p className="text-[#6b7280] text-sm leading-relaxed mb-8">
                  Tài khoản của bạn đã được bảo mật. Đăng nhập lại để tiếp tục hành trình dưỡng da.
                </p>
                <button
                  onClick={() => navigate("/login")}
                  className="w-full py-3.5 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white flex items-center justify-center gap-2 shadow-lg shadow-[#c4a882]/25 hover:opacity-95 transition-all"
                >
                  Đăng Nhập Ngay
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}