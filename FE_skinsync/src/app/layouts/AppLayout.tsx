import { useEffect, useState } from "react";
import { Outlet } from "react-router";
import { useAuth } from "../contexts/AuthContext";
import { useImpersonation } from "../contexts/ImpersonationContext";
import { ImpersonationBanner } from "../components/ImpersonationBanner";
import { getCurrentSubscriptionApi } from "../services/subscriptionService";
import { AppSidebar } from "./AppSidebar";
import { AppTopbar } from "./AppTopbar";
import "../styles/app-shell.css";

export function AppLayout() {
  const { user, logout } = useAuth();
  const { isImpersonating } = useImpersonation();
  const [mobileOpen, setMobileOpen] = useState(false);
  const [planName, setPlanName] = useState("Plan unavailable");

  useEffect(() => {
    let active = true;
    void getCurrentSubscriptionApi().then((result) => {
      if (!active) return;
      if (result.success && result.content?.plan?.name) {
        setPlanName(result.content.plan.name);
      }
    });

    return () => {
      active = false;
    };
  }, []);

  return (
    <div className="app-shell">
      <ImpersonationBanner />
      <div className="app-shell-grid">
        <aside className="app-sidebar">
          <AppSidebar
            userName={user?.fullName || "User"}
            userEmail={user?.email || "user@skinsync.app"}
            planName={planName}
            isImpersonating={isImpersonating}
            onNavigate={() => undefined}
            onLogout={logout}
          />
        </aside>

        <div className="app-main">
          <AppTopbar
            userName={user?.fullName || "User"}
            mobileOpen={mobileOpen}
            onToggle={() => setMobileOpen((value) => !value)}
          />
          {mobileOpen ? (
            <div className="app-mobile-drawer md:hidden">
              <button
                type="button"
                aria-label="Close sidebar"
                className="app-mobile-overlay"
                onClick={() => setMobileOpen(false)}
              />
              <div className="app-mobile-panel">
                <AppSidebar
                  userName={user?.fullName || "User"}
                  userEmail={user?.email || "user@skinsync.app"}
                  planName={planName}
                  isImpersonating={isImpersonating}
                  onNavigate={() => setMobileOpen(false)}
                  onLogout={logout}
                  compact
                />
              </div>
            </div>
          ) : null}

          <main className="min-w-0 px-4 py-6 sm:px-6 lg:px-8 xl:px-10">
            <div className="app-content">
              <Outlet />
            </div>
          </main>
        </div>
      </div>
    </div>
  );
}
