import { useEffect, useState } from "react";
import { Bar, BarChart, CartesianGrid, Cell, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { AppShell } from "../components/AppShell";
import { StatCard } from "../components/StatCard";
import { ErrorState, LoadingState } from "../components/StateViews";
import { api } from "../lib/api";
import { ENDPOINTS } from "../lib/constants";
import { RISK_LEVEL_LABELS } from "../lib/format";

const RISK_COLORS = {
  1: "#4F8A5B",
  2: "#8BAA4E",
  3: "#D4A12C",
  4: "#D9763B",
  5: "#C1432E",
};

export default function OverviewPage() {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const overview = await api.get(ENDPOINTS.analyticsOverview);
      setData(overview);
    } catch (err) {
      setError(err.messageAr);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const chartData = data
    ? Object.entries(data.risk_level_distribution)
        .sort(([a], [b]) => Number(a) - Number(b))
        .map(([level, count]) => ({
          level: Number(level),
          label: `${level} · ${RISK_LEVEL_LABELS[level]}`,
          count,
        }))
    : [];

  return (
    <AppShell title="نظرة عامة" description="ملخص حالة المرضى والنشاط على المنصة">
      {loading && <LoadingState />}
      {error && <ErrorState message={error} onRetry={load} />}

      {data && (
        <div className="space-y-6">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <StatCard label="إجمالي المرضى" value={data.total_patients} />
            <StatCard
              label="نشطون خلال 7 أيام"
              value={data.active_patients_last_7_days}
              hint="مرضى أكملوا محادثة تفاعلية"
            />
            <StatCard
              label="جلسات آخر 30 يوم"
              value={data.total_sessions_last_30_days}
              hint="جلسات مكتملة"
            />
          </div>

          <div className="rounded-lg border border-line bg-white p-4 sm:p-6">
            <h2 className="font-display text-lg text-ink">توزيع مستويات الخطر</h2>
            <p className="mt-1 text-sm text-sage">عدد آخر التقييمات النفسية لكل مستوى خطر</p>
            <div className="mt-6 overflow-x-auto">
            <div className="h-72 min-w-[320px]">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData} margin={{ top: 8, right: 16, left: 0, bottom: 8 }}>
                  <CartesianGrid stroke="#E8E4DC" vertical={false} />
                  <XAxis
                    dataKey="label"
                    tick={{ fontSize: 12, fill: "#6B8E8E" }}
                    tickLine={false}
                    axisLine={{ stroke: "#E8E4DC" }}
                  />
                  <YAxis
                    allowDecimals={false}
                    tick={{ fontSize: 12, fill: "#6B8E8E" }}
                    tickLine={false}
                    axisLine={{ stroke: "#E8E4DC" }}
                  />
                  <Tooltip
                    cursor={{ fill: "#F6F5F1" }}
                    contentStyle={{ borderRadius: 8, border: "1px solid #E8E4DC", fontSize: 12 }}
                    formatter={(value) => [value, "عدد المرضى"]}
                  />
                  <Bar dataKey="count" radius={[4, 4, 0, 0]}>
                    {chartData.map((entry) => (
                      <Cell key={entry.level} fill={RISK_COLORS[entry.level]} />
                    ))}
                  </Bar>
                </BarChart>
               </ResponsiveContainer>
            </div>
            </div>
          </div>
        </div>
      )}
    </AppShell>
  );
}
