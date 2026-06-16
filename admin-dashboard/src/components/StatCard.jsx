export function StatCard({ label, value, hint }) {
  return (
    <div className="rounded-lg border border-line bg-white p-5">
      <p className="text-xs text-sage">{label}</p>
      <p className="mt-2 font-display text-3xl tabular text-ink">{value}</p>
      {hint && <p className="mt-1 text-xs text-sage">{hint}</p>}
    </div>
  );
}
