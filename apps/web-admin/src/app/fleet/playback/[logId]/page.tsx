'use client';

/**
 * Route playback for a single vehicle log — mirrors
 * apps/mobile/lib/features/admin/presentation/pages/route_playback_screen.dart
 */

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import dynamic from 'next/dynamic';
import { motion, AnimatePresence } from 'framer-motion';
import {
  ArrowLeft,
  Play,
  Pause,
  Square,
  Route,
  Clock,
  Gauge,
  Zap,
} from 'lucide-react';

import AppLayout from '@/components/layout/AppLayout';
import { getVehicleLog } from '@/lib/admin-api';
import { FROGIO_COLORS, FROGIO_GRADIENTS } from '@/lib/theme';

const PlaybackMap = dynamic(
  () => import('@/components/map/PlaybackMap'),
  {
    ssr: false,
    loading: () => (
      <div className="h-full w-full flex items-center justify-center bg-gray-50">
        <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary" />
      </div>
    ),
  }
);

export interface RoutePoint {
  lat: number;
  lng: number;
  speed: number | null;
  heading: number | null;
  timestamp: Date | null;
}

const SPEEDS = [1, 2, 4, 8] as const;

// Haversine distance in kilometers.
function haversineKm(
  lat1: number,
  lng1: number,
  lat2: number,
  lng2: number
): number {
  const R = 6371;
  const toRad = (d: number) => (d * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.min(1, Math.sqrt(a)));
}

function parseRoutePoint(raw: Record<string, unknown>): RoutePoint | null {
  const lat =
    typeof raw.lat === 'number'
      ? raw.lat
      : typeof raw.latitude === 'number'
        ? raw.latitude
        : parseFloat(String(raw.lat ?? raw.latitude));
  const lng =
    typeof raw.lng === 'number'
      ? raw.lng
      : typeof raw.longitude === 'number'
        ? raw.longitude
        : parseFloat(String(raw.lng ?? raw.longitude));
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  const speedRaw = raw.speed as unknown;
  const headingRaw = (raw.heading ?? raw.bearing) as unknown;
  const tsRaw = (raw.timestamp ?? raw.recorded_at ?? raw.recordedAt) as unknown;
  const speed =
    speedRaw != null && Number.isFinite(parseFloat(String(speedRaw)))
      ? parseFloat(String(speedRaw))
      : null;
  const heading =
    headingRaw != null && Number.isFinite(parseFloat(String(headingRaw)))
      ? parseFloat(String(headingRaw))
      : null;
  let timestamp: Date | null = null;
  if (tsRaw) {
    const d = new Date(String(tsRaw));
    if (!Number.isNaN(d.getTime())) timestamp = d;
  }
  return { lat, lng, speed, heading, timestamp };
}

function formatDuration(ms: number): string {
  if (!Number.isFinite(ms) || ms < 0) return '0:00';
  const s = Math.floor(ms / 1000);
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const sec = s % 60;
  if (h > 0) {
    return `${h}:${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;
  }
  return `${m}:${String(sec).padStart(2, '0')}`;
}

export default function RoutePlaybackPage() {
  const params = useParams<{ logId: string }>();
  const router = useRouter();
  const logId = params?.logId;

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [points, setPoints] = useState<RoutePoint[]>([]);
  const [plate, setPlate] = useState<string>('');
  const [driver, setDriver] = useState<string>('');

  // Playback state
  const [index, setIndex] = useState(0);
  const [playing, setPlaying] = useState(false);
  const [speedMult, setSpeedMult] = useState<(typeof SPEEDS)[number]>(1);
  const [progress, setProgress] = useState(0); // 0..1
  const [toast, setToast] = useState<string | null>(null);

  const rafRef = useRef<number | null>(null);
  const lastTimeRef = useRef<number | null>(null);

  // Load log
  useEffect(() => {
    if (!logId) return;
    (async () => {
      setLoading(true);
      setError(null);
      try {
        const log = await getVehicleLog(logId);
        if (!log) {
          setError('No se pudo cargar la bitácora');
          return;
        }
        const raw = log.route_points ?? log.routePoints ?? [];
        const parsed: RoutePoint[] = [];
        for (const r of raw) {
          const p = parseRoutePoint(r as Record<string, unknown>);
          if (p) parsed.push(p);
        }
        parsed.sort((a, b) => {
          const at = a.timestamp?.getTime() ?? 0;
          const bt = b.timestamp?.getTime() ?? 0;
          return at - bt;
        });
        if (parsed.length === 0) {
          setError('La bitácora no tiene puntos de ruta');
        }
        setPoints(parsed);
        setPlate(
          String(
            (log as Record<string, unknown>).plate ??
              (log as Record<string, unknown>).vehicle_plate ??
              ''
          ).toUpperCase()
        );
        setDriver(
          String(
            (log as Record<string, unknown>).driver_name ??
              (log as Record<string, unknown>).driverName ??
              ''
          )
        );
      } catch (e) {
        setError((e as Error).message);
      } finally {
        setLoading(false);
      }
    })();
  }, [logId]);

  // Stats
  const stats = useMemo(() => {
    let dist = 0;
    let maxSpeed = 0;
    let sumSpeed = 0;
    let nSpeed = 0;
    for (let i = 0; i < points.length; i++) {
      const p = points[i];
      if (p.speed != null) {
        if (p.speed > maxSpeed) maxSpeed = p.speed;
        sumSpeed += p.speed;
        nSpeed++;
      }
      if (i > 0) {
        dist += haversineKm(
          points[i - 1].lat,
          points[i - 1].lng,
          p.lat,
          p.lng
        );
      }
    }
    const total =
      points.length >= 2 &&
      points[0].timestamp != null &&
      points[points.length - 1].timestamp != null
        ? Math.max(
            0,
            points[points.length - 1].timestamp!.getTime() -
              points[0].timestamp!.getTime()
          )
        : 0;
    return {
      totalDistanceKm: dist,
      totalDurationMs: total,
      avgSpeedKmh: nSpeed > 0 ? sumSpeed / nSpeed : 0,
      maxSpeedKmh: maxSpeed,
    };
  }, [points]);

  // Route duration used for playback pacing
  const routeDurationMs = useMemo(() => {
    if (stats.totalDurationMs > 0) return stats.totalDurationMs;
    // Fallback: 1 second per point
    return Math.max(1000, points.length * 1000);
  }, [stats.totalDurationMs, points.length]);

  const indexAtProgress = useCallback(
    (p: number): number => {
      if (points.length === 0) return 0;
      if (
        points[0].timestamp == null ||
        points[points.length - 1].timestamp == null
      ) {
        return Math.min(
          points.length - 1,
          Math.max(0, Math.floor(p * (points.length - 1)))
        );
      }
      const start = points[0].timestamp!.getTime();
      const target = start + routeDurationMs * p;
      // Binary search would be fine; linear ok.
      let i = 0;
      while (
        i < points.length - 1 &&
        (points[i + 1].timestamp?.getTime() ?? Infinity) <= target
      ) {
        i++;
      }
      return i;
    },
    [points, routeDurationMs]
  );

  // Animation loop
  useEffect(() => {
    if (!playing) return;
    lastTimeRef.current = null;
    const step = (t: number) => {
      if (lastTimeRef.current == null) lastTimeRef.current = t;
      const dt = t - lastTimeRef.current;
      lastTimeRef.current = t;
      setProgress((prev) => {
        const next = prev + (dt * speedMult) / routeDurationMs;
        if (next >= 1) {
          setPlaying(false);
          setIndex(points.length - 1);
          setToast('Reproducción finalizada');
          setTimeout(() => setToast(null), 2200);
          return 1;
        }
        setIndex(indexAtProgress(next));
        return next;
      });
      rafRef.current = requestAnimationFrame(step);
    };
    rafRef.current = requestAnimationFrame(step);
    return () => {
      if (rafRef.current != null) cancelAnimationFrame(rafRef.current);
      rafRef.current = null;
    };
  }, [playing, speedMult, routeDurationMs, points.length, indexAtProgress]);

  function onPlay() {
    if (points.length < 2) return;
    if (progress >= 1) {
      setProgress(0);
      setIndex(0);
    }
    setPlaying(true);
  }
  function onPause() {
    setPlaying(false);
  }
  function onStop() {
    setPlaying(false);
    setProgress(0);
    setIndex(0);
  }
  function onSeek(value: number) {
    setProgress(value);
    setIndex(indexAtProgress(value));
  }

  const current = points[index] ?? null;

  return (
    <AppLayout>
      <div
        className="flex flex-col"
        style={{ height: 'calc(100vh - 8rem)' }}
      >
        {/* Header */}
        <div
          className="flex items-center gap-3 px-4 py-3 rounded-2xl text-white shadow-sm mb-3"
          style={{ background: FROGIO_GRADIENTS.primary }}
        >
          <button
            onClick={() => router.back()}
            className="p-2 -ml-1 rounded-full hover:bg-white/10"
            aria-label="Volver"
          >
            <ArrowLeft className="h-5 w-5" />
          </button>
          <div className="flex-1 min-w-0">
            <h1 className="text-lg font-extrabold tracking-wide truncate">
              Reproducción de ruta — {plate || '—'}
            </h1>
            {driver && (
              <p className="text-xs font-medium text-white/80 truncate">
                {driver}
              </p>
            )}
          </div>
        </div>

        {loading ? (
          <div className="flex-1 flex items-center justify-center">
            <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary" />
          </div>
        ) : error ? (
          <div className="flex-1 flex items-center justify-center text-center px-6">
            <div>
              <Route className="h-12 w-12 mx-auto text-muted-foreground mb-3" />
              <h3 className="text-lg font-semibold text-foreground">
                No se puede reproducir
              </h3>
              <p className="text-sm text-muted-foreground mt-1">{error}</p>
            </div>
          </div>
        ) : (
          <>
            {/* Map */}
            <div className="relative flex-1 rounded-2xl overflow-hidden border border-border shadow-sm">
              <PlaybackMap
                points={points}
                currentIndex={index}
                autoPan
              />
            </div>

            {/* Bottom panel */}
            <div className="mt-3 bg-white rounded-2xl border border-border shadow-sm p-4 space-y-3">
              {/* Stats */}
              <div className="grid grid-cols-2 md:grid-cols-4 gap-2">
                <StatCard
                  icon={<Route className="h-4 w-4" />}
                  label="Distancia"
                  value={`${stats.totalDistanceKm.toFixed(2)} km`}
                  color={FROGIO_COLORS.primary}
                />
                <StatCard
                  icon={<Clock className="h-4 w-4" />}
                  label="Tiempo"
                  value={formatDuration(stats.totalDurationMs)}
                  color={FROGIO_COLORS.warning}
                />
                <StatCard
                  icon={<Gauge className="h-4 w-4" />}
                  label="Vel. promedio"
                  value={`${stats.avgSpeedKmh.toFixed(1)} km/h`}
                  color={FROGIO_COLORS.info}
                />
                <StatCard
                  icon={<Zap className="h-4 w-4" />}
                  label="Vel. máxima"
                  value={`${stats.maxSpeedKmh.toFixed(1)} km/h`}
                  color={FROGIO_COLORS.emergency}
                />
              </div>

              {/* Current point info */}
              <div
                className="rounded-xl px-3 py-2 text-xs"
                style={{ background: `${FROGIO_COLORS.primary}10` }}
              >
                <div className="flex items-center justify-between">
                  <div>
                    <p className="text-[11px] font-bold text-muted-foreground">
                      {current?.timestamp
                        ? current.timestamp.toLocaleString('es-CL')
                        : `Punto ${index + 1}/${points.length}`}
                    </p>
                    <p className="text-foreground font-semibold mt-0.5">
                      Vel: {current?.speed?.toFixed(1) ?? '—'} km/h · Dir:{' '}
                      {current?.heading?.toFixed(0) ?? '—'}°
                    </p>
                  </div>
                  <span
                    className="font-extrabold"
                    style={{ color: FROGIO_COLORS.primaryDark }}
                  >
                    {index + 1}/{points.length}
                  </span>
                </div>
              </div>

              {/* Seek slider */}
              <input
                type="range"
                min={0}
                max={1}
                step={0.001}
                value={progress}
                onChange={(e) => onSeek(parseFloat(e.target.value))}
                className="w-full accent-[color:var(--primary)]"
                style={{ accentColor: FROGIO_COLORS.primary }}
              />

              {/* Controls */}
              <div className="flex items-center gap-2">
                <button
                  onClick={playing ? onPause : onPlay}
                  disabled={points.length < 2}
                  className="inline-flex items-center justify-center w-12 h-12 rounded-full text-white shadow-md disabled:opacity-60"
                  style={{ background: FROGIO_COLORS.primary }}
                >
                  {playing ? (
                    <Pause className="h-6 w-6" />
                  ) : (
                    <Play className="h-6 w-6" />
                  )}
                </button>
                <button
                  onClick={onStop}
                  className="inline-flex items-center justify-center w-10 h-10 rounded-full bg-white border border-border"
                  title="Stop"
                >
                  <Square className="h-4 w-4 text-muted-foreground" />
                </button>
                <div className="flex items-center gap-1.5 ml-2 flex-wrap">
                  {SPEEDS.map((s) => (
                    <button
                      key={s}
                      onClick={() => setSpeedMult(s)}
                      className="px-2.5 py-1 rounded-full text-xs font-extrabold transition-all"
                      style={{
                        background:
                          speedMult === s
                            ? FROGIO_COLORS.primary
                            : FROGIO_COLORS.surface,
                        color:
                          speedMult === s
                            ? '#fff'
                            : FROGIO_COLORS.textSecondary,
                        border: `1px solid ${
                          speedMult === s
                            ? FROGIO_COLORS.primary
                            : FROGIO_COLORS.border
                        }`,
                      }}
                    >
                      {s}x
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </>
        )}
      </div>

      {/* Toast */}
      <AnimatePresence>
        {toast && (
          <motion.div
            className="fixed bottom-6 left-1/2 -translate-x-1/2 z-[1200]"
            initial={{ opacity: 0, y: 16 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 16 }}
          >
            <div
              className="px-4 py-2 rounded-full text-white text-sm font-semibold shadow-lg"
              style={{ background: FROGIO_COLORS.primaryDark }}
            >
              {toast}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </AppLayout>
  );
}

function StatCard({
  icon,
  label,
  value,
  color,
}: {
  icon: React.ReactNode;
  label: string;
  value: string;
  color: string;
}) {
  return (
    <div
      className="rounded-xl px-3 py-2 border"
      style={{
        background: `${color}10`,
        borderColor: `${color}33`,
      }}
    >
      <div className="flex items-center gap-1.5 text-xs font-bold" style={{ color }}>
        {icon}
        {label}
      </div>
      <p className="text-base font-extrabold text-foreground mt-0.5 tabular-nums">
        {value}
      </p>
    </div>
  );
}
