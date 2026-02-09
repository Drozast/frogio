'use client';

import { useState, useEffect } from 'react';
import { ClockIcon, UserIcon, CheckCircleIcon, DocumentTextIcon, PlusCircleIcon, BellIcon } from '@heroicons/react/24/outline';

interface CitationVersion {
  id: string;
  citation_id: string;
  version_number: number;
  citation_type: string;
  target_type: string;
  target_name: string | null;
  status: string;
  notes: string | null;
  notification_method: string | null;
  modified_by: string;
  modified_at: string;
  change_reason: string | null;
  modifier_first_name?: string;
  modifier_last_name?: string;
  is_creation?: boolean;
}

interface CitationVersionHistoryProps {
  citationId: string;
}

const statusLabels: Record<string, string> = {
  pendiente: 'Pendiente',
  notificado: 'Notificado',
  asistio: 'Asistio',
  no_asistio: 'No Asistio',
  cancelado: 'Cancelado',
};

const statusColors: Record<string, { bg: string; text: string; border: string }> = {
  pendiente: { bg: 'bg-yellow-50', text: 'text-yellow-700', border: 'border-yellow-200' },
  notificado: { bg: 'bg-blue-50', text: 'text-blue-700', border: 'border-blue-200' },
  asistio: { bg: 'bg-green-50', text: 'text-green-700', border: 'border-green-200' },
  no_asistio: { bg: 'bg-red-50', text: 'text-red-700', border: 'border-red-200' },
  cancelado: { bg: 'bg-gray-50', text: 'text-gray-700', border: 'border-gray-200' },
};

export default function CitationVersionHistory({ citationId }: CitationVersionHistoryProps) {
  const [versions, setVersions] = useState<CitationVersion[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    async function fetchVersions() {
      try {
        const response = await fetch(`/api/citations/${citationId}/versions`);
        if (response.ok) {
          const data = await response.json();
          setVersions(data);
        }
      } catch (error) {
        console.error('Error fetching versions:', error);
      } finally {
        setLoading(false);
      }
    }

    fetchVersions();
  }, [citationId]);

  if (loading) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
          <ClockIcon className="h-5 w-5 text-gray-500" />
          Historial de la Citacion
        </h2>
        <div className="flex items-center justify-center py-4">
          <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-indigo-600"></div>
        </div>
      </div>
    );
  }

  if (versions.length === 0) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
          <ClockIcon className="h-5 w-5 text-gray-500" />
          Historial de la Citacion
        </h2>
        <p className="text-sm text-gray-500 text-center py-4">
          Sin historial de cambios
        </p>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
        <ClockIcon className="h-5 w-5 text-gray-500" />
        Historial de la Citacion
      </h2>

      <div className="space-y-4">
        {versions.map((version, index) => {
          const colors = statusColors[version.status] || statusColors.pendiente;
          const isResolution = version.status === 'asistio' || version.status === 'no_asistio' || version.status === 'cancelado';
          const isCreation = version.is_creation === true;
          const isNotification = version.status === 'notificado';

          // Determine dot color
          let dotColor = 'bg-gray-300';
          if (isCreation) {
            dotColor = 'bg-indigo-500';
          } else if (isResolution) {
            dotColor = 'bg-green-500';
          } else if (isNotification) {
            dotColor = 'bg-blue-500';
          }

          return (
            <div
              key={version.id}
              className={`relative pl-6 ${index !== versions.length - 1 ? 'pb-4' : ''}`}
            >
              {/* Timeline line */}
              {index !== versions.length - 1 && (
                <div className="absolute left-[11px] top-6 bottom-0 w-0.5 bg-gray-200" />
              )}

              {/* Timeline dot */}
              <div className={`absolute left-0 top-1 w-6 h-6 rounded-full flex items-center justify-center ${dotColor}`}>
                {isCreation ? (
                  <PlusCircleIcon className="h-4 w-4 text-white" />
                ) : isNotification ? (
                  <BellIcon className="h-4 w-4 text-white" />
                ) : isResolution ? (
                  <CheckCircleIcon className="h-4 w-4 text-white" />
                ) : (
                  <div className="w-2 h-2 rounded-full bg-white" />
                )}
              </div>

              <div className={`${isCreation ? 'bg-indigo-50 border-indigo-200' : colors.bg + ' ' + colors.border} border rounded-lg p-4`}>
                {/* Header */}
                <div className="flex items-start justify-between mb-2">
                  <div>
                    {isCreation ? (
                      <span className="inline-flex items-center px-2 py-1 rounded-md text-xs font-medium bg-indigo-100 text-indigo-700">
                        Citacion Creada
                      </span>
                    ) : (
                      <span className={`inline-flex items-center px-2 py-1 rounded-md text-xs font-medium ${colors.bg} ${colors.text}`}>
                        {statusLabels[version.status] || version.status}
                      </span>
                    )}
                  </div>
                  <span className="text-xs text-gray-500">
                    {new Date(version.modified_at).toLocaleDateString('es-CL', {
                      day: '2-digit',
                      month: 'short',
                      year: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </span>
                </div>

                {/* User info */}
                <div className="flex items-center gap-2 text-sm text-gray-600 mb-2">
                  <UserIcon className="h-4 w-4" />
                  <span className="font-medium">
                    {version.modifier_first_name} {version.modifier_last_name}
                  </span>
                  {isCreation && (
                    <span className="text-xs text-gray-400">(Inspector)</span>
                  )}
                </div>

                {/* Notes/Resolution reason */}
                {version.change_reason && !isCreation && (
                  <div className={`mt-3 p-3 rounded-lg ${isResolution ? 'bg-white' : 'bg-white/50'}`}>
                    <div className="flex items-start gap-2">
                      <DocumentTextIcon className="h-4 w-4 text-gray-500 mt-0.5 flex-shrink-0" />
                      <div>
                        <p className="text-xs font-medium text-gray-500 mb-1">
                          {isResolution ? 'Notas de resolucion:' : 'Observaciones:'}
                        </p>
                        <p className="text-sm text-gray-800 whitespace-pre-wrap">
                          {version.change_reason}
                        </p>
                      </div>
                    </div>
                  </div>
                )}

                {/* Notification method */}
                {version.notification_method && isNotification && (
                  <div className="mt-2 text-xs text-gray-500">
                    Metodo: {version.notification_method}
                  </div>
                )}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
