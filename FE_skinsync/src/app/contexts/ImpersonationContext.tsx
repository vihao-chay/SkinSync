import { createContext, useContext, useEffect, useMemo, useState } from "react";
import {
  clearImpersonationSession,
  endImpersonationApi,
  getImpersonationSession,
  saveImpersonationSession,
  startImpersonationApi,
  type ImpersonationSession,
} from "../services/impersonationService";

interface ImpersonationContextValue {
  session: ImpersonationSession | null;
  isImpersonating: boolean;
  start: (userId: string) => Promise<{ success: boolean; message: string }>;
  end: () => Promise<void>;
}

const ImpersonationContext = createContext<ImpersonationContextValue | undefined>(undefined);

export function ImpersonationProvider({ children }: { children: React.ReactNode }) {
  const [session, setSession] = useState<ImpersonationSession | null>(getImpersonationSession());

  useEffect(() => {
    const sync = () => setSession(getImpersonationSession());
    window.addEventListener("skinsync-impersonation-changed", sync);
    window.addEventListener("storage", sync);
    return () => {
      window.removeEventListener("skinsync-impersonation-changed", sync);
      window.removeEventListener("storage", sync);
    };
  }, []);

  const value = useMemo<ImpersonationContextValue>(() => ({
    session,
    isImpersonating: Boolean(session),
    start: async (userId: string) => {
      const result = await startImpersonationApi({ userId });
      if (!result.success || !result.content) {
        return {
          success: false,
          message: result.message || "Unable to start view as user.",
        };
      }

      saveImpersonationSession(result.content);
      setSession(result.content);
      return {
        success: true,
        message: result.message || "View as user started.",
      };
    },
    end: async () => {
      await endImpersonationApi();
      clearImpersonationSession();
      setSession(null);
    },
  }), [session]);

  return <ImpersonationContext.Provider value={value}>{children}</ImpersonationContext.Provider>;
}

export function useImpersonation() {
  const context = useContext(ImpersonationContext);
  if (!context) {
    throw new Error("useImpersonation must be used inside ImpersonationProvider");
  }

  return context;
}
