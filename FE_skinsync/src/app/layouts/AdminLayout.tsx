import { Bot, ChevronRight, LayoutDashboard, Package, Shield, Users } from "lucide-react";
import { Link, NavLink, Outlet } from "react-router";
import { BrandMark } from "../components/BrandMark";
import { Button } from "../components/ui/button";
import { useAuth } from "../contexts/AuthContext";
import "../styles/app-shell.css";

const links = [
  { to: "/admin/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { to: "/admin/users", label: "Users", icon: Users },
  { to: "/admin/products", label: "Products", icon: Package },
  { to: "/admin/ai-logs", label: "AI logs", icon: Bot },
  { to: "/admin/subscriptions", label: "Subscriptions", icon: Shield },
];

export function AdminLayout() {
  const { user, logout } = useAuth();

  return (
    <div className="app-admin-shell">
      <div className="app-admin-grid">
        <aside className="app-admin-sidebar">
          <div className="flex h-full flex-col">
            <div className="border-b border-border/80 px-6 py-6">
              <Link to="/admin/dashboard" className="flex items-center gap-3">
                <BrandMark className="h-12 w-12 rounded-2xl" />
                <div className="min-w-0">
                  <p className="truncate text-base font-semibold text-foreground">SkinSync Admin</p>
                  <p className="truncate text-xs tracking-[0.18em] text-muted-foreground uppercase">Control Center</p>
                </div>
              </Link>
            </div>

            <div className="px-5 pt-5">
              <div className="rounded-[28px] border border-border/70 bg-card/90 p-4 shadow-sm">
                <p className="text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground">Signed in</p>
                <p className="mt-3 truncate text-sm font-medium text-foreground">{user?.fullName || "Admin"}</p>
                <p className="truncate text-xs text-muted-foreground">{user?.email || "admin@skinsync.app"}</p>
              </div>
            </div>

            <nav className="flex-1 px-5 py-6">
              <p className="px-3 text-[11px] font-semibold uppercase tracking-[0.2em] text-muted-foreground">
                Workspace
              </p>
              <div className="mt-3 space-y-1.5">
                {links.map(({ to, label, icon: Icon }) => (
                  <NavLink
                    key={to}
                    to={to}
                    className={({ isActive }) =>
                      `flex items-center gap-3 rounded-2xl px-4 py-3 text-sm transition ${
                        isActive
                          ? "bg-primary text-primary-foreground shadow-sm"
                          : "text-foreground hover:bg-muted hover:text-foreground"
                      }`
                    }
                  >
                    {({ isActive }) => (
                      <>
                        <Icon className="h-4 w-4 shrink-0" />
                        <span className="flex-1">{label}</span>
                        {isActive ? <ChevronRight className="h-4 w-4 opacity-80" /> : null}
                      </>
                    )}
                  </NavLink>
                ))}
              </div>
            </nav>

            <div className="border-t border-border/80 p-5">
              <Button
                variant="outline"
                className="w-full justify-start border-border bg-card text-foreground hover:bg-muted"
                onClick={async () => {
                  await logout();
                }}
              >
                Sign out
              </Button>
            </div>
          </div>
        </aside>

        <div className="app-admin-main">
          <div className="app-admin-topbar">
            <div className="flex items-center justify-between px-6 py-4 lg:px-8">
              <div>
                <p className="text-xs font-semibold uppercase tracking-[0.22em] text-muted-foreground">Admin</p>
                <p className="text-sm text-foreground">Operations, catalog quality, AI usage, and subscriptions</p>
              </div>
            </div>
          </div>

          <main className="px-4 py-6 sm:px-6 lg:px-8">
            <div className="ss-page-wrap-app">
              <Outlet />
            </div>
          </main>
        </div>
      </div>
    </div>
  );
}
