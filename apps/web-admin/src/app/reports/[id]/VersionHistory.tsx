'use client';

import { useState, useEffect } from 'react';
import { ClockIcon, UserIcon, ChevronDownIcon, ChevronUpIcon } from '@heroicons/react/24/outline';

interface ReportVersion {
  id: string;
  report_id: string;
  version_number: number;
  title: string;
  description: string;
  type: string;
  status: string;
  priority: string;
  address: string | null;
  modified_by: string;
  modified_at: string;
  change_reason: string | null;
  modifier_first_name?: string;
  modifier_last_name?: string;
}

interface VersionHistoryProps {
  reportId: string;
}

const statusLabels: Record<string, string> = {
  pendiente: 'Pendiente',
  en_proceso: 'En Proceso',
  resuelto: 'Resuelto',
  rechazado: 'Rechazado',
};

const priorityLabels: Record<string, string> = {
  baja: 'Baja',
  media: 'Media',
  alta: 'Alta',
  urgente: 'Urgente',
};

const typeLabels: Record<string, string> = {
  denuncia: 'Denuncia',
  sugerencia: 'Sugerencia',
  emergencia: 'Emergencia',
  infraestructura: 'Infraestructura',
  otro: 'Otro',
};

export default function VersionHistory({ reportId }: VersionHistoryProps) {
  const [versions, setVersions] = useState<ReportVersion[]>([]);
  const [loading, setLoading] = useState(true);
  const [expanded, setExpanded] = useState(false);
  const [expandedVersion, setExpandedVersion] = useState<number | null>(null);

  useEffect(() => {
    async function fetchVersions() {
      try {
        const response = await fetch(`/api/reports/${reportId}/versions`);
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
  }, [reportId]);

  if (loading) {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
          <ClockIcon className="h-5 w-5 text-gray-500" />
          Historial de Versiones
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
          Historial de Versiones
        </h2>
        <p className="text-sm text-gray-500 text-center py-4">
          Sin historial de cambios
        </p>
      </div>
    );
  }

  const displayedVersions = expanded ? versions : versions.slice(0, 3);

  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
        <ClockIcon className="h-5 w-5 text-gray-500" />
        Historial de Versiones
        <span className="text-sm font-normal text-gray-500">({versions.length})</span>
      </h2>

      <div className="space-y-3">
        {displayedVersions.map((version) => (
          <div
            key={version.id}
            className="border border-gray-200 rounded-lg overflow-hidden"
          >
            {/* Version Header */}
            <button
              onClick={() => setExpandedVersion(expandedVersion === version.version_number ? null : version.version_number)}
              className="w-full px-4 py-3 flex items-center justify-between bg-gray-50 hover:bg-gray-100 transition-colors text-left"
            >
              <div className="flex items-center gap-3">
                <span className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-indigo-100 text-indigo-700 text-xs font-medium">
                  v{version.version_number}
                </span>
                <div>
                  <p className="text-sm font-medium text-gray-900">
                    {version.change_reason || 'Sin descripción del cambio'}
                  </p>
                  <p className="text-xs text-gray-500 flex items-center gap-1 mt-0.5">
                    <UserIcon className="h-3 w-3" />
                    {version.modifier_first_name} {version.modifier_last_name}
                    <span className="mx-1">•</span>
                    {new Date(version.modified_at).toLocaleDateString('es-CL', {
                      day: '2-digit',
                      month: 'short',
                      year: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </p>
                </div>
              </div>
              {expandedVersion === version.version_number ? (
                <ChevronUpIcon className="h-5 w-5 text-gray-400" />
              ) : (
                <ChevronDownIcon className="h-5 w-5 text-gray-400" />
              )}
            </button>

            {/* Version Details */}
            {expandedVersion === version.version_number && (
              <div className="px-4 py-3 border-t border-gray-200 bg-white">
                <dl className="grid grid-cols-2 gap-3 text-sm">
                  <div>
                    <dt className="text-gray-500">Título</dt>
                    <dd className="font-medium text-gray-900">{version.title}</dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">Tipo</dt>
                    <dd className="font-medium text-gray-900">{typeLabels[version.type] || version.type}</dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">Estado</dt>
                    <dd className="font-medium text-gray-900">{statusLabels[version.status] || version.status}</dd>
                  </div>
                  <div>
                    <dt className="text-gray-500">Prioridad</dt>
                    <dd className="font-medium text-gray-900">{priorityLabels[version.priority] || version.priority}</dd>
                  </div>
                  {version.address && (
                    <div className="col-span-2">
                      <dt className="text-gray-500">Dirección</dt>
                      <dd className="font-medium text-gray-900">{version.address}</dd>
                    </div>
                  )}
                  <div className="col-span-2">
                    <dt className="text-gray-500">Descripción</dt>
                    <dd className="font-medium text-gray-900 whitespace-pre-wrap">{version.description}</dd>
                  </div>
                </dl>
              </div>
            )}
          </div>
        ))}
      </div>

      {versions.length > 3 && (
        <button
          onClick={() => setExpanded(!expanded)}
          className="w-full mt-3 px-4 py-2 text-sm font-medium text-indigo-600 hover:text-indigo-800 hover:bg-indigo-50 rounded-lg transition-colors"
        >
          {expanded ? 'Ver menos' : `Ver todas (${versions.length - 3} más)`}
        </button>
      )}
    </div>
  );
}
