'use client';

import { useState, useCallback, useEffect } from 'react';
import Link from 'next/link';
import { motion } from 'framer-motion';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
  Area,
  ComposedChart,
} from 'recharts';
import {
  DocumentTextIcon,
  ScaleIcon,
  UserGroupIcon,
  TruckIcon,
  TruckIcon as ShippingIcon,
  CheckBadgeIcon,
  MapIcon,
  ArrowTrendingUpIcon,
  ArrowPathIcon,
  ChartBarIcon,
  PresentationChartLineIcon,
  ChartPieIcon,
  ClockIcon,
  ArrowRightIcon,
} from '@heroicons/react/24/outline';
import AnimatedCounter from '@/components/ui/AnimatedCounter';
import { getDashboardStats, type AdminRecord } from '@/lib/admin-api';
import { FROGIO_COLORS, FROGIO_GRADIENTS, getStatusColor } from '@/lib/theme';

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface BitacoraLog {
  vehiclePlate?: string;
  plate?: string;
  driverName?: string;
  driver_name?: string;
  startTime?: string;
  start_time?: string;
  totalDistanceKm?: number | null;
  total_distance_km?: number | null;
}

interface DashboardStats {
  summary: {
    totalUsers: number;
    totalInfractions: number;
    totalReports: number;
    totalVehicles: number;
  };
  recentActivity: {
    infractionsLast7Days: number;
    reportsLast7Days: number;
  };
  reportsByStatus: Record<string, number>;
  infractionsByStatus: Record<string, number>;
  infractionsByType: { type: string; count: number }[];
  dailyActivity: { date: string; count: number }[];
  bitacora: {
    activeTrips: number;
    completedToday: number;
    totalKmToday: number;
    recentLogs: BitacoraLog[];
  };
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function toInt(v: unknown): number {
  if (typeof v === 'number') return Math.round(v);
  if (typeof v === 'string') return parseInt(v, 10) || 0;
  return 0;
}

function toFloat(v: unknown): number {
  if (typeof v === 'number') return v;
  if (typeof v === 'string') return parseFloat(v) || 0;
  return 0;
}

function normalizeStats(raw: AdminRecord): DashboardStats {
  const summary = (raw.summary as AdminRecord) ?? {};
  const recentActivity = (raw.recentActivity as AdminRecord) ?? {};
  const bitacora = (raw.bitacora as AdminRecord) ?? {};
  const reportsByStatus = (raw.reportsByStatus as Record<string, unknown>) ?? {};
  const infractionsByStatus = (raw.infractionsByStatus as Record<string, unknown>) ?? {};
  const infractionsByType = (raw.infractionsByType as Array<Record<string, unknown>>) ?? [];
  const dailyActivity = (raw.dailyActivity as Array<Record<string, unknown>>) ?? [];

  const mapNumeric = (m: Record<string, unknown>): Record<string, number> => {
    const out: Record<string, number> = {};
    for (const [k, v] of Object.entries(m)) out[k] = toInt(v);
    return out;
  };

  return {
    summary: {
      totalUsers: toInt(summary.totalUsers),
      totalInfractions: toInt(summary.totalInfractions),
      totalReports: toInt(summary.totalReports),
      totalVehicles: toInt(summary.totalVehicles),
    },
    recentActivity: {
      infractionsLast7Days: toInt(recentActivity.infractionsLast7Days),
      reportsLast7Days: toInt(recentActivity.reportsLast7Days),
    },
    reportsByStatus: mapNumeric(reportsByStatus),
    infractionsByStatus: mapNumeric(infractionsByStatus),
    infractionsByType: infractionsByType.map((i) => ({
      type: String(i.type ?? '-'),
      count: toInt(i.count),
    })),
    dailyActivity: dailyActivity.map((i) => ({
      date: String(i.date ?? ''),
      count: toInt(i.count),
    })),
    bitacora: {
      activeTrips: toInt(bitacora.activeTrips),
      completedToday: toInt(bitacora.completedToday),
      totalKmToday: toFloat(bitacora.totalKmToday),
      recentLogs: ((bitacora.recentLogs as BitacoraLog[]) ?? []).slice(0, 5),
    },
  };
}

function fmtDayKey(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

function fmtDayLabel(d: Date): string {
  return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}`;
}

function buildLast14Series(daily: { date: string; count: number }[]) {
  const map = new Map<string, number>();
  const now = new Date();
  for (let i = 13; i >= 0; i--) {
    const d = new Date(now);
    d.setDate(now.getDate() - i);
    map.set(fmtDayKey(d), 0);
  }
  for (const item of daily) {
    if (!item.date) continue;
    const d = new Date(item.date);
    if (isNaN(d.getTime())) continue;
    const key = fmtDayKey(d);
    if (map.has(key)) map.set(key, item.count);
  }
  return Array.from(map.entries()).map(([key, count]) => {
    const d = new Date(key);
    return { date: key, label: fmtDayLabel(d), count };
  });
}

// ---------------------------------------------------------------------------
// Animation variants
// ---------------------------------------------------------------------------

const stagger = {
  hidden: { opacity: 0 },
  show: { opacity: 1, transition: { staggerChildren: 0.08 } },
};
const item = {
  hidden: { opacity: 0, y: 14, scale: 0.97 },
  show: { opacity: 1, y: 0, scale: 1, transition: { duration: 0.35, ease: 'easeOut' as const } },
};

// ---------------------------------------------------------------------------
// Small components
// ---------------------------------------------------------------------------

function LivePulseBadge() {
  return (
    <div
      className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full border"
      style={{
        backgroundColor: `${FROGIO_COLORS.success}1F`,
        borderColor: `${FROGIO_COLORS.success}55`,
      }}
    >
      <span className="relative flex h-2 w-2">
        <span
          className="animate-ping absolute inline-flex h-full w-full rounded-full opacity-75"
          style={{ backgroundColor: FROGIO_COLORS.success }}
        />
        <span
          className="relative inline-flex rounded-full h-2 w-2"
          style={{ backgroundColor: FROGIO_COLORS.success }}
        />
      </span>
      <span
        className="text-[10px] font-extrabold tracking-wider"
        style={{ color: FROGIO_COLORS.success }}
      >
        LIVE
      </span>
    </div>
  );
}

interface KpiCardProps {
  label: string;
  value: number;
  color: string;
  icon: React.ReactNode;
  deltaText?: string;
  deltaArrow?: boolean;
  subText?: string;
}

function KpiCard({ label, value, color, icon, deltaText, deltaArrow, subText }: KpiCardProps) {
  return (
    <motion.div
      variants={item}
      whileHover={{ y: -2 }}
      className="group relative rounded-2xl bg-white border p-4 transition-shadow"
      style={{
        borderColor: `${color}26`,
        boxShadow: `0 4px 14px ${color}14`,
      }}
    >
      <div
        className="absolute inset-0 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity pointer-events-none"
        style={{ boxShadow: `0 10px 28px ${color}33` }}
      />
      <div className="flex items-start justify-between">
        <div
          className="rounded-xl p-2.5"
          style={{
            background: `linear-gradient(135deg, ${color}33 0%, ${color}14 100%)`,
            color,
          }}
        >
          {icon}
        </div>
        {deltaText && (
          <div
            className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[10px] font-bold"
            style={{
              backgroundColor: `${FROGIO_COLORS.success}1F`,
              color: FROGIO_COLORS.success,
            }}
          >
            {deltaArrow && <ArrowTrendingUpIcon className="h-3 w-3" />}
            {deltaText}
          </div>
        )}
      </div>
      <div className="mt-4">
        <div
          className="text-3xl font-extrabold leading-none tracking-tight"
          style={{ color: FROGIO_COLORS.textPrimary }}
        >
          <AnimatedCounter value={value} duration={600} />
        </div>
        <div className="mt-1 text-xs font-semibold" style={{ color: FROGIO_COLORS.textSecondary }}>
          {label}
        </div>
        {subText && (
          <div className="mt-1 text-[11px]" style={{ color: FROGIO_COLORS.textTertiary }}>
            {subText}
          </div>
        )}
      </div>
    </motion.div>
  );
}

function StatusRow({
  label,
  count,
  total,
  color,
}: {
  label: string;
  count: number;
  total: number;
  color: string;
}) {
  const pct = total === 0 ? 0 : Math.round((count / total) * 100);
  return (
    <div className="py-2">
      <div className="flex items-center gap-2">
        <span
          className="inline-block h-2 w-2 rounded-full flex-shrink-0"
          style={{ backgroundColor: color }}
        />
        <span
          className="text-sm capitalize flex-1 truncate"
          style={{ color: FROGIO_COLORS.textPrimary }}
        >
          {label.replace(/_/g, ' ')}
        </span>
        <span className="text-sm font-bold" style={{ color }}>
          {count}
        </span>
        <span className="text-[11px] w-9 text-right" style={{ color: FROGIO_COLORS.textTertiary }}>
          {pct}%
        </span>
      </div>
      <div
        className="mt-1.5 h-1.5 w-full rounded-full overflow-hidden"
        style={{ backgroundColor: `${color}1A` }}
      >
        <motion.div
          initial={{ width: 0 }}
          animate={{ width: `${pct}%` }}
          transition={{ duration: 0.8, ease: 'easeOut' }}
          className="h-full rounded-full"
          style={{ backgroundColor: color }}
        />
      </div>
    </div>
  );
}

function SkeletonCard({ height = 140 }: { height?: number }) {
  return (
    <div
      className="animate-pulse rounded-2xl bg-white border border-gray-100"
      style={{ height }}
    />
  );
}

function ErrorCard({ message, onRetry }: { message: string; onRetry: () => void }) {
  return (
    <div className="rounded-2xl bg-white border border-red-100 p-8 text-center">
      <div
        className="mx-auto h-14 w-14 rounded-full flex items-center justify-center"
        style={{ backgroundColor: `${FROGIO_COLORS.emergency}1A`, color: FROGIO_COLORS.emergency }}
      >
        <ArrowPathIcon className="h-7 w-7" />
      </div>
      <h3 className="mt-3 text-lg font-bold" style={{ color: FROGIO_COLORS.textPrimary }}>
        Sin conexión
      </h3>
      <p className="mt-1 text-sm" style={{ color: FROGIO_COLORS.textTertiary }}>
        {message}
      </p>
      <button
        onClick={onRetry}
        className="mt-4 inline-flex items-center gap-2 px-4 py-2 rounded-lg text-white text-sm font-semibold shadow-md hover:brightness-110 active:scale-95 transition"
        style={{ background: FROGIO_GRADIENTS.primary }}
      >
        <ArrowPathIcon className="h-4 w-4" />
        Reintentar
      </button>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Main component
// ---------------------------------------------------------------------------

export default function DashboardClient() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState<Date | null>(null);
  const [updateLabel, setUpdateLabel] = useState<string>('--:--:--');

  const load = useCallback(async () => {
    try {
      const raw = await getDashboardStats();
      if (!raw || Object.keys(raw).length === 0) {
        throw new Error('Respuesta vacía del servidor');
      }
      setStats(normalizeStats(raw));
      setError(null);
      setLastUpdate(new Date());
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Error desconocido');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
    const id = setInterval(load, 30_000);
    return () => clearInterval(id);
  }, [load]);

  // Locale-safe time string only on client to avoid hydration mismatch.
  useEffect(() => {
    if (lastUpdate) {
      setUpdateLabel(lastUpdate.toLocaleTimeString('es-CL'));
    }
  }, [lastUpdate]);

  // ───────── Loading
  if (loading && !stats) {
    return (
      <div className="space-y-5">
        <div className="h-12 animate-pulse rounded-xl bg-white border border-gray-100" />
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {Array.from({ length: 4 }).map((_, i) => (
            <SkeletonCard key={i} />
          ))}
        </div>
        <SkeletonCard height={70} />
        <SkeletonCard height={260} />
        <SkeletonCard height={220} />
      </div>
    );
  }

  // ───────── Error
  if (error && !stats) {
    return <ErrorCard message={error} onRetry={load} />;
  }

  if (!stats) return null;

  const { summary, recentActivity, bitacora } = stats;

  // Chart data
  const chartData = buildLast14Series(stats.dailyActivity);
  const chartTotal = chartData.reduce((a, b) => a + b.count, 0);
  const chartAvg = chartData.length === 0 ? 0 : chartTotal / chartData.length;

  // Status breakdown
  const reportEntries = Object.entries(stats.reportsByStatus);
  const reportTotal = reportEntries.reduce((a, [, v]) => a + v, 0);
  const topInfractionTypes = stats.infractionsByType.slice(0, 5);
  const typeTotal = topInfractionTypes.reduce((a, b) => a + b.count, 0);

  return (
    <div className="space-y-6">
      {/* Header */}
      <motion.div
        className="flex items-center gap-3"
        initial={{ opacity: 0, y: -8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
      >
        <div
          className="w-1 h-8 rounded-full"
          style={{ background: FROGIO_GRADIENTS.primary }}
        />
        <div className="flex-1 min-w-0">
          <h1 className="text-2xl font-bold tracking-tight" style={{ color: FROGIO_COLORS.textPrimary }}>
            Panel de Control
          </h1>
          <p className="text-xs" style={{ color: FROGIO_COLORS.textTertiary }}>
            Resumen en tiempo real · actualizado {updateLabel}
          </p>
        </div>
        <LivePulseBadge />
      </motion.div>

      {/* KPI grid */}
      <motion.div
        className="grid grid-cols-2 lg:grid-cols-4 gap-4"
        variants={stagger}
        initial="hidden"
        animate="show"
      >
        <KpiCard
          label="Denuncias"
          value={summary.totalReports}
          color={FROGIO_COLORS.warning}
          icon={<DocumentTextIcon className="h-5 w-5" />}
          deltaText={`${recentActivity.reportsLast7Days} (7d)`}
          deltaArrow
        />
        <KpiCard
          label="Citaciones"
          value={summary.totalInfractions}
          color={FROGIO_COLORS.primary}
          icon={<ScaleIcon className="h-5 w-5" />}
          deltaText={`${recentActivity.infractionsLast7Days} (7d)`}
          deltaArrow
        />
        <KpiCard
          label="Usuarios"
          value={summary.totalUsers}
          color={FROGIO_COLORS.info}
          icon={<UserGroupIcon className="h-5 w-5" />}
          subText="activos"
        />
        <KpiCard
          label="Flota"
          value={summary.totalVehicles}
          color={FROGIO_COLORS.accent}
          icon={<TruckIcon className="h-5 w-5" />}
          subText={`${bitacora.activeTrips} en ruta`}
        />
      </motion.div>

      {/* Live strip */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, delay: 0.1 }}
        className="rounded-2xl px-6 py-4 text-white shadow-lg"
        style={{
          background: FROGIO_GRADIENTS.primary,
          boxShadow: `0 10px 26px ${FROGIO_COLORS.primary}40`,
        }}
      >
        <div className="grid grid-cols-3 divide-x divide-white/20">
          <div className="flex flex-col items-center px-2">
            <ShippingIcon className="h-4 w-4 opacity-90" />
            <div className="mt-1 text-2xl font-extrabold tabular-nums">{bitacora.activeTrips}</div>
            <div className="text-[10px] uppercase tracking-wider opacity-80">En ruta</div>
          </div>
          <div className="flex flex-col items-center px-2">
            <CheckBadgeIcon className="h-4 w-4 opacity-90" />
            <div className="mt-1 text-2xl font-extrabold tabular-nums">{bitacora.completedToday}</div>
            <div className="text-[10px] uppercase tracking-wider opacity-80">Completados hoy</div>
          </div>
          <div className="flex flex-col items-center px-2">
            <MapIcon className="h-4 w-4 opacity-90" />
            <div className="mt-1 text-2xl font-extrabold tabular-nums">
              {bitacora.totalKmToday.toFixed(1)} km
            </div>
            <div className="text-[10px] uppercase tracking-wider opacity-80">Distancia hoy</div>
          </div>
        </div>
      </motion.div>

      {/* Chart card */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, delay: 0.15 }}
        className="rounded-2xl bg-white border p-5"
        style={{ borderColor: `${FROGIO_COLORS.primary}1F` }}
      >
        <div className="flex items-center gap-3 mb-4">
          <div
            className="rounded-lg p-2 text-white"
            style={{ background: FROGIO_GRADIENTS.primary }}
          >
            <PresentationChartLineIcon className="h-4 w-4" />
          </div>
          <div className="flex-1 min-w-0">
            <h3 className="text-sm font-bold" style={{ color: FROGIO_COLORS.textPrimary }}>
              Citaciones — últimos 14 días
            </h3>
            <p className="text-[11px]" style={{ color: FROGIO_COLORS.textTertiary }}>
              Promedio: {chartAvg.toFixed(1)} · Total: {chartTotal}
            </p>
          </div>
        </div>
        <div className="h-56 -mx-2">
          <ResponsiveContainer width="100%" height="100%">
            <ComposedChart data={chartData} margin={{ top: 8, right: 12, left: 0, bottom: 0 }}>
              <defs>
                <linearGradient id="strokeGradient" x1="0" y1="0" x2="1" y2="0">
                  <stop offset="0%" stopColor={FROGIO_COLORS.primaryDark} />
                  <stop offset="100%" stopColor={FROGIO_COLORS.accent} />
                </linearGradient>
                <linearGradient id="fillGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor={FROGIO_COLORS.primary} stopOpacity={0.3} />
                  <stop offset="100%" stopColor={FROGIO_COLORS.primary} stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke={FROGIO_COLORS.border} vertical={false} />
              <XAxis
                dataKey="label"
                tick={{ fontSize: 10, fill: FROGIO_COLORS.textTertiary }}
                axisLine={false}
                tickLine={false}
                interval={2}
              />
              <YAxis
                tick={{ fontSize: 10, fill: FROGIO_COLORS.textTertiary }}
                axisLine={false}
                tickLine={false}
                allowDecimals={false}
                width={28}
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: FROGIO_COLORS.primaryDark,
                  border: 'none',
                  borderRadius: 8,
                  color: '#fff',
                  fontSize: 12,
                  padding: '6px 10px',
                }}
                labelStyle={{ color: 'rgba(255,255,255,0.7)', fontSize: 10 }}
                formatter={(v: number) => [v, 'Citaciones']}
              />
              <Area
                type="monotone"
                dataKey="count"
                stroke="none"
                fill="url(#fillGradient)"
                isAnimationActive
                animationDuration={800}
              />
              <Line
                type="monotone"
                dataKey="count"
                stroke="url(#strokeGradient)"
                strokeWidth={2.5}
                dot={false}
                activeDot={{ r: 5, fill: FROGIO_COLORS.primary, stroke: '#fff', strokeWidth: 2 }}
                isAnimationActive
                animationDuration={900}
              />
            </ComposedChart>
          </ResponsiveContainer>
        </div>
      </motion.div>

      {/* Status breakdown */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, delay: 0.2 }}
        className="grid grid-cols-1 lg:grid-cols-2 gap-4"
      >
        <div
          className="rounded-2xl bg-white border p-5"
          style={{ borderColor: FROGIO_COLORS.border }}
        >
          <div className="flex items-center gap-2 mb-2">
            <ChartPieIcon className="h-4 w-4" style={{ color: FROGIO_COLORS.primary }} />
            <h4 className="text-sm font-bold" style={{ color: FROGIO_COLORS.textPrimary }}>
              Denuncias por estado
            </h4>
          </div>
          {reportEntries.length === 0 ? (
            <p className="text-xs py-4" style={{ color: FROGIO_COLORS.textTertiary }}>
              Sin datos disponibles.
            </p>
          ) : (
            reportEntries.map(([status, count]) => (
              <StatusRow
                key={status}
                label={status}
                count={count}
                total={reportTotal}
                color={getStatusColor(status)}
              />
            ))
          )}
        </div>
        <div
          className="rounded-2xl bg-white border p-5"
          style={{ borderColor: FROGIO_COLORS.border }}
        >
          <div className="flex items-center gap-2 mb-2">
            <ChartBarIcon className="h-4 w-4" style={{ color: FROGIO_COLORS.primary }} />
            <h4 className="text-sm font-bold" style={{ color: FROGIO_COLORS.textPrimary }}>
              Top tipos de citación
            </h4>
          </div>
          {topInfractionTypes.length === 0 ? (
            <p className="text-xs py-4" style={{ color: FROGIO_COLORS.textTertiary }}>
              Sin datos disponibles.
            </p>
          ) : (
            topInfractionTypes.map((t) => (
              <StatusRow
                key={t.type}
                label={t.type}
                count={t.count}
                total={typeTotal}
                color={FROGIO_COLORS.primary}
              />
            ))
          )}
        </div>
      </motion.div>

      {/* Quick actions */}
      <motion.div
        variants={stagger}
        initial="hidden"
        animate="show"
        className="grid grid-cols-2 lg:grid-cols-4 gap-3"
      >
        {(
          [
            { href: '/data', label: 'Datos', icon: ChartBarIcon, color: FROGIO_COLORS.info },
            { href: '/fleet', label: 'Flota', icon: TruckIcon, color: FROGIO_COLORS.accent },
            { href: '/users', label: 'Usuarios', icon: UserGroupIcon, color: FROGIO_COLORS.warning },
            { href: '/live-map', label: 'Mapa en vivo', icon: MapIcon, color: FROGIO_COLORS.primary },
          ] as const
        ).map((a) => {
          const Icon = a.icon;
          return (
            <motion.div key={a.href} variants={item}>
              <Link
                href={a.href}
                className="group flex flex-col items-center gap-2 p-4 rounded-2xl bg-white border hover:shadow-lg transition-all"
                style={{
                  borderColor: `${a.color}26`,
                }}
              >
                <div
                  className="rounded-full p-2.5 group-hover:scale-110 transition-transform"
                  style={{
                    background: `linear-gradient(135deg, ${a.color}33 0%, ${a.color}14 100%)`,
                    color: a.color,
                  }}
                >
                  <Icon className="h-5 w-5" />
                </div>
                <span
                  className="text-xs font-bold"
                  style={{ color: FROGIO_COLORS.textPrimary }}
                >
                  {a.label}
                </span>
              </Link>
            </motion.div>
          );
        })}
      </motion.div>

      {/* Recent activity */}
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.4, delay: 0.25 }}
        className="rounded-2xl bg-white border p-5"
        style={{ borderColor: FROGIO_COLORS.border }}
      >
        <div className="flex items-center gap-2 mb-3">
          <div
            className="rounded-lg p-1.5"
            style={{ backgroundColor: `${FROGIO_COLORS.primary}1A`, color: FROGIO_COLORS.primary }}
          >
            <ClockIcon className="h-4 w-4" />
          </div>
          <h4 className="text-sm font-bold flex-1" style={{ color: FROGIO_COLORS.textPrimary }}>
            Últimos viajes
          </h4>
          <Link
            href="/fleet"
            className="inline-flex items-center gap-1 text-xs font-semibold hover:underline"
            style={{ color: FROGIO_COLORS.primary }}
          >
            Ver todos <ArrowRightIcon className="h-3 w-3" />
          </Link>
        </div>
        {bitacora.recentLogs.length === 0 ? (
          <div className="py-8 text-center">
            <ShippingIcon
              className="h-8 w-8 mx-auto opacity-50"
              style={{ color: FROGIO_COLORS.textTertiary }}
            />
            <p className="mt-2 text-xs" style={{ color: FROGIO_COLORS.textTertiary }}>
              Sin viajes recientes
            </p>
          </div>
        ) : (
          <ul className="divide-y" style={{ borderColor: FROGIO_COLORS.border }}>
            {bitacora.recentLogs.map((log, idx) => {
              const plate = log.vehiclePlate ?? log.plate ?? 'Sin patente';
              const driver = log.driverName ?? log.driver_name ?? '';
              const startRaw = log.startTime ?? log.start_time;
              const dist = log.totalDistanceKm ?? log.total_distance_km;
              const distNum = typeof dist === 'number' ? dist : toFloat(dist);
              const startDate = startRaw ? new Date(startRaw) : null;
              const startText =
                startDate && !isNaN(startDate.getTime())
                  ? startDate.toLocaleString('es-CL', {
                      day: '2-digit',
                      month: 'short',
                      hour: '2-digit',
                      minute: '2-digit',
                    })
                  : '';
              return (
                <motion.li
                  key={idx}
                  initial={{ opacity: 0, x: 10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: idx * 0.05, duration: 0.3 }}
                  className="flex items-center gap-3 py-3"
                >
                  <div
                    className="rounded-lg p-2"
                    style={{
                      background: `linear-gradient(135deg, ${FROGIO_COLORS.primary}26 0%, ${FROGIO_COLORS.primary}0D 100%)`,
                      color: FROGIO_COLORS.primary,
                    }}
                  >
                    <TruckIcon className="h-4 w-4" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div
                      className="text-sm font-bold tracking-wide truncate"
                      style={{ color: FROGIO_COLORS.textPrimary }}
                    >
                      {plate}
                    </div>
                    {driver && (
                      <div
                        className="text-[11px] truncate"
                        style={{ color: FROGIO_COLORS.textSecondary }}
                      >
                        {driver}
                      </div>
                    )}
                    {startText && (
                      <div
                        className="text-[10px]"
                        style={{ color: FROGIO_COLORS.textTertiary }}
                      >
                        {startText}
                      </div>
                    )}
                  </div>
                  <span
                    className="px-2.5 py-1 rounded-full text-[11px] font-extrabold"
                    style={{
                      backgroundColor: `${FROGIO_COLORS.primary}1A`,
                      color: FROGIO_COLORS.primaryDark,
                    }}
                  >
                    {distNum.toFixed(1)} km
                  </span>
                </motion.li>
              );
            })}
          </ul>
        )}
      </motion.div>
    </div>
  );
}
