import { createBrowserRouter, Navigate, Outlet, useRouteError } from "react-router";
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
import { Navigation } from "./components/Navigation";

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
    // Main layout with Navigation
    path: "/",
    Component: MainLayout,
    errorElement: <ErrorBoundary />,
    children: [
      { index: true, element: <LandingPage /> },
      { path: "quiz", element: <QuizPage /> },
      { path: "upload", element: <UploadPage /> },
      { path: "analysis", element: <SkinAnalysisPage /> },
      { path: "routine", element: <RoutinePage /> },
      { path: "progress", element: <ProgressPage /> },
      { path: "checkin", element: <CheckInPage /> },
      { path: "profile", element: <ProfilePage /> },
      { path: "dashboard", element: <Navigate to="/analysis" replace /> },
    ],
  },
  {
    // Standalone pages (no nav)
    path: "/login",
    element: <LoginPage />,
    errorElement: <ErrorBoundary />,
  },
  {
    // Admin section
    path: "/admin",
    Component: AdminLayout,
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