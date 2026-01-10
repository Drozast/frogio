'use client';

import { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import AppLayout from '@/components/layout/AppLayout';
import {
  PlusIcon,
  MagnifyingGlassIcon,
  FunnelIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  CalendarIcon,
  UserIcon,
  HomeIcon,
  TruckIcon,
  BuildingStorefrontIcon,
  QuestionMarkCircleIcon,
  ExclamationTriangleIcon,
  DocumentTextIcon,
  MapPinIcon,
  XMarkIcon,
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
  citation_number: string;
  reason: string;
  status: string;
  created_at: string;
  issuer_first_name?: string;
  issuer_last_name?: string;
}

const citationTypeLabels: Record<string, { label: string; color: string; icon: typeof DocumentTextIcon }> = {
  advertencia: { label: 'Advertencia', color: 'bg-amber-100 text-amber-800', icon: ExclamationTriangleIcon },
  citacion: { label: 'Citación', color: 'bg-indigo-100 text-indigo-800', icon: DocumentTextIcon },
};

const targetTypeIcons: Record<string, typeof UserIcon> = {
  persona: UserIcon,
  domicilio: HomeIcon,
  vehiculo: TruckIcon,
  comercio: BuildingStorefrontIcon,
  otro: QuestionMarkCircleIcon,
};

const statusLabels: Record<string, { label: string; color: string }> = {
  pendiente: { label: 'Pendiente', color: 'bg-yellow-100 text-yellow-800' },
  notificado: { label: 'Notificado', color: 'bg-blue-100 text-blue-800' },
  asistio: { label: 'Asistió', color: 'bg-green-100 text-green-800' },
  no_asistio: { label: 'No Asistió', color: 'bg-red-100 text-red-800' },
  cancelado: { label: 'Cancelado', color: 'bg-gray-100 text-gray-800' },
};

export default function CitationsPage() {
  const [citations, setCitations] = useState<Citation[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState('');
  const [filterTargetType, setFilterTargetType] = useState('');
  const [filterStatus, setFilterStatus] = useState('');
  const [selectedDate, setSelectedDate] = useState('');
  const [showFilters, setShowFilters] = useState(false);

  useEffect(() => {
    fetchCitations();
  }, []);

  async function fetchCitations() {
    try {
      const response = await fetch('/api/citations');
      if (response.ok) {
        const data = await response.json();
        setCitations(data);
      }
    } catch (error) {
      console.error('Error fetching citations:', error);
    } finally {
      setLoading(false);
    }
  }

  const getDateKey = (dateStr: string) => {
    const date = new Date(dateStr);
    return date.toISOString().split('T')[0];
  };

  const formatDateLabel = (dateKey: string) => {
    const date = new Date(dateKey + 'T12:00:00');
    const today = new Date();
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    if (dateKey === today.toISOString().split('T')[0]) {
      return 'Hoy';
    } else if (dateKey === yesterday.toISOString().split('T')[0]) {
      return 'Ayer';
    } else {
      return date.toLocaleDateString('es-CL', {
        weekday: 'long',
        day: 'numeric',
        month: 'long',
        year: 'numeric',
      });
    }
  };

  const filteredCitations = useMemo(() => {
    return citations.filter(citation => {
      if (searchQuery) {
        const query = searchQuery.toLowerCase();
        const matchesSearch =
          citation.citation_number.toLowerCase().includes(query) ||
          (citation.target_name?.toLowerCase().includes(query)) ||
          (citation.target_rut?.toLowerCase().includes(query)) ||
          (citation.target_plate?.toLowerCase().includes(query)) ||
          (citation.reason?.toLowerCase().includes(query)) ||
          (citation.location_address?.toLowerCase().includes(query));
        if (!matchesSearch) return false;
      }

      if (filterType && citation.citation_type !== filterType) return false;
      if (filterTargetType && citation.target_type !== filterTargetType) return false;
      if (filterStatus && citation.status !== filterStatus) return false;

      if (selectedDate) {
        const citationDate = getDateKey(citation.created_at);
        if (citationDate !== selectedDate) return false;
      }

      return true;
    });
  }, [citations, searchQuery, filterType, filterTargetType, filterStatus, selectedDate]);

  const groupedCitations = useMemo(() => {
    const groups: Record<string, Citation[]> = {};

    filteredCitations.forEach(citation => {
      const dateKey = getDateKey(citation.created_at);
      if (!groups[dateKey]) {
        groups[dateKey] = [];
      }
      groups[dateKey].push(citation);
    });

    return Object.entries(groups).sort(([a], [b]) => new Date(b).getTime() - new Date(a).getTime());
  }, [filteredCitations]);

  const navigateDate = (direction: 'prev' | 'next') => {
    const current = selectedDate ? new Date(selectedDate + 'T12:00:00') : new Date();
    if (direction === 'prev') {
      current.setDate(current.getDate() - 1);
    } else {
      current.setDate(current.getDate() + 1);
    }
    setSelectedDate(current.toISOString().split('T')[0]);
  };

  const clearFilters = () => {
    setSearchQuery('');
    setFilterType('');
    setFilterTargetType('');
    setFilterStatus('');
    setSelectedDate('');
  };

  const hasActiveFilters = searchQuery || filterType || filterTargetType || filterStatus || selectedDate;

  const getTargetDisplay = (citation: Citation) => {
    switch (citation.target_type) {
      case 'persona':
        return citation.target_name || 'Sin nombre';
      case 'vehiculo':
        return citation.target_plate || 'Sin patente';
      case 'domicilio':
      case 'comercio':
        return citation.target_name || citation.target_address || 'Sin identificar';
      default:
        return citation.target_name || 'Sin identificar';
    }
  };

  if (loading) {
    return (
      <AppLayout>
        <div className="flex items-center justify-center min-h-96">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
        </div>
      </AppLayout>
    );
  }

  return (
    <AppLayout>
      <div className="space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Notificaciones</h1>
            <p className="text-sm text-gray-500 mt-1">
              Advertencias y citaciones emitidas
            </p>
          </div>
          <Link
            href="/citations/new"
            className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors"
          >
            <PlusIcon className="h-4 w-4" />
            Nueva Notificación
          </Link>
        </div>

        {/* Search and Filters */}
        <div className="bg-white rounded-lg shadow p-4 space-y-4">
          {/* Search Bar */}
          <div className="flex items-center gap-3">
            <div className="relative flex-1">
              <MagnifyingGlassIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                type="text"
                placeholder="Buscar por número, nombre, RUT, patente..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-9 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              />
            </div>
            <button
              onClick={() => setShowFilters(!showFilters)}
              className={`inline-flex items-center gap-2 px-4 py-2 border rounded-lg text-sm font-medium transition-colors ${
                showFilters || hasActiveFilters
                  ? 'bg-indigo-50 border-indigo-300 text-indigo-700'
                  : 'border-gray-300 text-gray-700 hover:bg-gray-50'
              }`}
            >
              <FunnelIcon className="h-4 w-4" />
              Filtros
              {hasActiveFilters && (
                <span className="w-2 h-2 bg-indigo-600 rounded-full"></span>
              )}
            </button>
          </div>

          {/* Filter Options */}
          {showFilters && (
            <div className="flex flex-wrap items-center gap-3 pt-3 border-t">
              <select
                value={filterType}
                onChange={(e) => setFilterType(e.target.value)}
                className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500"
              >
                <option value="">Todos los tipos</option>
                <option value="advertencia">Advertencia</option>
                <option value="citacion">Citación</option>
              </select>
              <select
                value={filterTargetType}
                onChange={(e) => setFilterTargetType(e.target.value)}
                className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500"
              >
                <option value="">Todo objetivo</option>
                <option value="persona">Persona</option>
                <option value="vehiculo">Vehículo</option>
                <option value="domicilio">Domicilio</option>
                <option value="comercio">Comercio</option>
                <option value="otro">Otro</option>
              </select>
              <select
                value={filterStatus}
                onChange={(e) => setFilterStatus(e.target.value)}
                className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500"
              >
                <option value="">Todos los estados</option>
                <option value="pendiente">Pendiente</option>
                <option value="notificado">Notificado</option>
                <option value="asistio">Asistió</option>
                <option value="no_asistio">No Asistió</option>
                <option value="cancelado">Cancelado</option>
              </select>
              {hasActiveFilters && (
                <button
                  onClick={clearFilters}
                  className="inline-flex items-center gap-1 px-3 py-1.5 text-sm text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                >
                  <XMarkIcon className="h-4 w-4" />
                  Limpiar
                </button>
              )}
            </div>
          )}

          {/* Date Navigation */}
          <div className="flex items-center justify-between pt-3 border-t">
            <button
              onClick={() => navigateDate('prev')}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <ChevronLeftIcon className="h-5 w-5 text-gray-600" />
            </button>
            <div className="flex items-center gap-2">
              <CalendarIcon className="h-4 w-4 text-gray-400" />
              <input
                type="date"
                value={selectedDate}
                onChange={(e) => setSelectedDate(e.target.value)}
                className="px-3 py-1.5 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500"
              />
              {selectedDate && (
                <button
                  onClick={() => setSelectedDate('')}
                  className="text-sm text-indigo-600 hover:text-indigo-800"
                >
                  Ver todas
                </button>
              )}
            </div>
            <button
              onClick={() => navigateDate('next')}
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <ChevronRightIcon className="h-5 w-5 text-gray-600" />
            </button>
          </div>
        </div>

        {/* Results Count */}
        <div className="text-sm text-gray-500">
          {filteredCitations.length} notificación{filteredCitations.length !== 1 ? 'es' : ''} encontrada{filteredCitations.length !== 1 ? 's' : ''}
        </div>

        {/* Citations List */}
        {groupedCitations.length === 0 ? (
          <div className="bg-white rounded-lg shadow p-8 text-center">
            <DocumentTextIcon className="h-12 w-12 text-gray-300 mx-auto mb-3" />
            <h3 className="text-lg font-medium text-gray-900 mb-1">
              No hay notificaciones
            </h3>
            <p className="text-sm text-gray-500 mb-4">
              {hasActiveFilters
                ? 'No se encontraron notificaciones con los filtros seleccionados'
                : 'Aún no se han registrado advertencias o citaciones'}
            </p>
            {hasActiveFilters && (
              <button
                onClick={clearFilters}
                className="text-sm text-indigo-600 hover:text-indigo-800"
              >
                Limpiar filtros
              </button>
            )}
          </div>
        ) : (
          <div className="space-y-6">
            {groupedCitations.map(([dateKey, dateCitations]) => (
              <div key={dateKey}>
                <h3 className="text-sm font-medium text-gray-500 mb-3 capitalize">
                  {formatDateLabel(dateKey)}
                </h3>
                <div className="space-y-2">
                  {dateCitations.map((citation) => {
                    const typeInfo = citationTypeLabels[citation.citation_type] || citationTypeLabels.citacion;
                    const TargetIcon = targetTypeIcons[citation.target_type] || QuestionMarkCircleIcon;
                    const statusInfo = statusLabels[citation.status] || statusLabels.pendiente;

                    return (
                      <Link
                        key={citation.id}
                        href={`/citations/${citation.id}`}
                        className="block bg-white rounded-lg shadow hover:shadow-md transition-shadow overflow-hidden"
                      >
                        <div className="flex">
                          {/* Type Indicator */}
                          <div className={`w-1.5 ${citation.citation_type === 'advertencia' ? 'bg-amber-500' : 'bg-indigo-500'}`} />

                          <div className="flex-1 p-4">
                            <div className="flex items-start justify-between gap-4">
                              <div className="flex items-start gap-3 min-w-0 flex-1">
                                {/* Target Icon */}
                                <div className={`p-2 rounded-full ${citation.citation_type === 'advertencia' ? 'bg-amber-100' : 'bg-indigo-100'}`}>
                                  <TargetIcon className={`h-5 w-5 ${citation.citation_type === 'advertencia' ? 'text-amber-600' : 'text-indigo-600'}`} />
                                </div>

                                <div className="min-w-0 flex-1">
                                  {/* Target Name */}
                                  <h4 className="font-medium text-gray-900 truncate">
                                    {getTargetDisplay(citation)}
                                  </h4>

                                  {/* Reason */}
                                  <p className="text-sm text-gray-500 line-clamp-1 mt-0.5">
                                    {citation.reason}
                                  </p>

                                  {/* Meta Info */}
                                  <div className="flex flex-wrap items-center gap-2 mt-2 text-xs text-gray-400">
                                    <span className={`px-2 py-0.5 rounded-full ${typeInfo.color}`}>
                                      {typeInfo.label}
                                    </span>
                                    <span className="text-gray-300">•</span>
                                    <span>{citation.citation_number}</span>
                                    {citation.location_address && (
                                      <>
                                        <span className="text-gray-300">•</span>
                                        <span className="flex items-center gap-1">
                                          <MapPinIcon className="h-3 w-3" />
                                          <span className="truncate max-w-[150px]">{citation.location_address}</span>
                                        </span>
                                      </>
                                    )}
                                  </div>
                                </div>
                              </div>

                              {/* Right Side */}
                              <div className="flex flex-col items-end gap-2">
                                <span className={`px-2 py-0.5 text-xs font-medium rounded-full ${statusInfo.color}`}>
                                  {statusInfo.label}
                                </span>
                                <span className="text-xs text-gray-400">
                                  {new Date(citation.created_at).toLocaleTimeString('es-CL', {
                                    hour: '2-digit',
                                    minute: '2-digit',
                                  })}
                                </span>
                                {citation.issuer_first_name && (
                                  <span className="text-xs text-gray-400">
                                    por {citation.issuer_first_name}
                                  </span>
                                )}
                              </div>
                            </div>
                          </div>
                        </div>
                      </Link>
                    );
                  })}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </AppLayout>
  );
}
