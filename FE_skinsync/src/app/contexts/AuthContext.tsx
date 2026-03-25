import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import {
  AUTH_STATE_CHANGED_EVENT,
  type AuthUser,
  clearAuthData,
  getSavedUser,
  isAuthenticated,
  loginApi,
  logoutApi,
  meApi,
  saveAuthData,
  setAuthProvider,
  setSavedUser,
} from "../services/authService";

interface AuthContextValue {
  user: AuthUser | null;
  isAuthenticated: boolean;
  isInitializing: boolean;
  login: (email: string, password: string) => Promise<{ success: boolean; message: string; user?: AuthUser }>;
  logout: () => Promise<void>;
  refreshCurrentUser: () => Promise<void>;
  setCurrentUser: (user: AuthUser | null) => void;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(getSavedUser());
  const [isInitializing, setIsInitializing] = useState(true);

  const hydrateCurrentUser = useCallback(async () => {
    if (!isAuthenticated()) {
      setUser(null);
      setIsInitializing(false);
      return;
    }

    const meResult = await meApi();
    if (meResult.success && meResult.content) {
      setSavedUser(meResult.content);
      setUser(meResult.content);
    } else {
      clearAuthData();
      setUser(null);
    }

    setIsInitializing(false);
  }, []);

  useEffect(() => {
    void hydrateCurrentUser();
  }, [hydrateCurrentUser]);

  useEffect(() => {
    const syncUserFromStorage = () => {
      setUser(getSavedUser());
    };

    const onStorageChange = (event: StorageEvent) => {
      if (event.key && !event.key.startsWith("skinsync_")) {
        return;
      }

      syncUserFromStorage();
    };

    window.addEventListener(AUTH_STATE_CHANGED_EVENT, syncUserFromStorage);
    window.addEventListener("storage", onStorageChange);
    return () => {
      window.removeEventListener(AUTH_STATE_CHANGED_EVENT, syncUserFromStorage);
      window.removeEventListener("storage", onStorageChange);
    };
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const result = await loginApi(email, password);
    if (!result.success || !result.content) {
      return {
        success: false,
        message: result.message || "Đăng nhập thất bại.",
      };
    }

    saveAuthData(result.content);
    setAuthProvider("password");
    setUser(result.content.user);

    return {
      success: true,
      message: result.message || "Đăng nhập thành công.",
      user: result.content.user,
    };
  }, []);

  const logout = useCallback(async () => {
    await logoutApi();
    setUser(null);
  }, []);

  const refreshCurrentUser = useCallback(async () => {
    const result = await meApi();
    if (result.success && result.content) {
      setSavedUser(result.content);
      setUser(result.content);
      return;
    }

    clearAuthData();
    setUser(null);
  }, []);

  const setCurrentUser = useCallback((nextUser: AuthUser | null) => {
    if (nextUser) {
      setSavedUser(nextUser);
    } else {
      clearAuthData();
    }
    setUser(nextUser);
  }, []);

  const value = useMemo<AuthContextValue>(() => ({
    user,
    isAuthenticated: Boolean(user),
    isInitializing,
    login,
    logout,
    refreshCurrentUser,
    setCurrentUser,
  }), [user, isInitializing, login, logout, refreshCurrentUser, setCurrentUser]);

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used inside AuthProvider");
  }

  return context;
}
