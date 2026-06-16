import { useEffect, useState } from "react";
import { AppShell } from "../components/AppShell";
import { EmptyState, ErrorState, LoadingState } from "../components/StateViews";
import { api } from "../lib/api";
import { ENDPOINTS } from "../lib/constants";
import { formatDateTime } from "../lib/format";

const ACTION_LABELS = {
  user_status_updated: "تحديث حالة المستخدم",
};

export default function AuditLogsPage() {
  const [logs, setLogs] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.get(ENDPOINTS.auditLogs);
      setLogs(data);
    } catch (err) {
      setError(err.messageAr);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  return (
    <AppShell title="سجل التدقيق" description="سجل الإجراءات الإدارية والتغييرات المهمة على المنصة">
      {loading && <LoadingState />}
      {error && <ErrorState message={error} onRetry={load} />}

      {logs && (
        <div className="overflow-hidden rounded-lg border border-line bg-white">
          {logs.length === 0 ? (
            <EmptyState title="لا توجد سجلات تدقيق حتى الآن" />
          ) : (
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-line bg-paper/60 text-right text-xs text-sage">
                  <th className="px-5 py-3 font-medium">الإجراء</th>
                  <th className="px-5 py-3 font-medium">الجدول المستهدف</th>
                  <th className="px-5 py-3 font-medium">المعرّف المستهدف</th>
                  <th className="px-5 py-3 font-medium">التفاصيل</th>
                  <th className="px-5 py-3 font-medium">التاريخ</th>
                </tr>
              </thead>
              <tbody>
                {logs.map((log) => (
                  <tr key={log.id} className="border-b border-line last:border-0">
                    <td className="px-5 py-3.5 font-medium text-ink">{ACTION_LABELS[log.action] || log.action}</td>
                    <td className="px-5 py-3.5 tabular text-sage" dir="ltr">
                      {log.target_table}
                    </td>
                    <td className="max-w-[160px] truncate px-5 py-3.5 tabular text-sage" dir="ltr">
                      {log.target_id}
                    </td>
                    <td className="px-5 py-3.5 tabular text-xs text-sage" dir="ltr">
                      {log.metadata_json ? JSON.stringify(log.metadata_json) : "—"}
                    </td>
                    <td className="px-5 py-3.5 tabular text-sage">{formatDateTime(log.created_at)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </AppShell>
  );
}
