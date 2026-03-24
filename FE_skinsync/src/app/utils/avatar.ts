import type { AuthUser } from "../services/authService";

const DEFAULT_AVATAR =
  "https://images.unsplash.com/photo-1630228462324-e29eec6e3f26?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400";

function createEmailAvatar(email: string, name?: string) {
  const seed = encodeURIComponent((name?.trim() || email.trim() || "SkinSync").toLowerCase());
  return `https://api.dicebear.com/9.x/initials/svg?seed=${seed}&backgroundType=gradientLinear`;
}

function normalizeAvatarUrl(rawUrl: string) {
  const trimmed = rawUrl.trim();
  if (!trimmed) {
    return trimmed;
  }

  if (trimmed.startsWith("/uploads/")) {
    return trimmed;
  }

  try {
    const parsed = new URL(trimmed);
    if (parsed.pathname.startsWith("/uploads/")) {
      return parsed.pathname;
    }
  } catch {
    return trimmed;
  }

  return trimmed;
}

export function resolveUserAvatar(user: AuthUser | null | undefined) {
  if (user?.avatarUrl && user.avatarUrl.trim()) {
    return normalizeAvatarUrl(user.avatarUrl);
  }

  if (user?.email && user.email.trim()) {
    return createEmailAvatar(user.email, user.fullName);
  }

  return DEFAULT_AVATAR;
}
