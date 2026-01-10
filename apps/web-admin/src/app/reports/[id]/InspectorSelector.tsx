'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { UserIcon, UserCircleIcon, XMarkIcon, PencilSquareIcon } from '@heroicons/react/24/outline';

interface Inspector {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  isActive?: boolean;
}

interface InspectorSelectorProps {
  reportId: string;
  inspectors: Inspector[];
  currentInspectorId?: string;
  currentInspectorName?: string;
}

export default function InspectorSelector({
  reportId,
  inspectors,
  currentInspectorId,
  currentInspectorName,
}: InspectorSelectorProps) {
  const router = useRouter();
  const [modalOpen, setModalOpen] = useState(false);
  const [assigning, setAssigning] = useState(false);

  // Agrupar inspectores por estado activo/inactivo
  const activeInspectors = inspectors.filter(i => i.isActive !== false);
  const inactiveInspectors = inspectors.filter(i => i.isActive === false);

  const handleAssignInspector = async (inspectorId: string) => {
    setAssigning(true);
    try {
      const response = await fetch(`/api/reports/${reportId}/assign`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ assigned_to: inspectorId }),
      });

      if (response.ok) {
        setModalOpen(false);
        router.refresh();
      } else {
        alert('Error al asignar el inspector');
      }
    } catch (error) {
      console.error('Error assigning inspector:', error);
      alert('Error al asignar el inspector');
    } finally {
      setAssigning(false);
    }
  };

  const handleRemoveInspector = async () => {
    if (!confirm('¿Estás seguro de quitar el inspector asignado?')) return;

    setAssigning(true);
    try {
      const response = await fetch(`/api/reports/${reportId}/assign`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ assigned_to: null }),
      });

      if (response.ok) {
        router.refresh();
      } else {
        alert('Error al quitar el inspector');
      }
    } catch (error) {
      console.error('Error removing inspector:', error);
      alert('Error al quitar el inspector');
    } finally {
      setAssigning(false);
    }
  };

  return (
    <>
      {/* Card de Inspector Asignado */}
      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
          <UserIcon className="h-5 w-5 text-gray-500" />
          Inspector Asignado
        </h2>

        {currentInspectorName ? (
          <div className="space-y-3">
            <div className="flex items-center gap-3">
              <div className="h-12 w-12 rounded-full bg-green-100 flex items-center justify-center">
                <span className="text-green-600 font-semibold text-lg">
                  {currentInspectorName.split(' ').map(n => n.charAt(0)).join('').slice(0, 2)}
                </span>
              </div>
              <div className="flex-1">
                <p className="font-medium text-gray-900">{currentInspectorName}</p>
                <p className="text-sm text-green-600">Asignado</p>
              </div>
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => setModalOpen(true)}
                className="flex-1 flex items-center justify-center gap-1 px-3 py-2 text-sm font-medium text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-lg transition-colors"
              >
                <PencilSquareIcon className="h-4 w-4" />
                Cambiar
              </button>
              <button
                onClick={handleRemoveInspector}
                disabled={assigning}
                className="flex-1 flex items-center justify-center gap-1 px-3 py-2 text-sm font-medium text-red-600 bg-red-50 hover:bg-red-100 rounded-lg transition-colors disabled:opacity-50"
              >
                <XMarkIcon className="h-4 w-4" />
                Quitar
              </button>
            </div>
          </div>
        ) : (
          <div className="space-y-3">
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 text-center">
              <p className="text-sm text-yellow-800">Sin inspector asignado</p>
            </div>
            <button
              onClick={() => setModalOpen(true)}
              className="w-full flex items-center justify-center gap-2 px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg transition-colors"
            >
              <UserCircleIcon className="h-5 w-5" />
              Asignar Inspector
            </button>
          </div>
        )}
      </div>

      {/* Modal de Asignar Inspector */}
      {modalOpen && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          <div className="flex min-h-full items-center justify-center p-4">
            <div
              className="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"
              onClick={() => setModalOpen(false)}
            />

            <div className="relative bg-white rounded-lg shadow-xl max-w-md w-full p-6">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-lg font-semibold text-gray-900">Asignar Inspector</h3>
                <button
                  onClick={() => setModalOpen(false)}
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
                          disabled={assigning || inspector.id === currentInspectorId}
                          className={`w-full flex items-center gap-3 px-4 py-3 hover:bg-green-50 transition-colors disabled:opacity-50 text-left ${
                            inspector.id === currentInspectorId ? 'bg-green-50' : ''
                          }`}
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
                          {inspector.id === currentInspectorId ? (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                              Asignado
                            </span>
                          ) : (
                            <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-green-100 text-green-800">
                              Disponible
                            </span>
                          )}
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
                          disabled={assigning}
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
                  onClick={() => setModalOpen(false)}
                  className="px-4 py-2 text-sm font-medium text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-md"
                >
                  Cancelar
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
