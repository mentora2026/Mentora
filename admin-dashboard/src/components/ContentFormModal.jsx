import { useEffect, useState } from "react";
import { CONTENT_TYPE_LABELS } from "../lib/format";

export function ContentFormModal({ conditions, onSubmit, onClose, submitting, error }) {
  const [form, setForm] = useState({
    content_type: "article",
    key: "",
    chronic_condition_id: "",
    title_ar: "",
    body_ar: "",
    is_published: true,
  });

  useEffect(() => {
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = "";
    };
  }, []);

  const handleSubmit = (e) => {
    e.preventDefault();
    onSubmit({
      ...form,
      chronic_condition_id: form.chronic_condition_id || null,
      title_ar: form.title_ar || null,
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4">
      <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-lg bg-white p-6">
        <h2 className="font-display text-xl text-ink">محتوى تعليمي جديد</h2>

        <form onSubmit={handleSubmit} className="mt-4 space-y-4">
          <div>
            <label className="mb-1.5 block text-sm font-medium text-ink">نوع المحتوى</label>
            <select
              value={form.content_type}
              onChange={(e) => setForm((p) => ({ ...p, content_type: e.target.value }))}
              className="w-full rounded border border-line bg-paper px-3 py-2 text-sm outline-none focus:border-teal"
            >
              {Object.entries(CONTENT_TYPE_LABELS).map(([key, label]) => (
                <option key={key} value={key}>
                  {label}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-medium text-ink">المفتاح (key)</label>
            <input
              required
              dir="ltr"
              value={form.key}
              onChange={(e) => setForm((p) => ({ ...p, key: e.target.value }))}
              className="w-full rounded border border-line bg-paper px-3 py-2 text-sm outline-none focus:border-teal"
              placeholder="e.g. breathing_intro"
            />
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-medium text-ink">المرض المرتبط (اختياري)</label>
            <select
              value={form.chronic_condition_id}
              onChange={(e) => setForm((p) => ({ ...p, chronic_condition_id: e.target.value }))}
              className="w-full rounded border border-line bg-paper px-3 py-2 text-sm outline-none focus:border-teal"
            >
              <option value="">عام لجميع الأمراض</option>
              {conditions.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name_ar}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-medium text-ink">العنوان (اختياري)</label>
            <input
              value={form.title_ar}
              onChange={(e) => setForm((p) => ({ ...p, title_ar: e.target.value }))}
              className="w-full rounded border border-line bg-paper px-3 py-2 text-sm outline-none focus:border-teal"
            />
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-medium text-ink">المحتوى</label>
            <textarea
              required
              rows={5}
              value={form.body_ar}
              onChange={(e) => setForm((p) => ({ ...p, body_ar: e.target.value }))}
              className="w-full rounded border border-line bg-paper px-3 py-2 text-sm outline-none focus:border-teal"
            />
          </div>

          <label className="flex items-center gap-2 text-sm text-ink">
            <input
              type="checkbox"
              checked={form.is_published}
              onChange={(e) => setForm((p) => ({ ...p, is_published: e.target.checked }))}
              className="h-4 w-4 rounded border-line text-teal focus:ring-teal"
            />
            نشر هذا المحتوى فوراً
          </label>

          {error && <p className="text-sm text-terracotta">{error}</p>}

          <div className="flex justify-end gap-3 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="rounded border border-line px-4 py-2 text-sm text-ink transition hover:border-teal"
            >
              إلغاء
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="rounded bg-teal px-4 py-2 text-sm font-medium text-paper transition hover:bg-teal-600 disabled:opacity-60"
            >
              {submitting ? "جارِ الحفظ..." : "حفظ"}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
