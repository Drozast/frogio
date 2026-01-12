'use client';

import { GeofenceEvent } from '@/hooks/useFleetSocket';
import { ArrowRightOnRectangleIcon, ArrowLeftOnRectangleIcon } from '@heroicons/react/24/outline';

interface GeofenceAlertsProps {
  events: GeofenceEvent[];
}

export default function GeofenceAlerts({ events }: GeofenceAlertsProps) {
  if (events.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-6 text-gray-500">
        <p className="text-sm">Sin eventos de geofencing</p>
        <p className="text-xs text-gray-400 mt-1">
          Los eventos aparecerán cuando vehículos entren o salgan de zonas
        </p>
      </div>
    );
  }

  return (
    <div className="divide-y divide-gray-100 max-h-64 overflow-y-auto">
      {events.map((event) => (
        <div
          key={event.id}
          className={`p-3 ${
            event.eventType === 'enter' ? 'bg-green-50' : 'bg-red-50'
          }`}
        >
          <div className="flex items-start gap-3">
            <div className={`p-1.5 rounded-full ${
              event.eventType === 'enter' ? 'bg-green-100' : 'bg-red-100'
            }`}>
              {event.eventType === 'enter' ? (
                <ArrowRightOnRectangleIcon className="h-4 w-4 text-green-600" />
              ) : (
                <ArrowLeftOnRectangleIcon className="h-4 w-4 text-red-600" />
              )}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-900">
                {event.vehiclePlate} {event.eventType === 'enter' ? 'entró a' : 'salió de'} {event.geofenceName}
              </p>
              <p className="text-xs text-gray-500">
                {event.inspectorName}
              </p>
              <p className="text-xs text-gray-400 mt-1">
                {new Date(event.recordedAt).toLocaleString('es-CL', {
                  day: '2-digit',
                  month: 'short',
                  hour: '2-digit',
                  minute: '2-digit',
                })}
              </p>
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}
