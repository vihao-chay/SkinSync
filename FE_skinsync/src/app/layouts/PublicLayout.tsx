import { Link, Outlet } from "react-router";
import { Navigation } from "../components/Navigation";
import { Footer } from "../components/SiteFooter";

export function PublicLayout() {
  return (
    <div className="min-h-screen bg-[#f9f6f0] text-[#2c2a28]">
      <Navigation />
      <main className="pt-16">
        <Outlet />
      </main>
      <Footer />
      <div className="border-t border-[#e8d5b7]/60 bg-white/70 px-4 py-3 text-center text-xs text-[#78716c]">
        <Link to="/features" className="mx-2 hover:text-[#8c6e52]">Features</Link>
        <Link to="/pricing" className="mx-2 hover:text-[#8c6e52]">Pricing</Link>
        <Link to="/faq" className="mx-2 hover:text-[#8c6e52]">FAQ</Link>
        <Link to="/contact" className="mx-2 hover:text-[#8c6e52]">Support</Link>
      </div>
    </div>
  );
}
