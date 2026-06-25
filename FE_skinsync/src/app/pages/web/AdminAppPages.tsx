import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router";
import { Button } from "../../components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "../../components/ui/card";
import { ErrorState } from "../../components/ErrorState";
import { LoadingState } from "../../components/LoadingState";
import { PageHeader } from "../../components/PageHeader";
import { useImpersonation } from "../../contexts/ImpersonationContext";
import { getAdminAiLogsApi } from "../../services/adminAiLogService";
import { getAdminDashboardApi } from "../../services/adminDashboardService";
import { getAdminProductDetail, getAdminProducts, importAdminProductsCsv, toggleAdminProductActive } from "../../services/adminProductsService";
import { getAdminSubscriptionsApi } from "../../services/adminSubscriptionService";
import { getAdminUserDetailApi, getAdminUsersApi, updateAdminUserStatusApi } from "../../services/adminUserService";

export function AdminDashboardWebPage() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    void getAdminDashboardApi().then((result) => {
      setData(result.content);
      setLoading(false);
    });
  }, []);

  if (loading) return <LoadingState label="Loading admin dashboard..." />;
  if (!data) return <ErrorState message="Unable to load admin dashboard." />;

  return (
    <div className="space-y-6">
      <PageHeader title="Admin Dashboard" description="System overview from real backend summary endpoints." />
      <div className="grid gap-4 md:grid-cols-3">
        <AdminStatCard label="Total users" value={String(data.totalUsers)} />
        <AdminStatCard label="Active users" value={String(data.activeUsers)} />
        <AdminStatCard label="Analyses" value={String(data.totalAnalyses)} />
      </div>
      <Card className="border-[#e8d5b7]/60 bg-white/90">
        <CardHeader><CardTitle>Skin type distribution</CardTitle></CardHeader>
        <CardContent className="space-y-2 text-sm text-[#5b5249]">
          {Object.entries(data.skinTypeDistribution || {}).map(([key, value]) => (
            <div key={key} className="flex justify-between rounded-2xl bg-[#faf7f2] px-4 py-3">
              <span>{key}</span>
              <strong>{String(value)}</strong>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}

export function AdminUsersWebPage() {
  const navigate = useNavigate();
  const { start } = useImpersonation();
  const [users, setUsers] = useState<any[]>([]);
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    const result = await getAdminUsersApi(search);
    setUsers(result.content?.items || []);
    setLoading(false);
  };

  useEffect(() => { void load(); }, []);

  if (loading) return <LoadingState label="Loading users..." />;

  return (
    <div className="space-y-6">
      <PageHeader title="User Management" description="Search, review, update status, and launch view-as-user from real admin data." />
      <div className="flex gap-3">
        <input className="flex-1 rounded-2xl border border-[#d9c7a9] bg-white px-4 py-3" placeholder="Search by name or email" value={search} onChange={(event) => setSearch(event.target.value)} />
        <Button className="bg-[#c2a67d] hover:bg-[#b0946b]" onClick={() => void load()}>Search</Button>
      </div>
      <div className="space-y-3">
        {users.map((user) => (
          <Card key={user.id} className="border-[#e8d5b7]/60 bg-white/90">
            <CardContent className="flex flex-col gap-4 pt-6 md:flex-row md:items-center md:justify-between">
              <div>
                <p className="text-base text-[#2c2a28]">{user.fullName}</p>
                <p className="text-sm text-[#78716c]">{user.email}</p>
                <p className="text-xs text-[#8c6e52]">{user.status} • {user.planType}</p>
              </div>
              <div className="flex flex-wrap gap-2">
                <Button variant="outline" className="border-[#d9c7a9]" onClick={() => navigate(`/admin/users/${user.id}`)}>Details</Button>
                <Button variant="outline" className="border-[#d9c7a9]" onClick={async () => {
                  const nextStatus = user.status === "active" ? "inactive" : "active";
                  const result = await updateAdminUserStatusApi(user.id, nextStatus);
                  if (result.success) void load();
                }}>
                  {user.status === "active" ? "Deactivate" : "Activate"}
                </Button>
                <Button className="bg-[#1f1b17] text-white hover:bg-[#15120f]" onClick={async () => {
                  const result = await start(user.id);
                  if (result.success) navigate("/app/dashboard");
                }}>
                  View as User
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}

export function AdminUserDetailWebPage() {
  const { id = "" } = useParams();
  const { start } = useImpersonation();
  const navigate = useNavigate();
  const [detail, setDetail] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    void getAdminUserDetailApi(id).then((result) => {
      setDetail(result.content);
      setLoading(false);
    });
  }, [id]);

  if (loading) return <LoadingState label="Loading user detail..." />;
  if (!detail) return <ErrorState message="User detail unavailable." />;

  return (
    <div className="space-y-6">
      <PageHeader
        title={detail.fullName}
        description={`${detail.email} • ${detail.status} • ${detail.planType}`}
        actions={<Button className="bg-[#1f1b17] text-white hover:bg-[#15120f]" onClick={async () => {
          const result = await start(detail.id);
          if (result.success) navigate("/app/dashboard");
        }}>View as this user</Button>}
      />
      <Card className="border-[#e8d5b7]/60 bg-white/90">
        <CardHeader><CardTitle>Profile snapshot</CardTitle></CardHeader>
        <CardContent className="space-y-2 text-sm text-[#5b5249]">
          <p>Skin type: {detail.profile?.skinType || "Unavailable"}</p>
          <p>Concerns: {detail.profile?.skinConcerns?.join(", ") || "Unavailable"}</p>
          <p>Budget: {detail.profile?.monthlyBudget ?? "Unavailable"}</p>
        </CardContent>
      </Card>
      <Card className="border-[#e8d5b7]/60 bg-white/90">
        <CardHeader><CardTitle>Recent activity</CardTitle></CardHeader>
        <CardContent className="space-y-2 text-sm text-[#5b5249]">
          {(detail.recentActivities || []).length ? detail.recentActivities.map((activity: any) => (
            <div key={`${activity.type}-${activity.occurredAt}`} className="rounded-2xl bg-[#faf7f2] px-4 py-3">
              {activity.title} • {activity.occurredAt}
            </div>
          )) : <p className="text-[#78716c]">No recent activity.</p>}
        </CardContent>
      </Card>
    </div>
  );
}

export function AdminProductsWebPage() {
  const [data, setData] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    const result = await getAdminProducts(1, 20);
    setData(result.content?.items || []);
    setLoading(false);
  };

  useEffect(() => { void load(); }, []);
  if (loading) return <LoadingState label="Loading products..." />;

  return (
    <div className="space-y-6">
      <PageHeader
        title="Product Management"
        description="Catalog listing, active state control, and CSV import through real admin endpoints."
        actions={<Button className="bg-[#c2a67d] hover:bg-[#b0946b]" onClick={async () => { await importAdminProductsCsv(); void load(); }}>Import CSV</Button>}
      />
      <div className="space-y-3">
        {data.map((product) => (
          <Card key={product.id} className="border-[#e8d5b7]/60 bg-white/90">
            <CardContent className="flex flex-col gap-4 pt-6 md:flex-row md:items-center md:justify-between">
              <div>
                <p className="text-base text-[#2c2a28]">{product.name}</p>
                <p className="text-sm text-[#78716c]">{product.brand} • {product.category}</p>
              </div>
              <div className="flex flex-wrap gap-2">
                <Button asChild variant="outline" className="border-[#d9c7a9]"><Link to={`/admin/products/${product.id}`}>Details</Link></Button>
                <Button variant="outline" className="border-[#d9c7a9]" onClick={async () => { await toggleAdminProductActive(product.id); void load(); }}>
                  {product.isActive ? "Deactivate" : "Activate"}
                </Button>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>
    </div>
  );
}

export function AdminProductDetailWebPage() {
  const { id = "" } = useParams();
  const [product, setProduct] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    void getAdminProductDetail(id).then((result) => {
      setProduct(result.content || null);
      setLoading(false);
    });
  }, [id]);

  if (loading) return <LoadingState label="Loading product detail..." />;
  if (!product) return <ErrorState message="Product not found." />;

  return (
    <div className="space-y-6">
      <PageHeader title={product.name} description={`${product.brand} • ${product.category}`} />
      <Card className="border-[#e8d5b7]/60 bg-white/90">
        <CardContent className="space-y-3 pt-6 text-sm text-[#5b5249]">
          <p>Description: {product.description || "Unavailable"}</p>
          <p>Ingredients: {product.ingredients?.join(", ") || "Unavailable"}</p>
          <p>Source: {product.source || "Unavailable"}</p>
          <p>Usage time: {product.usageTime || "Unavailable"}</p>
        </CardContent>
      </Card>
    </div>
  );
}

export function AdminAiLogsWebPage() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    void getAdminAiLogsApi().then((result) => {
      setData(result.content);
      setLoading(false);
    });
  }, []);

  if (loading) return <LoadingState label="Loading AI logs..." />;
  if (!data) return <ErrorState message="Unable to load AI logs." />;

  return (
    <div className="space-y-6">
      <PageHeader title="AI Logs" description="Recent AI usage events with model, feature, and token information where available." />
      <div className="grid gap-4 md:grid-cols-2">
        <AdminStatCard label="Total logs" value={String(data.totalLogs)} />
        <AdminStatCard label="Distinct users" value={String(data.distinctUsers)} />
      </div>
      <Card className="border-[#e8d5b7]/60 bg-white/90">
        <CardContent className="space-y-2 pt-6 text-sm text-[#5b5249]">
          {data.items.map((item: any) => (
            <div key={item.id} className="rounded-2xl bg-[#faf7f2] px-4 py-3">
              {item.userEmail} • {item.featureName} • {item.model || "n/a"} • {item.usedAt}
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}

export function AdminSubscriptionsWebPage() {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    void getAdminSubscriptionsApi().then((result) => {
      setData(result.content);
      setLoading(false);
    });
  }, []);

  if (loading) return <LoadingState label="Loading subscriptions..." />;
  if (!data) return <ErrorState message="Unable to load subscriptions." />;

  return (
    <div className="space-y-6">
      <PageHeader title="Subscriptions" description="Subscription status across users from real backend records." />
      <div className="grid gap-4 md:grid-cols-2">
        <AdminStatCard label="Total subscriptions" value={String(data.totalSubscriptions)} />
        <AdminStatCard label="Active subscriptions" value={String(data.activeSubscriptions)} />
      </div>
      <Card className="border-[#e8d5b7]/60 bg-white/90">
        <CardContent className="space-y-2 pt-6 text-sm text-[#5b5249]">
          {data.items.map((item: any) => (
            <div key={item.subscriptionId} className="rounded-2xl bg-[#faf7f2] px-4 py-3">
              {item.userEmail} • {item.planName} • {item.status}
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}

function AdminStatCard({ label, value }: { label: string; value: string }) {
  return (
    <Card className="border-[#e8d5b7]/60 bg-white/90">
      <CardContent className="space-y-2 pt-6">
        <p className="text-xs uppercase tracking-wide text-[#8c6e52]">{label}</p>
        <p className="text-2xl text-[#2c2a28]">{value}</p>
      </CardContent>
    </Card>
  );
}
