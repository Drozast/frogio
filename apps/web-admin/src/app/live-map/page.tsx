'use client';

/**
 * Mapa en Vivo (Admin) — mirrors
 * apps/mobile/lib/features/admin/presentation/pages/admin_live_map_screen.dart
 *
 * Section header + filter chips + Leaflet map with three layers:
 *   inspectores (vehicles), SOS (panic), denuncias (reports).
 */

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import dynamic from 'next/dynamic';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Activity,
  AlertTriangle,
  Car,
  FileWarning,
  RefreshCw,
  Crosshair,
  Share2,
  X,
  FileSpreadsheet,
  FileText,
  User as UserIcon,
  Phone,
  MapPin,
  Clock,
  Tag,
  MessageSquare,
  Gauge,
  Hash,
} from 'lucide-react';

import AppLayout from '@/components/layout/AppLayout';
import {
  getLivePositions,
  getVehicles,
  getPanicAlerts,
  getReports,
  pick,
  type AdminRecord,
} from '@/lib/admin-api';
import { exportCSV, exportPDF } from '@/lib/export-service';
import { FROGIO_COLORS } from '@/lib/theme';
import type {
  AdminLiveMapHandle,
  MapVehicle,
  MapSos,
  MapReport,
} from '@/components/map/AdminLiveMap';

const AdminLiveMap = dynamic(() => import('@/components/map/AdminLiveMap'), {
  ssr: false,
  loading: () => (
    <div className="h-full w-full flex items-center justify-center bg-gray-50">
      <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-primary" />
    </div>
  ),
});

function fmtTime(d: Date): string {
  return d.toLocaleTimeString('es-CL', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
}

function fmtDateTime(s?: string | null): string {
  if (!s) return '—';
  try {
    const d = new Date(s);
    if (Number.isNaN(d.getTime())) return '—';
    return d.toLocaleString('es-CL');
  } catch {
    return '—';
  }
}

function toNumOrNull(v: unknown): number | null {
  if (v == null) return null;
  if (typeof v === 'number') return Number.isFinite(v) ? v : null;
  const n = parseFloat(String(v));
  return Number.isFinite(n) ? n : null;
}

function hasLatLng(o: AdminRecord, latKey = 'latitude', lngKey = 'longitude'): boolean {
  const lat = toNumOrNull(o[latKey]);
  const lng = toNumOrNull(o[lngKey]);
  return lat != null && lng != null;
}

// Normalize a /api/vehicles record (fallback path) into MapVehicle shape.
function normalizeFallbackVehicle(v: AdminRecord): MapVehicle {
  return {
    vehicleId: pick<string>(v, 'id'),
    vehiclePlate: pick<string>(v, 'plate'),
    driverName: pick<string>(v, 'active_driver_name', 'driverName'),
    latitude: toNumOrNull(v.latitude ?? v.last_latitude),
    longitude: toNumOrNull(v.longitude ?? v.last_longitude),
    speed: toNumOrNull(v.speed ?? v.last_speed),
    lastUpdate: pick<string>(v, 'last_update', 'updated_at'),
  };
}

type Tab = 'inspectores' | 'sos' | 'denuncias';

export default function LiveMapPage() {
  const mapRef = useRef<AdminLiveMapHandle | null>(null);

  // Data
  const [vehicles, setVehicles] = useState<MapVehicle[]>([]);
  const [sos, setSos] = useState<MapSos[]>([]);
  const [reports, setReports] = useState<MapReport[]>([]);

  // Filters
  const [showVehicles, setShowVehicles] = useState(true);
  const [showSos, setShowSos] = useState(true);
  const [showReports, setShowReports] = useState(true);

  // State
  const [loading, setLoading] = useState(false);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(null);
  const [exportOpen, setExportOpen] = useState(false);

  // Side panel
  const [panel, setPanel] = useState<{
    tab: Tab;
    data: MapVehicle | MapSos | MapReport;
  } | null>(null);

  const fetchVehicles = useCallback(async (): Promise<MapVehicle[]> => {
    const live = await getLivePositions();
    const liveMapped = live
      .filter((v) => hasLatLng(v))
      .map((v) => ({
        vehicleId: pick<string>(v, 'vehicleId', 'id'),
        vehiclePlate: pick<string>(v, 'vehiclePlate', 'plate'),
        driverName: pick<string>(v, 'driverName', 'driver_name'),
        latitude: toNumOrNull(v.latitude),
        longitude: toNumOrNull(v.longitude),
        speed: toNumOrNull(v.speed),
        lastUpdate: pick<string>(v, 'lastUpdate', 'last_update', 'updated_at'),
      })) as MapVehicle[];
    if (liveMapped.length > 0) return liveMapped;

    // Fallback to /api/vehicles where active_log_id != null
    const all = await getVehicles();
    return all
      .filter((v) => v.active_log_id != null)
      .map(normalizeFallbackVehicle)
      .filter(
        (v) => toNumOrNull(v.latitude) != null && toNumOrNull(v.longitude) != null
      );
  }, []);

  const fetchSos = useCallback(async (): Promise<MapSos[]> => {
    const raw = await getPanicAlerts();
    return raw
      .filter((a) => {
        const st = String(a.status ?? '').toLowerCase();
        return st === 'active' || st === 'responding';
      })
      .filter((a) => hasLatLng(a))
      .map((a) => ({
        id: pick<string>(a, 'id'),
        first_name: pick<string>(a, 'first_name'),
        last_name: pick<string>(a, 'last_name'),
        contact_phone: pick<string>(a, 'contact_phone'),
        address: pick<string>(a, 'address'),
        status: pick<string>(a, 'status'),
        message: pick<string>(a, 'message'),
        latitude: toNumOrNull(a.latitude)!,
        longitude: toNumOrNull(a.longitude)!,
        created_at: pick<string>(a, 'created_at'),
      }));
  }, []);

  const fetchReports = useCallback(async (): Promise<MapReport[]> => {
    const raw = await getReports();
    return raw
      .filter(
        (r) => String(r.status ?? '').toLowerCase() === 'pendiente'
      )
      .filter((r) => hasLatLng(r))
      .map((r) => ({
        id: pick<string>(r, 'id'),
        title: pick<string>(r, 'title'),
        category: pick<string>(r, 'category'),
        report_type: pick<string>(r, 'report_type'),
        status: pick<string>(r, 'status'),
        address: pick<string>(r, 'address'),
        citizen_name: pick<string>(r, 'citizen_name', 'citizenName'),
        latitude: toNumOrNull(r.latitude)!,
        longitude: toNumOrNull(r.longitude)!,
        created_at: pick<string>(r, 'created_at'),
      }));
  }, []);

  const loadAll = useCallback(async () => {
    setLoading(true);
    try {
      const [v, s, r] = await Promise.all([
        fetchVehicles(),
        fetchSos(),
        fetchReports(),
      ]);
      setVehicles(v);
      setSos(s);
      setReports(r);
      setLastUpdated(new Date());
    } finally {
      setLoading(false);
    }
  }, [fetchVehicles, fetchSos, fetchReports]);

  useEffect(() => {
    loadAll();
    const id = window.setInterval(loadAll, 15000);
    return () => window.clearInterval(id);
  }, [loadAll]);

  // Counts shown in pill
  const counts = useMemo(
    () => ({
      v: showVehicles ? vehicles.length : 0,
      s: showSos ? sos.length : 0,
      r: showReports ? reports.length : 0,
    }),
    [showVehicles, showSos, showReports, vehicles, sos, reports]
  );

  // Export -------------------------------------------------------------------
  function handleExportCSV() {
    setExportOpen(false);
    if (showVehicles && vehicles.length > 0) {
      exportCSV({
        filenamePrefix: 'mapa_inspectores',
        headers: ['Patente', 'Conductor', 'Lat', 'Lng', 'Velocidad', 'Actualizado'],
        rows: vehicles.map((v) => [
          (v.vehiclePlate ?? v.plate ?? '').toString(),
          (v.driverName ?? v.driver_name ?? '').toString(),
          toNumOrNull(v.latitude) ?? '',
          toNumOrNull(v.longitude) ?? '',
          toNumOrNull(v.speed)?.toFixed(1) ?? '',
          fmtDateTime(v.lastUpdate ?? v.last_update),
        ]),
      });
    }
    if (showSos && sos.length > 0) {
      exportCSV({
        filenamePrefix: 'mapa_sos',
        headers: ['ID', 'Nombre', 'Telefono', 'Direccion', 'Estado', 'Fecha'],
        rows: sos.map((s) => [
          s.id ?? '',
          [s.first_name, s.last_name].filter(Boolean).join(' '),
          s.contact_phone ?? '',
          s.address ?? '',
          s.status ?? '',
          fmtDateTime(s.created_at),
        ]),
      });
    }
    if (showReports && reports.length > 0) {
      exportCSV({
        filenamePrefix: 'mapa_denuncias',
        headers: ['Titulo', 'Categoria', 'Direccion', 'Ciudadano', 'Estado', 'Fecha'],
        rows: reports.map((r) => [
          r.title ?? '',
          (r.category ?? r.report_type) ?? '',
          r.address ?? '',
          r.citizen_name ?? '',
          r.status ?? '',
          fmtDateTime(r.created_at),
        ]),
      });
    }
  }

  async function handleExportPDF() {
    setExportOpen(false);
    const stamp = new Date().toLocaleString('es-CL');
    if (showVehicles && vehicles.length > 0) {
      await exportPDF({
        title: 'Mapa en vivo - Inspectores',
        subtitle: `Generado: ${stamp}`,
        headers: ['Patente', 'Conductor', 'Lat', 'Lng', 'Velocidad', 'Actualizado'],
        rows: vehicles.map((v) => [
          String(v.vehiclePlate ?? v.plate ?? ''),
          String(v.driverName ?? v.driver_name ?? ''),
          String(toNumOrNull(v.latitude) ?? ''),
          String(toNumOrNull(v.longitude) ?? ''),
          toNumOrNull(v.speed)?.toFixed(1) ?? '',
          fmtDateTime(v.lastUpdate ?? v.last_update),
        ]),
      });
    }
    if (showSos && sos.length > 0) {
      await exportPDF({
        title: 'Mapa en vivo - Alertas SOS',
        subtitle: `Generado: ${stamp}`,
        headers: ['ID', 'Nombre', 'Telefono', 'Direccion', 'Estado', 'Fecha'],
        rows: sos.map((s) => [
          String(s.id ?? ''),
          [s.first_name, s.last_name].filter(Boolean).join(' '),
          String(s.contact_phone ?? ''),
          String(s.address ?? ''),
          String(s.status ?? ''),
          fmtDateTime(s.created_at),
        ]),
      });
    }
    if (showReports && reports.length > 0) {
      await exportPDF({
        title: 'Mapa en vivo - Denuncias',
        subtitle: `Generado: ${stamp}`,
        headers: ['Titulo', 'Categoria', 'Direccion', 'Ciudadano', 'Estado', 'Fecha'],
        rows: reports.map((r) => [
          String(r.title ?? ''),
          String((r.category ?? r.report_type) ?? ''),
          String(r.address ?? ''),
          String(r.citizen_name ?? ''),
          String(r.status ?? ''),
          fmtDateTime(r.created_at),
        ]),
      });
    }
  }

  // ---------------------------------------------------------------------------
  return (
    <AppLayout>
      <div className="flex flex-col" style={{ height: 'calc(100vh - 8rem)' }}>
        {/* Section header */}
        <div className="flex items-center gap-3 px-1 pb-3">
          <div
            className="w-1 h-7 rounded"
            style={{
              background: `linear-gradient(180deg, ${FROGIO_COLORS.primaryDark} 0%, ${FROGIO_COLORS.primary} 100%)`,
            }}
          />
          <h1 className="text-xl font-bold text-foreground">Mapa en Vivo</h1>
          <LiveBadge />
          <span className="text-xs text-muted-foreground tabular-nums">
            {lastUpdated ? fmtTime(lastUpdated) : '--:--:--'}
          </span>
          <div className="ml-auto">
            <button
              onClick={() => setExportOpen(true)}
              className="inline-flex items-center gap-2 px-3 py-2 text-sm font-semibold rounded-lg border border-primary/20 bg-primary/5 text-primary hover:bg-primary/10 transition-colors"
            >
              <Share2 className="h-4 w-4" />
              Exportar
            </button>
          </div>
        </div>

        {/* Filter chips */}
        <div className="flex items-center gap-2 overflow-x-auto pb-3 px-1">
          <FilterChip
            label="Inspectores"
            color={FROGIO_COLORS.primary}
            icon={<Car className="h-3.5 w-3.5" />}
            selected={showVehicles}
            count={vehicles.length}
            onClick={() => setShowVehicles((v) => !v)}
          />
          <FilterChip
            label="SOS"
            color={FROGIO_COLORS.emergency}
            icon={<AlertTriangle className="h-3.5 w-3.5" />}
            selected={showSos}
            count={sos.length}
            onClick={() => setShowSos((v) => !v)}
          />
          <FilterChip
            label="Denuncias"
            color={FROGIO_COLORS.info}
            icon={<FileWarning className="h-3.5 w-3.5" />}
            selected={showReports}
            count={reports.length}
            onClick={() => setShowReports((v) => !v)}
          />
        </div>

        {/* Map */}
        <div className="relative flex-1 rounded-2xl overflow-hidden border border-border shadow-sm">
          <AdminLiveMap
            ref={mapRef}
            vehicles={vehicles}
            sos={sos}
            reports={reports}
            showVehicles={showVehicles}
            showSos={showSos}
            showReports={showReports}
            onVehicleClick={(v) => setPanel({ tab: 'inspectores', data: v })}
            onSosClick={(s) => setPanel({ tab: 'sos', data: s })}
            onReportClick={(r) => setPanel({ tab: 'denuncias', data: r })}
          />

          {/* Counter pill (top-right) */}
          <div className="absolute top-3 right-3 z-[1000]">
            <div className="px-3 py-1.5 rounded-full bg-white border border-border shadow-sm text-xs font-bold text-foreground">
              {counts.v} inspectores · {counts.s} SOS · {counts.r} denuncias
            </div>
          </div>

          {/* Centrar (bottom-left) */}
          <div className="absolute bottom-4 left-4 z-[1000]">
            <button
              onClick={() => mapRef.current?.fitToMarkers()}
              className="inline-flex items-center gap-1.5 px-3.5 py-2.5 bg-white rounded-full shadow-md border border-border text-sm font-bold text-primary hover:bg-primary/5"
            >
              <Crosshair className="h-4 w-4" />
              Centrar
            </button>
          </div>

          {/* Recargar (bottom-right) */}
          <div className="absolute bottom-4 right-4 z-[1000]">
            <button
              onClick={loadAll}
              disabled={loading}
              className="inline-flex items-center gap-1.5 px-3.5 py-2.5 rounded-full shadow-md text-sm font-bold text-white disabled:opacity-70"
              style={{ background: FROGIO_COLORS.primary }}
            >
              <RefreshCw
                className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`}
              />
              Recargar
            </button>
          </div>
        </div>
      </div>

      {/* Side panel */}
      <AnimatePresence>
        {panel && (
          <motion.div
            className="fixed inset-0 z-[1100] flex"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setPanel(null)}
          >
            <div className="flex-1 bg-black/30" />
            <motion.div
              className="w-full max-w-md bg-white shadow-2xl h-full overflow-y-auto"
              initial={{ x: '100%' }}
              animate={{ x: 0 }}
              exit={{ x: '100%' }}
              transition={{ type: 'spring', stiffness: 320, damping: 30 }}
              onClick={(e) => e.stopPropagation()}
            >
              <DetailPanel panel={panel} onClose={() => setPanel(null)} />
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Export modal */}
      <AnimatePresence>
        {exportOpen && (
          <motion.div
            className="fixed inset-0 z-[1100] flex items-center justify-center bg-black/40 p-4"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setExportOpen(false)}
          >
            <motion.div
              className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6"
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              onClick={(e) => e.stopPropagation()}
            >
              <div className="flex items-start justify-between mb-1">
                <h3 className="text-lg font-bold text-foreground">
                  Exportar mapa en vivo
                </h3>
                <button
                  onClick={() => setExportOpen(false)}
                  className="text-muted-foreground hover:text-foreground"
                  aria-label="Cerrar"
                >
                  <X className="h-5 w-5" />
                </button>
              </div>
              <p className="text-sm text-muted-foreground mb-5">
                Se exportarán solo las capas visibles
              </p>
              <button
                onClick={handleExportCSV}
                className="w-full mb-3 inline-flex items-center justify-center gap-2 py-3 rounded-xl text-white font-semibold"
                style={{ background: FROGIO_COLORS.primary }}
              >
                <FileSpreadsheet className="h-5 w-5" />
                Exportar como CSV
              </button>
              <button
                onClick={handleExportPDF}
                className="w-full inline-flex items-center justify-center gap-2 py-3 rounded-xl border-2 font-semibold"
                style={{
                  borderColor: FROGIO_COLORS.primary,
                  color: FROGIO_COLORS.primaryDark,
                }}
              >
                <FileText className="h-5 w-5" />
                Exportar como PDF
              </button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </AppLayout>
  );
}

// ---------------------------------------------------------------------------
// Sub-components
// ---------------------------------------------------------------------------

function LiveBadge() {
  return (
    <span
      className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[10px] font-extrabold tracking-wide border"
      style={{
        color: FROGIO_COLORS.success,
        background: '#E8F5E9',
        borderColor: '#A5D6A7',
      }}
    >
      <span className="relative flex h-1.5 w-1.5">
        <span
          className="absolute inline-flex h-full w-full rounded-full opacity-70 animate-ping"
          style={{ background: FROGIO_COLORS.success }}
        />
        <span
          className="relative inline-flex h-1.5 w-1.5 rounded-full"
          style={{ background: FROGIO_COLORS.success }}
        />
      </span>
      LIVE
    </span>
  );
}

function FilterChip({
  label,
  color,
  icon,
  selected,
  count,
  onClick,
}: {
  label: string;
  color: string;
  icon: React.ReactNode;
  selected: boolean;
  count: number;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      className="inline-flex items-center gap-2 px-3 py-2 rounded-full border transition-all whitespace-nowrap"
      style={{
        background: selected ? `${color}1F` : '#fff',
        borderColor: selected ? `${color}66` : '#E5E7EB',
        borderWidth: selected ? 1.5 : 1,
        color: selected ? color : FROGIO_COLORS.textSecondary,
      }}
    >
      {icon}
      <span className="text-xs font-bold">{label}</span>
      <span
        className="text-[10px] font-extrabold px-1.5 rounded-full text-white"
        style={{ background: selected ? color : '#9CA3AF', minWidth: 18 }}
      >
        {count}
      </span>
    </button>
  );
}

function DetailPanel({
  panel,
  onClose,
}: {
  panel: { tab: Tab; data: MapVehicle | MapSos | MapReport };
  onClose: () => void;
}) {
  const accent =
    panel.tab === 'inspectores'
      ? FROGIO_COLORS.primary
      : panel.tab === 'sos'
        ? FROGIO_COLORS.emergency
        : FROGIO_COLORS.info;

  let title = '';
  let subtitle = '';
  let rows: { icon: React.ReactNode; label: string; value: string }[] = [];

  if (panel.tab === 'inspectores') {
    const v = panel.data as MapVehicle;
    const plate = (v.vehiclePlate ?? v.plate ?? '').toString().toUpperCase();
    title = plate || 'Vehículo';
    subtitle = 'Inspector en terreno';
    const lat = toNumOrNull(v.latitude);
    const lng = toNumOrNull(v.longitude);
    rows = [
      {
        icon: <UserIcon className="h-4 w-4" />,
        label: 'Conductor',
        value: (v.driverName ?? v.driver_name ?? '—').toString(),
      },
      {
        icon: <Gauge className="h-4 w-4" />,
        label: 'Velocidad',
        value:
          toNumOrNull(v.speed) != null
            ? `${toNumOrNull(v.speed)!.toFixed(1)} km/h`
            : '—',
      },
      {
        icon: <MapPin className="h-4 w-4" />,
        label: 'Coordenadas',
        value:
          lat != null && lng != null
            ? `${lat.toFixed(5)}, ${lng.toFixed(5)}`
            : '—',
      },
      {
        icon: <Clock className="h-4 w-4" />,
        label: 'Actualizado',
        value: fmtDateTime(v.lastUpdate ?? v.last_update),
      },
    ];
  } else if (panel.tab === 'sos') {
    const s = panel.data as MapSos;
    title = 'ALERTA SOS';
    subtitle = (s.status ?? '').toUpperCase();
    rows = [
      {
        icon: <UserIcon className="h-4 w-4" />,
        label: 'Nombre',
        value: [s.first_name, s.last_name].filter(Boolean).join(' ') || '—',
      },
      {
        icon: <Phone className="h-4 w-4" />,
        label: 'Teléfono',
        value: s.contact_phone || '—',
      },
      {
        icon: <MapPin className="h-4 w-4" />,
        label: 'Dirección',
        value: s.address || '—',
      },
      ...(s.message
        ? [
            {
              icon: <MessageSquare className="h-4 w-4" />,
              label: 'Mensaje',
              value: s.message,
            },
          ]
        : []),
      {
        icon: <Clock className="h-4 w-4" />,
        label: 'Recibida',
        value: fmtDateTime(s.created_at),
      },
    ];
  } else {
    const r = panel.data as MapReport;
    title = r.title ?? 'Denuncia';
    subtitle = 'Denuncia ciudadana';
    rows = [
      {
        icon: <Tag className="h-4 w-4" />,
        label: 'Categoría',
        value: (r.category ?? r.report_type) || '—',
      },
      {
        icon: <MapPin className="h-4 w-4" />,
        label: 'Dirección',
        value: r.address || '—',
      },
      {
        icon: <UserIcon className="h-4 w-4" />,
        label: 'Ciudadano',
        value: r.citizen_name || '—',
      },
      {
        icon: <Hash className="h-4 w-4" />,
        label: 'Estado',
        value: r.status || '—',
      },
      {
        icon: <Clock className="h-4 w-4" />,
        label: 'Creada',
        value: fmtDateTime(r.created_at),
      },
    ];
  }

  return (
    <div className="p-6">
      <div className="flex items-center gap-3 mb-5">
        <div
          className="w-11 h-11 rounded-xl flex items-center justify-center"
          style={{
            background: `${accent}1F`,
            border: `1px solid ${accent}55`,
          }}
        >
          <Activity className="h-5 w-5" style={{ color: accent }} />
        </div>
        <div className="flex-1 min-w-0">
          <h2 className="text-lg font-bold text-foreground truncate">{title}</h2>
          <p
            className="text-xs font-bold uppercase tracking-wide"
            style={{ color: accent }}
          >
            {subtitle}
          </p>
        </div>
        <button
          onClick={onClose}
          className="text-muted-foreground hover:text-foreground"
          aria-label="Cerrar"
        >
          <X className="h-5 w-5" />
        </button>
      </div>

      <div className="space-y-3">
        {rows.map((r, i) => (
          <div key={i} className="flex items-start gap-3">
            <span style={{ color: accent }}>{r.icon}</span>
            <div className="w-28 text-xs font-semibold text-muted-foreground">
              {r.label}
            </div>
            <div className="flex-1 text-sm text-foreground font-medium break-words">
              {r.value}
            </div>
          </div>
        ))}
      </div>

      <button
        onClick={onClose}
        className="mt-6 w-full py-2.5 rounded-xl border border-border text-sm font-semibold hover:bg-muted"
      >
        Cerrar
      </button>
    </div>
  );
}
