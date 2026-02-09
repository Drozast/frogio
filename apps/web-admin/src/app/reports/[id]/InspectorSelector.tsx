'use client';

import { UserIcon, CheckCircleIcon } from '@heroicons/react/24/outline';

interface InspectorSelectorProps {
  reportId: string;
  inspectors: any[];
  currentInspectorId?: string;
  currentInspectorName?: string;
}

export default function InspectorSelector({
  currentInspectorName,
}: InspectorSelectorProps) {
  return (
    <div className="bg-white rounded-lg shadow p-6">
      <h2 className="text-lg font-semibold text-gray-900 mb-4 flex items-center gap-2">
        <UserIcon className="h-5 w-5 text-gray-500" />
        Inspector que Atendió
      </h2>

      {currentInspectorName ? (
        <div className="flex items-center gap-3">
          <div className="h-12 w-12 rounded-full bg-green-100 flex items-center justify-center">
            <span className="text-green-600 font-semibold text-lg">
              {currentInspectorName.split(' ').map(n => n.charAt(0)).join('').slice(0, 2)}
            </span>
          </div>
          <div className="flex-1">
            <p className="font-medium text-gray-900">{currentInspectorName}</p>
            <p className="text-sm text-green-600 flex items-center gap-1">
              <CheckCircleIcon className="h-4 w-4" />
              Caso atendido
            </p>
          </div>
        </div>
      ) : (
        <div className="bg-gray-50 border border-gray-200 rounded-lg p-4 text-center">
          <UserIcon className="h-8 w-8 text-gray-400 mx-auto mb-2" />
          <p className="text-sm text-gray-500">Sin inspector asignado</p>
          <p className="text-xs text-gray-400 mt-1">
            El caso aún no ha sido atendido
          </p>
        </div>
      )}
    </div>
  );
}
