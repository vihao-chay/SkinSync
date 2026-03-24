import {
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
} from "recharts";
import {
  Users,
  ScanFace,
  BrainCircuit,
  TrendingUp,
  TrendingDown,
  ArrowUpRight,
  Activity,
  AlertCircle,
  CheckCircle2,
} from "lucide-react";
import { AdminLayout } from "../../components/AdminSidebar";

// ── Data ──────────────────────────────────────────────
const dailyAnalysisData = Array.from({ length: 30 }, (_, i) => ({
  day: `${i + 1}/3`,
  count: Math.floor(600 + (i > 20 ? i * 12 : i * 5) + 80),
}));

const skinTypeData = [
  { name: "Da Dầu", value: 34, color: "#c4a882" },
  { name: "Da Khô", value: 22, color: "#a5f3fc" },
  { name: "Hỗn Hợp", value: 28, color: "#8c6e52" },
  { name: "Nhạy Cảm", value: 16, color: "#f9a8d4" },
];

const weeklyStats = [
  { label: "T2", users: 420, analyses: 310 },
  { label: "T3", users: 380, analyses: 290 },
  { label: "T4", users: 510, analyses: 410 },
  { label: "T5", users: 490, analyses: 380 },
  { label: "T6", users: 620, analyses: 520 },
  { label: "T7", users: 750, analyses: 640 },
  { label: "CN", users: 560, analyses: 480 },
];

const recentActivity = [
  { user: "Nguyễn Lan Anh", action: "Hoàn thành phân tích da", time: "2 phút trước", type: "analysis" },
  { user: "Trần Minh Khoa", action: "Đăng ký tài khoản mới", time: "8 phút trước", type: "register" },
  { user: "Lê Thị Hoa", action: "Cập nhật lộ trình lần 3", time: "15 phút trước", type: "routine" },
  { user: "Phạm Thu Hiền", action: "Check-in ngày thứ 14", time: "22 phút trước", type: "checkin" },
  { user: "Đỗ Văn Nam", action: "Báo cáo sản phẩm không phù hợp", time: "41 phút trước", type: "report" },
];

const activityColor: Record<string, string> = {
  analysis: "bg-[#c4a882]/10 text-[#c4a882]",
  register: "bg-emerald-50 text-emerald-600",
  routine: "bg-[#8c6e52]/10 text-[#8c6e52]",
  checkin: "bg-amber-50 text-amber-600",
  report: "bg-red-50 text-red-500",
};

const activityIcon: Record<string, React.ReactNode> = {
  analysis: <ScanFace className="w-3.5 h-3.5" />,
  register: <Users className="w-3.5 h-3.5" />,
  routine: <Activity className="w-3.5 h-3.5" />,
  checkin: <CheckCircle2 className="w-3.5 h-3.5" />,
  report: <AlertCircle className="w-3.5 h-3.5" />,
};

// ── Tooltip components ────────────────────────────────
const DailyTooltip = ({ active, payload, label }: any) => {
  if (active && payload?.length) {
    return (
      <div className="bg-white border border-[#e5e7eb] rounded-2xl px-4 py-3 shadow-xl text-sm">
        <p className="text-[#6b7280] text-xs mb-1">Ngày {label}</p>
        <p className="text-[#c4a882]">Phân tích: <span style={{ fontWeight: 600 }}>{payload[0]?.value}</span></p>
      </div>
    );
  }
  return null;
};

const WeeklyTooltip = ({ active, payload, label }: any) => {
  if (active && payload?.length) {
    return (
      <div className="bg-white border border-[#e5e7eb] rounded-2xl px-4 py-3 shadow-xl text-sm">
        <p className="text-[#6b7280] text-xs mb-1">{label}</p>
        {payload[0] && <p className="text-[#c4a882]">Người dùng: <span style={{ fontWeight: 600 }}>{payload[0].value}</span></p>}
        {payload[1] && <p className="text-[#8c6e52]">Phân tích: <span style={{ fontWeight: 600 }}>{payload[1].value}</span></p>}
      </div>
    );
  }
  return null;
};

// ── Isolated Chart Components (prevent recharts internal key collision) ──

function DailyAnalysisChart() {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <AreaChart id="admin-dash-daily" data={dailyAnalysisData} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
        <defs>
          <linearGradient id="dash-daily-grad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="#c4a882" stopOpacity={0.18} />
            <stop offset="95%" stopColor="#c4a882" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" vertical={false} />
        <XAxis
          dataKey="day"
          axisLine={false}
          tickLine={false}
          tick={{ fill: "#9ca3af", fontSize: 10 }}
          interval={4}
        />
        <YAxis axisLine={false} tickLine={false} tick={{ fill: "#9ca3af", fontSize: 10 }} />
        <Tooltip content={<DailyTooltip />} />
        <Area
          type="monotone"
          dataKey="count"
          stroke="#c4a882"
          strokeWidth={2.5}
          fill="url(#dash-daily-grad)"
          dot={false}
          activeDot={{ r: 5, fill: "#c4a882", stroke: "#fff", strokeWidth: 2 }}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}

function WeeklyActivityChart() {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <AreaChart id="admin-dash-weekly" data={weeklyStats} margin={{ top: 5, right: 5, left: -20, bottom: 0 }}>
        <defs>
          <linearGradient id="dash-weekly-users-grad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="#c4a882" stopOpacity={0.15} />
            <stop offset="95%" stopColor="#c4a882" stopOpacity={0} />
          </linearGradient>
          <linearGradient id="dash-weekly-analyses-grad" x1="0" y1="0" x2="0" y2="1">
            <stop offset="5%" stopColor="#8c6e52" stopOpacity={0.12} />
            <stop offset="95%" stopColor="#8c6e52" stopOpacity={0} />
          </linearGradient>
        </defs>
        <CartesianGrid strokeDasharray="3 3" stroke="#f3f4f6" vertical={false} />
        <XAxis dataKey="label" axisLine={false} tickLine={false} tick={{ fill: "#9ca3af", fontSize: 11 }} />
        <YAxis axisLine={false} tickLine={false} tick={{ fill: "#9ca3af", fontSize: 11 }} />
        <Tooltip content={<WeeklyTooltip />} />
        <Area
          type="monotone"
          dataKey="users"
          stroke="#c4a882"
          strokeWidth={2}
          fill="url(#dash-weekly-users-grad)"
          dot={{ fill: "#c4a882", r: 3, strokeWidth: 2, stroke: "#fff" }}
        />
        <Area
          type="monotone"
          dataKey="analyses"
          stroke="#8c6e52"
          strokeWidth={2}
          fill="url(#dash-weekly-analyses-grad)"
          strokeDasharray="5 3"
          dot={{ fill: "#8c6e52", r: 3, strokeWidth: 2, stroke: "#fff" }}
        />
      </AreaChart>
    </ResponsiveContainer>
  );
}

function SkinTypeDonut() {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <PieChart id="admin-dash-skin-donut">
        <Pie
          data={skinTypeData}
          cx="50%"
          cy="50%"
          innerRadius={48}
          outerRadius={72}
          paddingAngle={3}
          dataKey="value"
        >
          {skinTypeData.map((entry, index) => (
            <Cell key={`skin-cell-${index}`} fill={entry.color} stroke="transparent" />
          ))}
        </Pie>
        <Tooltip formatter={(value) => [`${value}%`, "Tỷ lệ"]} />
      </PieChart>
    </ResponsiveContainer>
  );
}

// ── Page ─────────────────────────────────────────────
export function AdminDashboardPage() {
  const topStats = [
    {
      label: "Tổng Người Dùng",
      value: "12,450",
      delta: "+8.2%",
      up: true,
      icon: <Users className="w-5 h-5" />,
      color: "#c4a882",
      bg: "from-[#c4a882]/10 to-[#c4a882]/5",
      border: "border-[#c4a882]/15",
    },
    {
      label: "Lượt Phân Tích Hôm Nay",
      value: "842",
      delta: "+12.5%",
      up: true,
      icon: <ScanFace className="w-5 h-5" />,
      color: "#8c6e52",
      bg: "from-[#8c6e52]/10 to-[#8c6e52]/5",
      border: "border-[#8c6e52]/15",
    },
    {
      label: "Độ Chính Xác AI",
      value: "94%",
      delta: "+1.3%",
      up: true,
      icon: <BrainCircuit className="w-5 h-5" />,
      color: "#10b981",
      bg: "from-emerald-50 to-teal-50/60",
      border: "border-emerald-100",
    },
    {
      label: "Tỷ Lệ Churn",
      value: "2.1%",
      delta: "-0.4%",
      up: false,
      icon: <TrendingDown className="w-5 h-5" />,
      color: "#f59e0b",
      bg: "from-amber-50 to-orange-50/60",
      border: "border-amber-100",
    },
  ];

  return (
    <AdminLayout title="Tổng Quan">
      {/* KPI Cards */}
      <div className="grid grid-cols-2 xl:grid-cols-4 gap-4 mb-7">
        {topStats.map((stat) => (
          <div
            key={stat.label}
            className={`bg-gradient-to-br ${stat.bg} border ${stat.border} rounded-2xl p-5 flex flex-col gap-3`}
          >
            <div className="flex items-center justify-between">
              <div
                className="w-10 h-10 rounded-xl flex items-center justify-center"
                style={{ background: `${stat.color}18` }}
              >
                <span style={{ color: stat.color }}>{stat.icon}</span>
              </div>
              <span
                className={`flex items-center gap-0.5 text-xs px-2 py-1 rounded-full ${
                  stat.up ? "bg-emerald-50 text-emerald-600" : "bg-amber-50 text-amber-600"
                }`}
              >
                {stat.up ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
                {stat.delta}
              </span>
            </div>
            <div>
              <div className="text-2xl text-[#1a1a2e]" style={{ fontWeight: 700 }}>{stat.value}</div>
              <div className="text-xs text-[#6b7280] mt-0.5">{stat.label}</div>
            </div>
          </div>
        ))}
      </div>

      {/* Charts Row */}
      <div className="grid lg:grid-cols-3 gap-5 mb-5">
        {/* Area Chart — Daily Analysis */}
        <div className="lg:col-span-2 bg-white rounded-2xl border border-[#e5e7eb] shadow-sm p-6">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h2 className="text-[#1a1a2e] text-base" style={{ fontWeight: 600 }}>
                Lượt Phân Tích Hằng Ngày
              </h2>
              <p className="text-xs text-[#6b7280]">30 ngày gần nhất — Tháng 3/2026</p>
            </div>
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#c4a882]/8 text-[#c4a882] text-xs">
              <ArrowUpRight className="w-3.5 h-3.5" />
              Tổng: 18,420
            </div>
          </div>
          <div className="h-56">
            <DailyAnalysisChart />
          </div>
        </div>

        {/* Donut Chart — Skin Types */}
        <div className="bg-white rounded-2xl border border-[#e5e7eb] shadow-sm p-6">
          <div className="mb-4">
            <h2 className="text-[#1a1a2e] text-base" style={{ fontWeight: 600 }}>
              Các Loại Da Phổ Biến
            </h2>
            <p className="text-xs text-[#6b7280]">Phân phối người dùng</p>
          </div>
          <div className="h-44">
            <SkinTypeDonut />
          </div>
          <div className="grid grid-cols-2 gap-2 mt-2">
            {skinTypeData.map((item) => (
              <div key={item.name} className="flex items-center gap-2">
                <span
                  className="w-2.5 h-2.5 rounded-full flex-shrink-0 border"
                  style={{
                    backgroundColor: item.color,
                    borderColor: "#d1d5db",
                  }}
                />
                <span className="text-xs text-[#4b5563] truncate">{item.name}</span>
                <span className="text-xs text-[#9ca3af] ml-auto">{item.value}%</span>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Bottom Row */}
      <div className="grid lg:grid-cols-3 gap-5">
        {/* Weekly Chart */}
        <div className="lg:col-span-2 bg-white rounded-2xl border border-[#e5e7eb] shadow-sm p-6">
          <div className="flex items-center justify-between mb-5">
            <div>
              <h2 className="text-[#1a1a2e] text-base" style={{ fontWeight: 600 }}>
                Hoạt Động Tuần Này
              </h2>
              <p className="text-xs text-[#6b7280]">Người dùng hoạt động & lượt phân tích</p>
            </div>
            <div className="flex items-center gap-4 text-xs text-[#6b7280]">
              <span className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-[#c4a882]" />Người dùng
              </span>
              <span className="flex items-center gap-1.5">
                <span className="w-2.5 h-2.5 rounded-full bg-[#8c6e52]" />Phân tích
              </span>
            </div>
          </div>
          <div className="h-44">
            <WeeklyActivityChart />
          </div>
        </div>

        {/* Activity Feed */}
        <div className="bg-white rounded-2xl border border-[#e5e7eb] shadow-sm p-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-[#1a1a2e] text-base" style={{ fontWeight: 600 }}>
              Hoạt Động Gần Đây
            </h2>
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
          </div>
          <div className="flex flex-col gap-3.5">
            {recentActivity.map((item, i) => (
              <div key={i} className="flex items-start gap-3">
                <div className={`w-7 h-7 rounded-xl flex items-center justify-center flex-shrink-0 ${activityColor[item.type]}`}>
                  {activityIcon[item.type]}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs text-[#1a1a2e] truncate" style={{ fontWeight: 500 }}>{item.user}</p>
                  <p className="text-[11px] text-[#6b7280] truncate">{item.action}</p>
                  <p className="text-[10px] text-[#9ca3af]">{item.time}</p>
                </div>
              </div>
            ))}
          </div>
          <button className="w-full mt-4 py-2.5 rounded-xl border border-[#e5e7eb] text-xs text-[#6b7280] hover:text-[#c4a882] hover:border-[#c4a882]/30 transition-colors">
            Xem Tất Cả →
          </button>
        </div>
      </div>
    </AdminLayout>
  );
}