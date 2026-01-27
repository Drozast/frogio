'use client';

import { useState, useEffect, useCallback, useMemo } from 'react';
import dynamic from 'next/dynamic';
import AppLayout from '@/components/layout/AppLayout';
import { useAutoRefresh } from '@/hooks/useAutoRefresh';
import {
  ArrowPathIcon,
  ExclamationTriangleIcon,
  MapPinIcon,
  TruckIcon,
  UserIcon,
  FunnelIcon,
  XMarkIcon,
} from '@heroicons/react/24/outline';

// Dynamically import the map component to avoid SSR issues
const LiveMapComponent = dynamic(
  () => import('@/components/map/LiveMapComponent'),
  {
    ssr: false,
    loading: () => (
      <div className="flex items-center justify-center h-full bg-gray-100 rounded-xl">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    ),
  }
);

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

interface Report {
  id: string;
  title: string;
  type: string;
  status: string;
  priority: string;
  latitude: number | null;
  longitude: number | null;
  address?: string;
  created_at: string;
}

interface Inspector {
  id: string;
  first_name: string;
  last_name: string;
  latitude?: number;
  longitude?: number;
  last_location_update?: string;
  is_active: boolean;
}

interface Vehicle {
  id: string;
  plate: string;
  model: string;
  latitude?: number;
  longitude?: number;
  last_location_update?: string;
  current_user_name?: string;
  status: string;
}

interface PanicAlert {
  id: string;
  user_id: string;
  first_name?: string;
  last_name?: string;
  latitude: number;
  longitude: number;
  address?: string;
  message?: string;
  status: string;
  created_at: string;
}

interface MapData {
  reports: Report[];
  inspectors: Inspector[];
  vehicles: Vehicle[];
  panicAlerts: PanicAlert[];
}

export default function LiveMapPage() {
  const [data, setData] = useState<MapData>({
    reports: [],
    inspectors: [],
    vehicles: [],
    panicAlerts: [],
  });
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [lastUpdate, setLastUpdate] = useState(new Date());
  const [filters, setFilters] = useState({
    showReports: true,
    showInspectors: true,
    showVehicles: true,
    showPanicAlerts: true,
    reportStatus: '',
  });
  const [showFilters, setShowFilters] = useState(false);

  const fetchData = useCallback(async () => {
    try {
      setIsRefreshing(true);
      const token = document.cookie
        .split('; ')
        .find(row => row.startsWith('accessToken='))
        ?.split('=')[1];

      if (!token) return;

      const headers = {
        'Authorization': `Bearer ${token}`,
        'X-Tenant-ID': 'santa_juana',
      };

      const [reportsRes, usersRes, vehiclesRes, panicRes] = await Promise.all([
        fetch(`${API_URL}/api/reports`, { headers }),
        fetch(`${API_URL}/api/users?role=inspector`, { headers }),
        fetch(`${API_URL}/api/vehicles`, { headers }),
        fetch(`${API_URL}/api/panic/active`, { headers }).catch(() => ({ ok: false })),
      ]);

      const reports = reportsRes.ok ? await reportsRes.json() : data.reports;
      const inspectors = usersRes.ok ? await usersRes.json() : data.inspectors;
      const vehicles = vehiclesRes.ok ? await vehiclesRes.json() : data.vehicles;
      const panicAlerts = panicRes.ok ? await (panicRes as Response).json() : data.panicAlerts;

      setData({ reports, inspectors, vehicles, panicAlerts });
      setLastUpdate(new Date());
    } catch (error) {
      console.error('Error fetching map data:', error);
    } finally {
      setIsRefreshing(false);
    }
  }, [data]);

  // Initial fetch
  useEffect(() => {
    fetchData();
  }, []);

  // Auto-refresh every 3 seconds
  useAutoRefresh(fetchData, { interval: 3000 });

  // Filter data for map
  const filteredData = useMemo(() => {
    return {
      reports: filters.showReports
        ? data.reports.filter(r =>
            r.latitude && r.longitude &&
            (!filters.reportStatus || r.status === filters.reportStatus)
          )
        : [],
      inspectors: filters.showInspectors
        ? data.inspectors.filter(i => i.latitude && i.longitude && i.is_active)
        : [],
      vehicles: filters.showVehicles
        ? data.vehicles.filter(v => v.latitude && v.longitude)
        : [],
      panicAlerts: filters.showPanicAlerts
        ? data.panicAlerts.filter(p => p.status === 'active' || p.status === 'responding')
        : [],
    };
  }, [data, filters]);

  // Stats
  const stats = useMemo(() => ({
    totalReports: data.reports.filter(r => r.latitude && r.longitude).length,
    pendingReports: data.reports.filter(r => r.latitude && r.longitude && r.status === 'pendiente').length,
    activeInspectors: data.inspectors.filter(i => i.latitude && i.longitude && i.is_active).length,
    activeVehicles: data.vehicles.filter(v => v.latitude && v.longitude).length,
    activePanicAlerts: data.panicAlerts.filter(p => p.status === 'active' || p.status === 'responding').length,
  }), [data]);

  return (
    <AppLayout>
      <div className="h-[calc(100vh-120px)] flex flex-col space-y-4">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Mapa en Vivo</h1>
            <p className="text-sm text-gray-500 flex items-center gap-2">
              Vista en tiempo real de la comuna
              <span className="inline-flex items-center gap-1 text-xs">
                <ArrowPathIcon className={`w-3 h-3 ${isRefreshing ? 'animate-spin' : ''}`} />
                {lastUpdate.toLocaleTimeString('es-CL')}
              </span>
            </p>
          </div>
          <button
            onClick={() => setShowFilters(!showFilters)}
            className={`inline-flex items-center gap-2 px-4 py-2 border rounded-lg text-sm font-medium transition-colors ${
              showFilters
                ? 'bg-primary text-white border-primary'
                : 'border-gray-300 text-gray-700 hover:bg-gray-50'
            }`}
          >
            <FunnelIcon className="h-4 w-4" />
            Filtros
          </button>
        </div>

        {/* Stats Cards */}
        <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
          <div className="bg-white rounded-xl p-3 border border-gray-200 shadow-sm">
            <div className="flex items-center gap-2">
              <MapPinIcon className="h-5 w-5 text-blue-500" />
              <div>
                <p className="text-xs text-gray-500">Reportes</p>
                <p className="text-lg font-bold text-gray-900">{stats.totalReports}</p>
              </div>
            </div>
          </div>
          <div className="bg-white rounded-xl p-3 border border-gray-200 shadow-sm">
            <div className="flex items-center gap-2">
              <ExclamationTriangleIcon className="h-5 w-5 text-orange-500" />
              <div>
                <p className="text-xs text-gray-500">Pendientes</p>
                <p className="text-lg font-bold text-gray-900">{stats.pendingReports}</p>
              </div>
            </div>
          </div>
          <div className="bg-white rounded-xl p-3 border border-gray-200 shadow-sm">
            <div className="flex items-center gap-2">
              <UserIcon className="h-5 w-5 text-emerald-500" />
              <div>
                <p className="text-xs text-gray-500">Inspectores</p>
                <p className="text-lg font-bold text-gray-900">{stats.activeInspectors}</p>
              </div>
            </div>
          </div>
          <div className="bg-white rounded-xl p-3 border border-gray-200 shadow-sm">
            <div className="flex items-center gap-2">
              <TruckIcon className="h-5 w-5 text-indigo-500" />
              <div>
                <p className="text-xs text-gray-500">Vehículos</p>
                <p className="text-lg font-bold text-gray-900">{stats.activeVehicles}</p>
              </div>
            </div>
          </div>
          {stats.activePanicAlerts > 0 && (
            <div className="bg-red-50 rounded-xl p-3 border border-red-200 shadow-sm animate-pulse">
              <div className="flex items-center gap-2">
                <ExclamationTriangleIcon className="h-5 w-5 text-red-600" />
                <div>
                  <p className="text-xs text-red-600">ALERTAS SOS</p>
                  <p className="text-lg font-bold text-red-700">{stats.activePanicAlerts}</p>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Filter Panel */}
        {showFilters && (
          <div className="bg-white rounded-xl p-4 border border-gray-200 shadow-sm">
            <div className="flex items-center justify-between mb-3">
              <h3 className="font-medium text-gray-900">Filtrar elementos</h3>
              <button onClick={() => setShowFilters(false)} className="text-gray-400 hover:text-gray-600">
                <XMarkIcon className="h-5 w-5" />
              </button>
            </div>
            <div className="flex flex-wrap gap-4">
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={filters.showReports}
                  onChange={(e) => setFilters(f => ({ ...f, showReports: e.target.checked }))}
                  className="rounded border-gray-300 text-primary focus:ring-primary"
                />
                <MapPinIcon className="h-4 w-4 text-blue-500" />
                <span className="text-sm">Reportes</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={filters.showInspectors}
                  onChange={(e) => setFilters(f => ({ ...f, showInspectors: e.target.checked }))}
                  className="rounded border-gray-300 text-primary focus:ring-primary"
                />
                <UserIcon className="h-4 w-4 text-emerald-500" />
                <span className="text-sm">Inspectores</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={filters.showVehicles}
                  onChange={(e) => setFilters(f => ({ ...f, showVehicles: e.target.checked }))}
                  className="rounded border-gray-300 text-primary focus:ring-primary"
                />
                <TruckIcon className="h-4 w-4 text-indigo-500" />
                <span className="text-sm">Vehículos</span>
              </label>
              <label className="flex items-center gap-2 cursor-pointer">
                <input
                  type="checkbox"
                  checked={filters.showPanicAlerts}
                  onChange={(e) => setFilters(f => ({ ...f, showPanicAlerts: e.target.checked }))}
                  className="rounded border-gray-300 text-primary focus:ring-primary"
                />
                <ExclamationTriangleIcon className="h-4 w-4 text-red-500" />
                <span className="text-sm">Alertas SOS</span>
              </label>
              <div className="border-l border-gray-200 pl-4">
                <select
                  value={filters.reportStatus}
                  onChange={(e) => setFilters(f => ({ ...f, reportStatus: e.target.value }))}
                  className="text-sm border border-gray-300 rounded-lg px-3 py-1.5 focus:ring-primary focus:border-primary"
                >
                  <option value="">Todos los estados</option>
                  <option value="pendiente">Pendientes</option>
                  <option value="en_proceso">En Proceso</option>
                  <option value="resuelto">Resueltos</option>
                </select>
              </div>
            </div>
          </div>
        )}

        {/* Map Container */}
        <div className="flex-1 bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
          <LiveMapComponent
            reports={filteredData.reports}
            inspectors={filteredData.inspectors}
            vehicles={filteredData.vehicles}
            panicAlerts={filteredData.panicAlerts}
          />
        </div>
      </div>
    </AppLayout>
  );
}
