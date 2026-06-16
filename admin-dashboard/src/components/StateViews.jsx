export function LoadingState({ label = "جارِ التحميل..." }) {
  return (
    <div className="flex items-center justify-center py-16 text-sage">
      <div className="flex items-center gap-3">
        <span className="inline-block h-4 w-4 animate-spin rounded-full border-2 border-sage border-t-transparent" />
        <span className="font-body text-sm">{label}</span>
      </div>
    </div>
  );
}

export function ErrorState({ message, onRetry }) {
  return (
    <div className="flex flex-col items-center justify-center gap-3 py-16 text-center">
      <p className="font-body text-sm text-terracotta">{message}</p>
      {onRetry && (
        <button
          onClick={onRetry}
          className="rounded border border-terracotta px-4 py-1.5 text-sm text-terracotta transition hover:bg-terracotta-50"
        >
          إعادة المحاولة
        </button>
      )}
    </div>
  );
}

export function EmptyState({ title, description }) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 py-16 text-center text-sage">
      <p className="font-body text-sm font-medium">{title}</p>
      {description && <p className="max-w-sm text-xs text-sage/80">{description}</p>}
    </div>
  );
}
