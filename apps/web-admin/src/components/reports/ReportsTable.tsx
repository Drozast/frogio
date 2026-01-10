'use client';

import { useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import {
  PencilIcon,
  TrashIcon,
  EyeIcon,
  XMarkIcon,
  UserCircleIcon,
  FunnelIcon,
  CalendarIcon,
  MagnifyingGlassIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
} from '@heroicons/react/24/outline';

interface Report {
  id: string;
  title: string;
  description: string;
  type: string;
  status: string;
  priority: string;
  user_id: string;
  assigned_to: string | null;
  latitude: number | null;
  longitude: number | null;
  created_at: string;
  updated_at: string;
  first_name?: string;
  last_name?: string;
}

interface Inspector {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  isActive?: boolean;
}

interface ReportsTableProps {
  reports: Report[];
  inspectors: Inspector[];
}

const typeLabels: Record<string, string> = {
  denuncia: 'Denuncia',
  sugerencia: 'Sugerencia',
  emergencia: 'Emergencia',
  infraestructura: 'Infraestructura',
  otro: 'Otro',
};

const statusConfig: Record<string, { label: string; color: string; bg: string }> = {
  pendiente: { label: 'Pendiente', color: 'text-yellow-700', bg: 'bg-yellow-100' },
  en_proceso: { label: 'En Proceso', color: 'text-blue-700', bg: 'bg-blue-100' },
  resuelto: { label: 'Resuelto', color: 'text-green-700', bg: 'bg-green-100' },
  rechazado: { label: 'Rechazado', color: 'text-red-700', bg: 'bg-red-100' },
};

const priorityConfig: Record<string, { label: string; color: string; dot: string }> = {
  baja: { label: 'Baja', color: 'text-gray-600', dot: 'bg-gray-400' },
  media: { label: 'Media', color: 'text-blue-600', dot: 'bg-blue-500' },
  alta: { label: 'Alta', color: 'text-orange-600', dot: 'bg-orange-500' },
  urgente: { label: 'Urgente', color: 'text-red-600', dot: 'bg-red-500' },
};

function formatDateHeader(dateStr: string): string {
  const date = new Date(dateStr);
  const today = new Date();
  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);

  if (date.toDateString() === today.toDateString()) {
    return 'Hoy';
  }
  if (date.toDateString() === yesterday.toDateString()) {
    return 'Ayer';
  }
  return date.toLocaleDateString('es-CL', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  });
}

function getDateKey(dateStr: string): string {
  return new Date(dateStr).toDateString();
}

export default function ReportsTable({ reports, inspectors }: ReportsTableProps) {
  const router = useRouter();
  const [isDeleting, setIsDeleting] = useState<string | null>(null);
  const [assignModalOpen, setAssignModalOpen] = useState(false);
  const [selectedReportId, setSelectedReportId] = useState<string | null>(null);
  const [assigningInspector, setAssigningInspector] = useState(false);
  const [showFilters, setShowFilters] = useState(false);

  // Filters state
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState('');
  const [filterStatus, setFilterStatus] = useState('');
  const [filterPriority, setFilterPriority] = useState('');
  const [selectedDate, setSelectedDate] = useState('');

  // Agrupar inspectores por estado activo/inactivo
  const activeInspectors = inspectors.filter(i => i.isActive !== false);
  const inactiveInspectors = inspectors.filter(i => i.isActive === false);

  // Apply filters
  const filteredReports = useMemo(() => {
    return reports.filter(report => {
      // Search filter
      if (searchQuery) {
        const query = searchQuery.toLowerCase();
        const matchesSearch =
          report.title.toLowerCase().includes(query) ||
          report.description.toLowerCase().includes(query) ||
          `${report.first_name} ${report.last_name}`.toLowerCase().includes(query);
        if (!matchesSearch) return false;
      }

      // Type filter
      if (filterType && report.type !== filterType) return false;

      // Status filter
      if (filterStatus && report.status !== filterStatus) return false;

      // Priority filter
      if (filterPriority && report.priority !== filterPriority) return false;

      // Date filter
      if (selectedDate) {
        const reportDate = new Date(report.created_at).toISOString().split('T')[0];
        if (reportDate !== selectedDate) return false;
      }

      return true;
    });
  }, [reports, searchQuery, filterType, filterStatus, filterPriority, selectedDate]);

  // Group reports by date
  const groupedReports = useMemo(() => {
    const groups: Record<string, Report[]> = {};

    filteredReports.forEach(report => {
      const dateKey = getDateKey(report.created_at);
      if (!groups[dateKey]) {
        groups[dateKey] = [];
      }
      groups[dateKey].push(report);
    });

    // Sort groups by date (newest first)
    const sortedGroups = Object.entries(groups).sort(([a], [b]) =>
      new Date(b).getTime() - new Date(a).getTime()
    );

    return sortedGroups;
  }, [filteredReports]);

  // Calendar navigation
  const navigateDate = (direction: 'prev' | 'next') => {
    const current = selectedDate ? new Date(selectedDate) : new Date();
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
    setFilterStatus('');
    setFilterPriority('');
    setSelectedDate('');
  };

  const hasActiveFilters = searchQuery || filterType || filterStatus || filterPriority || selectedDate;

  const handleView = (reportId: string) => {
    router.push(`/reports/${reportId}`);
  };

  const handleEdit = (reportId: string) => {
    router.push(`/reports/${reportId}/edit`);
  };

  const handleDelete = async (reportId: string, reportTitle: string) => {
    if (!confirm(`¿Estás seguro de eliminar el reporte "${reportTitle}"?`)) {
      return;
    }

    setIsDeleting(reportId);
    try {
      const response = await fetch(`/api/reports/${reportId}`, {
        method: 'DELETE',
      });

      if (response.ok) {
        router.refresh();
      } else {
        alert('Error al eliminar el reporte');
      }
    } catch (error) {
      console.error('Error deleting report:', error);
      alert('Error al eliminar el reporte');
    } finally {
      setIsDeleting(null);
    }
  };

  const openAssignModal = (reportId: string) => {
    setSelectedReportId(reportId);
    setAssignModalOpen(true);
  };

  const handleAssignInspector = async (inspectorId: string) => {
    if (!selectedReportId) return;

    setAssigningInspector(true);
    try {
      const response = await fetch(`/api/reports/${selectedReportId}/assign`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ assigned_to: inspectorId }),
      });

      if (response.ok) {
        setAssignModalOpen(false);
        setSelectedReportId(null);
        router.refresh();
      } else {
        alert('Error al asignar el inspector');
      }
    } catch (error) {
      console.error('Error assigning inspector:', error);
      alert('Error al asignar el inspector');
    } finally {
      setAssigningInspector(false);
    }
  };

  const handleUpdateStatus = async (reportId: string, newStatus: string) => {
    try {
      const response = await fetch(`/api/reports/${reportId}/status`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ status: newStatus }),
      });

      if (response.ok) {
        router.refresh();
      } else {
        alert('Error al actualizar el estado');
      }
    } catch (error) {
      console.error('Error updating status:', error);
      alert('Error al actualizar el estado');
    }
  };

  return (
    <>
      {/* Modal de Asignar Inspector */}
      {assignModalOpen && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" onClick={() => setAssignModalOpen(false)} />

            <div className="relative bg-white rounded-lg shadow-xl max-w-md w-full p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900">Asignar Inspector</h3>
                <button
                  onClick={() => setAssignModalOpen(false)}
                  className="text-gray-400 hover:text-gray-500"
                >
                  <XMarkIcon className="h-6 w-6" />
                </button>
              </div>

              <div className="space-y-4 max-h-96 overflow-y-auto">
                {activeInspectors.length > 0 && (
                  <div>
                    <h4 className="text-sm font-medium text-green-700 bg-green-50 px-3 py-2 rounded-t-lg border border-green-200">
                      Activos ({activeInspectors.length})
                    </h4>
                    <div className="border border-t-0 border-gray-200 rounded-b-lg divide-y">
                      {activeInspectors.map((inspector) => (
                        <button
                          key={inspector.id}
                          onClick={() => handleAssignInspector(inspector.id)}
                          disabled={assigningInspector}
                          className="w-full flex items-center gap-3 px-4 py-3 hover:bg-green-50 transition-colors disabled:opacity-50 text-left"
                        >
                          <span className="flex-shrink-0">
                            <UserCircleIcon className="h-8 w-8 text-green-500" />
                          </span>
                          <span className="flex-1 min-w-0">
                            <span className="text-sm font-medium text-gray-900 block">
                              {inspector.firstName} {inspector.lastName}
                            </span>
                            <span className="text-xs text-gray-500 truncate block">{inspector.email}</span>
                          </span>
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                {inactiveInspectors.length > 0 && (
                  <div>
                    <h4 className="text-sm font-medium text-gray-500 bg-gray-100 px-3 py-2 rounded-t-lg border border-gray-200">
                      No disponibles ({inactiveInspectors.length})
                    </h4>
                    <div className="border border-t-0 border-gray-200 rounded-b-lg divide-y">
                      {inactiveInspectors.map((inspector) => (
                        <button
                          key={inspector.id}
                          onClick={() => handleAssignInspector(inspector.id)}
                          disabled={assigningInspector}
                          className="w-full flex items-center gap-3 px-4 py-3 hover:bg-gray-50 transition-colors disabled:opacity-50 text-left opacity-60"
                        >
                          <span className="flex-shrink-0">
                            <UserCircleIcon className="h-8 w-8 text-gray-400" />
                          </span>
                          <span className="flex-1 min-w-0">
                            <span className="text-sm font-medium text-gray-700 block">
                              {inspector.firstName} {inspector.lastName}
                            </span>
                            <span className="text-xs text-gray-400 truncate block">{inspector.email}</span>
                          </span>
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                {inspectors.length === 0 && (
                  <p className="text-center text-gray-500 py-4">No hay inspectores registrados</p>
                )}
              </div>

              <div className="mt-4 flex justify-end">
                <button
                  onClick={() => setAssignModalOpen(false)}
                  className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md"
                >
                  Cancelar
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Filters Bar */}
      <div className="bg-white shadow rounded-lg mb-4">
        <div className="p-4">
          {/* Search and Filter Toggle */}
          <div className="flex flex-col sm:flex-row gap-3">
            {/* Search Input */}
            <div className="flex-1 relative">
              <MagnifyingGlassIcon className="h-5 w-5 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
              <input
                type="text"
                placeholder="Buscar por título, descripción o ciudadano..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm"
              />
            </div>

            {/* Date Navigation */}
            <div className="flex items-center gap-2">
              <button
                onClick={() => navigateDate('prev')}
                className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                title="Día anterior"
              >
                <ChevronLeftIcon className="h-5 w-5 text-gray-600" />
              </button>
              <div className="relative">
                <CalendarIcon className="h-5 w-5 absolute left-3 top-1/2 -translate-y-1/2 text-gray-400" />
                <input
                  type="date"
                  value={selectedDate}
                  onChange={(e) => setSelectedDate(e.target.value)}
                  className="pl-10 pr-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm"
                />
              </div>
              <button
                onClick={() => navigateDate('next')}
                className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
                title="Día siguiente"
              >
                <ChevronRightIcon className="h-5 w-5 text-gray-600" />
              </button>
            </div>

            {/* Filter Toggle */}
            <button
              onClick={() => setShowFilters(!showFilters)}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg border transition-colors ${
                showFilters || hasActiveFilters
                  ? 'bg-indigo-50 border-indigo-200 text-indigo-700'
                  : 'border-gray-300 text-gray-700 hover:bg-gray-50'
              }`}
            >
              <FunnelIcon className="h-5 w-5" />
              <span className="text-sm font-medium">Filtros</span>
              {hasActiveFilters && (
                <span className="inline-flex items-center justify-center w-5 h-5 text-xs font-bold text-white bg-indigo-600 rounded-full">
                  {[filterType, filterStatus, filterPriority, selectedDate].filter(Boolean).length}
                </span>
              )}
            </button>
          </div>

          {/* Extended Filters */}
          {showFilters && (
            <div className="mt-4 pt-4 border-t border-gray-200">
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
                {/* Type Filter */}
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1">Tipo</label>
                  <select
                    value={filterType}
                    onChange={(e) => setFilterType(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm"
                  >
                    <option value="">Todos los tipos</option>
                    {Object.entries(typeLabels).map(([value, label]) => (
                      <option key={value} value={value}>{label}</option>
                    ))}
                  </select>
                </div>

                {/* Status Filter */}
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1">Estado</label>
                  <select
                    value={filterStatus}
                    onChange={(e) => setFilterStatus(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm"
                  >
                    <option value="">Todos los estados</option>
                    {Object.entries(statusConfig).map(([value, config]) => (
                      <option key={value} value={value}>{config.label}</option>
                    ))}
                  </select>
                </div>

                {/* Priority Filter */}
                <div>
                  <label className="block text-xs font-medium text-gray-500 mb-1">Prioridad</label>
                  <select
                    value={filterPriority}
                    onChange={(e) => setFilterPriority(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 text-sm"
                  >
                    <option value="">Todas las prioridades</option>
                    {Object.entries(priorityConfig).map(([value, config]) => (
                      <option key={value} value={value}>{config.label}</option>
                    ))}
                  </select>
                </div>
              </div>

              {hasActiveFilters && (
                <div className="mt-3 flex justify-end">
                  <button
                    onClick={clearFilters}
                    className="text-sm text-indigo-600 hover:text-indigo-800 font-medium"
                  >
                    Limpiar filtros
                  </button>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Results Summary */}
        <div className="px-4 py-2 bg-gray-50 border-t border-gray-200 rounded-b-lg">
          <p className="text-sm text-gray-600">
            {filteredReports.length} {filteredReports.length === 1 ? 'reporte' : 'reportes'}
            {hasActiveFilters && ' (filtrado)'}
          </p>
        </div>
      </div>

      {/* Reports grouped by date */}
      {filteredReports.length === 0 ? (
        <div className="bg-white shadow rounded-lg">
          <div className="px-6 py-12 text-center">
            <p className="text-gray-500 text-lg">
              {hasActiveFilters ? 'No hay reportes que coincidan con los filtros' : 'No hay reportes disponibles'}
            </p>
            {hasActiveFilters && (
              <button
                onClick={clearFilters}
                className="mt-2 text-indigo-600 hover:text-indigo-800 font-medium"
              >
                Limpiar filtros
              </button>
            )}
          </div>
        </div>
      ) : (
        <div className="space-y-4">
          {groupedReports.map(([dateKey, dateReports]) => (
            <div key={dateKey} className="bg-white shadow rounded-lg overflow-hidden">
              {/* Date Header */}
              <div className="px-4 py-2 bg-gray-50 border-b border-gray-200">
                <h3 className="text-sm font-semibold text-gray-700 capitalize">
                  {formatDateHeader(dateReports[0].created_at)}
                  <span className="ml-2 text-gray-400 font-normal">
                    ({dateReports.length} {dateReports.length === 1 ? 'reporte' : 'reportes'})
                  </span>
                </h3>
              </div>

              {/* Reports List - Compact Card View */}
              <div className="divide-y divide-gray-100">
                {dateReports.map((report) => {
                  const assignedInspector = inspectors.find(i => i.id === report.assigned_to);
                  const status = statusConfig[report.status] || statusConfig.pendiente;
                  const priority = priorityConfig[report.priority] || priorityConfig.media;

                  return (
                    <div
                      key={report.id}
                      className="px-4 py-3 hover:bg-gray-50 transition-colors"
                    >
                      <div className="flex items-start gap-3">
                        {/* Priority Indicator */}
                        <div className={`w-1 self-stretch rounded-full ${priority.dot}`} />

                        {/* Main Content */}
                        <div className="flex-1 min-w-0">
                          <div className="flex items-start justify-between gap-2">
                            <div className="min-w-0 flex-1">
                              {/* Title Row */}
                              <div className="flex items-center gap-2 flex-wrap">
                                <h4 className="text-sm font-medium text-gray-900 truncate">
                                  {report.title}
                                </h4>
                                <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${status.bg} ${status.color}`}>
                                  {status.label}
                                </span>
                                <span className="text-xs text-gray-400">
                                  {typeLabels[report.type] || report.type}
                                </span>
                              </div>

                              {/* Meta Row */}
                              <div className="mt-1 flex items-center gap-3 text-xs text-gray-500">
                                <span>{report.first_name} {report.last_name}</span>
                                <span>•</span>
                                <span>
                                  {new Date(report.created_at).toLocaleTimeString('es-CL', {
                                    hour: '2-digit',
                                    minute: '2-digit',
                                  })}
                                </span>
                                {assignedInspector ? (
                                  <>
                                    <span>•</span>
                                    <button
                                      onClick={() => openAssignModal(report.id)}
                                      className="text-indigo-600 hover:text-indigo-800"
                                    >
                                      {assignedInspector.firstName} {assignedInspector.lastName}
                                    </button>
                                  </>
                                ) : (
                                  <>
                                    <span>•</span>
                                    <button
                                      onClick={() => openAssignModal(report.id)}
                                      className="text-orange-600 hover:text-orange-800 font-medium"
                                    >
                                      Sin asignar
                                    </button>
                                  </>
                                )}
                              </div>
                            </div>

                            {/* Actions */}
                            <div className="flex items-center gap-1 flex-shrink-0">
                              <select
                                value={report.status}
                                onChange={(e) => handleUpdateStatus(report.id, e.target.value)}
                                className="text-xs border-0 bg-transparent py-1 pr-6 pl-2 rounded focus:ring-2 focus:ring-indigo-500 text-gray-600 cursor-pointer hover:bg-gray-100"
                              >
                                <option value="pendiente">Pendiente</option>
                                <option value="en_proceso">En Proceso</option>
                                <option value="resuelto">Resuelto</option>
                                <option value="rechazado">Rechazado</option>
                              </select>
                              <button
                                onClick={() => handleView(report.id)}
                                className="p-1.5 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded transition-colors"
                                title="Ver detalles"
                              >
                                <EyeIcon className="h-4 w-4" />
                              </button>
                              <button
                                onClick={() => handleEdit(report.id)}
                                className="p-1.5 text-gray-400 hover:text-indigo-600 hover:bg-indigo-50 rounded transition-colors"
                                title="Editar"
                              >
                                <PencilIcon className="h-4 w-4" />
                              </button>
                              <button
                                onClick={() => handleDelete(report.id, report.title)}
                                disabled={isDeleting === report.id}
                                className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded transition-colors disabled:opacity-50"
                                title="Eliminar"
                              >
                                <TrashIcon className="h-4 w-4" />
                              </button>
                            </div>
                          </div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          ))}
        </div>
      )}
    </>
  );
}
