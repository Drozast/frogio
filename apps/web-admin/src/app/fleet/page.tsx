'use client';

import { useState, useEffect } from 'react';
import dynamic from 'next/dynamic';
import AppLayout from '@/components/layout/AppLayout';
import VehicleList from '@/components/fleet/VehicleList';
import GeofenceAlerts from '@/components/fleet/GeofenceAlerts';
import { useFleetSocket, VehiclePosition } from '@/hooks/useFleetSocket';
import {
  TruckIcon,
  SignalIcon,
  SignalSlashIcon,
  MapIcon,
  ClockIcon,
  ChartBarIcon,
} from '@heroicons/react/24/outline';
import Link from 'next/link';

// Dynamic import for the map component (client-side only)
const FleetMap = dynamic(() => import('@/components/fleet/FleetMap'), {
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
  geofence_type: 'circle' | 'polygon';
  center_lat?: number;
  center_lng?: number;
  radius_meters?: number;
  polygon_coordinates?: { lat: number; lng: number }[];
  is_active: boolean;
}

export default function FleetPage() {
  const { isConnected, vehicles, geofenceEvents, error } = useFleetSocket();
  const [selectedVehicleId, setSelectedVehicleId] = useState<string | null>(null);
  const [geofences, setGeofences] = useState<Geofence[]>([]);
  const [showGeofences, setShowGeofences] = useState(true);
  const [initialPositions, setInitialPositions] = useState<Map<string, VehiclePosition>>(new Map());

  // Fetch initial positions and geofences
  useEffect(() => {
    async function fetchInitialData() {
      try {
        // Fetch live positions
        const posResponse = await fetch('/api/fleet/live');
        if (posResponse.ok) {
          const positions = await posResponse.json();
          const posMap = new Map<string, VehiclePosition>();
          positions.forEach((pos: VehiclePosition) => {
            posMap.set(pos.vehicleId, pos);
          });
          setInitialPositions(posMap);
        }

        // Fetch geofences
        const geoResponse = await fetch('/api/geofences?active=true');
        if (geoResponse.ok) {
          const geoData = await geoResponse.json();
          setGeofences(geoData);
        }
      } catch (err) {
        console.error('Error fetching initial data:', err);
      }
    }

    fetchInitialData();
  }, []);

  // Merge initial positions with socket updates
  const mergedVehicles = new Map(initialPositions);
  vehicles.forEach((v, k) => mergedVehicles.set(k, v));

  const activeCount = mergedVehicles.size;

  // Transform geofences for the map component
  const mapGeofences = geofences.map(g => ({
    id: g.id,
    name: g.name,
    geofenceType: g.geofence_type,
    centerLat: g.center_lat,
    centerLng: g.center_lng,
    radiusMeters: g.radius_meters,
    polygonCoordinates: g.polygon_coordinates,
    isActive: g.is_active,
  }));

  return (
    <AppLayout>
      <div className="h-[calc(100vh-4rem)] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Flota GPS</h1>
            <p className="text-sm text-gray-500">
              Seguimiento en tiempo real de vehículos municipales
            </p>
          </div>
          <div className="flex items-center gap-4">
            {/* Connection Status */}
            <div className={`flex items-center gap-2 px-3 py-1.5 rounded-full text-sm ${
              isConnected ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
            }`}>
              {isConnected ? (
                <SignalIcon className="h-4 w-4" />
              ) : (
                <SignalSlashIcon className="h-4 w-4" />
              )}
              {isConnected ? 'Conectado' : 'Desconectado'}
            </div>

            {/* Navigation Links */}
            <Link
              href="/fleet/history"
              className="flex items-center gap-2 px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <ClockIcon className="h-4 w-4" />
              Historial
            </Link>
            <Link
              href="/fleet/stats"
              className="flex items-center gap-2 px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <ChartBarIcon className="h-4 w-4" />
              Estadísticas
            </Link>
            <Link
              href="/fleet/geofences"
              className="flex items-center gap-2 px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <MapIcon className="h-4 w-4" />
              Zonas
            </Link>
          </div>
        </div>

        {/* Error Banner */}
        {error && (
          <div className="mb-4 p-3 bg-red-50 text-red-700 rounded-lg text-sm">
            {error}
          </div>
        )}

        {/* Main Content */}
        <div className="flex-1 grid grid-cols-1 lg:grid-cols-4 gap-4 min-h-0">
          {/* Left Panel - Vehicle List */}
          <div className="lg:col-span-1 bg-white rounded-lg shadow overflow-hidden flex flex-col">
            <div className="p-4 border-b bg-gray-50">
              <div className="flex items-center justify-between">
                <h2 className="font-semibold text-gray-900">Vehículos Activos</h2>
                <span className="inline-flex items-center justify-center w-6 h-6 bg-indigo-100 text-indigo-800 text-xs font-medium rounded-full">
                  {activeCount}
                </span>
              </div>
            </div>
            <div className="flex-1 overflow-y-auto">
              <VehicleList
                vehicles={mergedVehicles}
                selectedVehicleId={selectedVehicleId}
                onVehicleSelect={setSelectedVehicleId}
              />
            </div>
          </div>

          {/* Center - Map */}
          <div className="lg:col-span-2 bg-white rounded-lg shadow overflow-hidden">
            <div className="h-full">
              <FleetMap
                vehicles={mergedVehicles}
                selectedVehicleId={selectedVehicleId}
                onVehicleClick={setSelectedVehicleId}
                geofences={mapGeofences}
                showGeofences={showGeofences}
              />
            </div>
          </div>

          {/* Right Panel - Geofence Events & Stats */}
          <div className="lg:col-span-1 flex flex-col gap-4">
            {/* Quick Stats */}
            <div className="bg-white rounded-lg shadow p-4">
              <h3 className="font-semibold text-gray-900 mb-3">Resumen</h3>
              <div className="grid grid-cols-2 gap-3">
                <div className="p-3 bg-green-50 rounded-lg">
                  <p className="text-xs text-green-600 font-medium">En Movimiento</p>
                  <p className="text-2xl font-bold text-green-700">
                    {Array.from(mergedVehicles.values()).filter(v => v.status === 'moving').length}
                  </p>
                </div>
                <div className="p-3 bg-red-50 rounded-lg">
                  <p className="text-xs text-red-600 font-medium">Detenidos</p>
                  <p className="text-2xl font-bold text-red-700">
                    {Array.from(mergedVehicles.values()).filter(v => v.status === 'stopped').length}
                  </p>
                </div>
              </div>
            </div>

            {/* Geofence Toggle */}
            <div className="bg-white rounded-lg shadow p-4">
              <div className="flex items-center justify-between">
                <h3 className="font-semibold text-gray-900">Zonas Geofencing</h3>
                <label className="flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={showGeofences}
                    onChange={(e) => setShowGeofences(e.target.checked)}
                    className="sr-only"
                  />
                  <div className={`w-10 h-6 rounded-full transition-colors ${
                    showGeofences ? 'bg-indigo-600' : 'bg-gray-300'
                  }`}>
                    <div className={`w-4 h-4 rounded-full bg-white shadow transform transition-transform mt-1 ${
                      showGeofences ? 'translate-x-5' : 'translate-x-1'
                    }`} />
                  </div>
                </label>
              </div>
              <p className="text-xs text-gray-500 mt-1">
                {geofences.length} zona{geofences.length !== 1 ? 's' : ''} configurada{geofences.length !== 1 ? 's' : ''}
              </p>
            </div>

            {/* Geofence Events */}
            <div className="bg-white rounded-lg shadow overflow-hidden flex-1 flex flex-col">
              <div className="p-4 border-b bg-gray-50">
                <h3 className="font-semibold text-gray-900">Alertas Recientes</h3>
              </div>
              <div className="flex-1 overflow-y-auto">
                <GeofenceAlerts events={geofenceEvents} />
              </div>
            </div>
          </div>
        </div>
      </div>
    </AppLayout>
  );
}
