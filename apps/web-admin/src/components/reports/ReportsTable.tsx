'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { PencilIcon, TrashIcon, EyeIcon, XMarkIcon, UserCircleIcon } from '@heroicons/react/24/outline';
import { PriorityBadge } from '@/components/ui/Badge';

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

export default function ReportsTable({ reports, inspectors }: ReportsTableProps) {
  const router = useRouter();
  const [isDeleting, setIsDeleting] = useState<string | null>(null);
  const [assignModalOpen, setAssignModalOpen] = useState(false);
  const [selectedReportId, setSelectedReportId] = useState<string | null>(null);
  const [assigningInspector, setAssigningInspector] = useState(false);

  // Agrupar inspectores por estado activo/inactivo
  const activeInspectors = inspectors.filter(i => i.isActive !== false);
  const inactiveInspectors = inspectors.filter(i => i.isActive === false);

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

  if (reports.length === 0) {
    return (
      <div className="bg-white shadow rounded-lg">
        <div className="px-6 py-12 text-center">
          <p className="text-gray-500 text-lg">No hay reportes disponibles</p>
          <p className="text-gray-400 text-sm mt-2">Los reportes creados por ciudadanos aparecerán aquí</p>
        </div>
      </div>
    );
  }

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
                {/* Inspectores Activos */}
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
                            <UserCircleIcon className="h-10 w-10 text-green-500" />
                          </span>
                          <span className="flex-1 min-w-0 flex flex-col">
                            <span className="text-sm font-medium text-gray-900">
                              {inspector.firstName} {inspector.lastName}
                            </span>
                            <span className="text-sm text-gray-500 truncate">{inspector.email}</span>
                          </span>
                          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                            Disponible
                          </span>
                        </button>
                      ))}
                    </div>
                  </div>
                )}

                {/* Inspectores Inactivos */}
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
                            <UserCircleIcon className="h-10 w-10 text-gray-400" />
                          </span>
                          <span className="flex-1 min-w-0 flex flex-col">
                            <span className="text-sm font-medium text-gray-700">
                              {inspector.firstName} {inspector.lastName}
                            </span>
                            <span className="text-sm text-gray-400 truncate">{inspector.email}</span>
                          </span>
                          <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-600">
                            No disponible
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

      {/* Tabla de Reportes */}
      <div className="bg-white shadow rounded-lg overflow-hidden">
        <div className="overflow-x-auto">
          <table className="min-w-full divide-y divide-gray-200">
            <thead className="bg-gray-50">
              <tr>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Título
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Tipo
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Estado
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Prioridad
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Ciudadano
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Inspector Asignado
                </th>
                <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Fecha
                </th>
                <th scope="col" className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Acciones
                </th>
              </tr>
            </thead>
            <tbody className="bg-white divide-y divide-gray-200">
              {reports.map((report) => {
                const assignedInspector = inspectors.find(i => i.id === report.assigned_to);

                return (
                  <tr key={report.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4">
                      <div className="text-sm font-medium text-gray-900">{report.title}</div>
                      <div className="text-sm text-gray-500 truncate max-w-xs">
                        {report.description}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900 capitalize">{report.type.replace('_', ' ')}</div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <select
                        value={report.status}
                        onChange={(e) => handleUpdateStatus(report.id, e.target.value)}
                        className="text-xs rounded-full border-0 bg-transparent font-medium focus:ring-2 focus:ring-indigo-500"
                      >
                        <option value="pendiente">Pendiente</option>
                        <option value="en_proceso">En Proceso</option>
                        <option value="resuelto">Resuelto</option>
                        <option value="rechazado">Rechazado</option>
                      </select>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <PriorityBadge priority={report.priority} />
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="text-sm text-gray-900">
                        {report.first_name} {report.last_name}
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap">
                      {assignedInspector ? (
                        <div className="flex items-center gap-2">
                          <span className="text-sm text-gray-900">
                            {assignedInspector.firstName} {assignedInspector.lastName}
                          </span>
                          <button
                            onClick={() => openAssignModal(report.id)}
                            className="text-xs text-indigo-600 hover:text-indigo-800"
                          >
                            (cambiar)
                          </button>
                        </div>
                      ) : (
                        <button
                          onClick={() => openAssignModal(report.id)}
                          className="inline-flex items-center gap-1 text-sm text-indigo-600 hover:text-indigo-900 font-medium"
                        >
                          <UserCircleIcon className="h-4 w-4" />
                          Asignar
                        </button>
                      )}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                      {new Date(report.created_at).toLocaleDateString('es-CL')}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => handleView(report.id)}
                          className="text-blue-600 hover:text-blue-900 p-1 rounded hover:bg-blue-50 transition-colors"
                          title="Ver detalles"
                        >
                          <EyeIcon className="h-5 w-5" />
                        </button>
                        <button
                          onClick={() => handleEdit(report.id)}
                          className="text-indigo-600 hover:text-indigo-900 p-1 rounded hover:bg-indigo-50 transition-colors"
                          title="Editar reporte"
                        >
                          <PencilIcon className="h-5 w-5" />
                        </button>
                        <button
                          onClick={() => handleDelete(report.id, report.title)}
                          disabled={isDeleting === report.id}
                          className="text-red-600 hover:text-red-900 p-1 rounded hover:bg-red-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                          title="Eliminar reporte"
                        >
                          <TrashIcon className="h-5 w-5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      </div>
    </>
  );
}
