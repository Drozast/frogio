'use client';

import { useState, useEffect, useCallback } from 'react';
import {
  ClockIcon,
  UserIcon,
  TruckIcon,
  MapPinIcon,
  ArrowPathIcon,
  PlayIcon,
  StopIcon,
} from '@heroicons/react/24/outline';
import { format, formatDistanceToNow } from 'date-fns';
import { es } from 'date-fns/locale';

interface VehicleLog {
  id: string;
  vehicle_id: string;
  vehicle_plate: string;
  vehicle_brand: string;
  vehicle_model: string;
  driver_id: string;
  driver_name: string;
  usage_type: string;
  purpose: string | null;
  start_km: number;
  end_km: number | null;
  start_time: string;
  end_time: string | null;
  total_distance_km: number | null;
  observations: string | null;
  status: string;
}

const usageTypeLabels: Record<string, string> = {
  official: 'Servicio Oficial',
  emergency: 'Emergencia',
  maintenance: 'Mantención',
  transfer: 'Traslado',
  other: 'Otro',
};

const usageTypeColors: Record<string, string> = {
  official: 'bg-blue-100 text-blue-800',
  emergency: 'bg-red-100 text-red-800',
  maintenance: 'bg-orange-100 text-orange-800',
  transfer: 'bg-purple-100 text-purple-800',
  other: 'bg-gray-100 text-gray-800',
};

interface VehicleUsageHistoryProps {
  onViewRoute?: (vehicleId: string, date: string) => void;
}

export default function VehicleUsageHistory({ onViewRoute }: VehicleUsageHistoryProps) {
  const [logs, setLogs] = useState<VehicleLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchLogs = useCallback(async () => {
    try {
      setLoading(true);
      // Fetch recent logs (last 7 days)
      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - 7);

      const params = new URLSearchParams();
      params.append('startDate', startDate.toISOString().split('T')[0]);
      params.append('endDate', endDate.toISOString().split('T')[0]);

      const response = await fetch(`/api/vehicles/logs?${params.toString()}`);
      if (response.ok) {
        const data = await response.json();
        setLogs(data);
        setError(null);
      } else {
        setError('Error al cargar historial');
      }
    } catch {
      setError('Error de conexión');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchLogs();
    // Refresh every 30 seconds
    const interval = setInterval(fetchLogs, 30000);
    return () => clearInterval(interval);
  }, [fetchLogs]);

  if (loading && logs.length === 0) {
    return (
      <div className="flex items-center justify-center py-8">
        <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  if (error && logs.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-8 text-gray-500">
        <ClockIcon className="h-8 w-8 mb-2 text-gray-300" />
        <p className="text-sm text-red-500">{error}</p>
        <button
          onClick={fetchLogs}
          className="mt-2 text-xs text-indigo-600 hover:underline"
        >
          Reintentar
        </button>
      </div>
    );
  }

  if (logs.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-8 text-gray-500">
        <ClockIcon className="h-8 w-8 mb-2 text-gray-300" />
        <p className="text-sm">Sin registros recientes</p>
        <p className="text-xs text-gray-400 mt-1">Últimos 7 días</p>
      </div>
    );
  }

  // Separate active and completed logs
  const activeLogs = logs.filter((log) => log.status === 'active');
  const completedLogs = logs.filter((log) => log.status !== 'active');

  return (
    <div className="divide-y divide-gray-100">
      {/* Header with refresh */}
      <div className="p-3 flex items-center justify-between bg-gray-50">
        <h3 className="font-semibold text-gray-900 text-sm">Historial de Uso</h3>
        <button
          onClick={fetchLogs}
          className="p-1 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded"
          title="Actualizar"
        >
          <ArrowPathIcon className="h-4 w-4" />
        </button>
      </div>

      {/* Active Usage Section */}
      {activeLogs.length > 0 && (
        <div className="bg-green-50 p-2">
          <p className="text-xs font-medium text-green-700 mb-2 flex items-center gap-1">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
            </span>
            En uso ahora ({activeLogs.length})
          </p>
          {activeLogs.map((log) => (
            <div
              key={log.id}
              className="bg-white rounded-lg p-3 mb-2 last:mb-0 border border-green-200"
            >
              <div className="flex items-start gap-2">
                <div className="p-1.5 rounded-full bg-green-100">
                  <TruckIcon className="h-4 w-4 text-green-600" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <p className="text-sm font-medium text-gray-900 uppercase">
                      {log.vehicle_plate}
                    </p>
                    <span
                      className={`px-1.5 py-0.5 text-xs font-medium rounded ${
                        usageTypeColors[log.usage_type] || usageTypeColors.other
                      }`}
                    >
                      {usageTypeLabels[log.usage_type] || log.usage_type}
                    </span>
                  </div>
                  <p className="text-xs text-gray-500">
                    {log.vehicle_brand} {log.vehicle_model}
                  </p>
                  <div className="mt-1 flex items-center gap-1 text-xs text-green-700">
                    <UserIcon className="h-3 w-3" />
                    <span className="font-medium">{log.driver_name}</span>
                  </div>
                  <div className="mt-1 flex items-center gap-1 text-xs text-gray-500">
                    <PlayIcon className="h-3 w-3" />
                    <span>
                      Inició{' '}
                      {formatDistanceToNow(new Date(log.start_time), {
                        addSuffix: true,
                        locale: es,
                      })}
                    </span>
                  </div>
                  <div className="mt-1 flex items-center gap-1 text-xs text-gray-500">
                    <MapPinIcon className="h-3 w-3" />
                    <span>Km inicial: {log.start_km}</span>
                  </div>
                  {log.purpose && (
                    <p className="mt-1 text-xs text-gray-600 italic">
                      &quot;{log.purpose}&quot;
                    </p>
                  )}
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Completed Logs */}
      <div className="max-h-96 overflow-y-auto">
        {completedLogs.slice(0, 20).map((log) => (
          <div
            key={log.id}
            className="p-3 hover:bg-gray-50 cursor-pointer transition-colors"
            onClick={() => {
              if (onViewRoute) {
                const date = log.start_time.split('T')[0];
                onViewRoute(log.vehicle_id, date);
              }
            }}
          >
            <div className="flex items-start gap-2">
              <div className="p-1.5 rounded-full bg-gray-100">
                <TruckIcon className="h-4 w-4 text-gray-500" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between">
                  <p className="text-sm font-medium text-gray-900 uppercase">
                    {log.vehicle_plate}
                  </p>
                  <span
                    className={`px-1.5 py-0.5 text-xs font-medium rounded ${
                      usageTypeColors[log.usage_type] || usageTypeColors.other
                    }`}
                  >
                    {usageTypeLabels[log.usage_type] || log.usage_type}
                  </span>
                </div>
                <div className="mt-1 flex items-center gap-1 text-xs text-gray-600">
                  <UserIcon className="h-3 w-3" />
                  <span>{log.driver_name}</span>
                </div>
                <div className="mt-1 flex items-center justify-between text-xs text-gray-500">
                  <span className="flex items-center gap-1">
                    <ClockIcon className="h-3 w-3" />
                    {format(new Date(log.start_time), 'dd/MM HH:mm', { locale: es })}
                    {log.end_time && (
                      <>
                        {' → '}
                        {format(new Date(log.end_time), 'HH:mm', { locale: es })}
                      </>
                    )}
                  </span>
                  {log.total_distance_km && (
                    <span className="text-green-600 font-medium">
                      +{log.total_distance_km.toFixed(1)} km
                    </span>
                  )}
                </div>
                {log.status === 'completed' && (
                  <div className="mt-1 flex items-center gap-1 text-xs text-gray-400">
                    <StopIcon className="h-3 w-3" />
                    <span>
                      Km: {log.start_km} → {log.end_km}
                    </span>
                  </div>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>

      {completedLogs.length > 20 && (
        <div className="p-2 text-center">
          <p className="text-xs text-gray-500">
            Mostrando 20 de {completedLogs.length} registros
          </p>
        </div>
      )}
    </div>
  );
}
