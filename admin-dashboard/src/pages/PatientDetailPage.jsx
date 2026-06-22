import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { AppShell } from "../components/AppShell";
import { RiskBadge, RiskSpine } from "../components/RiskBadge";
import { EmptyState, ErrorState, LoadingState } from "../components/StateViews";
import { api } from "../lib/api";
import { ENDPOINTS } from "../lib/constants";
import { formatDateTime, formatNumber, SESSION_STATUS_LABELS } from "../lib/format";

const ACTIVITY_LABELS = {
  sedentary: "قليل الحركة",
  light: "نشاط خفيف",
  moderate: "نشاط متوسط",
  active: "نشيط",
};

const SOCIAL_SUPPORT_LABELS = {
  none: "لا يوجد دعم",
  low: "دعم محدود",
  medium: "دعم متوسط",
  high: "دعم قوي",
};

export default function PatientDetailPage() {
  const { userId } = useParams();
  const navigate = useNavigate();
  const [detail, setDetail] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  // Send Recommendation Modal State
  const [showRecModal, setShowRecModal] = useState(false);
  const [recTitle, setRecTitle] = useState("");
  const [recContent, setRecContent] = useState("");
  const [recSending, setRecSending] = useState(false);
  const [recError, setRecError] = useState(null);
  const [recSuccess, setRecSuccess] = useState(false);

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.get(ENDPOINTS.adminPatientDetail(userId));
      setDetail(data);
    } catch (err) {
      setError(err.messageAr);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [userId]);

  const handleSendRec = async (e) => {
    e.preventDefault();
    setRecSending(true);
    setRecError(null);
    setRecSuccess(false);

    try {
      await api.post(ENDPOINTS.sendDirectRecommendation(detail.patient_profile_id), {
        title_ar: recTitle,
        content_ar: recContent,
      });
      setRecSuccess(true);
      setTimeout(() => {
        setShowRecModal(false);
        setRecTitle("");
        setRecContent("");
        setRecSuccess(false);
      }, 2000);
    } catch (err) {
      setRecError(err.messageAr);
    } finally {
      setRecSending(false);
    }
  };

  const latestRiskLevel = detail?.risk_history?.[0]?.risk_level ?? null;

  return (
    <AppShell title={detail ? detail.full_name : "ملف المريض"} description={detail ? detail.email : ""}>
      <div className="flex items-center justify-between mb-4">
        <button
          onClick={() => navigate(-1)}
          className="inline-flex items-center gap-1.5 text-sm text-sage transition hover:text-teal"
        >
          <svg className="h-4 w-4 rotate-180" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
            <path d="M9 18l6-6-6-6" strokeLinecap="round" strokeLinejoin="round" />
          </svg>
          رجوع
        </button>

        {detail && (
          <button
            onClick={() => setShowRecModal(true)}
            className="rounded-md bg-teal px-4 py-2 text-sm font-medium text-white transition hover:bg-teal-600 shadow-sm"
          >
            إرسال توصية مباشرة
          </button>
        )}
      </div>

      {loading && <LoadingState />}
      {error && <ErrorState message={error} onRetry={load} />}

      {detail && (
        <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
          {/* Profile summary sidebar */}
          <div className="space-y-4 lg:col-span-1">
            <div className="rounded-lg border border-line bg-white p-5">
              <h2 className="font-display text-lg text-ink">الحالة الحالية</h2>
              <div className="mt-3">
                <RiskBadge level={latestRiskLevel} size="lg" />
              </div>
            </div>

            <div className="rounded-lg border border-line bg-white p-5">
              <h2 className="font-display text-lg text-ink">معلومات الملف الشخصي</h2>
              <dl className="mt-3 space-y-2.5 text-sm">
                <Row label="إعداد الملف" value={detail.onboarding_completed ? "مكتمل" : "غير مكتمل"} />
                <Row
                  label="مستوى النشاط"
                  value={detail.activity_level ? ACTIVITY_LABELS[detail.activity_level] : "—"}
                />
                <Row
                  label="الدعم الاجتماعي"
                  value={detail.social_support_level ? SOCIAL_SUPPORT_LABELS[detail.social_support_level] : "—"}
                />
                <Row
                  label="متوسط ساعات النوم"
                  value={detail.sleep_hours_avg !== null ? `${formatNumber(detail.sleep_hours_avg)} ساعات` : "—"}
                />
                <Row
                  label="مدة المرض"
                  value={
                    detail.disease_duration_months !== null
                      ? `${formatNumber(detail.disease_duration_months, 0)} شهر`
                      : "—"
                  }
                />
                <Row label="تاريخ التسجيل" value={formatDateTime(detail.created_at)} />
              </dl>
            </div>

            <div className="rounded-lg border border-line bg-white p-5">
              <h2 className="font-display text-lg text-ink">الأمراض المزمنة</h2>
              {detail.conditions.length === 0 ? (
                <p className="mt-2 text-sm text-sage">لم يتم تسجيل أمراض مزمنة</p>
              ) : (
                <ul className="mt-3 flex flex-wrap gap-2">
                  {detail.conditions.map((c) => (
                    <li
                      key={c.code}
                      className={`rounded-full border px-3 py-1 text-xs ${
                        c.is_primary ? "border-teal bg-teal-50 text-teal" : "border-line text-ink"
                      }`}
                    >
                      {c.name_ar}
                      {c.is_primary && " · أساسي"}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          </div>

          {/* History main content */}
          <div className="space-y-5 lg:col-span-2">
            {/* Risk assessment history */}
            <div className="rounded-lg border border-line bg-white p-5">
              <h2 className="font-display text-lg text-ink">سجل التقييمات النفسية</h2>
              {detail.risk_history.length === 0 ? (
                <EmptyState title="لا يوجد تقييمات نفسية بعد" />
              ) : (
                <div className="mt-3 overflow-x-auto rounded border border-line">
                  <table className="w-full text-sm min-w-[360px]">
                    <thead>
                      <tr className="border-b border-line bg-paper/60 text-right text-xs text-sage">
                        <th className="px-4 py-2.5 font-medium">المستوى</th>
                        <th className="px-4 py-2.5 font-medium">الدرجة المركبة</th>
                        <th className="px-4 py-2.5 font-medium">التاريخ</th>
                      </tr>
                    </thead>
                    <tbody>
                      {detail.risk_history.map((ra) => (
                        <tr key={ra.id} className="border-b border-line last:border-0">
                          <td className="px-4 py-2.5">
                            <RiskSpine level={ra.risk_level} className="pr-3">
                              <RiskBadge level={ra.risk_level} />
                            </RiskSpine>
                          </td>
                          <td className="px-4 py-2.5 tabular text-ink">{formatNumber(ra.composite_score)}</td>
                          <td className="px-4 py-2.5 tabular text-sage">{formatDateTime(ra.created_at)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>

            {/* Interview sessions */}
            <div className="rounded-lg border border-line bg-white p-5">
              <h2 className="font-display text-lg text-ink">سجل جلسات المحادثة</h2>
              {detail.interview_sessions.length === 0 ? (
                <EmptyState title="لا توجد جلسات محادثة بعد" />
              ) : (
                <>
                  {/* Desktop table */}
                  <div className="hidden sm:block mt-3 overflow-x-auto rounded border border-line">
                    <table className="w-full text-sm min-w-[500px]">
                      <thead>
                        <tr className="border-b border-line bg-paper/60 text-right text-xs text-sage">
                          <th className="px-4 py-2.5 font-medium">التاريخ</th>
                          <th className="px-4 py-2.5 font-medium">الحالة</th>
                          <th className="px-4 py-2.5 font-medium">عدد الأسئلة</th>
                          <th className="px-4 py-2.5 font-medium">مستوى الخطر</th>
                          <th className="px-4 py-2.5 font-medium"></th>
                        </tr>
                      </thead>
                      <tbody>
                        {detail.interview_sessions.map((s) => (
                          <tr key={s.id} className="border-b border-line last:border-0">
                            <td className="px-4 py-2.5 tabular text-sage">{formatDateTime(s.started_at)}</td>
                            <td className="px-4 py-2.5 text-ink">{SESSION_STATUS_LABELS[s.status] || s.status}</td>
                            <td className="px-4 py-2.5 tabular text-ink">{s.total_questions_asked}</td>
                            <td className="px-4 py-2.5">
                              <RiskBadge level={s.risk_level} />
                            </td>
                            <td className="px-4 py-2.5">
                              <button
                                onClick={() => navigate(`/interviews/${s.id}`)}
                                className="rounded border border-line px-3 py-1 text-xs text-ink transition hover:border-teal hover:text-teal"
                              >
                                عرض المحادثة
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>

                  {/* Mobile cards */}
                  <div className="sm:hidden mt-3 space-y-2">
                    {detail.interview_sessions.map((s) => (
                      <div key={s.id} className="rounded-lg border border-line p-3">
                        <div className="flex items-center justify-between gap-3">
                          <div className="min-w-0 flex-1">
                            <p className="text-xs text-sage">{formatDateTime(s.started_at)}</p>
                            <div className="mt-1 flex flex-wrap items-center gap-2">
                              <span className="text-sm text-ink">{SESSION_STATUS_LABELS[s.status] || s.status}</span>
                              <span className="text-sage text-xs">·</span>
                              <span className="text-xs text-sage">{s.total_questions_asked} سؤال</span>
                            </div>
                            {s.risk_level && (
                              <div className="mt-1.5">
                                <RiskBadge level={s.risk_level} />
                              </div>
                            )}
                          </div>
                          <button
                            onClick={() => navigate(`/interviews/${s.id}`)}
                            className="shrink-0 rounded border border-line px-3 py-1.5 text-xs text-ink transition hover:border-teal hover:text-teal"
                          >
                            عرض
                          </button>
                        </div>
                      </div>
                    ))}
                  </div>
                </>
              )}
            </div>
          </div>
        </div>
      )}

      {/* Send Recommendation Modal */}
      {showRecModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-ink/50 p-4">
          <div className="w-full max-w-md rounded-xl border border-line bg-white p-6 shadow-xl">
            <div className="mb-4 flex items-center justify-between">
              <h3 className="font-display text-lg text-ink">إرسال توصية مباشرة للمريض</h3>
              <button
                onClick={() => {
                  setShowRecModal(false);
                  setRecSuccess(false);
                  setRecError(null);
                }}
                className="text-sage hover:text-ink transition"
              >
                <svg className="h-5 w-5" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M18 6L6 18M6 6l12 12" strokeLinecap="round" strokeLinejoin="round" />
                </svg>
              </button>
            </div>

            {recSuccess ? (
              <div className="rounded-lg bg-teal-50 p-4 text-center">
                <p className="font-medium text-teal">تم إرسال التوصية بنجاح!</p>
              </div>
            ) : (
              <form onSubmit={handleSendRec} className="space-y-4">
                {recError && <div className="rounded border border-red-200 bg-red-50 p-3 text-sm text-red-600">{recError}</div>}
                <div>
                  <label className="mb-1 block text-sm font-medium text-ink">عنوان التوصية</label>
                  <input
                    type="text"
                    required
                    value={recTitle}
                    onChange={(e) => setRecTitle(e.target.value)}
                    className="w-full rounded-md border border-line bg-paper px-3 py-2 text-sm text-ink outline-none transition focus:border-teal"
                    placeholder="مثال: تعليمات جديدة للطوارئ"
                  />
                </div>
                <div>
                  <label className="mb-1 block text-sm font-medium text-ink">المحتوى</label>
                  <textarea
                    required
                    rows="4"
                    value={recContent}
                    onChange={(e) => setRecContent(e.target.value)}
                    className="w-full rounded-md border border-line bg-paper px-3 py-2 text-sm text-ink outline-none transition focus:border-teal"
                    placeholder="اكتب التوصية أو الرسالة الموجهة للمريض هنا..."
                  ></textarea>
                </div>
                <div className="flex justify-end gap-3 pt-2">
                  <button
                    type="button"
                    onClick={() => setShowRecModal(false)}
                    className="rounded-md border border-line px-4 py-2 text-sm font-medium text-ink transition hover:bg-paper"
                  >
                    إلغاء
                  </button>
                  <button
                    type="submit"
                    disabled={recSending || !recTitle.trim() || !recContent.trim()}
                    className="rounded-md bg-teal px-4 py-2 text-sm font-medium text-white transition hover:bg-teal-600 disabled:opacity-50 flex items-center gap-2"
                  >
                    {recSending && (
                      <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent"></div>
                    )}
                    إرسال للمريض
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </AppShell>
  );
}

function Row({ label, value }) {
  return (
    <div className="flex items-start justify-between gap-4">
      <dt className="text-sage shrink-0">{label}</dt>
      <dd className="font-medium text-ink text-left">{value}</dd>
    </div>
  );
}
