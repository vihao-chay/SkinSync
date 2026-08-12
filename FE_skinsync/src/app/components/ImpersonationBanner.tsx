import { Link, useLocation, useNavigate } from "react-router";
import { Button } from "./ui/button";
import { useImpersonation } from "../contexts/ImpersonationContext";

export function ImpersonationBanner() {
  const { isImpersonating, session, end } = useImpersonation();
  const navigate = useNavigate();
  const location = useLocation();

  if (!isImpersonating || !session) {
    return null;
  }

  const returnPath = `/admin/users/${session.impersonatedUserId}`;

  return (
    <div className="sticky top-0 z-50 border-b border-border bg-muted/95 px-4 py-3 backdrop-blur">
      <div className="app-content flex flex-col gap-3 text-sm text-foreground md:flex-row md:items-center md:justify-between">
        <p>
          Admin mode: Viewing as <strong>{session.impersonatedUserEmail || session.impersonatedUserName}</strong>
        </p>
        <div className="flex flex-wrap gap-2">
          <Button
            variant="outline"
            className="border-border bg-card text-foreground hover:bg-background"
            onClick={async () => {
              await end();
              navigate(returnPath, { replace: true, state: { from: location.pathname } });
            }}
          >
            Exit View as User
          </Button>
          <Button asChild className="bg-primary text-primary-foreground hover:bg-primary/90">
            <Link to={returnPath}>Back to admin</Link>
          </Button>
        </div>
      </div>
    </div>
  );
}
