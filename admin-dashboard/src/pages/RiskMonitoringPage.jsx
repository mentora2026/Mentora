import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { AppShell } from "../components/AppShell";
import { RiskBadge, RiskSpine } from "../components/RiskBadge";
import { EmptyState, ErrorState, LoadingState } from "../components/StateViews";
import { api } from "../lib/api";
import { ENDPOINTS } from "../lib/constants";
import { formatDateTime } from "../lib/format";

export default function RiskMonitoringPage() {
  const [entries, setEntries] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.get(ENDPOINTS.riskMonitoring);
      setEntries(data);
    } catch (err) {
      setError(err.messageAr);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const highRisk = entries?.filter((e) => e.latest_risk_level >= 4) ?? [];

  return (
    <AppShell title="مراقبة الخطر" description="قائمة المرضى مرتبة بحسب آخر تقييم نفسي، الأعلى خطراً أولاً">
      {loading && <LoadingState />}
      {error && <ErrorState message={error} onRetry={load} />}

      {entries && (
        <div className="space-y-6">
          {highRisk.length > 0 && (
            <div className="rounded-lg border border-terracotta/30 bg-terracotta-50 p-4">
              <p className="text-sm font-medium text-terracotta">
                {highRisk.length} {highRisk.length === 1 ? "مريض" : "مرضى"} يحتاجون مراجعة عاجلة (مستوى 4 أو 5)
              </p>
            </div>
          )}

          {entries.length === 0 ? (
            <EmptyState title="لا يوجد مرضى مسجلون حالياً" />
          ) : (
            <div className="overflow-hidden rounded-lg border border-line bg-white">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-line bg-paper/60 text-right text-xs text-sage">
                    <th className="px-5 py-3 font-medium">المريض</th>
                    <th className="px-5 py-3 font-medium">آخر تقييم</th>
                    <th className="px-5 py-3 font-medium">تاريخ التقييم</th>
                  </tr>
                </thead>
                <tbody>
                  {entries.map((entry) => (
                    <tr
                      key={entry.patient_profile_id}
                      className="cursor-pointer border-b border-line last:border-0 hover:bg-paper/60"
                      onClick={() => navigate(`/users/${entry.user_id}`)}
                    >
                      <td className="px-5 py-3.5">
                        <RiskSpine level={entry.latest_risk_level} className="-mr-1 pr-3">
                          <span className="font-medium text-ink">{entry.user_full_name}</span>
                        </RiskSpine>
                      </td>
                      <td className="px-5 py-3.5">
                        <RiskBadge level={entry.latest_risk_level} />
                      </td>
                      <td className="px-5 py-3.5 tabular text-sage">
                        {formatDateTime(entry.latest_assessment_at)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </AppShell>
  );
}
