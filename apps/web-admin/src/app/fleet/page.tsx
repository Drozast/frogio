'use client';

/**
 * Flota Vehicular (Admin) — mirrors
 * apps/mobile/lib/features/admin/presentation/pages/admin_fleet_screen.dart
 *
 * Two pill-tabs: Vehiculos / Bitacoras.
 */

import { useCallback, useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Car,
  Route,
  Plus,
  RefreshCw,
  X,
  Pencil,
  Trash2,
  Play,
  CheckCircle2,
  Filter,
  FileSpreadsheet,
  PlayCircle,
  Clock,
  User as UserIcon,
  MapPin,
  Gauge,
} from 'lucide-react';

import AppLayout from '@/components/layout/AppLayout';
import {
  getVehicles,
  getVehicleLogs,
  createVehicle,
  updateVehicle,
  deleteVehicle,
  pick,
  type AdminRecord,
} from '@/lib/admin-api';
import { exportCSV } from '@/lib/export-service';
import { FROGIO_COLORS, FROGIO_GRADIENTS } from '@/lib/theme';

type VehicleStatus = 'in_use' | 'available' | 'out_of_service';

function deriveVehicleStatus(v: AdminRecord): VehicleStatus {
  const explicit = (v.status ?? '').toString();
  if (explicit) {
    if (
      explicit === 'in_use' ||
      explicit === 'available' ||
      explicit === 'out_of_service'
    ) {
      return explicit;
    }
  }
  if (v.active_log_id != null) return 'in_use';
  if (v.is_active === true) return 'available';
  return 'out_of_service';
}

const STATUS_LABEL: Record<VehicleStatus, string> = {
  in_use: 'En ruta',
  available: 'Disponible',
  out_of_service: 'Fuera de servicio',
};

const STATUS_COLOR: Record<VehicleStatus, string> = {
  in_use: FROGIO_COLORS.success,
  available: FROGIO_COLORS.info,
  out_of_service: FROGIO_COLORS.textTertiary,
};

function fmtDate(s?: string | null): string {
  if (!s) return '—';
  try {
    return new Date(s).toLocaleString('es-CL');
  } catch {
    return '—';
  }
}

function fmtTime(s?: string | null): string {
  if (!s) return '—';
  try {
    return new Date(s).toLocaleTimeString('es-CL', {
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return '—';
  }
}

export default function FleetPage() {
  const [tab, setTab] = useState<'vehicles' | 'logs'>('vehicles');

  // Vehicles
  const [vehicles, setVehicles] = useState<AdminRecord[]>([]);
  const [vehLoading, setVehLoading] = useState(false);
  const [editing, setEditing] = useState<AdminRecord | null>(null);
  const [creating, setCreating] = useState(false);
  const [deleting, setDeleting] = useState<AdminRecord | null>(null);

  // Logs
  const [logs, setLogs] = useState<AdminRecord[]>([]);
  const [logsLoading, setLogsLoading] = useState(false);
  const [logsFilter, setLogsFilter] = useState<'all' | 'active' | 'completed'>(
    'all'
  );

  const loadVehicles = useCallback(async () => {
    setVehLoading(true);
    try {
      const data = await getVehicles();
      setVehicles(data);
    } finally {
      setVehLoading(false);
    }
  }, []);

  const loadLogs = useCallback(async () => {
    setLogsLoading(true);
    try {
      const data = await getVehicleLogs();
      setLogs(data);
    } finally {
      setLogsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadVehicles();
    loadLogs();
  }, [loadVehicles, loadLogs]);

  const filteredLogs = useMemo(() => {
    if (logsFilter === 'all') return logs;
    return logs.filter((l) => {
      const status = (l.status ?? '').toString().toLowerCase();
      if (logsFilter === 'active') {
        return status === 'active' || l.end_time == null;
      }
      return status === 'completed' || l.end_time != null;
    });
  }, [logs, logsFilter]);

  const counts = useMemo(
    () => ({
      all: logs.length,
      active: logs.filter(
        (l) =>
          (l.status ?? '').toString().toLowerCase() === 'active' ||
          l.end_time == null
      ).length,
      completed: logs.filter(
        (l) =>
          (l.status ?? '').toString().toLowerCase() === 'completed' ||
          l.end_time != null
      ).length,
    }),
    [logs]
  );

  function exportLogsCsv() {
    const rows = filteredLogs.map((l) => [
      String(pick(l, 'plate', 'vehicle_plate', 'vehiclePlate') ?? '').toUpperCase(),
      String(pick(l, 'driver_name', 'driverName') ?? ''),
      fmtDate(pick<string>(l, 'start_time', 'startTime')),
      fmtDate(pick<string>(l, 'end_time', 'endTime')),
      pick<number>(l, 'start_km', 'startKm') ?? '',
      pick<number>(l, 'end_km', 'endKm') ?? '',
      pick<number>(l, 'total_distance_km', 'totalDistanceKm') ?? '',
      String(pick(l, 'status') ?? ''),
    ]);
    exportCSV({
      filenamePrefix: 'bitacoras_flota',
      headers: [
        'Patente',
        'Conductor',
        'Inicio',
        'Fin',
        'Km inicial',
        'Km final',
        'Distancia (km)',
        'Estado',
      ],
      rows,
    });
  }

  return (
    <AppLayout>
      <div className="space-y-4">
        {/* Section header */}
        <div className="flex items-center gap-3 px-1">
          <div
            className="w-1 h-9 rounded"
            style={{
              background: `linear-gradient(180deg, ${FROGIO_COLORS.primaryDark} 0%, ${FROGIO_COLORS.primary} 100%)`,
            }}
          />
          <div className="flex-1">
            <h1 className="text-xl font-bold text-foreground">
              Flota Vehicular
            </h1>
            <p className="text-xs text-muted-foreground">
              {tab === 'vehicles'
                ? `${vehicles.length} vehículos en el sistema`
                : `${filteredLogs.length} bitácoras registradas`}
            </p>
          </div>
          {tab === 'logs' && (
            <button
              onClick={exportLogsCsv}
              className="inline-flex items-center gap-2 px-3 py-2 text-sm rounded-lg border border-border hover:bg-muted"
              title="Exportar CSV"
            >
              <FileSpreadsheet className="h-4 w-4" />
              CSV
            </button>
          )}
          <button
            onClick={tab === 'vehicles' ? loadVehicles : loadLogs}
            className="p-2 rounded-lg border border-border hover:bg-muted"
            title="Recargar"
          >
            <RefreshCw
              className={`h-4 w-4 ${
                (tab === 'vehicles' && vehLoading) ||
                (tab === 'logs' && logsLoading)
                  ? 'animate-spin'
                  : ''
              }`}
            />
          </button>
          {tab === 'vehicles' && (
            <button
              onClick={() => setCreating(true)}
              className="inline-flex items-center gap-2 px-3 py-2 text-sm font-semibold rounded-lg text-white shadow-sm"
              style={{ background: FROGIO_COLORS.primary }}
            >
              <Plus className="h-4 w-4" />
              Nuevo vehículo
            </button>
          )}
        </div>

        {/* Pill tabs */}
        <div className="px-1">
          <div className="inline-flex p-1 rounded-full bg-white border border-border">
            <PillTab
              active={tab === 'vehicles'}
              onClick={() => setTab('vehicles')}
              icon={<Car className="h-4 w-4" />}
              label="Vehículos"
            />
            <PillTab
              active={tab === 'logs'}
              onClick={() => setTab('logs')}
              icon={<Route className="h-4 w-4" />}
              label="Bitácoras"
            />
          </div>
        </div>

        {/* Content */}
        <div className="px-1">
          {tab === 'vehicles' ? (
            <VehiclesGrid
              vehicles={vehicles}
              loading={vehLoading}
              onEdit={(v) => setEditing(v)}
              onDelete={(v) => setDeleting(v)}
            />
          ) : (
            <LogsList
              logs={filteredLogs}
              loading={logsLoading}
              filter={logsFilter}
              onFilterChange={setLogsFilter}
              counts={counts}
            />
          )}
        </div>
      </div>

      {/* Create / Edit modal */}
      <AnimatePresence>
        {(creating || editing) && (
          <VehicleFormModal
            initial={editing ?? null}
            onClose={() => {
              setCreating(false);
              setEditing(null);
            }}
            onSaved={async () => {
              setCreating(false);
              setEditing(null);
              await loadVehicles();
            }}
          />
        )}
      </AnimatePresence>

      {/* Delete confirm */}
      <AnimatePresence>
        {deleting && (
          <motion.div
            className="fixed inset-0 z-[1100] flex items-center justify-center bg-black/40 p-4"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setDeleting(null)}
          >
            <motion.div
              className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-6"
              initial={{ scale: 0.9, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              exit={{ scale: 0.9, opacity: 0 }}
              onClick={(e) => e.stopPropagation()}
            >
              <h3 className="text-lg font-bold text-foreground mb-2">
                Eliminar vehículo
              </h3>
              <p className="text-sm text-muted-foreground mb-5">
                ¿Confirmas eliminar el vehículo{' '}
                <strong className="text-foreground">
                  {String(deleting.plate ?? '').toUpperCase()}
                </strong>
                ? Esta acción no se puede deshacer.
              </p>
              <div className="flex gap-3 justify-end">
                <button
                  onClick={() => setDeleting(null)}
                  className="px-4 py-2 rounded-lg border border-border text-sm font-semibold"
                >
                  Cancelar
                </button>
                <button
                  onClick={async () => {
                    const id = String(deleting.id ?? '');
                    if (!id) return;
                    try {
                      await deleteVehicle(id);
                      setDeleting(null);
                      await loadVehicles();
                    } catch (e) {
                      alert(`Error al eliminar: ${(e as Error).message}`);
                    }
                  }}
                  className="px-4 py-2 rounded-lg text-white text-sm font-semibold"
                  style={{ background: FROGIO_COLORS.emergency }}
                >
                  Eliminar
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>
    </AppLayout>
  );
}

// ---------------------------------------------------------------------------
// PillTab
// ---------------------------------------------------------------------------

function PillTab({
  active,
  onClick,
  icon,
  label,
}: {
  active: boolean;
  onClick: () => void;
  icon: React.ReactNode;
  label: string;
}) {
  return (
    <button
      onClick={onClick}
      className="relative inline-flex items-center gap-2 px-5 py-2 rounded-full text-sm font-bold transition-all"
      style={{
        background: active ? FROGIO_GRADIENTS.primary : 'transparent',
        color: active ? '#fff' : FROGIO_COLORS.textSecondary,
        boxShadow: active
          ? `0 4px 10px ${FROGIO_COLORS.primary}55`
          : 'none',
      }}
    >
      {icon}
      {label}
    </button>
  );
}

// ---------------------------------------------------------------------------
// Vehicles
// ---------------------------------------------------------------------------

function VehiclesGrid({
  vehicles,
  loading,
  onEdit,
  onDelete,
}: {
  vehicles: AdminRecord[];
  loading: boolean;
  onEdit: (v: AdminRecord) => void;
  onDelete: (v: AdminRecord) => void;
}) {
  if (loading && vehicles.length === 0) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {Array.from({ length: 6 }).map((_, i) => (
          <div
            key={i}
            className="h-36 rounded-2xl bg-gradient-to-br from-muted to-muted/40 animate-pulse"
          />
        ))}
      </div>
    );
  }
  if (vehicles.length === 0) {
    return (
      <div className="bg-white rounded-2xl border border-border p-10 text-center">
        <Car className="h-12 w-12 mx-auto text-muted-foreground mb-3" />
        <h3 className="text-lg font-semibold text-foreground">Sin vehículos</h3>
        <p className="text-sm text-muted-foreground mt-1">
          Aún no se han registrado vehículos.
        </p>
      </div>
    );
  }
  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
      {vehicles.map((v, i) => (
        <VehicleCard
          key={String(v.id ?? i)}
          v={v}
          onEdit={() => onEdit(v)}
          onDelete={() => onDelete(v)}
        />
      ))}
    </div>
  );
}

function VehicleCard({
  v,
  onEdit,
  onDelete,
}: {
  v: AdminRecord;
  onEdit: () => void;
  onDelete: () => void;
}) {
  const status = deriveVehicleStatus(v);
  const color = STATUS_COLOR[status];
  const plate = String(v.plate ?? '').toUpperCase();
  const brand = String(v.brand ?? '');
  const model = String(v.model ?? '');
  const year = v.year ?? '';
  const km = pick<number | string>(v, 'currentKm', 'current_km');
  const driver = String(pick(v, 'active_driver_name', 'driverName') ?? '');
  const isActive = v.active_log_id != null;

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.3 }}
      className="relative bg-white rounded-2xl border overflow-hidden cursor-pointer hover:shadow-md transition-shadow"
      style={{
        borderColor: isActive
          ? `${FROGIO_COLORS.primary}55`
          : FROGIO_COLORS.border,
        boxShadow: isActive
          ? `0 8px 18px ${FROGIO_COLORS.primary}25`
          : undefined,
      }}
      onClick={onEdit}
    >
      <div
        className="absolute left-0 top-0 bottom-0 w-1"
        style={{ background: color }}
      />
      <div className="p-4 pl-5">
        <div className="flex items-start gap-3">
          <div
            className="w-12 h-12 rounded-xl flex items-center justify-center"
            style={{
              background: `${color}1F`,
              border: `1px solid ${color}33`,
            }}
          >
            <Car className="h-6 w-6" style={{ color }} />
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2">
              <h3 className="text-base font-extrabold text-foreground truncate tracking-wider">
                {plate || '(Sin patente)'}
              </h3>
              <span
                className="ml-auto inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-extrabold"
                style={{
                  background: `${color}1F`,
                  color,
                  border: `1px solid ${color}55`,
                }}
              >
                <span
                  className="w-1.5 h-1.5 rounded-full"
                  style={{ background: color }}
                />
                {STATUS_LABEL[status]}
              </span>
            </div>
            <p className="text-xs text-muted-foreground mt-1 truncate">
              {[brand, model, year].filter(Boolean).join(' ')}
            </p>
            <div className="flex flex-wrap gap-1.5 mt-2">
              {km != null && km !== '' && (
                <Chip icon={<Gauge className="h-3 w-3" />} text={`${km} km`} />
              )}
              {driver && (
                <Chip
                  icon={<UserIcon className="h-3 w-3" />}
                  text={driver}
                  color={FROGIO_COLORS.primary}
                />
              )}
              {isActive && (
                <Chip
                  icon={<PlayCircle className="h-3 w-3" />}
                  text="En ruta"
                  color={FROGIO_COLORS.success}
                />
              )}
            </div>
          </div>
          <button
            onClick={(e) => {
              e.stopPropagation();
              onDelete();
            }}
            className="text-muted-foreground hover:text-red-600 p-1"
            title="Eliminar"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        </div>
        <div className="flex justify-end mt-3">
          <button
            onClick={(e) => {
              e.stopPropagation();
              onEdit();
            }}
            className="inline-flex items-center gap-1.5 text-xs font-semibold text-primary"
          >
            <Pencil className="h-3.5 w-3.5" />
            Editar
          </button>
        </div>
      </div>
    </motion.div>
  );
}

function Chip({
  icon,
  text,
  color,
}: {
  icon: React.ReactNode;
  text: string;
  color?: string;
}) {
  const c = color ?? FROGIO_COLORS.textSecondary;
  return (
    <span
      className="inline-flex items-center gap-1 text-[11px] font-bold px-2 py-0.5 rounded-md"
      style={{ background: `${c}14`, color: c, border: `1px solid ${c}25` }}
    >
      {icon}
      {text}
    </span>
  );
}

// ---------------------------------------------------------------------------
// Vehicle form modal (create or edit)
// ---------------------------------------------------------------------------

function VehicleFormModal({
  initial,
  onClose,
  onSaved,
}: {
  initial: AdminRecord | null;
  onClose: () => void;
  onSaved: () => void | Promise<void>;
}) {
  const isEdit = initial != null;
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  return (
    <motion.div
      className="fixed inset-0 z-[1100] flex items-center justify-center bg-black/40 p-4"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      onClick={onClose}
    >
      <motion.div
        className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto"
        initial={{ scale: 0.92, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.92, opacity: 0 }}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between p-5 border-b border-border">
          <h2 className="text-lg font-bold text-foreground">
            {isEdit
              ? `Editar vehículo: ${String(initial?.plate ?? '').toUpperCase()}`
              : 'Nuevo vehículo'}
          </h2>
          <button
            onClick={onClose}
            className="text-muted-foreground hover:text-foreground"
          >
            <X className="h-5 w-5" />
          </button>
        </div>
        <form
          className="p-5 space-y-4"
          onSubmit={async (e) => {
            e.preventDefault();
            setSaving(true);
            setError(null);
            const fd = new FormData(e.currentTarget);
            const yearRaw = (fd.get('year') as string) || '';
            const body = {
              plate: ((fd.get('plate') as string) || '').toUpperCase(),
              brand: (fd.get('brand') as string) || '',
              model: (fd.get('model') as string) || '',
              year: yearRaw ? parseInt(yearRaw, 10) : null,
              type: (fd.get('type') as string) || null,
              color: (fd.get('color') as string) || null,
              status: (fd.get('status') as string) || null,
              is_active: fd.get('status') !== 'out_of_service',
            };
            try {
              if (isEdit && initial?.id) {
                await updateVehicle(String(initial.id), body);
              } else {
                await createVehicle(body);
              }
              await onSaved();
            } catch (err) {
              setError((err as Error).message);
            } finally {
              setSaving(false);
            }
          }}
        >
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Field
              label="Patente"
              name="plate"
              defaultValue={String(initial?.plate ?? '')}
              required
            />
            <Field
              label="Marca"
              name="brand"
              defaultValue={String(initial?.brand ?? '')}
            />
            <Field
              label="Modelo"
              name="model"
              defaultValue={String(initial?.model ?? '')}
            />
            <Field
              label="Año"
              name="year"
              type="number"
              defaultValue={String(initial?.year ?? '')}
            />
            <SelectField
              label="Tipo"
              name="type"
              defaultValue={String(initial?.type ?? '')}
              options={[
                { value: '', label: 'Seleccionar...' },
                { value: 'auto', label: 'Auto' },
                { value: 'camioneta', label: 'Camioneta' },
                { value: 'camion', label: 'Camión' },
                { value: 'moto', label: 'Moto' },
                { value: 'bus', label: 'Bus' },
                { value: 'otro', label: 'Otro' },
              ]}
            />
            <Field
              label="Color"
              name="color"
              defaultValue={String(initial?.color ?? '')}
            />
            <SelectField
              label="Estado"
              name="status"
              defaultValue={
                initial ? deriveVehicleStatus(initial) : 'available'
              }
              options={[
                { value: 'available', label: 'Disponible' },
                { value: 'in_use', label: 'En ruta' },
                { value: 'out_of_service', label: 'Fuera de servicio' },
              ]}
            />
          </div>
          {error && (
            <p className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg p-3">
              {error}
            </p>
          )}
          <div className="flex gap-3 justify-end pt-2 border-t border-border">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 rounded-lg border border-border text-sm font-semibold"
            >
              Cancelar
            </button>
            <button
              type="submit"
              disabled={saving}
              className="px-5 py-2 rounded-lg text-white text-sm font-semibold disabled:opacity-60"
              style={{ background: FROGIO_COLORS.primary }}
            >
              {saving ? 'Guardando...' : 'Guardar'}
            </button>
          </div>
        </form>
      </motion.div>
    </motion.div>
  );
}

function Field({
  label,
  name,
  type = 'text',
  defaultValue,
  required = false,
}: {
  label: string;
  name: string;
  type?: string;
  defaultValue?: string;
  required?: boolean;
}) {
  return (
    <label className="block">
      <span className="text-xs font-semibold text-muted-foreground">
        {label}
      </span>
      <input
        name={name}
        type={type}
        defaultValue={defaultValue}
        required={required}
        className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none"
      />
    </label>
  );
}

function SelectField({
  label,
  name,
  defaultValue,
  options,
}: {
  label: string;
  name: string;
  defaultValue?: string;
  options: { value: string; label: string }[];
}) {
  return (
    <label className="block">
      <span className="text-xs font-semibold text-muted-foreground">
        {label}
      </span>
      <select
        name={name}
        defaultValue={defaultValue}
        className="mt-1 w-full rounded-lg border border-border px-3 py-2 text-sm focus:ring-2 focus:ring-primary/50 focus:border-primary outline-none bg-white"
      >
        {options.map((o) => (
          <option key={o.value} value={o.value}>
            {o.label}
          </option>
        ))}
      </select>
    </label>
  );
}

// ---------------------------------------------------------------------------
// Logs
// ---------------------------------------------------------------------------

function LogsList({
  logs,
  loading,
  filter,
  onFilterChange,
  counts,
}: {
  logs: AdminRecord[];
  loading: boolean;
  filter: 'all' | 'active' | 'completed';
  onFilterChange: (f: 'all' | 'active' | 'completed') => void;
  counts: { all: number; active: number; completed: number };
}) {
  return (
    <div className="space-y-4">
      {/* Filter pills */}
      <div className="flex items-center gap-2 flex-wrap">
        <FilterPill
          icon={<Filter className="h-3.5 w-3.5" />}
          label="Todos"
          active={filter === 'all'}
          color={FROGIO_COLORS.textSecondary}
          count={counts.all}
          onClick={() => onFilterChange('all')}
        />
        <FilterPill
          icon={<Play className="h-3.5 w-3.5" />}
          label="Activos"
          active={filter === 'active'}
          color={FROGIO_COLORS.success}
          count={counts.active}
          onClick={() => onFilterChange('active')}
        />
        <FilterPill
          icon={<CheckCircle2 className="h-3.5 w-3.5" />}
          label="Completados"
          active={filter === 'completed'}
          color={FROGIO_COLORS.info}
          count={counts.completed}
          onClick={() => onFilterChange('completed')}
        />
      </div>

      {/* List */}
      {loading && logs.length === 0 ? (
        <div className="space-y-3">
          {Array.from({ length: 4 }).map((_, i) => (
            <div
              key={i}
              className="h-24 rounded-2xl bg-gradient-to-br from-muted to-muted/40 animate-pulse"
            />
          ))}
        </div>
      ) : logs.length === 0 ? (
        <div className="bg-white rounded-2xl border border-border p-10 text-center">
          <Route className="h-12 w-12 mx-auto text-muted-foreground mb-3" />
          <h3 className="text-lg font-semibold text-foreground">Sin bitácoras</h3>
          <p className="text-sm text-muted-foreground mt-1">
            No hay registros con este filtro.
          </p>
        </div>
      ) : (
        <div className="space-y-3">
          {logs.map((l, i) => (
            <LogCard key={String(l.id ?? i)} log={l} />
          ))}
        </div>
      )}
    </div>
  );
}

function FilterPill({
  icon,
  label,
  active,
  color,
  count,
  onClick,
}: {
  icon: React.ReactNode;
  label: string;
  active: boolean;
  color: string;
  count: number;
  onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full border transition-all whitespace-nowrap"
      style={{
        background: active ? `${color}1F` : '#fff',
        borderColor: active ? `${color}66` : FROGIO_COLORS.border,
        borderWidth: active ? 1.5 : 1,
        color: active ? color : FROGIO_COLORS.textSecondary,
      }}
    >
      {icon}
      <span className="text-xs font-bold">{label}</span>
      <span
        className="text-[10px] font-extrabold px-1.5 rounded-full text-white"
        style={{ background: active ? color : '#9CA3AF', minWidth: 18 }}
      >
        {count}
      </span>
    </button>
  );
}

function LogCard({ log }: { log: AdminRecord }) {
  const plate = String(
    pick(log, 'plate', 'vehicle_plate', 'vehiclePlate') ?? ''
  ).toUpperCase();
  const driver = String(pick(log, 'driver_name', 'driverName') ?? '');
  const start = pick<string>(log, 'start_time', 'startTime');
  const end = pick<string>(log, 'end_time', 'endTime');
  const startKm = pick<number>(log, 'start_km', 'startKm');
  const endKm = pick<number>(log, 'end_km', 'endKm');
  const distance = pick<number>(log, 'total_distance_km', 'totalDistanceKm');
  const status = String(log.status ?? '').toLowerCase();
  const isActive = status === 'active' || end == null;
  const id = String(log.id ?? '');

  return (
    <Link
      href={`/fleet/playback/${id}`}
      className="block bg-white rounded-2xl border border-border p-4 hover:shadow-md transition-shadow"
    >
      <div className="flex items-start gap-3">
        <span
          className="inline-flex items-center px-2 py-1 rounded-md font-extrabold text-xs tracking-wider"
          style={{
            background: `${FROGIO_COLORS.primary}1F`,
            color: FROGIO_COLORS.primaryDark,
          }}
        >
          {plate || 'SIN PLACA'}
        </span>
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2">
            <UserIcon className="h-3.5 w-3.5 text-muted-foreground" />
            <span className="text-sm font-semibold text-foreground truncate">
              {driver || '—'}
            </span>
            <span
              className="ml-auto text-[10px] px-2 py-0.5 rounded-full font-bold"
              style={{
                background: isActive
                  ? `${FROGIO_COLORS.success}1F`
                  : `${FROGIO_COLORS.info}1F`,
                color: isActive ? FROGIO_COLORS.success : FROGIO_COLORS.info,
              }}
            >
              {isActive ? 'ACTIVO' : 'COMPLETADO'}
            </span>
          </div>
          <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs text-muted-foreground mt-2">
            <div className="inline-flex items-center gap-1">
              <Clock className="h-3 w-3" />
              {fmtTime(start)} → {fmtTime(end)}
            </div>
            <div className="inline-flex items-center gap-1">
              <MapPin className="h-3 w-3" />
              {distance != null ? `${Number(distance).toFixed(1)} km` : '—'}
            </div>
            <div>
              <span className="font-semibold text-foreground">
                {startKm ?? '—'}
              </span>
              <span className="mx-1">→</span>
              <span className="font-semibold text-foreground">
                {endKm ?? '—'}
              </span>{' '}
              km
            </div>
          </div>
        </div>
      </div>
    </Link>
  );
}
