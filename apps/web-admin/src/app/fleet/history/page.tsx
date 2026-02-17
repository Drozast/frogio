'use client';

import { useState, useEffect, useCallback } from 'react';
import dynamic from 'next/dynamic';
import AppLayout from '@/components/layout/AppLayout';
import Link from 'next/link';
import {
  ArrowLeftIcon,
  TruckIcon,
  ClockIcon,
  MapPinIcon,
} from '@heroicons/react/24/outline';
import ActivityCalendar from '@/components/fleet/ActivityCalendar';

const RouteMap = dynamic(() => import('@/components/fleet/RouteMap'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-full flex items-center justify-center bg-gray-100 rounded-lg">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600" />
    </div>
  ),
});

interface Vehicle {
  id: string;
  plate: string;
  brand: string;
  model: string;
}

interface RoutePoint {
  latitude: number;
  longitude: number;
  speed: number | null;
  recorded_at: string;
}

interface RouteData {
  points: RoutePoint[];
  totalDistance: number;
  avgSpeed: number;
  maxSpeed: number;
  startTime: string;
  endTime: string;
}

export default function FleetHistoryPage() {
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [selectedVehicle, setSelectedVehicle] = useState<string>('');
  const [selectedDate, setSelectedDate] = useState<string>(
    new Date().toISOString().split('T')[0]
  );
  const [routeData, setRouteData] = useState<RouteData | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchVehicles();
  }, []);

  async function fetchVehicles() {
    try {
      const response = await fetch('/api/vehicles');
      if (response.ok) {
        const data = await response.json();
        setVehicles(data);
      }
    } catch (error) {
      console.error('Error fetching vehicles:', error);
    }
  }

  const fetchRoute = useCallback(async () => {
    if (!selectedVehicle || !selectedDate) return;

    setLoading(true);
    try {
      const startDate = `${selectedDate}T00:00:00`;
      const endDate = `${selectedDate}T23:59:59`;

      const response = await fetch(
        `/api/fleet/history?vehicleId=${selectedVehicle}&startDate=${startDate}&endDate=${endDate}`
      );

      if (response.ok) {
        const data = await response.json();
        setRouteData(data);
      } else {
        setRouteData(null);
      }
    } catch (error) {
      console.error('Error fetching route:', error);
      setRouteData(null);
    } finally {
      setLoading(false);
    }
  }, [selectedVehicle, selectedDate]);

  // Auto-fetch when vehicle and date are selected
  useEffect(() => {
    if (selectedVehicle && selectedDate) {
      fetchRoute();
    }
  }, [selectedVehicle, selectedDate, fetchRoute]);

  const selectedVehicleData = vehicles.find(v => v.id === selectedVehicle);

  return (
    <AppLayout>
      <div className="h-[calc(100vh-4rem)] flex flex-col">
        {/* Header */}
        <div className="flex items-center gap-4 mb-4">
          <Link
            href="/fleet"
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <ArrowLeftIcon className="h-5 w-5 text-gray-600" />
          </Link>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Historial de Rutas</h1>
            <p className="text-sm text-gray-500">
              Consulta las rutas recorridas por vehículo y fecha
            </p>
          </div>
        </div>

        <div className="flex-1 grid grid-cols-1 lg:grid-cols-4 gap-4 min-h-0">
          {/* Left Panel - Filters */}
          <div className="lg:col-span-1 bg-white rounded-lg shadow p-4 space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                <TruckIcon className="h-4 w-4 inline mr-1" />
                Vehículo
              </label>
              <select
                value={selectedVehicle}
                onChange={(e) => setSelectedVehicle(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              >
                <option value="">Seleccionar vehículo...</option>
                {vehicles.map((vehicle) => (
                  <option key={vehicle.id} value={vehicle.id}>
                    {vehicle.plate} - {vehicle.brand} {vehicle.model}
                  </option>
                ))}
              </select>
            </div>

            {/* Activity Calendar */}
            <ActivityCalendar
              vehicleId={selectedVehicle}
              selectedDate={selectedDate}
              onDateSelect={(date) => setSelectedDate(date)}
            />

            {loading && (
              <div className="flex items-center justify-center py-2">
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-indigo-600" />
                <span className="ml-2 text-sm text-gray-500">Cargando ruta...</span>
              </div>
            )}

            {/* Route Stats */}
            {routeData && (
              <div className="pt-4 border-t space-y-3">
                <h3 className="font-semibold text-gray-900">Estadísticas del Día</h3>

                <div className="grid grid-cols-2 gap-3">
                  <div className="p-3 bg-gray-50 rounded-lg">
                    <p className="text-xs text-gray-500">Distancia</p>
                    <p className="text-lg font-bold text-gray-900">
                      {routeData.totalDistance.toFixed(1)} km
                    </p>
                  </div>
                  <div className="p-3 bg-gray-50 rounded-lg">
                    <p className="text-xs text-gray-500">Vel. Promedio</p>
                    <p className="text-lg font-bold text-gray-900">
                      {routeData.avgSpeed.toFixed(0)} km/h
                    </p>
                  </div>
                  <div className="p-3 bg-gray-50 rounded-lg">
                    <p className="text-xs text-gray-500">Vel. Máxima</p>
                    <p className="text-lg font-bold text-gray-900">
                      {routeData.maxSpeed.toFixed(0)} km/h
                    </p>
                  </div>
                  <div className="p-3 bg-gray-50 rounded-lg">
                    <p className="text-xs text-gray-500">Puntos GPS</p>
                    <p className="text-lg font-bold text-gray-900">
                      {routeData.points.length}
                    </p>
                  </div>
                </div>

                {routeData.startTime && routeData.endTime && (
                  <div className="p-3 bg-indigo-50 rounded-lg">
                    <p className="text-xs text-indigo-600 font-medium flex items-center gap-1">
                      <ClockIcon className="h-3 w-3" />
                      Período de Actividad
                    </p>
                    <p className="text-sm text-indigo-900 mt-1">
                      {new Date(routeData.startTime).toLocaleTimeString('es-CL', {
                        hour: '2-digit',
                        minute: '2-digit',
                      })} - {new Date(routeData.endTime).toLocaleTimeString('es-CL', {
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </p>
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Map */}
          <div className="lg:col-span-3 bg-white rounded-lg shadow overflow-hidden">
            {routeData && routeData.points.length > 0 ? (
              <RouteMap
                points={routeData.points}
                vehiclePlate={selectedVehicleData?.plate || ''}
              />
            ) : (
              <div className="h-full flex flex-col items-center justify-center text-gray-500">
                <MapPinIcon className="h-12 w-12 text-gray-300 mb-3" />
                <p className="text-sm">
                  {!selectedVehicle
                    ? 'Selecciona un vehículo para ver su historial'
                    : routeData === null
                    ? 'No hay datos de ruta para la fecha seleccionada'
                    : 'Selecciona un vehículo y fecha para consultar'
                  }
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </AppLayout>
  );
}
