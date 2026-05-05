'use client';

import Link from 'next/link';
import {
  XMarkIcon,
  MapPinIcon,
  ExclamationTriangleIcon,
} from '@heroicons/react/24/outline';

interface PanicAlert {
  id: string;
  userId: string;
  userName?: string;
  first_name?: string;
  last_name?: string;
  latitude: number;
  longitude: number;
  address?: string;
  message?: string;
  contactPhone?: string;
  phone?: string;
  createdAt?: string;
  created_at?: string;
}

interface SOSAlertToastProps {
  alert: PanicAlert;
  onDismiss: () => void;
}

export default function SOSAlertToast({ alert, onDismiss }: SOSAlertToastProps) {
  const userName =
    alert.userName ||
    `${alert.first_name || ''} ${alert.last_name || ''}`.trim() ||
    'Ciudadano';
  const createdAt = alert.createdAt || alert.created_at;

  return (
    <div className="pointer-events-auto bg-white border-l-4 border-red-600 rounded-lg shadow-2xl overflow-hidden animate-slide-in">
      <div className="flex items-start gap-3 p-4">
        <div className="p-2 bg-red-100 rounded-full animate-pulse shrink-0">
          <ExclamationTriangleIcon className="h-5 w-5 text-red-600" />
        </div>
        <div className="flex-1 min-w-0">
          <p className="font-semibold text-red-700 text-sm">
            🚨 Alerta SOS — {userName}
          </p>
          <p className="text-gray-600 text-xs mt-0.5 truncate">
            {alert.address || `${alert.latitude.toFixed(5)}, ${alert.longitude.toFixed(5)}`}
          </p>
          {createdAt && (
            <p className="text-gray-400 text-xs mt-0.5">
              {new Date(createdAt).toLocaleTimeString('es-CL')}
            </p>
          )}
          <div className="flex items-center gap-3 mt-2">
            <Link
              href="/live-map"
              className="inline-flex items-center gap-1 text-xs font-medium text-red-600 hover:text-red-700"
            >
              <MapPinIcon className="h-3.5 w-3.5" />
              Ver en mapa
            </Link>
            <button
              onClick={onDismiss}
              className="text-xs text-gray-500 hover:text-gray-700"
            >
              Descartar
            </button>
          </div>
        </div>
        <button
          onClick={onDismiss}
          className="p-1 text-gray-400 hover:text-gray-600 shrink-0"
          aria-label="Cerrar"
        >
          <XMarkIcon className="h-4 w-4" />
        </button>
      </div>
      <style jsx>{`
        @keyframes slide-in {
          0% {
            transform: translateX(100%);
            opacity: 0;
          }
          100% {
            transform: translateX(0);
            opacity: 1;
          }
        }
        .animate-slide-in {
          animation: slide-in 0.3s ease-out;
        }
      `}</style>
    </div>
  );
}
