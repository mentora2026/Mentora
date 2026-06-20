import { useEffect, useState } from "react";
import { RecommendationFormModal } from "../components/RecommendationFormModal";
import { AppShell } from "../components/AppShell";
import { EmptyState, ErrorState, LoadingState } from "../components/StateViews";
import { api } from "../lib/api";
import { ENDPOINTS } from "../lib/constants";
import { RECOMMENDATION_CATEGORY_LABELS } from "../lib/format";

export default function RecommendationsPage() {
  const [recommendations, setRecommendations] = useState(null);
  const [conditions, setConditions] = useState([]);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  const [editing, setEditing] = useState(null); // null | {} (new) | recommendation object
  const [formError, setFormError] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const [recs, conds] = await Promise.all([
        api.get(ENDPOINTS.adminRecommendations),
        api.get(ENDPOINTS.chronicConditions),
      ]);
      setRecommendations(recs);
      setConditions(conds);
    } catch (err) {
      setError(err.messageAr);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
  }, []);

  const handleSubmit = async (payload) => {
    setSubmitting(true);
    setFormError(null);
    try {
      if (editing?.id) {
        const updated = await api.put(ENDPOINTS.adminRecommendation(editing.id), payload);
        setRecommendations((prev) => prev.map((r) => (r.id === updated.id ? updated : r)));
      } else {
        const created = await api.post(ENDPOINTS.adminRecommendations, payload);
        setRecommendations((prev) => [created, ...prev]);
      }
      setEditing(null);
    } catch (err) {
      setFormError(err.messageAr);
    } finally {
      setSubmitting(false);
    }
  };

  const toggleActive = async (rec) => {
    try {
      if (rec.is_active) {
        await api.delete(ENDPOINTS.adminRecommendation(rec.id));
        setRecommendations((prev) => prev.map((r) => (r.id === rec.id ? { ...r, is_active: false } : r)));
      } else {
        const updated = await api.put(ENDPOINTS.adminRecommendation(rec.id), { is_active: true });
        setRecommendations((prev) => prev.map((r) => (r.id === rec.id ? updated : r)));
      }
    } catch (err) {
      setError(err.messageAr);
    }
  };

  const conditionNameById = Object.fromEntries(conditions.map((c) => [c.id, c.name_ar]));

  return (
    <AppShell title="التوصيات" description="إدارة محتوى التوصيات المقدمة للمرضى حسب مستوى الخطر والمرض">
      <div className="mb-4 flex justify-end">
        <button
          onClick={() => setEditing({})}
          className="rounded-lg bg-teal px-4 py-2 text-sm font-medium text-paper transition hover:bg-teal-600 active:bg-teal-700"
        >
          + توصية جديدة
        </button>
      </div>

      {loading && <LoadingState />}
      {error && <ErrorState message={error} onRetry={load} />}

      {recommendations && (
        <div className="space-y-3">
          {recommendations.length === 0 ? (
            <EmptyState title="لا توجد توصيات حتى الآن" />
          ) : (
            recommendations.map((rec) => (
              <div
                key={rec.id}
                className={`rounded-lg border bg-white p-5 ${rec.is_active ? "border-line" : "border-line opacity-50"}`}
              >
                <div className="flex items-start justify-between gap-4">
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="rounded-full bg-sage-100 px-2.5 py-0.5 text-xs text-teal">
                        {RECOMMENDATION_CATEGORY_LABELS[rec.category] || rec.category}
                      </span>
                      {rec.chronic_condition_id && (
                        <span className="rounded-full border border-line px-2.5 py-0.5 text-xs text-sage">
                          {conditionNameById[rec.chronic_condition_id] || "مرض محدد"}
                        </span>
                      )}
                      <span className="text-xs text-sage">
                        المستويات: {rec.applicable_risk_levels.join("، ")}
                      </span>
                      {!rec.is_active && <span className="text-xs text-terracotta">معطلة</span>}
                    </div>
                    <h3 className="mt-2 font-medium text-ink">{rec.title_ar}</h3>
                    <p className="mt-1 text-sm leading-relaxed text-sage">{rec.content_ar}</p>
                  </div>
                  <div className="flex shrink-0 flex-col gap-2">
                    <button
                      onClick={() => setEditing(rec)}
                      className="rounded border border-line px-3 py-1 text-xs text-ink transition hover:border-teal hover:text-teal"
                    >
                      تعديل
                    </button>
                    <button
                      onClick={() => toggleActive(rec)}
                      className="rounded border border-line px-3 py-1 text-xs text-ink transition hover:border-teal hover:text-teal"
                    >
                      {rec.is_active ? "تعطيل" : "تفعيل"}
                    </button>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {editing !== null && (
        <RecommendationFormModal
          initial={editing.id ? editing : null}
          conditions={conditions}
          onSubmit={handleSubmit}
          onClose={() => {
            setEditing(null);
            setFormError(null);
          }}
          submitting={submitting}
          error={formError}
        />
      )}
    </AppShell>
  );
}
