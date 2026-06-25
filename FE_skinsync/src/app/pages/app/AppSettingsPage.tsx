import { ShieldAlert, TimerReset, Trash2, UserRound } from "lucide-react";
import { useState } from "react";
import { Link, useNavigate } from "react-router";
import { AppEmptyState } from "../../components/AppEmptyState";
import { AppField } from "../../components/AppField";
import { AppPageHeader } from "../../components/AppPageHeader";
import { AppSection } from "../../components/AppSection";
import { Button } from "../../components/ui/button";
import { useAuth } from "../../contexts/AuthContext";
import { useImpersonation } from "../../contexts/ImpersonationContext";
import { changePasswordApi, updateProfileApi } from "../../services/authService";

export function AppSettingsPage() {
  const navigate = useNavigate();
  const { user, refreshCurrentUser, logout } = useAuth();
  const { isImpersonating } = useImpersonation();
  const [savingProfile, setSavingProfile] = useState(false);
  const [savingPassword, setSavingPassword] = useState(false);
  const [feedback, setFeedback] = useState("");
  const [profile, setProfile] = useState({
    fullName: user?.fullName || "",
    phone: user?.phone || "",
    email: user?.email || "",
  });
  const [passwords, setPasswords] = useState({
    oldPassword: "",
    newPassword: "",
  });

  return (
    <div className="space-y-6">
      <AppPageHeader
        eyebrow="Settings"
        title="Profile, security, and account preferences"
        description="The settings area is broken into clear sections so it behaves like a real user account center, not a loose collection of forms."
      />

      <div className="grid gap-4 xl:grid-cols-[1fr_0.95fr]">
        <AppSection title="Profile" description="Update the basic account information supported by the current backend.">
          <div className="grid gap-4">
            <AppField label="Name">
              <input
                className="app-input"
                value={profile.fullName}
                onChange={(event) => setProfile((prev) => ({ ...prev, fullName: event.target.value }))}
              />
            </AppField>
            <AppField label="Email" hint={isImpersonating ? "Email cannot be changed while viewing as user." : "Email is currently read-only."}>
              <input className="app-input bg-muted text-muted-foreground" value={profile.email} readOnly />
            </AppField>
            <AppField label="Phone">
              <input
                className="app-input"
                value={profile.phone}
                onChange={(event) => setProfile((prev) => ({ ...prev, phone: event.target.value }))}
              />
            </AppField>
            <div className="flex flex-wrap gap-3">
              <Button
                className="bg-primary text-primary-foreground hover:bg-primary/90"
                disabled={savingProfile}
                onClick={async () => {
                  setSavingProfile(true);
                  const result = await updateProfileApi(profile.fullName, profile.phone);
                  setSavingProfile(false);
                  setFeedback(result.message);
                  if (result.success) {
                    await refreshCurrentUser();
                  }
                }}
              >
                {savingProfile ? "Saving..." : "Save profile"}
              </Button>
              <Button asChild variant="outline" className="border-border bg-card hover:bg-muted">
                <Link to="/app/skin-profile">Open skin profile</Link>
              </Button>
            </div>
          </div>
        </AppSection>

        <AppSection title="Security" description="Higher-risk account actions are explicitly disabled during impersonation.">
          <div className="grid gap-4">
            <AppField label="Current password">
              <input
                className="app-input"
                type="password"
                disabled={isImpersonating}
                value={passwords.oldPassword}
                onChange={(event) => setPasswords((prev) => ({ ...prev, oldPassword: event.target.value }))}
              />
            </AppField>
            <AppField label="New password">
              <input
                className="app-input"
                type="password"
                disabled={isImpersonating}
                value={passwords.newPassword}
                onChange={(event) => setPasswords((prev) => ({ ...prev, newPassword: event.target.value }))}
              />
            </AppField>
            <Button
              className="bg-primary text-primary-foreground hover:bg-primary/90"
              disabled={savingPassword || isImpersonating}
              onClick={async () => {
                setSavingPassword(true);
                const result = await changePasswordApi(passwords.oldPassword, passwords.newPassword);
                setSavingPassword(false);
                setFeedback(result.message);
              }}
            >
              {savingPassword ? "Saving..." : "Change password"}
            </Button>
            {isImpersonating ? (
              <div className="rounded-2xl border border-border/70 bg-muted/70 px-4 py-3 text-sm text-foreground">
                Change password is disabled while viewing as user.
              </div>
            ) : null}
          </div>
        </AppSection>
      </div>

      <div className="grid gap-4 xl:grid-cols-[1fr_0.95fr]">
        <AppSection title="Preferences" description="Only preferences supported by the current backend are interactive.">
          <div className="grid gap-4">
            <div className="rounded-2xl border border-border/60 bg-muted/70 p-4">
              <div className="flex items-start gap-3">
                <TimerReset className="mt-0.5 h-5 w-5 text-primary" />
                <div>
                  <p className="text-sm font-medium text-foreground">Notifications and reminders</p>
                  <p className="mt-1 text-sm text-muted-foreground">
                    Reminder preference management is not available from the current backend flow yet.
                  </p>
                </div>
              </div>
            </div>
            <div className="rounded-2xl border border-border/60 bg-muted/70 p-4">
              <div className="flex items-start gap-3">
                <UserRound className="mt-0.5 h-5 w-5 text-primary" />
                <div>
                  <p className="text-sm font-medium text-foreground">Language and timezone</p>
                  <p className="mt-1 text-sm text-muted-foreground">
                    Language and timezone settings are not available yet. The user web app remains in English for consistency.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </AppSection>

        <AppSection title="Danger zone" description="High-risk actions stay obvious and constrained.">
          <div className="grid gap-4">
            <div className="rounded-2xl border border-red-100 bg-red-50 p-4">
              <div className="flex items-start gap-3">
                <ShieldAlert className="mt-0.5 h-5 w-5 text-red-500" />
                <div>
                  <p className="text-sm font-medium text-red-700">Delete account</p>
                  <p className="mt-1 text-sm text-red-600">
                    Delete account is unavailable from the current backend flow and remains disabled during impersonation.
                  </p>
                </div>
              </div>
            </div>
            {isImpersonating ? (
              <AppEmptyState
                title="Restricted actions while viewing as user"
                description="Change email, change password, delete account, and payment-related actions are disabled during impersonation."
                icon={ShieldAlert}
              />
            ) : null}
            <Button
              variant="outline"
              className="justify-start gap-2 border-border bg-card text-foreground hover:bg-muted"
              onClick={async () => {
                await logout();
                navigate("/login", { replace: true });
              }}
            >
              <Trash2 className="h-4 w-4" />
              Logout
            </Button>
          </div>
        </AppSection>
      </div>

      {feedback ? (
        <div className="rounded-2xl border border-border/70 bg-muted/70 px-4 py-3 text-sm text-foreground">{feedback}</div>
      ) : null}
    </div>
  );
}
