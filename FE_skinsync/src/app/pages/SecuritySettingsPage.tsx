import { useEffect, useState, useRef } from "react";
import { Link } from "react-router";
import {
    Lock,
    Eye,
    EyeOff,
    Save,
    CheckCircle2,
    ShieldCheck,
    ArrowLeft,
    AlertCircle,
    Camera,
    Mail,
    Phone,
    User,
} from "lucide-react";
import {
    changePasswordApi,
    getAuthProvider,
    updateAvatarApi,
    updateProfileApi,
} from "../services/authService";
import { useAuth } from "../contexts/AuthContext";
import { ImageWithFallback } from "../components/figma/ImageWithFallback";
import { resolveUserAvatar } from "../utils/avatar";

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

export function SecuritySettingsPage() {
    const { user, refreshCurrentUser, setCurrentUser } = useAuth();
    const isGoogleUser = getAuthProvider() === "google";
    const avatarInputRef = useRef<HTMLInputElement>(null);
    const [avatarUrl, setAvatarUrl] = useState(resolveUserAvatar(user));
    const [avatarSaved, setAvatarSaved] = useState(false);
    const [avatarLoading, setAvatarLoading] = useState(false);
    const [avatarError, setAvatarError] = useState<string | null>(null);

    // Info fields
    const [name, setName] = useState(user?.fullName ?? "");
    const [email, setEmail] = useState(user?.email ?? "");
    const [phone, setPhone] = useState(user?.phone ?? "");
    const [infoSaved, setInfoSaved] = useState(false);
    const [infoLoading, setInfoLoading] = useState(false);
    const [infoError, setInfoError] = useState<string | null>(null);

    // Password fields
    const [currentPw, setCurrentPw] = useState("");
    const [newPw, setNewPw] = useState("");
    const [confirmPw, setConfirmPw] = useState("");
    const [showCurrent, setShowCurrent] = useState(false);
    const [showNew, setShowNew] = useState(false);
    const [showConfirm, setShowConfirm] = useState(false);
    const [pwLoading, setPwLoading] = useState(false);
    const [pwSaved, setPwSaved] = useState(false);
    const [pwError, setPwError] = useState("");

    useEffect(() => {
        setName(user?.fullName ?? "");
        setEmail(user?.email ?? "");
        setPhone(user?.phone ?? "");
        setAvatarUrl(resolveUserAvatar(user));
    }, [user]);

    const pwMatch = newPw && confirmPw && newPw === confirmPw;
    const canSubmitPw = currentPw && newPw.length >= 8 && !!pwMatch;

    const handleAvatarChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
        const file = e.target.files?.[0];
        if (!file) {
            return;
        }

        setAvatarError(null);
        setAvatarLoading(true);

        try {
            const result = await updateAvatarApi(file);
            if (!result.success || !result.content) {
                setAvatarError(result.message || "Không thể cập nhật ảnh đại diện.");
                return;
            }

            setCurrentUser(result.content);
            setAvatarUrl(resolveUserAvatar(result.content));
            setAvatarSaved(true);
            setTimeout(() => setAvatarSaved(false), 2500);
        } finally {
            setAvatarLoading(false);
            e.target.value = "";
        }
    };

    const handleInfoSave = async (e: React.FormEvent) => {
        e.preventDefault();
        setInfoError(null);

        if (!name.trim()) {
            setInfoError("Vui lòng nhập họ và tên.");
            return;
        }

        setInfoLoading(true);

        try {
            const result = await updateProfileApi(name.trim(), phone.trim());
            if (!result.success || !result.content) {
                setInfoError(result.message || "Không thể cập nhật thông tin tài khoản.");
                return;
            }

            setCurrentUser(result.content);
            await refreshCurrentUser();
            setInfoLoading(false);
            setInfoSaved(true);
            setTimeout(() => setInfoSaved(false), 3000);
        } finally {
            setInfoLoading(false);
        }
    };

    const handlePwSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setPwError("");

        if (!canSubmitPw) {
            return;
        }

        setPwLoading(true);

        try {
            const result = await changePasswordApi(currentPw, newPw);
            if (!result.success) {
                setPwError(result.message || "Không thể đổi mật khẩu. Vui lòng thử lại.");
                return;
            }

            setPwLoading(false);
            setPwSaved(true);
            setCurrentPw(""); setNewPw(""); setConfirmPw("");
            setTimeout(() => setPwSaved(false), 3500);
        } finally {
            setPwLoading(false);
        }
    };

    return (
        <div className="min-h-screen bg-[#faf7f2] pt-20">
            <div className="max-w-2xl mx-auto px-6 py-8 flex flex-col gap-6">

                {/* Breadcrumb */}
                <div className="flex items-center gap-2">
                    <Link
                        to="/profile"
                        className="flex items-center gap-1.5 text-sm text-[#9ca3af] hover:text-[#c4a882] transition-colors"
                    >
                        <ArrowLeft className="w-3.5 h-3.5" />
                        Hồ Sơ
                    </Link>
                    <span className="text-[#d1d5db]">/</span>
                    <span className="text-sm text-[#2a2a2a]">Cài Đặt Tài Khoản</span>
                </div>

                {/* Page title */}
                <div>
                    <h1 className="text-2xl text-[#2a2a2a] mb-1">Cài Đặt Tài Khoản</h1>
                    <p className="text-sm text-[#6b7280]">Cập nhật thông tin cá nhân và bảo mật tài khoản của bạn</p>
                </div>

                {/* ── Avatar Card ── */}
                <div className="bg-white rounded-3xl border border-[#ede8e0] shadow-sm overflow-hidden">
                    <div className="flex items-center gap-3 px-6 py-4 border-b border-[#f0ebe3] bg-[#fdf8f2]">
                        <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[#c4a882] to-[#8c6e52] flex items-center justify-center shadow-sm">
                            <Camera className="w-4 h-4 text-white" />
                        </div>
                        <div>
                            <h2 className="text-[#2a2a2a] text-sm">Ảnh Đại Diện</h2>
                            <p className="text-xs text-[#9ca3af]">Nhấn vào ảnh để tải lên ảnh mới</p>
                        </div>
                        {avatarSaved && (
                            <div className="ml-auto flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-emerald-50 border border-emerald-100">
                                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                                <span className="text-xs text-emerald-600">Đã cập nhật!</span>
                            </div>
                        )}
                    </div>

                    <div className="p-6 flex items-center gap-6">
                        {avatarError && (
                            <div className="mb-3 flex items-center gap-2.5 px-4 py-3 rounded-xl bg-red-50 border border-red-100 w-full">
                                <AlertCircle className="w-4 h-4 text-red-500 flex-shrink-0" />
                                <p className="text-sm text-red-600">{avatarError}</p>
                            </div>
                        )}

                        <input
                            ref={avatarInputRef}
                            type="file"
                            accept="image/*"
                            className="hidden"
                            onChange={handleAvatarChange}
                        />
                        <button
                            type="button"
                            onClick={() => avatarInputRef.current?.click()}
                            disabled={avatarLoading}
                            className="relative w-24 h-24 rounded-full overflow-hidden border-4 border-[#e8d5b7] shadow-md group flex-shrink-0 cursor-pointer"
                        >
                            <ImageWithFallback
                                src={avatarUrl}
                                alt="Avatar"
                                className="w-full h-full object-cover object-top"
                            />
                            <div className="absolute inset-0 bg-black/35 opacity-0 group-hover:opacity-100 transition-opacity flex flex-col items-center justify-center gap-1">
                                <Camera className="w-5 h-5 text-white" />
                                <span className="text-white text-[10px]">{avatarLoading ? "Đang tải" : "Thay đổi"}</span>
                            </div>
                        </button>
                        <div className="flex flex-col gap-1.5">
                            <p className="text-sm text-[#2a2a2a]">Tải Lên Ảnh Mới</p>
                            <p className="text-xs text-[#9ca3af] leading-relaxed">
                                Định dạng JPG, PNG hoặc WEBP.<br />
                                Kích thước tối đa 5MB. Khuyến nghị ảnh vuông.
                            </p>
                            <button
                                type="button"
                                onClick={() => avatarInputRef.current?.click()}
                                disabled={avatarLoading}
                                className="mt-1 inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg border border-[#c4a882]/40 text-[#c4a882] text-xs hover:bg-[#c4a882]/5 transition-colors w-fit"
                            >
                                <Camera className="w-3.5 h-3.5" />
                                {avatarLoading ? "Đang tải..." : "Chọn Ảnh"}
                            </button>
                        </div>
                    </div>
                </div>

                {/* ── Thông Tin Cá Nhân Card ── */}
                <div className="bg-white rounded-3xl border border-[#ede8e0] shadow-sm overflow-hidden">
                    <div className="flex items-center gap-3 px-6 py-4 border-b border-[#f0ebe3] bg-[#fdf8f2]">
                        <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[#c4a882] to-[#8c6e52] flex items-center justify-center shadow-sm">
                            <User className="w-4 h-4 text-white" />
                        </div>
                        <div>
                            <h2 className="text-[#2a2a2a] text-sm">Thông Tin Cá Nhân</h2>
                            <p className="text-xs text-[#9ca3af]">Cập nhật tên, email và số điện thoại</p>
                        </div>
                        {infoSaved && (
                            <div className="ml-auto flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-emerald-50 border border-emerald-100">
                                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                                <span className="text-xs text-emerald-600">Đã lưu!</span>
                            </div>
                        )}
                    </div>

                    <form onSubmit={handleInfoSave} className="p-6 flex flex-col gap-5">
                        {infoError && (
                            <div className="flex items-center gap-2.5 px-4 py-3 rounded-xl bg-red-50 border border-red-100">
                                <AlertCircle className="w-4 h-4 text-red-500 flex-shrink-0" />
                                <p className="text-sm text-red-600">{infoError}</p>
                            </div>
                        )}

                        {/* Name */}
                        <div className="flex flex-col gap-1.5">
                            <label className="text-sm text-[#4b5563] flex items-center gap-1.5">
                                <User className="w-3.5 h-3.5 text-[#9ca3af]" />
                                Họ và Tên
                            </label>
                            <input
                                type="text"
                                value={name}
                                onChange={(e) => setName(e.target.value)}
                                placeholder="Nhập họ và tên"
                                className="w-full px-4 py-3 rounded-xl border border-[#e8d5b7] bg-[#fdf8f2] text-sm text-[#2a2a2a] placeholder-[#c9bfb0] focus:outline-none focus:border-[#c4a882] focus:ring-2 focus:ring-[#c4a882]/15 transition-all"
                            />
                        </div>

                        {/* Email */}
                        <div className="flex flex-col gap-1.5">
                            <label className="text-sm text-[#4b5563] flex items-center gap-1.5">
                                <Mail className="w-3.5 h-3.5 text-[#9ca3af]" />
                                Email
                            </label>
                            <input
                                type="email"
                                value={email}
                                placeholder="hello@example.com"
                                readOnly
                                className="w-full px-4 py-3 rounded-xl border border-[#e8d5b7] bg-[#fdf8f2] text-sm text-[#2a2a2a] placeholder-[#c9bfb0] focus:outline-none focus:border-[#c4a882] focus:ring-2 focus:ring-[#c4a882]/15 transition-all"
                            />
                            <p className="text-xs text-[#9ca3af]">Email được quản lý bởi hệ thống xác thực, không thể chỉnh sửa tại đây.</p>
                        </div>

                        {/* Phone */}
                        <div className="flex flex-col gap-1.5">
                            <label className="text-sm text-[#4b5563] flex items-center gap-1.5">
                                <Phone className="w-3.5 h-3.5 text-[#9ca3af]" />
                                Số Điện Thoại
                            </label>
                            <input
                                type="tel"
                                value={phone}
                                onChange={(e) => setPhone(e.target.value)}
                                placeholder="0901 234 567"
                                className="w-full px-4 py-3 rounded-xl border border-[#e8d5b7] bg-[#fdf8f2] text-sm text-[#2a2a2a] placeholder-[#c9bfb0] focus:outline-none focus:border-[#c4a882] focus:ring-2 focus:ring-[#c4a882]/15 transition-all"
                            />
                        </div>

                        <div className="flex justify-end pt-1">
                            <button
                                type="submit"
                                disabled={infoLoading}
                                className={`flex items-center gap-2 px-6 py-2.5 rounded-xl text-sm transition-all ${infoSaved
                                    ? "bg-emerald-500 text-white"
                                    : "bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white shadow-sm hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed"
                                    }`}
                            >
                                {infoLoading ? (
                                    <>
                                        <svg className="animate-spin w-3.5 h-3.5" viewBox="0 0 24 24" fill="none">
                                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                                        </svg>
                                        Đang lưu...
                                    </>
                                ) : infoSaved ? (
                                    <>
                                        <CheckCircle2 className="w-3.5 h-3.5" />
                                        Đã lưu!
                                    </>
                                ) : (
                                    <>
                                        <Save className="w-3.5 h-3.5" />
                                        Lưu Thông Tin
                                    </>
                                )}
                            </button>
                        </div>
                    </form>
                </div>

                {!isGoogleUser && (
                <div className="bg-white rounded-3xl border border-[#ede8e0] shadow-sm overflow-hidden">
                    <div className="flex items-center gap-3 px-6 py-4 border-b border-[#f0ebe3] bg-[#fdf8f2]">
                        <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-[#c4a882] to-[#8c6e52] flex items-center justify-center shadow-sm">
                            <Lock className="w-4 h-4 text-white" />
                        </div>
                        <div>
                            <h2 className="text-[#2a2a2a] text-sm">Đổi Mật Khẩu</h2>
                            <p className="text-xs text-[#9ca3af]">Cập nhật mật khẩu định kỳ để bảo vệ tài khoản</p>
                        </div>
                        {pwSaved && (
                            <div className="ml-auto flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-emerald-50 border border-emerald-100">
                                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                                <span className="text-xs text-emerald-600">Đã cập nhật!</span>
                            </div>
                        )}
                    </div>

                    <form onSubmit={handlePwSubmit} className="p-6 flex flex-col gap-5">
                        {pwError && (
                            <div className="flex items-center gap-2.5 px-4 py-3 rounded-xl bg-red-50 border border-red-100">
                                <AlertCircle className="w-4 h-4 text-red-500 flex-shrink-0" />
                                <p className="text-sm text-red-600">{pwError}</p>
                            </div>
                        )}

                        {/* Current password */}
                        <div className="flex flex-col gap-1.5">
                            <label className="text-sm text-[#4b5563] flex items-center gap-1.5">
                                <Lock className="w-3.5 h-3.5 text-[#9ca3af]" />
                                Mật Khẩu Hiện Tại
                            </label>
                            <div className="relative">
                                <input
                                    type={showCurrent ? "text" : "password"}
                                    value={currentPw}
                                    onChange={(e) => setCurrentPw(e.target.value)}
                                    placeholder="Nhập mật khẩu hiện tại"
                                    className="w-full px-4 py-3 pr-11 rounded-xl border border-[#e8d5b7] bg-[#fdf8f2] text-sm text-[#2a2a2a] placeholder-[#c9bfb0] focus:outline-none focus:border-[#c4a882] focus:ring-2 focus:ring-[#c4a882]/15 transition-all"
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowCurrent(!showCurrent)}
                                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#9ca3af] hover:text-[#c4a882] transition-colors"
                                >
                                    {showCurrent ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
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

                        <div className="h-px bg-[#f0ebe3]" />

                        {/* New password */}
                        <div className="flex flex-col gap-1.5">
                            <PasswordGuide password={newPw} />
                            <label className="text-sm text-[#4b5563] flex items-center gap-1.5">
                                <ShieldCheck className="w-3.5 h-3.5 text-[#9ca3af]" />
                                Mật Khẩu Mới
                            </label>
                            <div className="relative">
                                <input
                                    type={showNew ? "text" : "password"}
                                    value={newPw}
                                    onChange={(e) => setNewPw(e.target.value)}
                                    placeholder="Ít nhất 8 ký tự"
                                    className="w-full px-4 py-3 pr-11 rounded-xl border border-[#e8d5b7] bg-[#fdf8f2] text-sm text-[#2a2a2a] placeholder-[#c9bfb0] focus:outline-none focus:border-[#c4a882] focus:ring-2 focus:ring-[#c4a882]/15 transition-all"
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowNew(!showNew)}
                                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#9ca3af] hover:text-[#c4a882] transition-colors"
                                >
                                    {showNew ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                                </button>
                            </div>
                            <StrengthBar password={newPw} />
                        </div>

                        {/* Confirm password */}
                        <div className="flex flex-col gap-1.5">
                            <label className="text-sm text-[#4b5563] flex items-center gap-1.5">
                                <ShieldCheck className="w-3.5 h-3.5 text-[#9ca3af]" />
                                Xác Nhận Mật Khẩu Mới
                            </label>
                            <div className="relative">
                                <input
                                    type={showConfirm ? "text" : "password"}
                                    value={confirmPw}
                                    onChange={(e) => setConfirmPw(e.target.value)}
                                    placeholder="Nhập lại mật khẩu mới"
                                    className={`w-full px-4 py-3 pr-11 rounded-xl border bg-[#fdf8f2] text-sm text-[#2a2a2a] placeholder-[#c9bfb0] focus:outline-none focus:ring-2 transition-all ${confirmPw && !pwMatch
                                        ? "border-red-300 focus:ring-red-100 focus:border-red-400"
                                        : pwMatch
                                            ? "border-emerald-300 focus:ring-emerald-100 focus:border-emerald-400"
                                            : "border-[#e8d5b7] focus:border-[#c4a882] focus:ring-[#c4a882]/15"
                                        }`}
                                />
                                <button
                                    type="button"
                                    onClick={() => setShowConfirm(!showConfirm)}
                                    className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#9ca3af] hover:text-[#c4a882] transition-colors"
                                >
                                    {showConfirm ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
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

                        <div className="flex items-center justify-end pt-1">
                            <button
                                type="submit"
                                disabled={!canSubmitPw || pwLoading}
                                className={`flex items-center gap-2 px-6 py-2.5 rounded-xl text-sm transition-all ${pwSaved
                                    ? "bg-emerald-500 text-white"
                                    : "bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white shadow-sm hover:opacity-90 disabled:opacity-40 disabled:cursor-not-allowed"
                                    }`}
                            >
                                {pwLoading ? (
                                    <>
                                        <svg className="animate-spin w-3.5 h-3.5" viewBox="0 0 24 24" fill="none">
                                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                                        </svg>
                                        Đang lưu...
                                    </>
                                ) : pwSaved ? (
                                    <>
                                        <CheckCircle2 className="w-3.5 h-3.5" />
                                        Đã lưu!
                                    </>
                                ) : (
                                    <>
                                        <Save className="w-3.5 h-3.5" />
                                        Cập Nhật Mật Khẩu
                                    </>
                                )}
                            </button>
                        </div>
                    </form>
                </div>
                )}

                <div className="pb-4" />
            </div>
        </div>
    );
}
