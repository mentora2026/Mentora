import { useEffect, useState } from "react";
import { AppShell } from "../components/AppShell";
import { ContentFormModal } from "../components/ContentFormModal";
import { EmptyState, ErrorState, LoadingState } from "../components/StateViews";
import { api } from "../lib/api";
import { ENDPOINTS } from "../lib/constants";
import { CONTENT_TYPE_LABELS } from "../lib/format";

export default function ContentLibraryPage() {
  const [items, setItems] = useState(null);
  const [conditions, setConditions] = useState([]);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  const [showForm, setShowForm] = useState(false);
  const [formError, setFormError] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const [data, conds] = await Promise.all([
        api.get(ENDPOINTS.adminContentLibrary),
        api.get(ENDPOINTS.chronicConditions),
      ]);
      setItems(data);
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
      const created = await api.post(ENDPOINTS.adminContentLibrary, payload);
      setItems((prev) => [created, ...prev]);
      setShowForm(false);
    } catch (err) {
      setFormError(err.messageAr);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <AppShell title="المحتوى التعليمي" description="إدارة المقالات والنصائح والمحتوى التوعوي المعروض للمرضى">
      <div className="mb-4 flex justify-end">
        <button
          onClick={() => setShowForm(true)}
          className="rounded bg-teal px-4 py-2 text-sm font-medium text-paper transition hover:bg-teal-600"
        >
          + محتوى جديد
        </button>
      </div>

      {loading && <LoadingState />}
      {error && <ErrorState message={error} onRetry={load} />}

      {items && (
        <div className="space-y-3">
          {items.length === 0 ? (
            <EmptyState title="لا يوجد محتوى تعليمي حتى الآن" />
          ) : (
            items.map((item) => (
              <div key={item.id} className="rounded-lg border border-line bg-white p-5">
                <div className="flex flex-wrap items-center gap-2">
                  <span className="rounded-full bg-sage-100 px-2.5 py-0.5 text-xs text-teal">
                    {CONTENT_TYPE_LABELS[item.content_type] || item.content_type}
                  </span>
                  <span className="tabular text-xs text-sage" dir="ltr">
                    {item.key}
                  </span>
                  {!item.is_published && <span className="text-xs text-terracotta">غير منشور</span>}
                </div>
                {item.title_ar && <h3 className="mt-2 font-medium text-ink">{item.title_ar}</h3>}
                <p className="mt-1 text-sm leading-relaxed text-sage">{item.body_ar}</p>
              </div>
            ))
          )}
        </div>
      )}

      {showForm && (
        <ContentFormModal
          conditions={conditions}
          onSubmit={handleSubmit}
          onClose={() => {
            setShowForm(false);
            setFormError(null);
          }}
          submitting={submitting}
          error={formError}
        />
      )}
    </AppShell>
  );
}
