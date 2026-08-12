import { Sparkles } from "lucide-react";
import { useEffect, useState } from "react";
import { useNavigate } from "react-router";
import { AuthShell } from "../components/AuthShell";
import { Button } from "../components/ui/button";
import { useAuth } from "../contexts/AuthContext";
import { loginWithGoogleToken, saveAuthData, setAuthProvider, type SocialAuthProvider } from "../services/authService";

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
        const hashParams = new URLSearchParams(window.location.hash.substring(1));
        const accessToken = hashParams.get("access_token");

        if (!accessToken) {
          setError(`Could not find the access token from ${provider === "google" ? "Google" : "Facebook"}. Please try again.`);
          return;
        }

        const result = await loginWithGoogleToken(accessToken);

        if (result.success && result.content) {
          saveAuthData(result.content);
          setAuthProvider(provider);
          setCurrentUser(result.content.user);

          if (result.content.user.role === "admin") {
            navigate("/admin/dashboard", { replace: true });
          } else {
            navigate("/app/dashboard", { replace: true });
          }
        } else {
          setError(result.message || `Unable to complete ${provider === "google" ? "Google" : "Facebook"} sign-in. Please try again.`);
        }
      } catch (err: any) {
        setError(err?.message || "An unexpected error occurred while processing sign-in.");
      }
    }

    void handleCallback();
  }, [navigate, setCurrentUser]);

  if (error) {
    return (
      <AuthShell
        eyebrow="Social sign-in"
        title="Unable to complete sign-in"
        description={error}
        sideTitle="Your session is still protected"
        sideDescription="If social sign-in fails, SkinSync keeps the user outside the app until the callback finishes safely."
      >
        <div className="rounded-[28px] border border-danger/20 bg-danger/5 p-5">
          <p className="text-sm leading-6 text-foreground">{error}</p>
        </div>
        <Button variant="premium" className="w-full" onClick={() => navigate("/login", { replace: true })}>
          Back to login
        </Button>
      </AuthShell>
    );
  }

  return (
    <AuthShell
      eyebrow="Social sign-in"
      title="Completing your sign-in"
      description="SkinSync is validating the social login callback and restoring the right dashboard."
      sideTitle="One callback, same auth rules"
      sideDescription="Route guards, role redirects, and saved auth tokens continue to use the existing implementation."
    >
      <div className="rounded-[28px] border border-border/70 bg-card/95 p-6 text-center shadow-sm">
        <div className="mb-4 flex items-center justify-center gap-3">
          <Sparkles className="h-6 w-6 animate-pulse text-primary" />
          <span className="text-lg text-foreground">Processing sign-in...</span>
        </div>
        <div className="mx-auto h-8 w-8 rounded-full border-4 border-primary/20 border-t-primary animate-spin" />
      </div>
    </AuthShell>
  );
}
