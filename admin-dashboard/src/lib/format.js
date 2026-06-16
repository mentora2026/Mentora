export const RISK_LEVEL_LABELS = {
  1: "مستقرة",
  2: "قلق خفيف",
  3: "خطر متوسط",
  4: "خطر مرتفع",
  5: "اهتمام عاجل",
};

export const RISK_LEVEL_COLORS = {
  1: "var(--tw-risk-1, #4F8A5B)",
  2: "#8BAA4E",
  3: "#D4A12C",
  4: "#D9763B",
  5: "#C1432E",
};

// Tailwind-safe class names (since dynamic class strings aren't purged correctly)
export const RISK_BG_CLASS = {
  1: "bg-risk-1",
  2: "bg-risk-2",
  3: "bg-risk-3",
  4: "bg-risk-4",
  5: "bg-risk-5",
};

export const RISK_TEXT_CLASS = {
  1: "text-risk-1",
  2: "text-risk-2",
  3: "text-risk-3",
  4: "text-risk-4",
  5: "text-risk-5",
};

export const RECOMMENDATION_CATEGORY_LABELS = {
  breathing_exercise: "تمرين تنفس",
  relaxation: "استرخاء",
  sleep_tip: "نصيحة للنوم",
  stress_management: "إدارة التوتر",
  motivational: "رسالة تحفيزية",
  educational: "محتوى تعليمي",
  professional_help: "دعم متخصص",
};

export const NOTIFICATION_TYPE_LABELS = {
  daily_checkin: "تذكير يومي",
  follow_up: "متابعة",
  mood_reminder: "تذكير بالحالة المزاجية",
  recommendation_alert: "تنبيه توصية",
  engagement: "تفاعل",
  risk_alert_admin: "تنبيه خطر للمسؤول",
};

export const CONTENT_TYPE_LABELS = {
  article: "مقال",
  tip: "نصيحة",
  faq: "أسئلة شائعة",
  onboarding_text: "نص تهيئة",
  ui_label: "تسمية واجهة",
};

export const SESSION_STATUS_LABELS = {
  in_progress: "جارية",
  completed: "مكتملة",
  abandoned: "متروكة",
};

export const SENDER_LABELS = {
  bot: "المساعد",
  patient: "المريض",
};

export const USER_ROLE_LABELS = {
  patient: "مريض",
  admin: "مسؤول",
  clinical_supervisor: "مشرف سريري",
};

export function formatDateTime(isoString) {
  if (!isoString) return "—";
  const date = new Date(isoString);
  return date.toLocaleString("ar", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

export function formatDate(isoString) {
  if (!isoString) return "—";
  const date = new Date(isoString);
  return date.toLocaleDateString("ar", { year: "numeric", month: "short", day: "numeric" });
}

export function formatNumber(value, decimals = 1) {
  if (value === null || value === undefined) return "—";
  return Number(value).toFixed(decimals);
}
