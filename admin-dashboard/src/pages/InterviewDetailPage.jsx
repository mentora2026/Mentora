import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { AppShell } from "../components/AppShell";
import { RiskBadge } from "../components/RiskBadge";
import { ErrorState, LoadingState } from "../components/StateViews";
import { api } from "../lib/api";
import { ENDPOINTS } from "../lib/constants";
import { formatDateTime, formatNumber, SENDER_LABELS, SESSION_STATUS_LABELS } from "../lib/format";

const EMOTION_LABELS = {
  anxiety: "قلق",
  stress: "توتر",
  sadness: "حزن",
  burnout: "إرهاق",
  frustration: "إحباط",
  positive: "إيجابي",
  neutral: "محايد",
};

const EMOTION_COLORS = {
  anxiety: "text-risk-4",
  stress: "text-risk-4",
  sadness: "text-risk-3",
  burnout: "text-risk-4",
  frustration: "text-risk-3",
  positive: "text-risk-1",
  neutral: "text-sage",
};

export default function InterviewDetailPage() {
  const { sessionId } = useParams();
  const navigate = useNavigate();
  const [detail, setDetail] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.get(ENDPOINTS.adminInterviewSession(sessionId));
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
  }, [sessionId]);

  return (
    <AppShell
      title="تفاصيل جلسة المحادثة"
      description={detail ? `${detail.patient_full_name} · ${formatDateTime(detail.started_at)}` : ""}
    >
      <button
        onClick={() => navigate(-1)}
        className="mb-4 inline-flex items-center gap-1.5 text-sm text-sage transition hover:text-teal"
      >
        <svg className="h-4 w-4 rotate-180" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8">
          <path d="M9 18l6-6-6-6" strokeLinecap="round" strokeLinejoin="round" />
        </svg>
        رجوع
      </button>

      {loading && <LoadingState />}
      {error && <ErrorState message={error} onRetry={load} />}

      {detail && (
        <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
          {/* Main content */}
          <div className="space-y-5 lg:col-span-2">
            {/* Conversation */}
            <div className="rounded-lg border border-line bg-white p-5">
              <div className="flex items-center justify-between">
                <h2 className="font-display text-lg text-ink">المحادثة</h2>
                <span className="text-xs text-sage">{SESSION_STATUS_LABELS[detail.status] || detail.status}</span>
              </div>
              <div className="mt-4 space-y-3 max-h-[60vh] overflow-y-auto">
                {detail.conversation.map((msg) => (
                  <div
                    key={msg.id}
                    className={`flex flex-col rounded-lg px-4 py-3 text-sm ${
                      msg.sender === "bot" ? "bg-paper" : "ms-4 sm:ms-8 bg-teal-50"
                    }`}
                  >
                    <span className="mb-1 text-[11px] text-sage">{SENDER_LABELS[msg.sender]}</span>
                    <p className="leading-relaxed text-ink">{msg.message_text_ar}</p>
                  </div>
                ))}
              </div>
            </div>

            {/* Session summary */}
            {detail.session_summary_ar && (
              <div className="rounded-lg border border-line bg-white p-5">
                <h2 className="font-display text-lg text-ink">ملخص الجلسة</h2>
                <p className="mt-2 text-sm leading-relaxed text-ink">{detail.session_summary_ar}</p>
              </div>
            )}

            {/* Answers analysis */}
            <div className="rounded-lg border border-line bg-white p-5">
              <h2 className="font-display text-lg text-ink">تحليل الإجابات والمشاعر</h2>

              {/* Desktop table */}
              <div className="hidden sm:block mt-3 overflow-x-auto rounded border border-line">
                <table className="w-full text-sm min-w-[480px]">
                  <thead>
                    <tr className="border-b border-line bg-paper/60 text-right text-xs text-sage">
                      <th className="px-4 py-2.5 font-medium">السؤال</th>
                      <th className="px-4 py-2.5 font-medium">الإجابة</th>
                      <th className="px-4 py-2.5 font-medium">المشاعر المكتشفة</th>
                    </tr>
                  </thead>
                  <tbody>
                    {detail.answers.map((a, idx) => (
                      <tr key={idx} className="border-b border-line align-top last:border-0">
                        <td className="max-w-xs px-4 py-2.5 text-ink">{a.question_text_ar_snapshot}</td>
                        <td className="max-w-xs px-4 py-2.5 text-ink">
                          {a.answer_text_ar ||
                            (a.answer_value_numeric !== null ? formatNumber(a.answer_value_numeric, 0) : "—")}
                        </td>
                        <td className="px-4 py-2.5">
                          {a.sentiment_label ? (
                            <span className={`font-medium ${EMOTION_COLORS[a.sentiment_label] || "text-ink"}`}>
                              {EMOTION_LABELS[a.sentiment_label] || a.sentiment_label}
                              {a.sentiment_score !== null && (
                                <span className="ms-1 tabular text-xs text-sage">
                                  ({formatNumber(a.sentiment_score, 2)})
                                </span>
                              )}
                            </span>
                          ) : (
                            <span className="text-sage">—</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Mobile cards */}
              <div className="sm:hidden mt-3 space-y-3">
                {detail.answers.map((a, idx) => (
                  <div key={idx} className="rounded-lg border border-line p-3">
                    <p className="text-xs font-medium text-sage mb-1">السؤال {idx + 1}</p>
                    <p className="text-sm text-ink">{a.question_text_ar_snapshot}</p>
                    <div className="mt-2 pt-2 border-t border-line">
                      <p className="text-xs text-sage mb-0.5">الإجابة</p>
                      <p className="text-sm text-ink">
                        {a.answer_text_ar ||
                          (a.answer_value_numeric !== null ? formatNumber(a.answer_value_numeric, 0) : "—")}
                      </p>
                    </div>
                    {a.sentiment_label && (
                      <div className="mt-2 pt-2 border-t border-line">
                        <p className="text-xs text-sage mb-0.5">المشاعر</p>
                        <span className={`text-sm font-medium ${EMOTION_COLORS[a.sentiment_label] || "text-ink"}`}>
                          {EMOTION_LABELS[a.sentiment_label] || a.sentiment_label}
                          {a.sentiment_score !== null && (
                            <span className="ms-1 tabular text-xs text-sage">
                              ({formatNumber(a.sentiment_score, 2)})
                            </span>
                          )}
                        </span>
                      </div>
                    )}
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Risk assessment sidebar */}
          <div className="space-y-4 lg:col-span-1">
            {detail.risk_assessment ? (
              <>
                <div className="rounded-lg border border-line bg-white p-5">
                  <h2 className="font-display text-lg text-ink">نتيجة التقييم</h2>
                  <div className="mt-3">
                    <RiskBadge level={detail.risk_assessment.risk_level} size="lg" />
                  </div>
                  <p className="mt-3 text-sm leading-relaxed text-ink">{detail.risk_assessment.explanation_ar}</p>
                </div>

                <div className="rounded-lg border border-line bg-white p-5">
                  <h2 className="font-display text-lg text-ink">الدرجات الفرعية</h2>
                  <dl className="mt-3 space-y-2.5 text-sm">
                    <ScoreRow label="القلق" value={detail.risk_assessment.anxiety_score} />
                    <ScoreRow label="التوتر" value={detail.risk_assessment.stress_score} />
                    <ScoreRow label="الحزن" value={detail.risk_assessment.sadness_score} />
                    <ScoreRow label="الإرهاق" value={detail.risk_assessment.burnout_score} />
                    <ScoreRow label="جودة النوم" value={detail.risk_assessment.sleep_quality_score} />
                    <ScoreRow label="الالتزام بالعلاج" value={detail.risk_assessment.adherence_score} />
                    <div className="mt-2 flex items-center justify-between border-t border-line pt-2 font-medium">
                      <dt className="text-ink">الدرجة المركبة</dt>
                      <dd className="tabular text-ink">{formatNumber(detail.risk_assessment.composite_score)}</dd>
                    </div>
                  </dl>
                </div>

                {detail.risk_assessment.explanation_factors_json?.crisis_language_detected && (
                  <div className="rounded-lg border border-risk-5/30 bg-terracotta-50 p-4">
                    <p className="text-sm font-medium text-terracotta">
                      تم رصد لغة تشير إلى أزمة نفسية محتملة خلال هذه الجلسة. تم تنبيه فريق الإدارة.
                    </p>
                  </div>
                )}
              </>
            ) : (
              <div className="rounded-lg border border-line bg-white p-5 text-sm text-sage">
                لا يوجد تقييم نفسي لهذه الجلسة (قد تكون لا تزال جارية).
              </div>
            )}
          </div>
        </div>
      )}
    </AppShell>
  );
}

function ScoreRow({ label, value }) {
  return (
    <div className="flex items-center justify-between">
      <dt className="text-sage">{label}</dt>
      <dd className="tabular text-ink">{formatNumber(value)}</dd>
    </div>
  );
}
