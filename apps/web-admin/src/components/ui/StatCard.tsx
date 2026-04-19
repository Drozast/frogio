'use client';

import Link from 'next/link';
import { motion } from 'framer-motion';
import AnimatedCounter from './AnimatedCounter';

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

const accentColors: Record<string, string> = {
  primary: 'hsl(126 57% 23%)',
  success: 'hsl(122 39% 41%)',
  warning: 'hsl(27 98% 47%)',
  destructive: 'hsl(0 72% 51%)',
  info: 'hsl(211 69% 43%)',
  muted: 'hsl(0 0% 70%)',
};

const glowColors: Record<string, string> = {
  primary: 'rgba(27, 94, 32, 0.12)',
  success: 'rgba(34, 139, 34, 0.12)',
  warning: 'rgba(245, 158, 11, 0.12)',
  destructive: 'rgba(239, 68, 68, 0.12)',
  info: 'rgba(59, 130, 246, 0.12)',
  muted: 'rgba(0, 0, 0, 0.06)',
};

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
            <p className="text-3xl font-bold text-foreground tracking-tight stat-glow">
              {typeof value === 'number' ? (
                <AnimatedCounter value={value} />
              ) : (
                value
              )}
            </p>
            {trend && (
              <motion.span
                className={`inline-flex items-center text-sm font-medium ${
                  trend.isPositive ? 'text-success-600' : 'text-red-600'
                }`}
                initial={{ opacity: 0, y: 5 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.5 }}
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
              </motion.span>
            )}
          </div>
          {subtitle && (
            <p className="mt-1.5 text-xs text-muted-foreground">
              {subtitle}
            </p>
          )}
        </div>
        {icon && (
          <motion.div
            className={`flex-shrink-0 p-3 rounded-xl ${iconColors[color]} transition-all`}
            whileHover={{ scale: 1.1, rotate: 5 }}
            transition={{ type: 'spring', stiffness: 400, damping: 17 }}
          >
            {icon}
          </motion.div>
        )}
      </div>
    </div>
  );

  const cardContent = (
    <motion.div
      className={`
        group bg-card rounded-xl border border-border/50 overflow-hidden
        shadow-card transition-all duration-400
        ${href ? 'cursor-pointer' : ''}
      `}
      whileHover={{
        y: -3,
        boxShadow: `0 0 24px ${glowColors[color]}, 0 12px 40px rgba(0,0,0,0.08)`,
      }}
      transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
    >
      {/* Top accent line with gradient */}
      <div
        className="h-[3px] w-full"
        style={{
          background: `linear-gradient(90deg, ${accentColors[color]}, ${accentColors[color]}88, ${accentColors[color]})`,
        }}
      />
      {content}
    </motion.div>
  );

  if (href) {
    return (
      <Link href={href} className="block">
        {cardContent}
      </Link>
    );
  }

  return cardContent;
}

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
      <span className="text-sm font-semibold text-foreground tabular-nums">{value}</span>
    </div>
  );
}
