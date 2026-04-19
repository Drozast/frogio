export function SkeletonStatCard() {
  return (
    <div className="bg-card rounded-xl border border-border/50 shadow-card p-5">
      <div className="flex items-start justify-between">
        <div className="flex-1 space-y-3">
          <div className="skeleton h-4 w-24" />
          <div className="skeleton h-8 w-16" />
          <div className="skeleton h-3 w-20" />
        </div>
        <div className="skeleton-circle w-12 h-12" />
      </div>
    </div>
  );
}

export function SkeletonTable({ rows = 5 }: { rows?: number }) {
  return (
    <div className="space-y-0">
      {/* Header */}
      <div className="flex gap-4 px-4 py-3 bg-muted/50">
        {[1, 2, 3, 4, 5].map((i) => (
          <div key={i} className="skeleton h-3 flex-1" />
        ))}
      </div>
      {/* Rows */}
      {Array.from({ length: rows }).map((_, i) => (
        <div key={i} className="flex gap-4 px-4 py-3 border-b border-border/50">
          {[1, 2, 3, 4, 5].map((j) => (
            <div
              key={j}
              className="skeleton h-4 flex-1"
              style={{ animationDelay: `${(i * 5 + j) * 50}ms` }}
            />
          ))}
        </div>
      ))}
    </div>
  );
}

export function SkeletonChart() {
  return (
    <div className="bg-card rounded-xl border border-border/50 shadow-card p-6">
      <div className="skeleton h-5 w-40 mb-4" />
      <div className="flex items-center justify-center h-64">
        <div className="skeleton-circle w-40 h-40" />
      </div>
    </div>
  );
}

export function Skeleton({ className = '' }: { className?: string }) {
  return <div className={`skeleton ${className}`} />;
}
