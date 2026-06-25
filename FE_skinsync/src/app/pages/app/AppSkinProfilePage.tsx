import { AppSkinProfileForm } from "./AppSkinProfileForm";

export function AppSkinProfilePage() {
  return (
    <AppSkinProfileForm
      title="Skin Profile"
      description="Review the profile details that shape your analysis context, routine decisions, and product browsing."
      redirectTo="/app/dashboard"
    />
  );
}
