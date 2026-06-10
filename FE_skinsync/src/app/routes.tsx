import { createBrowserRouter, Navigate, Outlet, useLocation, useRouteError } from "react-router";
import { LandingPage } from "./pages/LandingPage";
import { QuizPage } from "./pages/QuizPage";
import { UploadPage } from "./pages/UploadPage";
import { SkinAnalysisPage } from "./pages/SkinAnalysisPage";
import { RoutinePage } from "./pages/RoutinePage";
import { ProgressPage } from "./pages/ProgressPage";
import { CheckInPage } from "./pages/CheckInPage";
import { LoginPage } from "./pages/LoginPage";
import { ProfilePage } from "./pages/ProfilePage";
import { AdminDashboardPage } from "./pages/admin/AdminDashboardPage";
import { AdminProductsPage } from "./pages/admin/AdminProductsPage";
import { AdminAIConfigPage } from "./pages/admin/AdminAIConfigPage";
import { AdminUsersPage } from "./pages/admin/AdminUsersPage";
import { AdminProfilePage } from "./pages/admin/AdminProfilePage";
import { ForgotPasswordPage } from "./pages/ForgotPasswordPage";
import { ResetPasswordPage } from "./pages/ResetPasswordPage";
import { SecuritySettingsPage } from "./pages/SecuritySettingsPage";
import { Navigation } from "./components/Navigation";
import { AuthCallbackPage } from "./pages/AuthCallbackPage";
import { BlogPage } from "./pages/BlogPage";
import { TroGiupPage } from "./pages/TroGiupPage";
import { ChinhSachBaoMatPage } from "./pages/ChinhSachBaoMatPage";
import { DieuKhoanSuDungPage } from "./pages/DieuKhoanSuDungPage";
import { useAuth } from "./contexts/AuthContext";

function MainLayout() {
  return (
    <>
      <Navigation />
      <Outlet />
    </>
  );
}

function AdminLayout() {
  return <Outlet />;
}

function FullPageLoader() {
  return (
    <div className="min-h-screen bg-[#f5f5f0] flex items-center justify-center">
      <div className="w-8 h-8 border-2 border-[#c4a882]/30 border-t-[#c4a882] rounded-full animate-spin" />
    </div>
  );
}

function getRecoveryHash() {
  const hash = window.location.hash;
  if (!hash) {
    return null;
  }

  const hashParams = new URLSearchParams(hash.replace(/^#/, ""));
  const recoveryType = hashParams.get("type");
  const accessToken = hashParams.get("access_token");

  if (recoveryType === "recovery" && accessToken) {
    return hash;
  }

  return null;
}

function RequireAuth({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isInitializing } = useAuth();
  const recoveryHash = getRecoveryHash();

  if (recoveryHash) {
    return <Navigate to={{ pathname: "/reset-password", hash: recoveryHash }} replace />;
  }

  if (isInitializing) {
    return <FullPageLoader />;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  return <>{children}</>;
}

function GuestOnly({ children }: { children: React.ReactNode }) {
  const location = useLocation();
  const { isAuthenticated, isInitializing, user } = useAuth();
  const recoveryHash = getRecoveryHash();

  if (recoveryHash && location.pathname !== "/reset-password") {
    return <Navigate to={{ pathname: "/reset-password", hash: recoveryHash }} replace />;
  }

  if (isInitializing) {
    return <FullPageLoader />;
  }

  if (isAuthenticated) {
    if (user?.role === "admin") {
      return <Navigate to="/admin" replace />;
    }

    return <Navigate to="/" replace />;
  }

  return <>{children}</>;
}

function AdminOnly({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, isInitializing, user } = useAuth();

  if (isInitializing) {
    return <FullPageLoader />;
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace />;
  }

  if (user?.role !== "admin") {
    return <Navigate to="/" replace />;
  }

  return <>{children}</>;
}

function ErrorBoundary() {
  const error = useRouteError() as any;
  const is404 =
    error?.status === 404 ||
    (typeof error?.message === "string" && error.message.includes("No route matches"));

  return (
    <div className="min-h-screen bg-[#f5f5f0] flex items-center justify-center px-6">
      <div className="text-center max-w-md">
        <div className="w-20 h-20 rounded-3xl bg-gradient-to-br from-[#6366f1]/10 to-[#a855f7]/10 border border-[#6366f1]/15 flex items-center justify-center mx-auto mb-6 text-4xl">
          {is404 ? "🔍" : "⚠️"}
        </div>
        <h1 className="text-3xl text-[#1a1a2e] mb-2" style={{ fontWeight: 700 }}>
          {is404 ? "404" : "Có Lỗi Xảy Ra"}
        </h1>
        <p className="text-[#6b7280] mb-6">
          {is404
            ? "Trang bạn tìm kiếm không tồn tại."
            : "Đã xảy ra lỗi không mong muốn. Vui lòng thử lại."}
        </p>
        <a
          href="/"
          className="inline-flex items-center gap-2 px-6 py-3 rounded-2xl bg-gradient-to-r from-[#6366f1] to-[#a855f7] text-white text-sm shadow-lg shadow-[#6366f1]/25 hover:shadow-[#6366f1]/40 transition-all"
        >
          ← Về Trang Chủ
        </a>
      </div>
    </div>
  );
}

export const router = createBrowserRouter([
  {
    path: "/",
    element: <LandingPage />,
    errorElement: <ErrorBoundary />,
  },
  {
    // Main app layout with Navigation
    element: (
      <RequireAuth>
        <MainLayout />
      </RequireAuth>
    ),
    errorElement: <ErrorBoundary />,
    children: [
      { path: "quiz", element: <QuizPage /> },
      { path: "upload", element: <UploadPage /> },
      { path: "analysis", element: <SkinAnalysisPage /> },
      { path: "routine", element: <RoutinePage /> },
      { path: "progress", element: <ProgressPage /> },
      { path: "checkin", element: <CheckInPage /> },
      { path: "profile", element: <ProfilePage /> },
      { path: "settings/security", element: <SecuritySettingsPage /> },
      { path: "dashboard", element: <Navigate to="/analysis" replace /> },
    ],
  },
  {
    // Standalone pages (no nav)
    path: "/login",
    element: (
      <GuestOnly>
        <LoginPage />
      </GuestOnly>
    ),
    errorElement: <ErrorBoundary />,
  },
  {
    path: "/auth/callback",
    element: <AuthCallbackPage />,
    errorElement: <ErrorBoundary />,
  },
  {
    path: "/register",
    element: (
      <GuestOnly>
        <LoginPage initialMode="register" />
      </GuestOnly>
    ),
    errorElement: <ErrorBoundary />,
  },
  {
    path: "/forgot-password",
    element: <ForgotPasswordPage />,
    errorElement: <ErrorBoundary />,
  },
  {
    path: "/reset-password",
    element: <ResetPasswordPage />,
    errorElement: <ErrorBoundary />,
  },
  {
    // Public content pages
    path: "/blog",
    element: <BlogPage />,
    errorElement: <ErrorBoundary />,
  },
  {
    path: "/tro-giup",
    element: <TroGiupPage />,
    errorElement: <ErrorBoundary />,
  },
  {
    path: "/chinh-sach-bao-mat",
    element: <ChinhSachBaoMatPage />,
    errorElement: <ErrorBoundary />,
  },
  {
    path: "/dieu-khoan-su-dung",
    element: <DieuKhoanSuDungPage />,
    errorElement: <ErrorBoundary />,
  },
  {
    // Admin section
    path: "/admin",
    element: (
      <AdminOnly>
        <AdminLayout />
      </AdminOnly>
    ),
    errorElement: <ErrorBoundary />,
    children: [
      { index: true, element: <AdminDashboardPage /> },
      { path: "users", element: <AdminUsersPage /> },
      { path: "products", element: <AdminProductsPage /> },
      { path: "ai-config", element: <AdminAIConfigPage /> },
      { path: "profile", element: <AdminProfilePage /> },
    ],
  },
  {
    path: "*",
    element: <ErrorBoundary />,
  },
]);
