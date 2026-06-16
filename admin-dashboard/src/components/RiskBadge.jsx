import { RISK_BG_CLASS, RISK_LEVEL_LABELS, RISK_TEXT_CLASS } from "../lib/format";

/**
 * The risk-spine badge: a small filled dot + label, color-coded 1-5.
 * This is the recurring visual vocabulary for "risk" across the dashboard
 * (patient rows, analytics, interview detail).
 */
export function RiskBadge({ level, size = "sm" }) {
  if (level === null || level === undefined) {
    return <span className="text-xs text-sage">لا يوجد تقييم</span>;
  }

  const dotSize = size === "lg" ? "h-2.5 w-2.5" : "h-2 w-2";
  const textSize = size === "lg" ? "text-sm" : "text-xs";

  return (
    <span className={`inline-flex items-center gap-1.5 font-medium ${textSize} ${RISK_TEXT_CLASS[level]}`}>
      <span className={`inline-block rounded-full ${dotSize} ${RISK_BG_CLASS[level]}`} />
      المستوى {level} · {RISK_LEVEL_LABELS[level]}
    </span>
  );
}

/**
 * Vertical color spine for table rows / cards - the page's signature element.
 */
export function RiskSpine({ level, children, className = "" }) {
  const colorClass = level ? RISK_BG_CLASS[level] : "bg-line";
  return (
    <div className={`relative overflow-hidden rounded ${className}`}>
      <span className={`absolute inset-y-0 right-0 w-1 ${colorClass}`} aria-hidden="true" />
      {children}
    </div>
  );
}
