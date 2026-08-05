import { LogOut } from "lucide-react";
import { Link, NavLink } from "react-router";
import { APP_NAV_SECTIONS } from "../constants/appShell";
import { BrandMark } from "../components/BrandMark";
import { Button } from "../components/ui/button";

export function AppSidebar({
  userName,
  userEmail,
  planName,
  isImpersonating,
  compact = false,
  onNavigate,
  onLogout,
}: {
  userName: string;
  userEmail: string;
  planName: string;
  isImpersonating: boolean;
  compact?: boolean;
  onNavigate: () => void;
  onLogout: () => Promise<void>;
}) {
  return (
    <div className="flex h-full min-h-0 flex-col">
      <div className="border-b border-border/70 px-5 py-5">
        <Link to="/app/dashboard" onClick={onNavigate} className="flex items-center gap-3">
          <BrandMark className="h-11 w-11 rounded-2xl" />
          <div className="min-w-0">
            <p className="truncate text-base font-medium text-foreground">SkinSync App</p>
            <p className="truncate text-xs text-muted-foreground">Personal skincare workspace</p>
          </div>
        </Link>
      </div>

      <div className="px-4 pt-4">
        <div className="rounded-[20px] border border-border/60 bg-muted/70 px-4 py-4">
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-card text-sm font-medium text-foreground shadow-sm">
              {userName
                .split(/\s+/)
                .slice(0, 2)
                .map((part) => part[0])
                .join("")
                .toUpperCase()}
            </div>
            <div className="min-w-0">
              <p className="truncate text-sm font-medium text-foreground">{userName}</p>
              <p className="truncate text-xs text-muted-foreground">{userEmail}</p>
            </div>
          </div>
          <div className="mt-4 flex flex-wrap gap-2">
            <span className="app-pill">{planName}</span>
            {isImpersonating ? <span className="app-pill">Viewing as user</span> : null}
          </div>
        </div>
      </div>

      <nav className={`min-h-0 px-4 py-5 ${compact ? "overflow-y-auto" : "flex-1 overflow-y-auto"}`}>
        <div className="space-y-6">
          {APP_NAV_SECTIONS.map((section) => (
            <div key={section.title} className="space-y-2">
              <p className="px-3 text-[11px] font-medium uppercase tracking-[0.16em] text-muted-foreground">
                {section.title}
              </p>
              <div className="space-y-1">
                {section.items.map(({ to, label, icon: Icon }) => (
                  <NavLink
                    key={to}
                    to={to}
                    onClick={onNavigate}
                    className={({ isActive }) =>
                      `flex min-h-11 items-center gap-3 rounded-2xl px-4 py-3 text-sm transition ${
                        isActive
                          ? "bg-primary text-primary-foreground shadow-sm"
                          : "text-foreground hover:bg-muted hover:text-foreground"
                      }`
                    }
                  >
                    <Icon className="h-4 w-4 shrink-0" />
                    <span>{label}</span>
                  </NavLink>
                ))}
              </div>
            </div>
          ))}
        </div>
      </nav>

      <div className="border-t border-border/70 p-4">
        <Button
          variant="outline"
          className="w-full justify-start gap-2 border-border bg-card text-foreground hover:bg-muted"
          onClick={async () => {
            onNavigate();
            await onLogout();
          }}
        >
          <LogOut className="h-4 w-4" />
          Logout
        </Button>
      </div>
    </div>
  );
}
