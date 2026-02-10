'use client';

import { useState, useEffect, useCallback } from 'react';
import { TruckIcon, UserIcon, CheckCircleIcon, ClockIcon } from '@heroicons/react/24/outline';
import { VehiclePosition } from '@/hooks/useFleetSocket';

interface VehicleWithStatus {
  id: string;
  plate: string;
  brand: string | null;
  model: string | null;
  year: number | null;
  color: string | null;
  vehicleType: string | null;
  vehicleStatus: string;
  isActive: boolean;
  usageStatus: 'available' | 'in_use';
  currentDriverId?: string;
  currentDriverName?: string;
  usageStartTime?: string;
  usagePurpose?: string;
  vehicleLogId?: string;
}

interface AllVehiclesListProps {
  selectedVehicleId?: string | null;
  onVehicleSelect: (vehicleId: string) => void;
  liveVehicles: Map<string, VehiclePosition>;
}

export default function AllVehiclesList({
  selectedVehicleId,
  onVehicleSelect,
  liveVehicles,
}: AllVehiclesListProps) {
  const [vehicles, setVehicles] = useState<VehicleWithStatus[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchVehicles = useCallback(async () => {
    try {
      const response = await fetch('/api/vehicles/with-status');
      if (response.ok) {
        const data = await response.json();
        setVehicles(data);
        setError(null);
      } else {
        setError('Error al cargar vehículos');
      }
    } catch {
      setError('Error de conexión');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchVehicles();
    // Refresh every 30 seconds
    const interval = setInterval(fetchVehicles, 30000);
    return () => clearInterval(interval);
  }, [fetchVehicles]);

  if (loading) {
    return (
      <div className="flex items-center justify-center py-8">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="flex flex-col items-center justify-center py-8 text-gray-500">
        <TruckIcon className="h-12 w-12 mb-2 text-gray-300" />
        <p className="text-sm text-red-500">{error}</p>
        <button
          onClick={fetchVehicles}
          className="mt-2 text-xs text-indigo-600 hover:underline"
        >
          Reintentar
        </button>
      </div>
    );
  }

  if (vehicles.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-8 text-gray-500">
        <TruckIcon className="h-12 w-12 mb-2 text-gray-300" />
        <p className="text-sm">No hay vehículos registrados</p>
      </div>
    );
  }

  return (
    <div className="divide-y divide-gray-100">
      {vehicles.map((vehicle) => {
        const isInUse = vehicle.usageStatus === 'in_use';
        const liveData = liveVehicles.get(vehicle.id);
        const hasLiveGPS = !!liveData;

        return (
          <button
            key={vehicle.id}
            onClick={() => onVehicleSelect(vehicle.id)}
            className={`w-full p-3 text-left hover:bg-gray-50 transition-colors ${
              selectedVehicleId === vehicle.id
                ? 'bg-indigo-50 border-l-4 border-indigo-600'
                : ''
            }`}
          >
            <div className="flex items-start gap-3">
              <div
                className={`p-2 rounded-full ${
                  isInUse
                    ? hasLiveGPS
                      ? 'bg-green-100'
                      : 'bg-blue-100'
                    : 'bg-gray-100'
                }`}
              >
                <TruckIcon
                  className={`h-5 w-5 ${
                    isInUse
                      ? hasLiveGPS
                        ? 'text-green-600'
                        : 'text-blue-600'
                      : 'text-gray-400'
                  }`}
                />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between">
                  <p className="text-sm font-medium text-gray-900 uppercase">
                    {vehicle.plate}
                  </p>
                  {isInUse ? (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium bg-blue-100 text-blue-800">
                      <UserIcon className="h-3 w-3" />
                      En uso
                    </span>
                  ) : (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-xs font-medium bg-green-100 text-green-800">
                      <CheckCircleIcon className="h-3 w-3" />
                      Disponible
                    </span>
                  )}
                </div>
                <p className="text-xs text-gray-500 truncate">
                  {vehicle.brand} {vehicle.model}
                  {vehicle.year ? ` (${vehicle.year})` : ''}
                </p>
                {isInUse && vehicle.currentDriverName && (
                  <p className="text-xs text-blue-600 mt-1 flex items-center gap-1">
                    <UserIcon className="h-3 w-3" />
                    {vehicle.currentDriverName}
                  </p>
                )}
                {isInUse && vehicle.usageStartTime && (
                  <p className="text-xs text-gray-400 mt-0.5 flex items-center gap-1">
                    <ClockIcon className="h-3 w-3" />
                    Desde{' '}
                    {new Date(vehicle.usageStartTime).toLocaleTimeString('es-CL', {
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </p>
                )}
                {hasLiveGPS && liveData && (
                  <div className="flex items-center gap-2 mt-1 text-xs text-green-600">
                    <span className="flex items-center gap-1">
                      <span className="relative flex h-2 w-2">
                        <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-green-400 opacity-75"></span>
                        <span className="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
                      </span>
                      GPS activo
                    </span>
                    <span>
                      {liveData.speed ? `${Number(liveData.speed).toFixed(0)} km/h` : '0 km/h'}
                    </span>
                  </div>
                )}
              </div>
            </div>
          </button>
        );
      })}
    </div>
  );
}
