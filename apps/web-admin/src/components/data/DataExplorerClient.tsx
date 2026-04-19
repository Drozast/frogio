'use client';

import { useState, useEffect, useMemo, useCallback, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  FileText,
  AlertTriangle,
  Siren,
  Car,
  Route,
  Users,
  Download,
  Upload,
  FileDown,
  Search,
  X,
  Inbox,
  ShieldCheck,
  Clock,
  CheckCircle2,
  XCircle,
} from 'lucide-react';

import {
  getCitations,
  getReports,
  getPanicAlerts,
  getVehicles,
  getVehicleLogs,
  getUsers,
  pick,
  type AdminRecord,
} from '@/lib/admin-api';
import { exportCSV, exportPDF } from '@/lib/export-service';
import {
  IMPORT_DATASETS,
  parseCsv,
  uploadRows,
  downloadTemplate,
  type ImportDatasetKey,
  type ImportSummary,
} from '@/lib/import-service';
import { FROGIO_COLORS, getStatusColor } from '@/lib/theme';

// ---------------------------------------------------------------------------
// Tab spec
// ---------------------------------------------------------------------------

type TabKey =
  | 'citations'
  | 'reports'
  | 'sos'
  | 'vehicles'
  | 'logs'
  | 'users';

interface TabSpec {
  key: TabKey;
  label: string;
  icon: typeof FileText;
  filenamePrefix: string;
  pdfTitle: string;
  importDataset?: ImportDatasetKey;
  statusOptions: { value: string; label: string }[];
  headers: string[];
}

const TABS: TabSpec[] = [
  {
    key: 'citations',
    label: 'Citaciones',
    icon: FileText,
    filenamePrefix: 'citaciones',
    pdfTitle: 'Reporte de Citaciones',
    importDataset: 'citations',
    statusOptions: [
      { value: 'pendiente', label: 'Pendiente' },
      { value: 'emitida', label: 'Emitida' },
      { value: 'notificado', label: 'Notificado' },
      { value: 'cancelado', label: 'Cancelado' },
    ],
    headers: ['Numero', 'Tipo', 'Objetivo', 'RUT', 'Direccion', 'Fecha'],
  },
  {
    key: 'reports',
    label: 'Denuncias',
    icon: AlertTriangle,
    filenamePrefix: 'denuncias',
    pdfTitle: 'Reporte de Denuncias',
    importDataset: 'reports',
    statusOptions: [
      { value: 'pendiente', label: 'Pendiente' },
      { value: 'en_proceso', label: 'En Proceso' },
      { value: 'resuelto', label: 'Resuelto' },
      { value: 'rechazado', label: 'Rechazado' },
    ],
    headers: ['Titulo', 'Categoria', 'Ciudadano', 'Direccion', 'Estado', 'Fecha'],
  },
  {
    key: 'sos',
    label: 'SOS',
    icon: Siren,
    filenamePrefix: 'sos',
    pdfTitle: 'Reporte de Alertas SOS',
    statusOptions: [
      { value: 'active', label: 'Activa' },
      { value: 'responding', label: 'Respondiendo' },
      { value: 'resolved', label: 'Resuelta' },
      { value: 'cancelled', label: 'Cancelada' },
    ],
    headers: ['Nombre', 'Telefono', 'Direccion', 'Estado', 'Fecha'],
  },
  {
    key: 'vehicles',
    label: 'Vehiculos',
    icon: Car,
    filenamePrefix: 'vehiculos',
    pdfTitle: 'Reporte de Vehiculos',
    statusOptions: [
      { value: 'available', label: 'Disponible' },
      { value: 'in_use', label: 'En Uso' },
      { value: 'maintenance', label: 'Mantenimiento' },
      { value: 'out_of_service', label: 'Fuera de Servicio' },
    ],
    headers: ['Placa', 'Marca', 'Modelo', 'Año', 'Estado', 'Km'],
  },
  {
    key: 'logs',
    label: 'Bitacoras',
    icon: Route,
    filenamePrefix: 'bitacoras',
    pdfTitle: 'Reporte de Bitacoras',
    statusOptions: [
      { value: 'active', label: 'Activa' },
      { value: 'completed', label: 'Completada' },
      { value: 'cancelled', label: 'Cancelada' },
    ],
    headers: ['Placa', 'Conductor', 'Inicio', 'Fin', 'Distancia', 'Estado'],
  },
  {
    key: 'users',
    label: 'Usuarios',
    icon: Users,
    filenamePrefix: 'usuarios',
    pdfTitle: 'Reporte de Usuarios',
    importDataset: 'users',
    statusOptions: [
      { value: 'admin', label: 'Administrador' },
      { value: 'inspector', label: 'Inspector' },
      { value: 'citizen', label: 'Ciudadano' },
    ],
    headers: ['Nombre', 'Email', 'Rol', 'Activo', 'Fecha'],
  },
];

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

function pad(n: number): string {
  return n < 10 ? `0${n}` : String(n);
}

function toInputDate(d: Date): string {
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

function fromInputDate(s: string, end = false): Date {
  const [y, m, d] = s.split('-').map((n) => parseInt(n, 10));
  return end
    ? new Date(y, (m ?? 1) - 1, d ?? 1, 23, 59, 59, 999)
    : new Date(y, (m ?? 1) - 1, d ?? 1, 0, 0, 0, 0);
}

function formatDateDisplay(d: Date): string {
  return `${pad(d.getDate())}/${pad(d.getMonth() + 1)}/${d.getFullYear()}`;
}

function formatDateTime(value: unknown): string {
  if (!value) return '';
  const d = new Date(String(value));
  if (isNaN(d.getTime())) return String(value);
  return `${pad(d.getDate())}/${pad(d.getMonth() + 1)}/${d.getFullYear()} ${pad(
    d.getHours()
  )}:${pad(d.getMinutes())}`;
}

function s(v: unknown): string {
  if (v == null) return '';
  return String(v);
}

function isWithinRange(value: unknown, from: Date, to: Date): boolean {
  if (!value) return false;
  const d = new Date(String(value));
  if (isNaN(d.getTime())) return false;
  return d.getTime() >= from.getTime() && d.getTime() <= to.getTime();
}

function matchesSearch(record: AdminRecord, query: string): boolean {
  if (!query) return true;
  const q = query.toLowerCase();
  for (const v of Object.values(record)) {
    if (v == null) continue;
    if (typeof v === 'object') continue;
    if (String(v).toLowerCase().includes(q)) return true;
  }
  return false;
}

// ---------------------------------------------------------------------------
// Per-tab row mapping
// ---------------------------------------------------------------------------

function mapRow(tab: TabKey, item: AdminRecord): string[] {
  switch (tab) {
    case 'citations':
      return [
        s(pick(item, 'number', 'citationNumber', 'citation_number')),
        s(pick(item, 'citationType', 'type')),
        s(pick(item, 'targetName', 'target_name')),
        s(pick(item, 'targetRut', 'target_rut')),
        s(pick(item, 'targetAddress', 'target_address', 'locationAddress')),
        formatDateTime(pick(item, 'createdAt', 'created_at')),
      ];
    case 'reports':
      return [
        s(pick(item, 'title')),
        s(pick(item, 'category')),
        s(pick(item, 'citizenName', 'citizen_name')),
        s(pick(item, 'address')),
        s(pick(item, 'status')),
        formatDateTime(pick(item, 'createdAt', 'created_at')),
      ];
    case 'sos':
      return [
        s(pick(item, 'userName', 'user_name', 'name')),
        s(pick(item, 'phone', 'userPhone', 'user_phone')),
        s(pick(item, 'address')),
        s(pick(item, 'status')),
        formatDateTime(pick(item, 'createdAt', 'created_at', 'triggeredAt')),
      ];
    case 'vehicles':
      return [
        s(pick(item, 'plate')),
        s(pick(item, 'brand')),
        s(pick(item, 'model')),
        s(pick(item, 'year')),
        s(pick(item, 'status')),
        s(pick(item, 'currentKm', 'current_km')),
      ];
    case 'logs':
      return [
        s(pick(item, 'plate', 'vehiclePlate', 'vehicle_plate')),
        s(pick(item, 'driverName', 'driver_name')),
        formatDateTime(pick(item, 'startTime', 'start_time')),
        formatDateTime(pick(item, 'endTime', 'end_time')),
        s(pick(item, 'distanceKm', 'distance_km', 'distance')),
        s(pick(item, 'status')),
      ];
    case 'users':
      return [
        `${s(pick(item, 'firstName', 'first_name'))} ${s(pick(item, 'lastName', 'last_name'))}`.trim(),
        s(pick(item, 'email')),
        s(pick(item, 'role')),
        pick<boolean | string>(item, 'isActive', 'is_active', 'active') ? 'Si' : 'No',
        formatDateTime(pick(item, 'createdAt', 'created_at')),
      ];
  }
}

// ---------------------------------------------------------------------------
// Date / status filter helper
// ---------------------------------------------------------------------------

function getRecordDate(tab: TabKey, item: AdminRecord): unknown {
  switch (tab) {
    case 'logs':
      return pick(item, 'startTime', 'start_time', 'createdAt', 'created_at');
    default:
      return pick(item, 'createdAt', 'created_at', 'triggeredAt');
  }
}

function getRecordStatus(tab: TabKey, item: AdminRecord): string {
  if (tab === 'users') return s(pick(item, 'role'));
  return s(pick(item, 'status'));
}

// ---------------------------------------------------------------------------
// Toast (very lightweight)
// ---------------------------------------------------------------------------

interface Toast {
  id: number;
  message: string;
  variant: 'info' | 'success' | 'error';
}

function useToasts() {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const idRef = useRef(0);

  const push = useCallback(
    (message: string, variant: Toast['variant'] = 'info') => {
      const id = ++idRef.current;
      setToasts((t) => [...t, { id, message, variant }]);
      setTimeout(() => {
        setToasts((t) => t.filter((x) => x.id !== id));
      }, 3500);
    },
    []
  );

  return { toasts, push };
}

// ---------------------------------------------------------------------------
// Main component
// ---------------------------------------------------------------------------

interface DataExplorerClientProps {
  userEmail: string;
  userName?: string;
}

export default function DataExplorerClient({
  userEmail,
  userName,
}: DataExplorerClientProps) {
  const [activeTabKey, setActiveTabKey] = useState<TabKey>('citations');
  const activeTab = TABS.find((t) => t.key === activeTabKey)!;

  // Filters
  const today = useMemo(() => new Date(), []);
  const defaultFrom = useMemo(() => {
    const d = new Date();
    d.setDate(d.getDate() - 30);
    return d;
  }, []);

  const [fromStr, setFromStr] = useState<string>(toInputDate(defaultFrom));
  const [toStr, setToStr] = useState<string>(toInputDate(today));
  const [status, setStatus] = useState<string>('');
  const [search, setSearch] = useState<string>('');

  // Data
  const [items, setItems] = useState<AdminRecord[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [lastUpdate, setLastUpdate] = useState<Date>(new Date());
  const [now, setNow] = useState<Date>(new Date());

  // Modal
  const [importOpen, setImportOpen] = useState<boolean>(false);

  const { toasts, push } = useToasts();

  // Tick "Actualizado hace Xs"
  useEffect(() => {
    const id = setInterval(() => setNow(new Date()), 1000);
    return () => clearInterval(id);
  }, []);

  const fromDate = useMemo(() => fromInputDate(fromStr, false), [fromStr]);
  const toDate = useMemo(() => fromInputDate(toStr, true), [toStr]);

  // Reset status when changing tab (each tab has its own option set)
  useEffect(() => {
    setStatus('');
  }, [activeTabKey]);

  const fetchData = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      let data: AdminRecord[] = [];
      switch (activeTabKey) {
        case 'citations':
          data = await getCitations({
            from: fromDate,
            to: toDate,
            status: status || undefined,
          });
          break;
        case 'reports':
          data = await getReports({
            from: fromDate,
            to: toDate,
            status: status || undefined,
          });
          break;
        case 'sos': {
          const all = await getPanicAlerts();
          data = all.filter((it) => isWithinRange(getRecordDate('sos', it), fromDate, toDate));
          if (status) data = data.filter((it) => getRecordStatus('sos', it) === status);
          break;
        }
        case 'vehicles': {
          data = await getVehicles();
          if (status) data = data.filter((it) => getRecordStatus('vehicles', it) === status);
          break;
        }
        case 'logs': {
          const all = await getVehicleLogs();
          data = all.filter((it) => isWithinRange(getRecordDate('logs', it), fromDate, toDate));
          if (status) data = data.filter((it) => getRecordStatus('logs', it) === status);
          break;
        }
        case 'users': {
          data = await getUsers({ role: status || undefined });
          break;
        }
      }
      setItems(data);
      setLastUpdate(new Date());
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Error al cargar datos';
      setError(msg);
      setItems([]);
    } finally {
      setLoading(false);
    }
  }, [activeTabKey, fromDate, toDate, status]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const filteredItems = useMemo(() => {
    if (!search) return items;
    return items.filter((it) => matchesSearch(it, search));
  }, [items, search]);

  const rows = useMemo(
    () => filteredItems.map((it) => mapRow(activeTabKey, it)),
    [filteredItems, activeTabKey]
  );

  const secondsSinceUpdate = Math.max(
    0,
    Math.floor((now.getTime() - lastUpdate.getTime()) / 1000)
  );

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  const handleExportCSV = () => {
    if (rows.length === 0) {
      push('No hay datos para exportar', 'error');
      return;
    }
    exportCSV({
      filenamePrefix: activeTab.filenamePrefix,
      headers: activeTab.headers,
      rows,
    });
    push('CSV exportado', 'success');
  };

  const handleExportPDF = async () => {
    if (rows.length === 0) {
      push('No hay datos para exportar', 'error');
      return;
    }
    push('Generando PDF...', 'info');
    try {
      await exportPDF({
        title: activeTab.pdfTitle,
        subtitle: `Del ${formatDateDisplay(fromDate)} al ${formatDateDisplay(toDate)}`,
        headers: activeTab.headers,
        rows,
        generatedBy: userName || userEmail,
      });
      push('PDF generado', 'success');
    } catch {
      push('Error al generar PDF', 'error');
    }
  };

  // -------------------------------------------------------------------------
  // Render helpers
  // -------------------------------------------------------------------------

  const showImportButton = !!activeTab.importDataset;
  const isVehiclesTab = activeTabKey === 'vehicles';

  return (
    <div className="space-y-4">
      {/* Section header */}
      <div className="flex items-center gap-3 px-1">
        <div
          className="w-1 h-10 rounded-full"
          style={{ background: 'linear-gradient(to bottom, #2E7D32, #4CAF50)' }}
        />
        <div className="flex-1">
          <h1 className="text-2xl font-bold text-foreground tracking-tight">
            Explorador de Datos
          </h1>
          <p className="text-sm text-muted-foreground mt-0.5">
            Filtra, exporta e importa registros del municipio
          </p>
        </div>
        <div
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-white text-[11px] font-extrabold tracking-widest shadow-md"
          style={{
            background: 'linear-gradient(135deg, #2E7D32, #4CAF50)',
            boxShadow: '0 4px 10px rgba(46,125,50,0.3)',
          }}
        >
          <ShieldCheck className="w-3.5 h-3.5" />
          ADMIN
        </div>
      </div>

      {/* Pill tab bar */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-thin">
        {TABS.map((t) => {
          const Icon = t.icon;
          const isActive = t.key === activeTabKey;
          return (
            <button
              key={t.key}
              onClick={() => setActiveTabKey(t.key)}
              className={`relative inline-flex items-center gap-2 px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all ${
                isActive
                  ? 'text-white shadow-lg'
                  : 'bg-white text-[var(--frogio-text-secondary,#4A6741)] border border-border/60 hover:bg-muted/60'
              }`}
              style={
                isActive
                  ? {
                      background: 'linear-gradient(135deg, #2E7D32, #4CAF50)',
                      boxShadow: '0 4px 12px rgba(46,125,50,0.35)',
                    }
                  : undefined
              }
            >
              <Icon className="w-3.5 h-3.5" />
              {t.label}
            </button>
          );
        })}
      </div>

      {/* Tab content */}
      <AnimatePresence mode="wait">
        <motion.div
          key={activeTabKey}
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -8 }}
          transition={{ duration: 0.22 }}
          className="space-y-4"
        >
          {/* Filter row */}
          <div className="bg-white rounded-xl shadow-sm border border-border/40 p-4 flex flex-wrap items-end gap-3">
            <div className="flex flex-col">
              <label className="text-[11px] font-medium text-muted-foreground mb-1">
                Desde
              </label>
              <input
                type="date"
                value={fromStr}
                min={toInputDate(new Date(today.getFullYear() - 10, 0, 1))}
                max={toStr}
                onChange={(e) => setFromStr(e.target.value)}
                className="px-3 py-1.5 border border-border rounded-lg text-sm focus:ring-2 focus:ring-primary/30 focus:border-primary outline-none"
              />
            </div>
            <div className="flex flex-col">
              <label className="text-[11px] font-medium text-muted-foreground mb-1">
                Hasta
              </label>
              <input
                type="date"
                value={toStr}
                min={fromStr}
                max={toInputDate(today)}
                onChange={(e) => setToStr(e.target.value)}
                className="px-3 py-1.5 border border-border rounded-lg text-sm focus:ring-2 focus:ring-primary/30 focus:border-primary outline-none"
              />
            </div>

            <div className="flex flex-col">
              <label className="text-[11px] font-medium text-muted-foreground mb-1">
                {activeTabKey === 'users' ? 'Rol' : 'Estado'}
              </label>
              <select
                value={status}
                onChange={(e) => setStatus(e.target.value)}
                className="px-3 py-1.5 border border-border rounded-lg text-sm focus:ring-2 focus:ring-primary/30 focus:border-primary outline-none bg-white min-w-[160px]"
              >
                <option value="">Todos</option>
                {activeTab.statusOptions.map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex flex-col flex-1 min-w-[200px]">
              <label className="text-[11px] font-medium text-muted-foreground mb-1">
                Buscar
              </label>
              <div className="relative">
                <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
                <input
                  type="text"
                  value={search}
                  placeholder="Buscar en resultados..."
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-full pl-8 pr-8 py-1.5 border border-border rounded-lg text-sm focus:ring-2 focus:ring-primary/30 focus:border-primary outline-none"
                />
                {search && (
                  <button
                    onClick={() => setSearch('')}
                    className="absolute right-2 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                )}
              </div>
            </div>
          </div>

          {/* Action row */}
          <div className="flex flex-wrap items-center gap-2">
            <button
              onClick={handleExportCSV}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-white border border-border text-sm font-semibold text-foreground hover:bg-muted/60 transition-colors"
            >
              <Download className="w-4 h-4" />
              Exportar CSV
            </button>
            <button
              onClick={handleExportPDF}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-white border border-border text-sm font-semibold text-foreground hover:bg-muted/60 transition-colors"
            >
              <FileDown className="w-4 h-4" />
              Exportar PDF
            </button>
            {showImportButton && (
              <button
                onClick={() => setImportOpen(true)}
                className="inline-flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold text-white shadow-md transition-all hover:shadow-lg"
                style={{
                  background: 'linear-gradient(135deg, #2E7D32, #4CAF50)',
                }}
              >
                <Upload className="w-4 h-4" />
                Importar CSV
              </button>
            )}
            {isVehiclesTab && (
              <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs text-muted-foreground bg-muted/50 border border-border/40">
                Para importar/gestionar vehiculos use{' '}
                <span className="font-semibold text-primary">Gestion de Flota</span>
              </span>
            )}

            <div className="ml-auto inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium bg-primary/10 text-primary">
              <Clock className="w-3.5 h-3.5" />
              {filteredItems.length} resultados | Actualizado hace {secondsSinceUpdate}s
            </div>
          </div>

          {/* Body */}
          <div className="bg-white rounded-xl shadow-sm border border-border/40 overflow-hidden">
            {loading ? (
              <div className="p-4 space-y-3">
                {[...Array(6)].map((_, i) => (
                  <div
                    key={i}
                    className="h-14 rounded-lg bg-muted/40 animate-pulse"
                  />
                ))}
              </div>
            ) : error ? (
              <div className="p-10 text-center">
                <XCircle className="w-12 h-12 text-red-400 mx-auto mb-3" />
                <p className="text-sm text-foreground font-semibold mb-1">
                  Error al cargar
                </p>
                <p className="text-xs text-muted-foreground mb-4">{error}</p>
                <button
                  onClick={fetchData}
                  className="px-4 py-2 rounded-lg bg-primary text-white text-sm font-semibold hover:bg-primary/90"
                >
                  Reintentar
                </button>
              </div>
            ) : filteredItems.length === 0 ? (
              <div className="p-10 text-center">
                <Inbox className="w-12 h-12 text-muted-foreground/50 mx-auto mb-3" />
                <p className="text-sm font-semibold text-foreground mb-1">
                  Sin resultados
                </p>
                <p className="text-xs text-muted-foreground mb-4">
                  Ajusta los filtros o intenta otro rango de fechas.
                </p>
                <button
                  onClick={() => {
                    setFromStr(toInputDate(defaultFrom));
                    setToStr(toInputDate(today));
                    setStatus('');
                    setSearch('');
                  }}
                  className="px-4 py-2 rounded-lg bg-primary/10 text-primary text-sm font-semibold hover:bg-primary/20"
                >
                  Reiniciar filtros
                </button>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-sm">
                  <thead>
                    <tr className="bg-muted/40 border-b border-border/60">
                      {activeTab.headers.map((h) => (
                        <th
                          key={h}
                          className="text-left px-4 py-3 font-semibold text-xs uppercase tracking-wider text-muted-foreground"
                        >
                          {h}
                        </th>
                      ))}
                    </tr>
                  </thead>
                  <motion.tbody
                    initial="hidden"
                    animate="show"
                    variants={{
                      hidden: { opacity: 0 },
                      show: {
                        opacity: 1,
                        transition: { staggerChildren: 0.015 },
                      },
                    }}
                  >
                    {filteredItems.map((item, idx) => {
                      const row = rows[idx];
                      const accent = getStatusColor(getRecordStatus(activeTabKey, item) || 'default');
                      return (
                        <motion.tr
                          key={s(pick(item, 'id', '_id')) || idx}
                          variants={{
                            hidden: { opacity: 0, y: 6 },
                            show: { opacity: 1, y: 0 },
                          }}
                          className="border-b border-border/30 hover:bg-muted/30 transition-colors group"
                          style={{
                            boxShadow: `inset 4px 0 0 0 ${accent}`,
                          }}
                        >
                          {row.map((cell, ci) => (
                            <td
                              key={ci}
                              className="px-4 py-3 text-foreground/90 align-middle"
                            >
                              {cell || (
                                <span className="text-muted-foreground/60">—</span>
                              )}
                            </td>
                          ))}
                        </motion.tr>
                      );
                    })}
                  </motion.tbody>
                </table>
              </div>
            )}
          </div>
        </motion.div>
      </AnimatePresence>

      {/* Import modal */}
      <AnimatePresence>
        {importOpen && activeTab.importDataset && (
          <ImportModal
            datasetKey={activeTab.importDataset}
            onClose={() => setImportOpen(false)}
            onDone={(summary) => {
              push(
                `Importacion: ${summary.inserted} insertados / ${summary.failed} fallos`,
                summary.failed > 0 ? 'error' : 'success'
              );
              fetchData();
            }}
          />
        )}
      </AnimatePresence>

      {/* Toast stack */}
      <div className="fixed bottom-6 right-6 flex flex-col gap-2 z-[60] pointer-events-none">
        <AnimatePresence>
          {toasts.map((t) => (
            <motion.div
              key={t.id}
              initial={{ opacity: 0, x: 30 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: 30 }}
              className={`pointer-events-auto inline-flex items-center gap-2 px-4 py-2.5 rounded-lg shadow-lg text-sm font-medium text-white ${
                t.variant === 'success'
                  ? 'bg-green-600'
                  : t.variant === 'error'
                  ? 'bg-red-600'
                  : 'bg-slate-800'
              }`}
            >
              {t.variant === 'success' ? (
                <CheckCircle2 className="w-4 h-4" />
              ) : t.variant === 'error' ? (
                <XCircle className="w-4 h-4" />
              ) : (
                <Clock className="w-4 h-4" />
              )}
              {t.message}
            </motion.div>
          ))}
        </AnimatePresence>
      </div>
    </div>
  );
}

// ---------------------------------------------------------------------------
// Import modal
// ---------------------------------------------------------------------------

interface ImportModalProps {
  datasetKey: ImportDatasetKey;
  onClose: () => void;
  onDone: (summary: ImportSummary) => void;
}

function ImportModal({ datasetKey, onClose, onDone }: ImportModalProps) {
  const dataset = IMPORT_DATASETS[datasetKey];
  const [parsing, setParsing] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [rows, setRows] = useState<Record<string, string>[] | null>(null);
  const [fileName, setFileName] = useState<string>('');
  const [summary, setSummary] = useState<ImportSummary | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFile = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const f = e.target.files?.[0];
    if (!f) return;
    setParsing(true);
    setSummary(null);
    try {
      const parsed = await parseCsv(f);
      setRows(parsed);
      setFileName(f.name);
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'Error al leer el archivo';
      setSummary({ inserted: 0, failed: 0, errors: [msg] });
    } finally {
      setParsing(false);
    }
  };

  const handleConfirm = async () => {
    if (!rows) return;
    setUploading(true);
    try {
      const result = await uploadRows(datasetKey, rows);
      setSummary(result);
      onDone(result);
    } finally {
      setUploading(false);
    }
  };

  const handleReset = () => {
    setRows(null);
    setFileName('');
    setSummary(null);
    if (fileInputRef.current) fileInputRef.current.value = '';
  };

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 bg-black/50 flex items-center justify-center p-4"
      onClick={onClose}
    >
      <motion.div
        initial={{ opacity: 0, y: 20, scale: 0.96 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        exit={{ opacity: 0, y: 20, scale: 0.96 }}
        className="bg-white rounded-2xl shadow-2xl max-w-xl w-full overflow-hidden"
        onClick={(e) => e.stopPropagation()}
      >
        <div
          className="px-6 py-4 text-white flex items-center justify-between"
          style={{ background: 'linear-gradient(135deg, #2E7D32, #4CAF50)' }}
        >
          <h2 className="text-lg font-bold">Importar {dataset.label}</h2>
          <button
            onClick={onClose}
            className="p-1 rounded-full hover:bg-white/20 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="p-6 space-y-4">
          <p className="text-sm text-muted-foreground">
            Sube un archivo CSV con los registros a importar. Descarga la plantilla
            para ver las columnas requeridas.
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <button
              onClick={() => downloadTemplate(datasetKey)}
              className="inline-flex flex-col items-center justify-center gap-2 px-4 py-5 rounded-xl border-2 border-dashed border-border hover:border-primary hover:bg-primary/5 transition-colors"
            >
              <FileDown className="w-7 h-7 text-primary" />
              <span className="text-sm font-semibold text-foreground">
                Descargar plantilla
              </span>
              <span className="text-[11px] text-muted-foreground">
                {dataset.filename}
              </span>
            </button>

            <button
              onClick={() => fileInputRef.current?.click()}
              disabled={parsing || uploading}
              className="inline-flex flex-col items-center justify-center gap-2 px-4 py-5 rounded-xl text-white shadow-md hover:shadow-lg transition-shadow disabled:opacity-60"
              style={{
                background: 'linear-gradient(135deg, #2E7D32, #4CAF50)',
              }}
            >
              <Upload className="w-7 h-7" />
              <span className="text-sm font-semibold">
                {parsing ? 'Leyendo...' : 'Subir archivo'}
              </span>
              <span className="text-[11px] opacity-80">CSV (.csv)</span>
            </button>

            <input
              ref={fileInputRef}
              type="file"
              accept=".csv,text/csv"
              onChange={handleFile}
              className="hidden"
            />
          </div>

          {rows && !summary && (
            <div className="rounded-xl bg-muted/30 border border-border/40 p-4">
              <p className="text-sm font-semibold text-foreground">
                {fileName}
              </p>
              <p className="text-xs text-muted-foreground mt-1">
                {rows.length} fila{rows.length === 1 ? '' : 's'} listas para importar
              </p>
              <div className="mt-3 flex gap-2">
                <button
                  onClick={handleConfirm}
                  disabled={uploading}
                  className="flex-1 inline-flex items-center justify-center gap-2 px-4 py-2 rounded-lg text-white text-sm font-semibold disabled:opacity-60"
                  style={{
                    background: 'linear-gradient(135deg, #2E7D32, #4CAF50)',
                  }}
                >
                  {uploading ? 'Importando...' : 'Confirmar importacion'}
                </button>
                <button
                  onClick={handleReset}
                  disabled={uploading}
                  className="px-4 py-2 rounded-lg bg-white border border-border text-sm font-semibold text-foreground hover:bg-muted/60 disabled:opacity-60"
                >
                  Cambiar archivo
                </button>
              </div>
            </div>
          )}

          {summary && (
            <div
              className={`rounded-xl p-4 border ${
                summary.failed > 0
                  ? 'bg-amber-50 border-amber-200'
                  : 'bg-green-50 border-green-200'
              }`}
            >
              <div className="flex items-center gap-2">
                {summary.failed > 0 ? (
                  <AlertTriangle className="w-5 h-5 text-amber-600" />
                ) : (
                  <CheckCircle2 className="w-5 h-5 text-green-600" />
                )}
                <p
                  className={`text-sm font-semibold ${
                    summary.failed > 0 ? 'text-amber-800' : 'text-green-800'
                  }`}
                >
                  {summary.inserted} insertados / {summary.failed} fallos
                </p>
              </div>
              {summary.errors.length > 0 && (
                <div className="mt-3 max-h-40 overflow-y-auto bg-white rounded-lg p-2 text-xs text-amber-700 space-y-1">
                  {summary.errors.map((err, i) => (
                    <p key={i} className="leading-snug">
                      • {err}
                    </p>
                  ))}
                </div>
              )}
              <div className="mt-3 flex justify-end gap-2">
                <button
                  onClick={handleReset}
                  className="px-4 py-2 rounded-lg bg-white border border-border text-sm font-semibold text-foreground hover:bg-muted/60"
                >
                  Importar otro
                </button>
                <button
                  onClick={onClose}
                  className="px-4 py-2 rounded-lg text-white text-sm font-semibold"
                  style={{
                    background: `linear-gradient(135deg, ${FROGIO_COLORS.primaryDark}, ${FROGIO_COLORS.primary})`,
                  }}
                >
                  Cerrar
                </button>
              </div>
            </div>
          )}
        </div>
      </motion.div>
    </motion.div>
  );
}
