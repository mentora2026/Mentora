import { useEffect, useState } from "react";
import { RECOMMENDATION_CATEGORY_LABELS } from "../lib/format";

const RISK_LEVELS = [1, 2, 3, 4, 5];

export function RecommendationFormModal({ initial, conditions, onSubmit, onClose, submitting, error }) {
  const [form, setForm] = useState({
    category: initial?.category || "motivational",
    chronic_condition_id: initial?.chronic_condition_id || "",
    applicable_risk_levels: initial?.applicable_risk_levels || [1, 2],
    title_ar: initial?.title_ar || "",
    content_ar: initial?.content_ar || "",
    media_url: initial?.media_url || "",
  });

  useEffect(() => {
    document.body.style.overflow = "hidden";
    return () => {
      document.body.style.overflow = "";
    };
  }, []);

  const toggleRiskLevel = (level) => {
    setForm((prev) => {
      const has = prev.applicable_risk_levels.includes(level);
      const next = has
        ? prev.applicable_risk_levels.filter((l) => l !== level)
        : [...prev.applicable_risk_levels, level].sort();
      return { ...prev, applicable_risk_levels: next };
    });
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    const payload = {
      ...form,
      chronic_condition_id: form.chronic_condition_id || null,
      media_url: form.media_url || null,
    };
    onSubmit(payload);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 px-4">
      <div className="max-h-[90vh] w-full max-w-lg overflow-y-auto rounded-lg bg-white p-6">
        <h2 className="font-display text-xl text-ink">{initial ? "تعديل التوصية" : "توصية جديدة"}</h2>

        <form onSubmit={handleSubmit} className="mt-4 space-y-4">
          <div>
            <label className="mb-1.5 block text-sm font-medium text-ink">التصنيف</label>
            <select
              value={form.category}
              onChange={(e) => setForm((p) => ({ ...p, category: e.target.value }))}
              className="w-full rounded border border-line bg-paper px-3 py-2 text-sm outline-none focus:border-teal"
            >
              {Object.entries(RECOMMENDATION_CATEGORY_LABELS).map(([key, label]) => (
                <option key={key} value={key}>
                  {label}
                </option>
              ))}
            </select>
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
            <label className="mb-1.5 block text-sm font-medium text-ink">مستويات الخطر المستهدفة</label>
            <div className="flex flex-wrap gap-2">
              {RISK_LEVELS.map((level) => (
                <button
                  type="button"
                  key={level}
                  onClick={() => toggleRiskLevel(level)}
                  className={`rounded-full border px-3 py-1 text-xs transition ${
                    form.applicable_risk_levels.includes(level)
                      ? "border-teal bg-teal-50 text-teal"
                      : "border-line text-sage"
                  }`}
                >
                  المستوى {level}
                </button>
              ))}
            </div>
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-medium text-ink">العنوان</label>
            <input
              required
              value={form.title_ar}
              onChange={(e) => setForm((p) => ({ ...p, title_ar: e.target.value }))}
              className="w-full rounded border border-line bg-paper px-3 py-2 text-sm outline-none focus:border-teal"
            />
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-medium text-ink">المحتوى</label>
            <textarea
              required
              rows={4}
              value={form.content_ar}
              onChange={(e) => setForm((p) => ({ ...p, content_ar: e.target.value }))}
              className="w-full rounded border border-line bg-paper px-3 py-2 text-sm outline-none focus:border-teal"
            />
          </div>

          <div>
            <label className="mb-1.5 block text-sm font-medium text-ink">رابط ملف صوتي/مرفق (اختياري)</label>
            <input
              dir="ltr"
              value={form.media_url}
              onChange={(e) => setForm((p) => ({ ...p, media_url: e.target.value }))}
              className="w-full rounded border border-line bg-paper px-3 py-2 text-sm outline-none focus:border-teal"
              placeholder="https://"
            />
          </div>

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
              disabled={submitting || form.applicable_risk_levels.length === 0}
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
