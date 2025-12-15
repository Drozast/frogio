'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { PencilIcon, TrashIcon, EyeIcon } from '@heroicons/react/24/outline';

interface Infraction {
  id: string;
  type: string;
  description: string;
  amount: string;
  status: string;
  user_id: string;
  vehicle_id: string | null;
  vehicle_plate: string | null;
  location: string | null;
  created_at: string;
  user_first_name?: string;
  user_last_name?: string;
}

interface InfractionsTableProps {
  infractions: Infraction[];
}

export default function InfractionsTable({ infractions }: InfractionsTableProps) {
  const router = useRouter();
  const [isDeleting, setIsDeleting] = useState<string | null>(null);

  const handleView = (infractionId: string) => {
    router.push(`/infractions/${infractionId}`);
  };

  const handleEdit = (infractionId: string) => {
    router.push(`/infractions/${infractionId}/edit`);
  };

  const handleDelete = async (infractionId: string, infractionType: string) => {
    if (!confirm(`¿Estás seguro de eliminar la infracción "${infractionType}"?`)) {
      return;
    }

    setIsDeleting(infractionId);
    try {
      const response = await fetch(`/api/infractions/${infractionId}`, {
        method: 'DELETE',
      });

      if (response.ok) {
        router.refresh();
      } else {
        alert('Error al eliminar la infracción');
      }
    } catch (error) {
      console.error('Error deleting infraction:', error);
      alert('Error al eliminar la infracción');
    } finally {
      setIsDeleting(null);
    }
  };

  const handleUpdateStatus = async (infractionId: string, newStatus: string) => {
    try {
      const response = await fetch(`/api/infractions/${infractionId}/status`, {
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

  if (infractions.length === 0) {
    return (
      <div className="bg-white shadow rounded-lg">
        <div className="px-6 py-12 text-center">
          <p className="text-gray-500 text-lg">No hay infracciones registradas</p>
          <p className="text-gray-400 text-sm mt-2">Las infracciones creadas aparecerán aquí</p>
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
                Tipo
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Descripción
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Ciudadano
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Patente
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Monto
              </th>
              <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                Estado
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
            {infractions.map((infraction) => (
              <tr key={infraction.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm font-medium text-gray-900">{infraction.type}</div>
                </td>
                <td className="px-6 py-4">
                  <div className="text-sm text-gray-500 max-w-xs truncate">
                    {infraction.description}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-gray-900">
                    {infraction.user_first_name} {infraction.user_last_name}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm text-gray-900">
                    {infraction.vehicle_plate || '-'}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <div className="text-sm font-semibold text-gray-900">
                    ${parseFloat(infraction.amount).toLocaleString('es-CL')}
                  </div>
                </td>
                <td className="px-6 py-4 whitespace-nowrap">
                  <select
                    value={infraction.status}
                    onChange={(e) => handleUpdateStatus(infraction.id, e.target.value)}
                    className={`text-xs rounded-full px-2.5 py-0.5 font-medium border-0 focus:ring-2 focus:ring-indigo-500 ${getStatusColor(infraction.status)}`}
                  >
                    <option value="pendiente">Pendiente</option>
                    <option value="pagada">Pagada</option>
                    <option value="anulada">Anulada</option>
                  </select>
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                  {new Date(infraction.created_at).toLocaleDateString('es-CL')}
                </td>
                <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                  <div className="flex items-center justify-end gap-2">
                    <button
                      onClick={() => handleView(infraction.id)}
                      className="text-blue-600 hover:text-blue-900 p-1 rounded hover:bg-blue-50 transition-colors"
                      title="Ver detalles"
                    >
                      <EyeIcon className="h-5 w-5" />
                    </button>
                    <button
                      onClick={() => handleEdit(infraction.id)}
                      className="text-indigo-600 hover:text-indigo-900 p-1 rounded hover:bg-indigo-50 transition-colors"
                      title="Editar infracción"
                    >
                      <PencilIcon className="h-5 w-5" />
                    </button>
                    <button
                      onClick={() => handleDelete(infraction.id, infraction.type)}
                      disabled={isDeleting === infraction.id}
                      className="text-red-600 hover:text-red-900 p-1 rounded hover:bg-red-50 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                      title="Eliminar infracción"
                    >
                      <TrashIcon className="h-5 w-5" />
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function getStatusColor(status: string): string {
  const colors: Record<string, string> = {
    pendiente: 'bg-yellow-100 text-yellow-800',
    pagada: 'bg-green-100 text-green-800',
    anulada: 'bg-gray-100 text-gray-800',
  };
  return colors[status] || 'bg-gray-100 text-gray-800';
}
