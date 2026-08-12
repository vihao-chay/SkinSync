import { AppSkinProfileForm } from "./AppSkinProfileForm";

export function AppOnboardingPage() {
  return (
    <AppSkinProfileForm
      title="Onboarding"
      description="Complete your initial skin profile so SkinSync can move you from setup into analysis, routine, and daily tracking."
      redirectTo="/app/dashboard"
      saveBehavior="redirect"
    />
  );
}
