import { Bot, LayoutDashboard, Package, Shield, Users } from "lucide-react";
import { Link, NavLink, Outlet } from "react-router";
import { BrandMark } from "../components/BrandMark";
import { useAuth } from "../contexts/AuthContext";

const links = [
  { to: "/admin/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { to: "/admin/users", label: "Users", icon: Users },
  { to: "/admin/products", label: "Products", icon: Package },
  { to: "/admin/ai-logs", label: "AI Logs", icon: Bot },
  { to: "/admin/subscriptions", label: "Subscriptions", icon: Shield },
];

export function AdminLayout() {
  const { user } = useAuth();

  return (
    <div className="min-h-screen bg-[#f7f3ed]">
      <div className="mx-auto flex min-h-screen max-w-7xl flex-col md:flex-row">
        <aside className="border-b border-[#e8d5b7]/60 bg-[#1f1b17] text-white md:min-h-screen md:w-72 md:border-b-0 md:border-r md:border-r-white/10">
          <div className="flex items-center gap-3 border-b border-white/10 px-5 py-5">
            <BrandMark className="h-10 w-10 rounded-xl" />
            <div>
              <Link to="/admin/dashboard" className="text-base text-white">SkinSync Admin</Link>
              <p className="text-xs text-white/60">{user?.email}</p>
            </div>
          </div>
          <nav className="grid gap-1 p-4">
            {links.map(({ to, label, icon: Icon }) => (
              <NavLink
                key={to}
                to={to}
                className={({ isActive }) =>
                  `flex items-center gap-3 rounded-2xl px-4 py-3 text-sm transition ${
                    isActive ? "bg-[#c2a67d] text-white" : "text-white/75 hover:bg-white/10 hover:text-white"
                  }`
                }
              >
                <Icon className="h-4 w-4" />
                <span>{label}</span>
              </NavLink>
            ))}
          </nav>
        </aside>
        <main className="flex-1 px-4 py-6 sm:px-6 lg:px-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
