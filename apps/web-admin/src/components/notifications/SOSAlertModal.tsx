'use client';

import { useState } from 'react';
import Link from 'next/link';
import {
  XMarkIcon,
  MapPinIcon,
  PhoneIcon,
  UserIcon,
  ClockIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon,
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

interface SOSAlertModalProps {
  alert: PanicAlert;
  onClose: () => void;
}

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

export default function SOSAlertModal({ alert, onClose }: SOSAlertModalProps) {
  const [isResponding, setIsResponding] = useState(false);
  const [responded, setResponded] = useState(false);

  const userName = alert.userName || `${alert.first_name || ''} ${alert.last_name || ''}`.trim() || 'Usuario';
  const phone = alert.contactPhone || alert.phone;
  const createdAt = alert.createdAt || alert.created_at;

  const handleRespond = async () => {
    setIsResponding(true);
    try {
      const token = document.cookie
        .split('; ')
        .find(row => row.startsWith('accessToken='))
        ?.split('=')[1];

      const response = await fetch(`${API_URL}/api/panic/${alert.id}/respond`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Tenant-ID': 'santa_juana',
        },
      });

      if (response.ok) {
        setResponded(true);
        setTimeout(onClose, 2000);
      }
    } catch (error) {
      console.error('Error responding to alert:', error);
    } finally {
      setIsResponding(false);
    }
  };

  const openInMaps = () => {
    window.open(`https://maps.google.com/?q=${alert.latitude},${alert.longitude}`, '_blank');
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto">
      {/* Backdrop with pulsing animation */}
      <div className="fixed inset-0 bg-red-900/80 animate-pulse" />

      <div className="flex min-h-full items-center justify-center p-4">
        <div className="relative bg-white rounded-2xl shadow-2xl max-w-lg w-full overflow-hidden animate-bounce-in">
          {/* Red alert header */}
          <div className="bg-gradient-to-r from-red-600 to-red-700 px-6 py-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="p-2 bg-white/20 rounded-full animate-pulse">
                  <ExclamationTriangleIcon className="h-8 w-8 text-white" />
                </div>
                <div>
                  <h2 className="text-xl font-bold text-white">
                    🚨 ALERTA DE EMERGENCIA
                  </h2>
                  <p className="text-red-100 text-sm">
                    Un ciudadano necesita ayuda urgente
                  </p>
                </div>
              </div>
              <button
                onClick={onClose}
                className="p-2 hover:bg-white/20 rounded-full transition-colors"
              >
                <XMarkIcon className="h-6 w-6 text-white" />
              </button>
            </div>
          </div>

          {/* Alert content */}
          <div className="p-6 space-y-4">
            {responded ? (
              <div className="text-center py-8">
                <CheckCircleIcon className="h-16 w-16 text-green-500 mx-auto mb-4" />
                <h3 className="text-xl font-semibold text-gray-900">
                  Respondiendo a la alerta
                </h3>
                <p className="text-gray-500 mt-2">
                  El ciudadano ha sido notificado que la ayuda está en camino
                </p>
              </div>
            ) : (
              <>
                {/* User info */}
                <div className="flex items-center gap-4 p-4 bg-gray-50 rounded-xl">
                  <div className="p-3 bg-red-100 rounded-full">
                    <UserIcon className="h-6 w-6 text-red-600" />
                  </div>
                  <div>
                    <p className="font-semibold text-gray-900 text-lg">
                      {userName}
                    </p>
                    {phone && (
                      <a
                        href={`tel:${phone}`}
                        className="text-red-600 hover:underline flex items-center gap-1 text-sm"
                      >
                        <PhoneIcon className="h-4 w-4" />
                        {phone}
                      </a>
                    )}
                  </div>
                </div>

                {/* Location */}
                <div className="p-4 bg-gray-50 rounded-xl">
                  <div className="flex items-start gap-3">
                    <MapPinIcon className="h-5 w-5 text-red-600 mt-0.5" />
                    <div className="flex-1">
                      <p className="font-medium text-gray-900">Ubicación</p>
                      <p className="text-gray-600 text-sm">
                        {alert.address || `${alert.latitude.toFixed(6)}, ${alert.longitude.toFixed(6)}`}
                      </p>
                      <button
                        onClick={openInMaps}
                        className="mt-2 text-sm text-red-600 hover:underline"
                      >
                        Ver en Google Maps →
                      </button>
                    </div>
                  </div>
                </div>

                {/* Message if any */}
                {alert.message && (
                  <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-xl">
                    <p className="font-medium text-yellow-800 mb-1">Mensaje:</p>
                    <p className="text-yellow-700">{alert.message}</p>
                  </div>
                )}

                {/* Time */}
                {createdAt && (
                  <div className="flex items-center gap-2 text-gray-500 text-sm">
                    <ClockIcon className="h-4 w-4" />
                    <span>
                      Recibido: {new Date(createdAt).toLocaleString('es-CL')}
                    </span>
                  </div>
                )}

                {/* Actions */}
                <div className="flex gap-3 pt-4">
                  <button
                    onClick={handleRespond}
                    disabled={isResponding}
                    className="flex-1 py-3 px-4 bg-red-600 text-white font-semibold rounded-xl hover:bg-red-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    {isResponding ? 'Respondiendo...' : '✓ Responder a la alerta'}
                  </button>
                  <Link
                    href="/live-map"
                    className="py-3 px-4 bg-gray-100 text-gray-700 font-medium rounded-xl hover:bg-gray-200 transition-colors"
                    onClick={onClose}
                  >
                    Ver en mapa
                  </Link>
                </div>
              </>
            )}
          </div>
        </div>
      </div>

      <style jsx>{`
        @keyframes bounce-in {
          0% {
            transform: scale(0.5);
            opacity: 0;
          }
          50% {
            transform: scale(1.05);
          }
          100% {
            transform: scale(1);
            opacity: 1;
          }
        }
        .animate-bounce-in {
          animation: bounce-in 0.4s ease-out;
        }
      `}</style>
    </div>
  );
}
