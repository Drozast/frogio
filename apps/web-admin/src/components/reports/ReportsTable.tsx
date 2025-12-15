'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { PencilIcon, TrashIcon, UserPlusIcon, EyeIcon } from '@heroicons/react/24/outline';
import { StatusBadge, PriorityBadge } from '@/components/ui/Badge';

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
  first_name: string;
  last_name: string;
  email: string;
}

interface ReportsTableProps {
  reports: Report[];
  inspectors: Inspector[];
}

export default function ReportsTable({ reports, inspectors }: ReportsTableProps) {
  const router = useRouter();
  const [isDeleting, setIsDeleting] = useState<string | null>(null);
  const [assigningReport, setAssigningReport] = useState<string | null>(null);

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

  const handleAssignInspector = async (reportId: string) => {
    const inspectorId = prompt('Ingrese el ID del inspector:');
    if (!inspectorId) return;

    setAssigningReport(reportId);
    try {
      const response = await fetch(`/api/reports/${reportId}/assign`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ assigned_to: inspectorId }),
      });

      if (response.ok) {
        router.refresh();
      } else {
        alert('Error al asignar el inspector');
      }
    } catch (error) {
      console.error('Error assigning inspector:', error);
      alert('Error al asignar el inspector');
    } finally {
      setAssigningReport(null);
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
                      <option value="archivado">Archivado</option>
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
                      <div className="text-sm text-gray-900">
                        {assignedInspector.first_name} {assignedInspector.last_name}
                      </div>
                    ) : (
                      <button
                        onClick={() => handleAssignInspector(report.id)}
                        disabled={assigningReport === report.id}
                        className="text-sm text-indigo-600 hover:text-indigo-900 disabled:opacity-50"
                      >
                        Asignar Inspector
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
  );
}
