'use client';

import { VehiclePosition } from '@/hooks/useFleetSocket';
import { TruckIcon, SignalIcon, SignalSlashIcon } from '@heroicons/react/24/outline';

interface VehicleListProps {
  vehicles: Map<string, VehiclePosition>;
  selectedVehicleId?: string | null;
  onVehicleSelect: (vehicleId: string) => void;
}

const statusLabels = {
  moving: 'En movimiento',
  slow: 'Movimiento lento',
  stopped: 'Detenido',
};

const statusColors = {
  moving: 'bg-green-100 text-green-800',
  slow: 'bg-yellow-100 text-yellow-800',
  stopped: 'bg-red-100 text-red-800',
};

export default function VehicleList({ vehicles, selectedVehicleId, onVehicleSelect }: VehicleListProps) {
  const vehicleArray = Array.from(vehicles.values());

  if (vehicleArray.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-8 text-gray-500">
        <TruckIcon className="h-12 w-12 mb-2 text-gray-300" />
        <p className="text-sm">No hay vehículos activos</p>
        <p className="text-xs text-gray-400 mt-1">
          Los vehículos aparecerán aquí cuando los inspectores inicien uso
        </p>
      </div>
    );
  }

  return (
    <div className="divide-y divide-gray-100">
      {vehicleArray.map((vehicle) => (
        <button
          key={vehicle.vehicleId}
          onClick={() => onVehicleSelect(vehicle.vehicleId)}
          className={`w-full p-3 text-left hover:bg-gray-50 transition-colors ${
            selectedVehicleId === vehicle.vehicleId ? 'bg-indigo-50 border-l-4 border-indigo-600' : ''
          }`}
        >
          <div className="flex items-start gap-3">
            <div className={`p-2 rounded-full ${
              vehicle.status === 'moving' ? 'bg-green-100' :
              vehicle.status === 'slow' ? 'bg-yellow-100' : 'bg-red-100'
            }`}>
              <TruckIcon className={`h-5 w-5 ${
                vehicle.status === 'moving' ? 'text-green-600' :
                vehicle.status === 'slow' ? 'text-yellow-600' : 'text-red-600'
              }`} />
            </div>
            <div className="flex-1 min-w-0">
              <div className="flex items-center justify-between">
                <p className="text-sm font-medium text-gray-900 uppercase">
                  {vehicle.vehiclePlate}
                </p>
                <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${statusColors[vehicle.status]}`}>
                  {statusLabels[vehicle.status]}
                </span>
              </div>
              <p className="text-xs text-gray-500 truncate">
                {vehicle.vehicleBrand} {vehicle.vehicleModel}
              </p>
              <p className="text-xs text-gray-600 mt-1">
                {vehicle.inspectorName}
              </p>
              <div className="flex items-center gap-3 mt-1 text-xs text-gray-400">
                <span>
                  {vehicle.speed ? `${Number(vehicle.speed).toFixed(0)} km/h` : '0 km/h'}
                </span>
                <span>
                  {new Date(vehicle.recordedAt).toLocaleTimeString('es-CL', {
                    hour: '2-digit',
                    minute: '2-digit',
                  })}
                </span>
              </div>
            </div>
          </div>
        </button>
      ))}
    </div>
  );
}
