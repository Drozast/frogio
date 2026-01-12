'use client';

import { useState, useEffect } from 'react';
import AppLayout from '@/components/layout/AppLayout';
import Link from 'next/link';
import {
  ArrowLeftIcon,
  CalendarIcon,
  TruckIcon,
  UserIcon,
  ChartBarIcon,
} from '@heroicons/react/24/outline';

interface VehicleStats {
  vehicleId: string;
  vehiclePlate: string;
  vehicleBrand: string;
  vehicleModel: string;
  totalDistanceKm: number;
  totalTrips: number;
  totalPoints: number;
  avgSpeed: number;
  maxSpeed: number;
}

interface InspectorStats {
  inspectorId: string;
  inspectorName: string;
  totalDistanceKm: number;
  totalTrips: number;
  vehiclesUsed: number;
}

interface StatsData {
  byVehicle: VehicleStats[];
  byInspector: InspectorStats[];
  totals: {
    totalDistance: number;
    totalTrips: number;
    totalPoints: number;
  };
}

export default function FleetStatsPage() {
  const [stats, setStats] = useState<StatsData | null>(null);
  const [loading, setLoading] = useState(true);
  const [dateRange, setDateRange] = useState({
    start: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    end: new Date().toISOString().split('T')[0],
  });
  const [viewMode, setViewMode] = useState<'vehicle' | 'inspector'>('vehicle');

  useEffect(() => {
    fetchStats();
  }, [dateRange]);

  async function fetchStats() {
    setLoading(true);
    try {
      const response = await fetch(
        `/api/fleet/stats?startDate=${dateRange.start}&endDate=${dateRange.end}`
      );
      if (response.ok) {
        const data = await response.json();
        setStats(data);
      }
    } catch (error) {
      console.error('Error fetching stats:', error);
    } finally {
      setLoading(false);
    }
  }

  return (
    <AppLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-4">
            <Link
              href="/fleet"
              className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
            >
              <ArrowLeftIcon className="h-5 w-5 text-gray-600" />
            </Link>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">Estadísticas de Flota</h1>
              <p className="text-sm text-gray-500">
                Análisis de kilómetros y uso de vehículos
              </p>
            </div>
          </div>
        </div>

        {/* Date Filters */}
        <div className="bg-white rounded-lg shadow p-4">
          <div className="flex flex-wrap items-end gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                <CalendarIcon className="h-4 w-4 inline mr-1" />
                Desde
              </label>
              <input
                type="date"
                value={dateRange.start}
                onChange={(e) => setDateRange(prev => ({ ...prev, start: e.target.value }))}
                className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Hasta
              </label>
              <input
                type="date"
                value={dateRange.end}
                onChange={(e) => setDateRange(prev => ({ ...prev, end: e.target.value }))}
                max={new Date().toISOString().split('T')[0]}
                className="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500"
              />
            </div>
            <div className="flex gap-2 ml-auto">
              <button
                onClick={() => setViewMode('vehicle')}
                className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
                  viewMode === 'vehicle'
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                <TruckIcon className="h-4 w-4 inline mr-1" />
                Por Vehículo
              </button>
              <button
                onClick={() => setViewMode('inspector')}
                className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
                  viewMode === 'inspector'
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                <UserIcon className="h-4 w-4 inline mr-1" />
                Por Inspector
              </button>
            </div>
          </div>
        </div>

        {/* Summary Cards */}
        {stats?.totals && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center gap-3">
                <div className="p-3 bg-indigo-100 rounded-full">
                  <ChartBarIcon className="h-6 w-6 text-indigo-600" />
                </div>
                <div>
                  <p className="text-sm text-gray-500">Distancia Total</p>
                  <p className="text-2xl font-bold text-gray-900">
                    {stats.totals.totalDistance.toFixed(1)} km
                  </p>
                </div>
              </div>
            </div>
            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center gap-3">
                <div className="p-3 bg-green-100 rounded-full">
                  <TruckIcon className="h-6 w-6 text-green-600" />
                </div>
                <div>
                  <p className="text-sm text-gray-500">Total Viajes</p>
                  <p className="text-2xl font-bold text-gray-900">
                    {stats.totals.totalTrips}
                  </p>
                </div>
              </div>
            </div>
            <div className="bg-white rounded-lg shadow p-6">
              <div className="flex items-center gap-3">
                <div className="p-3 bg-blue-100 rounded-full">
                  <svg className="h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Puntos GPS</p>
                  <p className="text-2xl font-bold text-gray-900">
                    {stats.totals.totalPoints.toLocaleString()}
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Stats Table */}
        {loading ? (
          <div className="bg-white rounded-lg shadow p-8 flex items-center justify-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600" />
          </div>
        ) : viewMode === 'vehicle' ? (
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Vehículo
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">
                    Distancia
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">
                    Viajes
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">
                    Vel. Prom.
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">
                    Vel. Máx.
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {stats?.byVehicle.map((vehicle) => (
                  <tr key={vehicle.vehicleId} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center gap-3">
                        <div className="p-2 bg-gray-100 rounded-full">
                          <TruckIcon className="h-5 w-5 text-gray-600" />
                        </div>
                        <div>
                          <p className="text-sm font-medium text-gray-900 uppercase">
                            {vehicle.vehiclePlate}
                          </p>
                          <p className="text-xs text-gray-500">
                            {vehicle.vehicleBrand} {vehicle.vehicleModel}
                          </p>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm text-gray-900 font-medium">
                      {vehicle.totalDistanceKm.toFixed(1)} km
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm text-gray-500">
                      {vehicle.totalTrips}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm text-gray-500">
                      {vehicle.avgSpeed.toFixed(0)} km/h
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm text-gray-500">
                      {vehicle.maxSpeed.toFixed(0)} km/h
                    </td>
                  </tr>
                ))}
                {(!stats?.byVehicle || stats.byVehicle.length === 0) && (
                  <tr>
                    <td colSpan={5} className="px-6 py-8 text-center text-gray-500">
                      No hay datos para el período seleccionado
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        ) : (
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                    Inspector
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">
                    Distancia
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">
                    Viajes
                  </th>
                  <th className="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase">
                    Vehículos
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {stats?.byInspector.map((inspector) => (
                  <tr key={inspector.inspectorId} className="hover:bg-gray-50">
                    <td className="px-6 py-4 whitespace-nowrap">
                      <div className="flex items-center gap-3">
                        <div className="p-2 bg-indigo-100 rounded-full">
                          <UserIcon className="h-5 w-5 text-indigo-600" />
                        </div>
                        <p className="text-sm font-medium text-gray-900">
                          {inspector.inspectorName}
                        </p>
                      </div>
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm text-gray-900 font-medium">
                      {inspector.totalDistanceKm.toFixed(1)} km
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm text-gray-500">
                      {inspector.totalTrips}
                    </td>
                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm text-gray-500">
                      {inspector.vehiclesUsed}
                    </td>
                  </tr>
                ))}
                {(!stats?.byInspector || stats.byInspector.length === 0) && (
                  <tr>
                    <td colSpan={4} className="px-6 py-8 text-center text-gray-500">
                      No hay datos para el período seleccionado
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </AppLayout>
  );
}
