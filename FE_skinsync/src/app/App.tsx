import { RouterProvider } from "react-router";
import { router } from "./routes";
import { AuthProvider } from "./contexts/AuthContext";
import { ImpersonationProvider } from "./contexts/ImpersonationContext";
import { Toaster } from "./components/ui/sonner";

export default function App() {
  return (
    <AuthProvider>
      <ImpersonationProvider>
        <RouterProvider router={router} />
        <Toaster position="top-right" richColors closeButton />
      </ImpersonationProvider>
    </AuthProvider>
  );
}
