import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { loginWithGoogleToken, saveAuthData, setAuthProvider, type SocialAuthProvider } from "../services/authService";
import { Sparkles } from "lucide-react";
import { useAuth } from "../contexts/AuthContext";

/**
 * This page handles redirect callbacks from Supabase social OAuth.
 * After user logs in with Google/Facebook, Supabase redirects back with
 * access_token in the URL hash fragment (#access_token=...).
 * We extract it and call our backend to complete login.
 */
export function AuthCallbackPage() {
  const navigate = useNavigate();
  const { setCurrentUser } = useAuth();
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function handleCallback() {
      try {
        const searchParams = new URLSearchParams(window.location.search);
        const providerParam = searchParams.get("provider");
        const provider: SocialAuthProvider = providerParam === "facebook" ? "facebook" : "google";

        // Supabase puts tokens in the URL hash: #access_token=...&token_type=...
        const hashParams = new URLSearchParams(
          window.location.hash.substring(1) // Remove the '#'
        );

        const accessToken = hashParams.get("access_token");

        if (!accessToken) {
          setError(`Không tìm thấy access token từ ${provider === "google" ? "Google" : "Facebook"}. Vui lòng thử lại.`);
          return;
        }

        // Send the Supabase access token to our backend
        const result = await loginWithGoogleToken(accessToken);

        if (result.success && result.content) {
          saveAuthData(result.content);
          setAuthProvider(provider);
          setCurrentUser(result.content.user);
          // Navigate based on user role
          if (result.content.user.role === "admin") {
            navigate("/admin/dashboard", { replace: true });
          } else {
            navigate("/app/dashboard", { replace: true });
          }
        } else {
          setError(result.message || `Đăng nhập ${provider === "google" ? "Google" : "Facebook"} thất bại. Vui lòng thử lại.`);
        }
      } catch (err: any) {
        setError(err?.message || "Có lỗi xảy ra trong quá trình xử lý.");
      }
    }

    handleCallback();
  }, [navigate, setCurrentUser]);

  if (error) {
    return (
      <div className="min-h-screen bg-[#f5f5f0] flex items-center justify-center px-6">
        <div className="text-center max-w-md">
          <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-[#ef4444]/10 to-[#f97316]/10 border border-[#ef4444]/15 flex items-center justify-center mx-auto mb-6 text-4xl">
            ⚠️
          </div>
          <h1 className="text-2xl text-[#1a1a2e] mb-3" style={{ fontWeight: 700 }}>
            Đăng Nhập Thất Bại
          </h1>
          <p className="text-[#6b7280] mb-6">{error}</p>
          <button
            onClick={() => navigate("/login", { replace: true })}
            className="inline-flex items-center gap-2 px-6 py-3 rounded-2xl bg-gradient-to-r from-[#c4a882] to-[#8c6e52] text-white text-sm shadow-lg shadow-[#c4a882]/25 hover:shadow-[#c4a882]/40 transition-all"
          >
            ← Quay về Đăng Nhập
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#f5f5f0] flex items-center justify-center">
      <div className="text-center">
        <div className="flex items-center justify-center gap-3 mb-4">
          <Sparkles className="w-6 h-6 text-[#c4a882] animate-pulse" />
          <span className="text-lg text-[#2a2a2a]">Đang xử lý đăng nhập...</span>
        </div>
        <div className="w-8 h-8 border-3 border-[#c4a882]/30 border-t-[#c4a882] rounded-full animate-spin mx-auto" />
      </div>
    </div>
  );
}
