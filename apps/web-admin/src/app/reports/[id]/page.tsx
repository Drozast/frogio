import { cookies } from 'next/headers';
import { redirect, notFound } from 'next/navigation';
import Link from 'next/link';
import AppLayout from '@/components/layout/AppLayout';
import {
  ArrowLeftIcon,
  MapPinIcon,
  CalendarIcon,
  UserIcon,
  ClockIcon,
  ExclamationTriangleIcon
} from '@heroicons/react/24/outline';
import InspectorSelector from './InspectorSelector';
import VersionHistory from './VersionHistory';

const API_URL = process.env.API_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

interface Report {
  id: string;
  title: string;
  description: string;
  type: string;
  status: string;
  priority: string;
  address: string | null;
  latitude: string | number | null;
  longitude: string | number | null;
  created_at: string;
  updated_at: string;
  first_name?: string;
  last_name?: string;
  email?: string;
  assigned_to?: string;
  assigned_first_name?: string;
  assigned_last_name?: string;
}

interface Inspector {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  isActive?: boolean;
}

async function getReport(id: string, token: string): Promise<Report | null> {
  try {
    const response = await fetch(`${API_URL}/api/reports/${id}`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Tenant-ID': 'santa_juana',
      },
      cache: 'no-store',
    });

    if (!response.ok) return null;
    return await response.json();
  } catch (error) {
    console.error('Error fetching report:', error);
    return null;
  }
}

async function getInspectors(token: string): Promise<Inspector[]> {
  try {
    const response = await fetch(`${API_URL}/api/users?role=inspector`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Tenant-ID': 'santa_juana',
      },
      cache: 'no-store',
    });

    if (!response.ok) return [];
    return await response.json();
  } catch (error) {
    console.error('Error fetching inspectors:', error);
    return [];
  }
}

const statusColors: Record<string, string> = {
  pendiente: 'bg-yellow-100 text-yellow-800 border-yellow-300',
  en_proceso: 'bg-blue-100 text-blue-800 border-blue-300',
  resuelto: 'bg-green-100 text-green-800 border-green-300',
  rechazado: 'bg-red-100 text-red-800 border-red-300',
};

const statusLabels: Record<string, string> = {
  pendiente: 'Pendiente',
  en_proceso: 'En Proceso',
  resuelto: 'Resuelto',
  rechazado: 'Rechazado',
};

const priorityColors: Record<string, string> = {
  baja: 'bg-gray-100 text-gray-800',
  media: 'bg-blue-100 text-blue-800',
  alta: 'bg-orange-100 text-orange-800',
  urgente: 'bg-red-100 text-red-800',
};

const typeLabels: Record<string, string> = {
  denuncia: 'Denuncia',
  sugerencia: 'Sugerencia',
  emergencia: 'Emergencia',
  infraestructura: 'Infraestructura',
  otro: 'Otro',
};

export default async function ReportDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const cookieStore = await cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    redirect('/login');
  }

  const [report, inspectors] = await Promise.all([
    getReport(id, accessToken),
    getInspectors(accessToken),
  ]);

  if (!report) {
    notFound();
  }

  const hasLocation = report.latitude && report.longitude;
  const googleMapsUrl = hasLocation
    ? `https://www.google.com/maps?q=${report.latitude},${report.longitude}`
    : null;

  return (
    <AppLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center gap-4">
          <Link
            href="/reports"
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ArrowLeftIcon className="h-5 w-5 text-gray-600" />
          </Link>
          <div className="flex-1">
            <h1 className="text-2xl font-bold text-gray-900">{report.title}</h1>
            <p className="text-sm text-gray-500 mt-1">
              ID: {report.id.slice(0, 8)}...
            </p>
          </div>
          <div className="flex items-center gap-2">
            <span className={`px-3 py-1 rounded-full text-sm font-medium border ${statusColors[report.status] || 'bg-gray-100 text-gray-800'}`}>
              {statusLabels[report.status] || report.status}
            </span>
            <span className={`px-3 py-1 rounded-full text-sm font-medium ${priorityColors[report.priority] || 'bg-gray-100 text-gray-800'}`}>
              {report.priority.charAt(0).toUpperCase() + report.priority.slice(1)}
            </span>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Main Content */}
          <div className="lg:col-span-2 space-y-6">
            {/* Descripción */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Descripción</h2>
              <p className="text-gray-700 whitespace-pre-wrap">{report.description}</p>
            </div>

            {/* Ubicación */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
                <MapPinIcon className="h-5 w-5 text-gray-500" />
                Ubicación
              </h2>

              {report.address && (
                <p className="text-gray-700 mb-4">{report.address}</p>
              )}

              {hasLocation ? (
                <div className="space-y-4">
                  <div className="aspect-video bg-gray-100 rounded-lg overflow-hidden">
                    <iframe
                      width="100%"
                      height="100%"
                      style={{ border: 0 }}
                      loading="lazy"
                      allowFullScreen
                      referrerPolicy="no-referrer-when-downgrade"
                      src={`https://www.google.com/maps/embed/v1/place?key=AIzaSyBFw0Qbyq9zTFTd-tUY6dZWTgaQzuU17R8&q=${report.latitude},${report.longitude}&zoom=16`}
                    />
                  </div>
                  <div className="flex items-center justify-between">
                    <p className="text-sm text-gray-500">
                      Coordenadas: {Number(report.latitude).toFixed(6)}, {Number(report.longitude).toFixed(6)}
                    </p>
                    <a
                      href={googleMapsUrl || '#'}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-sm text-indigo-600 hover:text-indigo-800 font-medium"
                    >
                      Abrir en Google Maps
                    </a>
                  </div>
                </div>
              ) : (
                <div className="bg-gray-50 rounded-lg p-8 text-center">
                  <MapPinIcon className="h-12 w-12 text-gray-400 mx-auto mb-2" />
                  <p className="text-gray-500">No se registró ubicación para este reporte</p>
                </div>
              )}
            </div>
          </div>

          {/* Sidebar */}
          <div className="space-y-6">
            {/* Información */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Información</h2>

              <dl className="space-y-4">
                <div>
                  <dt className="text-sm font-medium text-gray-500 flex items-center gap-2">
                    <ExclamationTriangleIcon className="h-4 w-4" />
                    Tipo
                  </dt>
                  <dd className="mt-1 text-sm text-gray-900">
                    {typeLabels[report.type] || report.type}
                  </dd>
                </div>

                <div>
                  <dt className="text-sm font-medium text-gray-500 flex items-center gap-2">
                    <CalendarIcon className="h-4 w-4" />
                    Fecha de creación
                  </dt>
                  <dd className="mt-1 text-sm text-gray-900">
                    {new Date(report.created_at).toLocaleDateString('es-CL', {
                      weekday: 'long',
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                    })}
                  </dd>
                </div>

                <div>
                  <dt className="text-sm font-medium text-gray-500 flex items-center gap-2">
                    <ClockIcon className="h-4 w-4" />
                    Última actualización
                  </dt>
                  <dd className="mt-1 text-sm text-gray-900">
                    {new Date(report.updated_at).toLocaleDateString('es-CL', {
                      weekday: 'long',
                      year: 'numeric',
                      month: 'long',
                      day: 'numeric',
                    })}
                  </dd>
                </div>
              </dl>
            </div>

            {/* Ciudadano */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
                <UserIcon className="h-5 w-5 text-gray-500" />
                Reportado por
              </h2>

              <div className="flex items-center gap-3">
                <div className="h-12 w-12 rounded-full bg-indigo-100 flex items-center justify-center">
                  <span className="text-indigo-600 font-semibold text-lg">
                    {report.first_name?.charAt(0) || '?'}{report.last_name?.charAt(0) || ''}
                  </span>
                </div>
                <div>
                  <p className="font-medium text-gray-900">
                    {report.first_name} {report.last_name}
                  </p>
                  {report.email && (
                    <p className="text-sm text-gray-500">{report.email}</p>
                  )}
                </div>
              </div>
            </div>

            {/* Inspector Asignado */}
            <InspectorSelector
              reportId={report.id}
              inspectors={inspectors}
              currentInspectorId={report.assigned_to}
              currentInspectorName={
                report.assigned_first_name
                  ? `${report.assigned_first_name} ${report.assigned_last_name}`
                  : undefined
              }
            />

            {/* Historial de Versiones */}
            <VersionHistory reportId={report.id} />

            {/* Acciones */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-lg font-semibold text-gray-900 mb-4">Acciones</h2>

              <div className="space-y-3">
                <Link
                  href={`/reports/${report.id}/edit`}
                  className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 transition-colors"
                >
                  Editar Reporte
                </Link>
                <Link
                  href="/reports"
                  className="w-full flex items-center justify-center gap-2 px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
                >
                  Volver a la lista
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    </AppLayout>
  );
}
