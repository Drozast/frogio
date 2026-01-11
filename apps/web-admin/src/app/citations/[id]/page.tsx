'use client';

import { useState, useEffect } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import AppLayout from '@/components/layout/AppLayout';
import {
  ArrowLeftIcon,
  UserIcon,
  HomeIcon,
  TruckIcon,
  BuildingStorefrontIcon,
  QuestionMarkCircleIcon,
  MapPinIcon,
  PhoneIcon,
  IdentificationIcon,
  CalendarIcon,
  ClockIcon,
  TrashIcon,
} from '@heroicons/react/24/outline';

interface Citation {
  id: string;
  citation_type: 'advertencia' | 'citacion';
  target_type: 'persona' | 'domicilio' | 'vehiculo' | 'comercio' | 'otro';
  target_name: string | null;
  target_rut: string | null;
  target_address: string | null;
  target_phone: string | null;
  target_plate: string | null;
  location_address: string | null;
  latitude: number | null;
  longitude: number | null;
  citation_number: string;
  reason: string;
  notes: string | null;
  photos: string[] | null;
  status: string;
  notification_method: string | null;
  notified_at: string | null;
  created_at: string;
  updated_at: string;
  issuer_first_name?: string;
  issuer_last_name?: string;
}

const targetTypeIcons: Record<string, typeof UserIcon> = {
  persona: UserIcon,
  domicilio: HomeIcon,
  vehiculo: TruckIcon,
  comercio: BuildingStorefrontIcon,
  otro: QuestionMarkCircleIcon,
};

const targetTypeLabels: Record<string, string> = {
  persona: 'Persona',
  domicilio: 'Domicilio',
  vehiculo: 'Vehículo',
  comercio: 'Comercio',
  otro: 'Otro',
};


export default function CitationDetailPage() {
  const params = useParams();
  const router = useRouter();
  const id = params.id as string;

  const [citation, setCitation] = useState<Citation | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchCitation();
  }, [id]);

  async function fetchCitation() {
    try {
      const response = await fetch(`/api/citations/${id}`);
      if (!response.ok) {
        throw new Error('Error al cargar la citación');
      }
      const data = await response.json();
      setCitation(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error desconocido');
    } finally {
      setLoading(false);
    }
  }

  async function deleteCitation() {
    if (!confirm('¿Está seguro de eliminar esta notificación? Esta acción no se puede deshacer.')) {
      return;
    }

    try {
      const response = await fetch(`/api/citations/${id}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        throw new Error('Error al eliminar');
      }

      router.push('/citations');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Error desconocido');
    }
  }

  if (loading) {
    return (
      <AppLayout>
        <div className="flex items-center justify-center min-h-96">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
        </div>
      </AppLayout>
    );
  }

  if (error || !citation) {
    return (
      <AppLayout>
        <div className="text-center py-12">
          <p className="text-red-600 mb-4">{error || 'Citación no encontrada'}</p>
          <Link href="/citations" className="text-indigo-600 hover:text-indigo-800">
            Volver a la lista
          </Link>
        </div>
      </AppLayout>
    );
  }

  const TargetIcon = targetTypeIcons[citation.target_type] || QuestionMarkCircleIcon;

  return (
    <AppLayout>
      <div className="max-w-4xl mx-auto space-y-6">
        {/* Header */}
        <div className="flex items-start justify-between">
          <div className="flex items-center gap-4">
            <Link
              href="/citations"
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <ArrowLeftIcon className="h-5 w-5 text-gray-600" />
            </Link>
            <div>
              <div className="flex items-center gap-3">
                <h1 className="text-2xl font-bold text-gray-900">
                  {citation.citation_type === 'advertencia' ? 'Advertencia' : 'Citación'}
                </h1>
                <span className={`px-3 py-1 text-sm font-medium rounded-full border ${
                  citation.citation_type === 'advertencia'
                    ? 'bg-amber-100 text-amber-800 border-amber-200'
                    : 'bg-indigo-100 text-indigo-800 border-indigo-200'
                }`}>
                  {citation.citation_type === 'advertencia' ? 'Advertencia' : 'Citación'}
                </span>
              </div>
              <p className="text-sm text-gray-500 mt-1">
                N° {citation.citation_number}
              </p>
            </div>
          </div>
          <button
            onClick={deleteCitation}
            className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
            title="Eliminar"
          >
            <TrashIcon className="h-5 w-5" />
          </button>
        </div>

        {/* Main Content */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Left Column */}
          <div className="lg:col-span-2 space-y-6">
            {/* Target Info */}
            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center gap-3 mb-4">
                <div className={`p-3 rounded-full ${citation.citation_type === 'advertencia' ? 'bg-amber-100' : 'bg-indigo-100'}`}>
                  <TargetIcon className={`h-6 w-6 ${citation.citation_type === 'advertencia' ? 'text-amber-600' : 'text-indigo-600'}`} />
                </div>
                <div>
                  <h2 className="text-lg font-semibold text-gray-900">
                    {targetTypeLabels[citation.target_type]}
                  </h2>
                  <p className="text-sm text-gray-500">Destinatario de la notificación</p>
                </div>
              </div>

              <dl className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                {citation.target_name && (
                  <div>
                    <dt className="text-sm text-gray-500 flex items-center gap-1">
                      <UserIcon className="h-4 w-4" />
                      {citation.target_type === 'comercio' ? 'Nombre Comercio' : 'Nombre'}
                    </dt>
                    <dd className="text-sm font-medium text-gray-900 mt-1">{citation.target_name}</dd>
                  </div>
                )}
                {citation.target_rut && (
                  <div>
                    <dt className="text-sm text-gray-500 flex items-center gap-1">
                      <IdentificationIcon className="h-4 w-4" />
                      RUT
                    </dt>
                    <dd className="text-sm font-medium text-gray-900 mt-1">{citation.target_rut}</dd>
                  </div>
                )}
                {citation.target_plate && (
                  <div>
                    <dt className="text-sm text-gray-500">Patente</dt>
                    <dd className="text-sm font-medium text-gray-900 mt-1 uppercase">{citation.target_plate}</dd>
                  </div>
                )}
                {citation.target_phone && (
                  <div>
                    <dt className="text-sm text-gray-500 flex items-center gap-1">
                      <PhoneIcon className="h-4 w-4" />
                      Teléfono
                    </dt>
                    <dd className="text-sm font-medium text-gray-900 mt-1">{citation.target_phone}</dd>
                  </div>
                )}
                {citation.target_address && (
                  <div className="sm:col-span-2">
                    <dt className="text-sm text-gray-500 flex items-center gap-1">
                      <HomeIcon className="h-4 w-4" />
                      Dirección
                    </dt>
                    <dd className="text-sm font-medium text-gray-900 mt-1">{citation.target_address}</dd>
                  </div>
                )}
              </dl>
            </div>

            {/* Reason */}
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-3">Motivo</h3>
              <p className="text-gray-700 whitespace-pre-wrap">{citation.reason}</p>
              {citation.notes && (
                <div className="mt-4 pt-4 border-t">
                  <h4 className="text-sm font-medium text-gray-500 mb-2">Observaciones</h4>
                  <p className="text-gray-700 text-sm whitespace-pre-wrap">{citation.notes}</p>
                </div>
              )}
            </div>

            {/* Location */}
            {(citation.location_address || (citation.latitude && citation.longitude)) && (
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-3 flex items-center gap-2">
                  <MapPinIcon className="h-5 w-5 text-gray-500" />
                  Ubicación del Hecho
                </h3>
                {citation.location_address && (
                  <p className="text-gray-700">{citation.location_address}</p>
                )}
                {citation.latitude && citation.longitude && (
                  <div className="mt-3">
                    <a
                      href={`https://www.google.com/maps?q=${citation.latitude},${citation.longitude}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-2 text-sm text-indigo-600 hover:text-indigo-800"
                    >
                      <MapPinIcon className="h-4 w-4" />
                      Ver en Google Maps
                    </a>
                    <p className="text-xs text-gray-400 mt-1">
                      Coordenadas: {Number(citation.latitude).toFixed(6)}, {Number(citation.longitude).toFixed(6)}
                    </p>
                  </div>
                )}
              </div>
            )}

            {/* Photos */}
            {citation.photos && citation.photos.length > 0 && (
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-semibold text-gray-900 mb-3">Evidencia Fotográfica</h3>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
                  {citation.photos.map((photo, index) => (
                    <a
                      key={index}
                      href={photo}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="block"
                    >
                      <img
                        src={photo}
                        alt={`Evidencia ${index + 1}`}
                        className="w-full h-32 object-cover rounded-lg hover:opacity-90 transition-opacity"
                      />
                    </a>
                  ))}
                </div>
              </div>
            )}
          </div>

          {/* Right Column */}
          <div className="space-y-6">
            {/* Meta Info */}
            <div className="bg-white rounded-lg shadow p-6">
              <h3 className="text-lg font-semibold text-gray-900 mb-4">Información</h3>
              <dl className="space-y-3">
                <div>
                  <dt className="text-sm text-gray-500 flex items-center gap-1">
                    <CalendarIcon className="h-4 w-4" />
                    Fecha de Registro
                  </dt>
                  <dd className="text-sm font-medium text-gray-900 mt-1">
                    {new Date(citation.created_at).toLocaleDateString('es-CL', {
                      day: '2-digit',
                      month: 'long',
                      year: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </dd>
                </div>
                {citation.issuer_first_name && (
                  <div>
                    <dt className="text-sm text-gray-500 flex items-center gap-1">
                      <UserIcon className="h-4 w-4" />
                      Emitido por
                    </dt>
                    <dd className="text-sm font-medium text-gray-900 mt-1">
                      {citation.issuer_first_name} {citation.issuer_last_name}
                    </dd>
                  </div>
                )}
                <div>
                  <dt className="text-sm text-gray-500 flex items-center gap-1">
                    <ClockIcon className="h-4 w-4" />
                    Última Actualización
                  </dt>
                  <dd className="text-sm font-medium text-gray-900 mt-1">
                    {new Date(citation.updated_at).toLocaleDateString('es-CL', {
                      day: '2-digit',
                      month: 'long',
                      year: 'numeric',
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </dd>
                </div>
              </dl>
            </div>
          </div>
        </div>
      </div>
    </AppLayout>
  );
}
