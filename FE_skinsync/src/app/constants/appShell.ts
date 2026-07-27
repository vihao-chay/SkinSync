import {
  Activity,
  Bot,
  ClipboardCheck,
  CreditCard,
  LayoutDashboard,
  Package,
  Sparkles,
  Settings,
  SquarePen,
  UserRound,
} from "lucide-react";

export const IMAGE_TYPES = ["image/jpeg", "image/png", "image/webp"];
export const MAX_FILE_SIZE = 5 * 1024 * 1024;

export const APP_SUGGESTED_CHAT_PROMPTS = [
  "Build a beginner routine",
  "Explain my latest analysis",
  "Check ingredient compatibility",
  "Suggest what to track today",
];

export const APP_NAV_SECTIONS = [
  {
    title: "Home",
    items: [{ to: "/app/dashboard", label: "Dashboard", icon: LayoutDashboard }],
  },
  {
    title: "Care",
    items: [
      { to: "/app/skin-profile", label: "Skin Profile", icon: UserRound },
      { to: "/app/analysis", label: "Skin Analysis", icon: Sparkles },
      { to: "/app/routine", label: "Routine", icon: SquarePen },
      { to: "/app/check-up", label: "Daily Check-up", icon: ClipboardCheck },
      { to: "/app/products", label: "Products", icon: Package },
      { to: "/app/recommendations", label: "AI Recommendations", icon: Sparkles },
      { to: "/app/progress", label: "Progress", icon: Activity },
    ],
  },
  {
    title: "AI",
    items: [{ to: "/app/chat", label: "AI Chat", icon: Bot }],
  },
  {
    title: "Account",
    items: [
      { to: "/app/subscription", label: "Subscription", icon: CreditCard },
      { to: "/app/settings", label: "Settings", icon: Settings },
    ],
  },
];
