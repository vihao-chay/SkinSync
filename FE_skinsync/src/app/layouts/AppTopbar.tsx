import { Menu, X } from "lucide-react";
import { BrandMark } from "../components/BrandMark";
import { Button } from "../components/ui/button";

export function AppTopbar({
  userName,
  mobileOpen,
  onToggle,
}: {
  userName: string;
  mobileOpen: boolean;
  onToggle: () => void;
}) {
  return (
    <div className="sticky top-0 z-40 border-b border-border/70 bg-background/95 backdrop-blur md:hidden">
      <div className="flex items-center justify-between px-4 py-3">
        <div className="flex items-center gap-3">
          <BrandMark className="h-9 w-9 rounded-xl" />
          <div>
            <p className="text-sm font-medium text-foreground">SkinSync App</p>
            <p className="text-xs text-muted-foreground">{userName}</p>
          </div>
        </div>
        <Button variant="ghost" size="icon" className="text-foreground" onClick={onToggle}>
          {mobileOpen ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
        </Button>
      </div>
    </div>
  );
}
