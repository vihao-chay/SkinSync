import { useState } from "react";
import { Link } from "react-router";
import { Mail, ArrowLeft, Sparkles, Send, CheckCircle2 } from "lucide-react";
import { ImageWithFallback } from "../components/figma/ImageWithFallback";
import { BrandLogo } from "../components/BrandLogo";
import { forgotPasswordApi } from "../services/authService";
import { useAuth } from "../contexts/AuthContext";

export function ForgotPasswordPage() {
    const { isAuthenticated, user } = useAuth();
    const [email, setEmail] = useState("");
    const [isLoading, setIsLoading] = useState(false);
    const [isSent, setIsSent] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const backTo = isAuthenticated
        ? (user?.role === "admin" ? "/admin/profile" : "/settings/security")
        : "/login";
    const backLabel = isAuthenticated ? "Quay lại cài đặt bảo mật" : "Quay lại đăng nhập";

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!email) return;

        setError(null);
        setIsLoading(true);

        try {
            const redirectTo = `${window.location.origin}/reset-password`;
            const result = await forgotPasswordApi(email.trim(), redirectTo);

            if (!result.success) {
                setError(result.message || "Không thể gửi yêu cầu khôi phục mật khẩu.");
                return;
            }

            setIsSent(true);
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
                        <BrandLogo className="w-9 h-9 rounded-xl border border-white/30 shadow-md shadow-black/10" />
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
                        src="https://images.unsplash.com/photo-1665454486608-5c2f3f5ede35?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxib3RhbmljYWwlMjBsZWF2ZXMlMjBzb2Z0JTIwcGFzdGVsJTIwc2tpbmNhcmUlMjBiYWNrZ3JvdW5kfGVufDF8fHx8MTc3NDAwNjkzNHww&ixlib=rb-4.1.0&q=80&w=1080"
                        alt="SkinSync Visual"
                        className="absolute inset-0 w-full h-full object-cover object-center"
                    />
                    <div className="absolute inset-0 bg-gradient-to-br from-[#c4a882]/60 via-[#8c6e52]/40 to-[#e8d5b7]/30" />
                    <div className="absolute inset-0 bg-gradient-to-t from-black/40 via-transparent to-black/20" />

                    <div className="absolute inset-0 flex flex-col justify-between p-12 pointer-events-none">
                        <div className="mt-16">
                            <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-white/15 backdrop-blur-md border border-white/25">
                                <Sparkles className="w-4 h-4 text-[#d4f4f4]" />
                                <span className="text-white/90 text-sm">Phân Tích Da Bằng AI</span>
                            </div>
                        </div>
                        <div className="text-center">
                            <h2 className="text-5xl text-white mb-4" style={{ textShadow: "0 2px 20px rgba(0,0,0,0.3)" }}>
                                Đừng Lo Lắng
                                <br />
                                <span className="text-[#e8d5b7]">Chúng Tôi Hỗ Trợ Bạn</span>
                            </h2>
                            <p className="text-white/75 text-lg max-w-xs mx-auto leading-relaxed">
                                Chỉ vài giây, mật khẩu của bạn sẽ được khôi phục an toàn
                            </p>
                        </div>
                        <div className="pb-4">
                            <div className="bg-white/10 backdrop-blur-md rounded-2xl p-5 border border-white/20">
                                <div className="flex items-center gap-3 mb-2">
                                    <BrandLogo className="w-8 h-8 rounded-lg border border-white/20 shadow-sm" />
                                    <span className="text-white text-sm">SkinSync AI</span>
                                </div>
                                <p className="text-white/70 text-sm leading-relaxed">
                                    Bảo mật tài khoản là ưu tiên hàng đầu của chúng tôi. Link đặt lại chỉ có hiệu lực trong 15 phút.
                                </p>
                            </div>
                        </div>
                    </div>
                </div>

                {/* Right — form */}
                <div className="w-full lg:w-1/2 flex items-center justify-center bg-white px-6 py-16">
                    <div className="w-full max-w-md">

                        {/* Back to login */}
                        <Link
                            to={backTo}
                            className="inline-flex items-center gap-2 text-sm text-[#9ca3af] hover:text-[#c4a882] transition-colors mb-8"
                        >
                            <ArrowLeft className="w-4 h-4" />
                            {backLabel}
                        </Link>

                        {!isSent ? (
                            <>
                                {/* Header */}
                                <div className="mb-8">
                                    <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-[#c4a882]/15 to-[#8c6e52]/10 border border-[#e8d5b7] flex items-center justify-center mb-5">
                                        <Mail className="w-6 h-6 text-[#c4a882]" />
                                    </div>
                                    <h1 className="text-3xl text-[#2a2a2a] mb-2">Quên Mật Khẩu?</h1>
                                    <p className="text-[#6b7280] text-sm leading-relaxed">
                                        Nhập địa chỉ email đã đăng ký. Chúng tôi sẽ gửi link đặt lại mật khẩu ngay lập tức.
                                    </p>
                                </div>

                                {/* Form */}
                                <form onSubmit={handleSubmit} className="space-y-5">
                                    {error && (
                                        <div className="px-4 py-3 rounded-xl border border-red-200 bg-red-50 text-sm text-red-600">
                                            {error}
                                        </div>
                                    )}

                                    <div className="space-y-1.5">
                                        <label className="text-sm text-[#4b5563]">Địa Chỉ Email</label>
                                        <div className="relative">
                                            <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-[#9ca3af]" />
                                            <input
                                                type="email"
                                                value={email}
                                                onChange={(e) => setEmail(e.target.value)}
                                                placeholder="hello@example.com"
                                                required
                                                className="w-full pl-11 pr-4 py-3.5 rounded-xl border border-[#e5e7eb] bg-[#fafafa] text-[#2a2a2a] placeholder-[#d1d5db] focus:outline-none focus:border-[#c4a882] focus:ring-2 focus:ring-[#c4a882]/10 transition-all"
                                            />
                                        </div>
                                    </div>

                                    <button
                                        type="submit"
                                        disabled={isLoading || !email}
                                        className="w-full py-3.5 rounded-xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white flex items-center justify-center gap-2 shadow-lg shadow-[#c4a882]/25 hover:shadow-[#c4a882]/40 hover:opacity-95 transition-all disabled:opacity-60 disabled:cursor-not-allowed"
                                    >
                                        {isLoading ? (
                                            <div className="flex items-center gap-2">
                                                <svg className="animate-spin w-4 h-4" viewBox="0 0 24 24" fill="none">
                                                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                                                </svg>
                                                Đang gửi...
                                            </div>
                                        ) : (
                                            <>
                                                <Send className="w-4 h-4" />
                                                Gửi Mã Xác Nhận
                                            </>
                                        )}
                                    </button>
                                </form>

                                <p className="text-center text-xs text-[#9ca3af] mt-6">
                                    Chưa nhận được email?{" "}
                                    <button className="text-[#c4a882] hover:text-[#8c6e52] transition-colors">
                                        Gửi lại
                                    </button>
                                </p>
                            </>
                        ) : (
                            /* Success state */
                            <div className="text-center">
                                <div className="w-20 h-20 rounded-full bg-gradient-to-br from-emerald-50 to-teal-50 border-2 border-emerald-200 flex items-center justify-center mx-auto mb-6">
                                    <CheckCircle2 className="w-10 h-10 text-emerald-500" />
                                </div>
                                <h2 className="text-2xl text-[#2a2a2a] mb-3">Email Đã Được Gửi!</h2>
                                <p className="text-[#6b7280] text-sm leading-relaxed mb-2">
                                    Một liên kết đặt lại mật khẩu đã được gửi đến Gmail của bạn.
                                </p>
                                <p className="text-[#c4a882] text-sm mb-8">{email}</p>
                                <div className="bg-[#fdf8f2] rounded-2xl border border-[#e8d5b7] p-4 text-left mb-8">
                                    <p className="text-xs text-[#9ca3af] mb-1">Lưu ý:</p>
                                    <ul className="text-xs text-[#6b7280] space-y-1 list-disc list-inside">
                                        <li>Kiểm tra cả hộp thư Spam / Junk</li>
                                        <li>Link có hiệu lực trong vòng <span className="text-[#c4a882]">15 phút</span></li>
                                        <li>Mỗi link chỉ sử dụng được một lần</li>
                                    </ul>
                                </div>
                                <Link
                                    to={backTo}
                                    className="inline-flex items-center gap-2 px-6 py-3 rounded-xl border border-[#c4a882]/30 text-[#c4a882] text-sm hover:bg-[#c4a882]/5 transition-colors"
                                >
                                    <ArrowLeft className="w-4 h-4" />
                                    {backLabel}
                                </Link>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </div>
    );
}
