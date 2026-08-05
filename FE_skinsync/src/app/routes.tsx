import { createBrowserRouter, Navigate, Outlet, useRouteError } from "react-router";
import { AppLayout } from "./layouts/AppLayout";
import { AdminLayout } from "./layouts/AdminLayout";
import { PublicLayout } from "./layouts/PublicLayout";
import { LandingPage } from "./pages/LandingPage";
import { LoginPage } from "./pages/LoginPage";
import { ForgotPasswordPage } from "./pages/ForgotPasswordPage";
import { ResetPasswordPage } from "./pages/ResetPasswordPage";
import { AuthCallbackPage } from "./pages/AuthCallbackPage";
import { BlogPage } from "./pages/BlogPage";
import { TroGiupPage } from "./pages/TroGiupPage";
import { ChinhSachBaoMatPage } from "./pages/ChinhSachBaoMatPage";
import { DieuKhoanSuDungPage } from "./pages/DieuKhoanSuDungPage";
import { useAuth } from "./contexts/AuthContext";
import {
  ContactPage,
  FeaturesPage,
  PricingPage,
  AboutPage,
  FaqPage,
} from "./pages/web/PublicPages";
import { AppAnalysisPage } from "./pages/app/AppAnalysisPage";
import { AppChatPage } from "./pages/app/AppChatPage";
import { AppCheckUpPage } from "./pages/app/AppCheckUpPage";
import { AppDashboardPage } from "./pages/app/AppDashboardPage";
import { AppOnboardingPage } from "./pages/app/AppOnboardingPage";
import { AppProductDetailPage } from "./pages/app/AppProductDetailPage";
import { AppProductsPage } from "./pages/app/AppProductsPage";
import { AppRecommendationsPage } from "./pages/app/AppRecommendationsPage";
import { AppProgressPage } from "./pages/app/AppProgressPage";
import { AppRoutinePage } from "./pages/app/AppRoutinePage";
import { AppSettingsPage } from "./pages/app/AppSettingsPage";
import { AppSkinProfilePage } from "./pages/app/AppSkinProfilePage";
import { AppSubscriptionPage } from "./pages/app/AppSubscriptionPage";
import {
  AdminAiLogsWebPage,
  AdminDashboardWebPage,
  AdminProductDetailWebPage,
  AdminProductsWebPage,
  AdminSubscriptionsWebPage,
  AdminUserDetailWebPage,
  AdminUsersWebPage,
} from "./pages/web/AdminAppPages";

function FullPageLoader() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-[#f9f6f0]">
      <div className="h-10 w-10 animate-spin rounded-full border-2 border-[#c2a67d]/20 border-t-[#c2a67d]" />
    </div>
  );
}

function UserRoute({ children }: { children: React.ReactNode }) {
  const { user, isAuthenticated, isInitializing } = useAuth();
  if (isInitializing) return <FullPageLoader />;
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (user?.role !== "user" && user?.role !== "admin") return <Navigate to="/403" replace />;
  return <>{children}</>;
}

function AdminRoute({ children }: { children: React.ReactNode }) {
  const { user, isAuthenticated, isInitializing } = useAuth();
  if (isInitializing) return <FullPageLoader />;
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (user?.role !== "admin") return <Navigate to="/403" replace />;
  return <>{children}</>;
}

function GuestOnly({ children }: { children: React.ReactNode }) {
  const { user, isAuthenticated, isInitializing } = useAuth();
  if (isInitializing) return <FullPageLoader />;
  if (!isAuthenticated) return <>{children}</>;
  return <Navigate to={user?.role === "admin" ? "/admin/dashboard" : "/app/dashboard"} replace />;
}

function ForbiddenPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-[#f9f6f0] px-6">
      <div className="max-w-md rounded-3xl border border-[#e8d5b7] bg-white/90 p-8 text-center shadow-sm">
        <h1 className="text-3xl text-[#2c2a28]">403</h1>
        <p className="mt-2 text-sm text-[#78716c]">You do not have permission to access this area.</p>
      </div>
    </div>
  );
}

function ErrorBoundary() {
  const error = useRouteError() as { status?: number };
  if (error?.status === 403) {
    return <ForbiddenPage />;
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-[#f9f6f0] px-6">
      <div className="max-w-md rounded-3xl border border-[#e8d5b7] bg-white/90 p-8 text-center shadow-sm">
        <h1 className="text-3xl text-[#2c2a28]">Something went wrong</h1>
        <p className="mt-2 text-sm text-[#78716c]">Please try again or return to the homepage.</p>
      </div>
    </div>
  );
}

function LayoutOutlet() {
  return <Outlet />;
}

export const router = createBrowserRouter([
  {
    element: <PublicLayout />,
    errorElement: <ErrorBoundary />,
    children: [
      { path: "/", element: <LandingPage /> },
      { path: "/features", element: <FeaturesPage /> },
      { path: "/pricing", element: <PricingPage /> },
      { path: "/about", element: <AboutPage /> },
      { path: "/faq", element: <FaqPage /> },
      { path: "/contact", element: <ContactPage /> },
      { path: "/blog", element: <BlogPage /> },
      { path: "/tro-giup", element: <TroGiupPage /> },
      { path: "/chinh-sach-bao-mat", element: <ChinhSachBaoMatPage /> },
      { path: "/dieu-khoan-su-dung", element: <DieuKhoanSuDungPage /> },
    ],
  },
  {
    element: <GuestOnly><LayoutOutlet /></GuestOnly>,
    errorElement: <ErrorBoundary />,
    children: [
      { path: "/login", element: <LoginPage /> },
      { path: "/register", element: <LoginPage initialMode="register" /> },
      { path: "/forgot-password", element: <ForgotPasswordPage /> },
      { path: "/reset-password", element: <ResetPasswordPage /> },
    ],
  },
  { path: "/auth/callback", element: <AuthCallbackPage />, errorElement: <ErrorBoundary /> },
  {
    path: "/app",
    element: <UserRoute><AppLayout /></UserRoute>,
    errorElement: <ErrorBoundary />,
    children: [
      { index: true, element: <Navigate to="/app/dashboard" replace /> },
      { path: "dashboard", element: <AppDashboardPage /> },
      { path: "onboarding", element: <AppOnboardingPage /> },
      { path: "skin-profile", element: <AppSkinProfilePage /> },
      { path: "analysis", element: <AppAnalysisPage /> },
      { path: "chat", element: <AppChatPage /> },
      { path: "routine", element: <AppRoutinePage /> },
      { path: "products", element: <AppProductsPage /> },
      { path: "products/:id", element: <AppProductDetailPage /> },
      { path: "recommendations", element: <AppRecommendationsPage /> },
      { path: "progress", element: <AppProgressPage /> },
      { path: "check-up", element: <AppCheckUpPage /> },
      { path: "subscription", element: <AppSubscriptionPage /> },
      { path: "settings", element: <AppSettingsPage /> },
    ],
  },
  {
    path: "/admin",
    element: <AdminRoute><AdminLayout /></AdminRoute>,
    errorElement: <ErrorBoundary />,
    children: [
      { index: true, element: <Navigate to="/admin/dashboard" replace /> },
      { path: "dashboard", element: <AdminDashboardWebPage /> },
      { path: "users", element: <AdminUsersWebPage /> },
      { path: "users/:id", element: <AdminUserDetailWebPage /> },
      { path: "products", element: <AdminProductsWebPage /> },
      { path: "products/:id", element: <AdminProductDetailWebPage /> },
      { path: "ai-logs", element: <AdminAiLogsWebPage /> },
      { path: "subscriptions", element: <AdminSubscriptionsWebPage /> },
    ],
  },
  { path: "/403", element: <ForbiddenPage /> },

  { path: "/dashboard", element: <Navigate to="/app/dashboard" replace /> },
  { path: "/analysis", element: <Navigate to="/app/analysis" replace /> },
  { path: "/routine", element: <Navigate to="/app/routine" replace /> },
  { path: "/progress", element: <Navigate to="/app/progress" replace /> },
  { path: "/checkin", element: <Navigate to="/app/check-up" replace /> },
  { path: "/profile", element: <Navigate to="/app/settings" replace /> },
  { path: "/quiz", element: <Navigate to="/app/skin-profile" replace /> },
  { path: "/subscription", element: <Navigate to="/pricing" replace /> },
  { path: "*", element: <Navigate to="/" replace /> },
]);
