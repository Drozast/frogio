'use client';

import { useState, useEffect } from 'react';
import dynamic from 'next/dynamic';
import AppLayout from '@/components/layout/AppLayout';
import Link from 'next/link';
import {
  ArrowLeftIcon,
  PlusIcon,
  TrashIcon,
  PencilIcon,
  MapPinIcon,
} from '@heroicons/react/24/outline';

const GeofenceEditor = dynamic(() => import('@/components/fleet/GeofenceEditor'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-full flex items-center justify-center bg-gray-100 rounded-lg">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600" />
    </div>
  ),
});

interface Geofence {
  id: string;
  name: string;
  description: string | null;
  geofence_type: 'circle' | 'polygon';
  center_lat: number | null;
  center_lng: number | null;
  radius_meters: number | null;
  polygon_coordinates: { lat: number; lng: number }[] | null;
  is_active: boolean;
  alert_on_enter: boolean;
  alert_on_exit: boolean;
  created_at: string;
}

export default function GeofencesPage() {
  const [geofences, setGeofences] = useState<Geofence[]>([]);
  const [loading, setLoading] = useState(true);
  const [showEditor, setShowEditor] = useState(false);
  const [editingGeofence, setEditingGeofence] = useState<Geofence | null>(null);
  const [selectedGeofenceId, setSelectedGeofenceId] = useState<string | null>(null);

  useEffect(() => {
    fetchGeofences();
  }, []);

  async function fetchGeofences() {
    try {
      const response = await fetch('/api/geofences');
      if (response.ok) {
        const data = await response.json();
        setGeofences(data);
      }
    } catch (error) {
      console.error('Error fetching geofences:', error);
    } finally {
      setLoading(false);
    }
  }

  async function handleDelete(id: string) {
    if (!confirm('¿Está seguro de eliminar esta zona? Esta acción no se puede deshacer.')) {
      return;
    }

    try {
      const response = await fetch(`/api/geofences/${id}`, {
        method: 'DELETE',
      });

      if (response.ok) {
        setGeofences(prev => prev.filter(g => g.id !== id));
        if (selectedGeofenceId === id) {
          setSelectedGeofenceId(null);
        }
      }
    } catch (error) {
      console.error('Error deleting geofence:', error);
    }
  }

  async function handleSave(data: {
    name: string;
    description?: string;
    geofenceType: 'circle' | 'polygon';
    centerLat?: number;
    centerLng?: number;
    radiusMeters?: number;
    polygonCoordinates?: { lat: number; lng: number }[];
    alertOnEnter: boolean;
    alertOnExit: boolean;
  }) {
    try {
      const response = await fetch('/api/geofences', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
      });

      if (response.ok) {
        const newGeofence = await response.json();
        setGeofences(prev => [...prev, newGeofence]);
        setShowEditor(false);
      }
    } catch (error) {
      console.error('Error saving geofence:', error);
    }
  }

  const selectedGeofence = geofences.find(g => g.id === selectedGeofenceId);

  return (
    <AppLayout>
      <div className="h-[calc(100vh-4rem)] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-4">
            <Link
              href="/fleet"
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <ArrowLeftIcon className="h-5 w-5 text-gray-600" />
            </Link>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Zonas Geofencing</h1>
              <p className="text-sm text-gray-500">
                Define zonas para recibir alertas cuando vehículos entren o salgan
              </p>
            </div>
          </div>
          <button
            onClick={() => setShowEditor(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors"
          >
            <PlusIcon className="h-4 w-4" />
            Nueva Zona
          </button>
        </div>

        <div className="flex-1 grid grid-cols-1 lg:grid-cols-3 gap-4 min-h-0">
          {/* Left Panel - Geofence List */}
          <div className="lg:col-span-1 bg-white rounded-lg shadow overflow-hidden flex flex-col">
            <div className="p-4 border-b bg-gray-50">
              <h2 className="font-semibold text-gray-900">Zonas Configuradas</h2>
              <p className="text-xs text-gray-500 mt-1">
                {geofences.length} zona{geofences.length !== 1 ? 's' : ''}
              </p>
            </div>
            <div className="flex-1 overflow-y-auto">
              {loading ? (
                <div className="flex items-center justify-center py-8">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600" />
                </div>
              ) : geofences.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-8 text-gray-500">
                  <MapPinIcon className="h-12 w-12 text-gray-300 mb-2" />
                  <p className="text-sm">No hay zonas configuradas</p>
                  <button
                    onClick={() => setShowEditor(true)}
                    className="mt-3 text-sm text-indigo-600 hover:text-indigo-800"
                  >
                    Crear primera zona
                  </button>
                </div>
              ) : (
                <div className="divide-y divide-gray-100">
                  {geofences.map((geofence) => (
                    <div
                      key={geofence.id}
                      className={`p-4 cursor-pointer hover:bg-gray-50 transition-colors ${
                        selectedGeofenceId === geofence.id ? 'bg-indigo-50 border-l-4 border-indigo-600' : ''
                      }`}
                      onClick={() => setSelectedGeofenceId(geofence.id)}
                    >
                      <div className="flex items-start justify-between">
                        <div className="flex-1 min-w-0">
                          <div className="flex items-center gap-2">
                            <p className="text-sm font-medium text-gray-900 truncate">
                              {geofence.name}
                            </p>
                            {!geofence.is_active && (
                              <span className="px-1.5 py-0.5 text-xs bg-gray-100 text-gray-600 rounded">
                                Inactiva
                              </span>
                            )}
                          </div>
                          <p className="text-xs text-gray-500 mt-1">
                            {geofence.geofence_type === 'circle'
                              ? `Círculo - ${geofence.radius_meters}m radio`
                              : `Polígono - ${geofence.polygon_coordinates?.length || 0} puntos`
                            }
                          </p>
                          <div className="flex gap-2 mt-1 text-xs">
                            {geofence.alert_on_enter && (
                              <span className="text-green-600">Entrada</span>
                            )}
                            {geofence.alert_on_exit && (
                              <span className="text-red-600">Salida</span>
                            )}
                          </div>
                        </div>
                        <div className="flex items-center gap-1 ml-2">
                          <button
                            onClick={(e) => {
                              e.stopPropagation();
                              handleDelete(geofence.id);
                            }}
                            className="p-1.5 text-red-600 hover:bg-red-50 rounded transition-colors"
                            title="Eliminar"
                          >
                            <TrashIcon className="h-4 w-4" />
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Map / Editor */}
          <div className="lg:col-span-2 bg-white rounded-lg shadow overflow-hidden">
            {showEditor ? (
              <GeofenceEditor
                onSave={handleSave}
                onCancel={() => setShowEditor(false)}
              />
            ) : (
              <GeofenceEditor
                geofences={geofences}
                selectedGeofenceId={selectedGeofenceId}
                readOnly
              />
            )}
          </div>
        </div>
      </div>
    </AppLayout>
  );
}
