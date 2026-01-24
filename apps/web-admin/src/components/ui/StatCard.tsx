import Link from 'next/link';

interface StatCardProps {
  title: string;
  value: string | number;
  icon?: React.ReactNode;
  trend?: {
    value: number;
    isPositive: boolean;
  };
  color?: 'primary' | 'success' | 'warning' | 'destructive' | 'info' | 'muted';
  href?: string;
  subtitle?: string;
}

export default function StatCard({ title, value, icon, trend, color = 'primary', href, subtitle }: StatCardProps) {
  const iconColors = {
    primary: 'bg-primary/10 text-primary',
    success: 'bg-success-100 text-success-600',
    warning: 'bg-warning-100 text-warning-600',
    destructive: 'bg-red-100 text-red-600',
    info: 'bg-info-100 text-info-600',
    muted: 'bg-muted text-muted-foreground',
  };

  const content = (
    <div className="p-5">
      <div className="flex items-start justify-between">
        <div className="flex-1">
          <p className="text-sm font-medium text-muted-foreground">
            {title}
          </p>
          <div className="mt-2 flex items-baseline gap-2">
            <p className="text-3xl font-bold text-foreground tracking-tight">
              {value}
            </p>
            {trend && (
              <span
                className={`inline-flex items-center text-sm font-medium ${
                  trend.isPositive ? 'text-success-600' : 'text-red-600'
                }`}
              >
                <svg
                  className={`w-4 h-4 mr-0.5 ${trend.isPositive ? '' : 'rotate-180'}`}
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 10l7-7m0 0l7 7m-7-7v18" />
                </svg>
                {Math.abs(trend.value)}%
              </span>
            )}
          </div>
          {subtitle && (
            <p className="mt-1 text-xs text-muted-foreground">
              {subtitle}
            </p>
          )}
        </div>
        {icon && (
          <div className={`flex-shrink-0 p-3 rounded-xl ${iconColors[color]}`}>
            {icon}
          </div>
        )}
      </div>
    </div>
  );

  const cardClasses = `
    bg-card rounded-xl border border-border/50
    shadow-card transition-all duration-200
    ${href ? 'hover:shadow-card-hover hover:-translate-y-0.5 cursor-pointer' : 'hover:shadow-md'}
  `;

  if (href) {
    return (
      <Link href={href} className="block">
        <div className={cardClasses}>
          {content}
        </div>
      </Link>
    );
  }

  return (
    <div className={cardClasses}>
      {content}
    </div>
  );
}

// Compact variant for smaller stat displays
export function StatCardCompact({
  label,
  value,
  color = 'primary'
}: {
  label: string;
  value: string | number;
  color?: 'primary' | 'success' | 'warning' | 'destructive' | 'info';
}) {
  const dotColors = {
    primary: 'bg-primary',
    success: 'bg-success',
    warning: 'bg-warning',
    destructive: 'bg-destructive',
    info: 'bg-info',
  };

  return (
    <div className="flex items-center justify-between py-2">
      <div className="flex items-center gap-2">
        <span className={`w-2 h-2 rounded-full ${dotColors[color]}`}></span>
        <span className="text-sm text-muted-foreground">{label}</span>
      </div>
      <span className="text-sm font-semibold text-foreground">{value}</span>
    </div>
  );
}
