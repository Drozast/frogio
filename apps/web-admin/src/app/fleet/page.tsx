'use client';

import { useState, useEffect, useCallback, Suspense } from 'react';
import { useSearchParams, useRouter } from 'next/navigation';
import dynamic from 'next/dynamic';
import Link from 'next/link';
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
  PlusIcon,
  MagnifyingGlassIcon,
  DocumentArrowDownIcon,
  FunnelIcon,
  ArrowPathIcon,
  CalendarIcon,
  Cog6ToothIcon,
  MapPinIcon,
  PlayIcon,
} from '@heroicons/react/24/outline';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import * as XLSX from 'xlsx';

// Dynamic imports for map components (client-side only)
const FleetMap = dynamic(() => import('@/components/fleet/FleetMap'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-full flex items-center justify-center bg-gray-100 rounded-lg">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600" />
    </div>
  ),
});

const RouteMap = dynamic(() => import('@/components/fleet/RouteMap'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-full flex items-center justify-center bg-gray-100 rounded-lg">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600" />
    </div>
  ),
});

// Types
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

interface Vehicle {
  id: string;
  plate: string;
  brand: string;
  model: string;
  year: number | null;
  color: string | null;
  vehicle_type: string | null;
  owner_first_name: string;
  owner_last_name: string;
  owner_rut: string;
  is_active: boolean;
  created_at: string;
}

interface VehicleLog {
  id: string;
  vehicle_id: string;
  vehicle_plate: string;
  vehicle_brand: string;
  vehicle_model: string;
  driver_id: string;
  driver_name: string;
  usage_type: string;
  purpose: string | null;
  start_km: number;
  end_km: number | null;
  start_time: string;
  end_time: string | null;
  total_distance_km: number | null;
  observations: string | null;
}

interface Inspector {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
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

type TabType = 'live' | 'logs' | 'history' | 'vehicles' | 'settings';

const usageTypeLabels: Record<string, string> = {
  'official': 'Servicio Oficial',
  'emergency': 'Emergencia',
  'maintenance': 'Mantención',
  'transfer': 'Traslado',
  'other': 'Otro',
};

function FleetPageContent() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const tabParam = searchParams.get('tab') as TabType | null;
  const [activeTab, setActiveTab] = useState<TabType>(tabParam && ['live', 'logs', 'history', 'vehicles', 'settings'].includes(tabParam) ? tabParam : 'live');

  // Sync URL with active tab
  const handleTabChange = useCallback((tab: TabType) => {
    setActiveTab(tab);
    router.push(`/fleet?tab=${tab}`, { scroll: false });
  }, [router]);

  // Live tracking state
  const { isConnected, vehicles: socketVehicles, geofenceEvents, error: socketError, refreshPositions } = useFleetSocket();
  const [selectedVehicleId, setSelectedVehicleId] = useState<string | null>(null);
  const [geofences, setGeofences] = useState<Geofence[]>([]);
  const [showGeofences, setShowGeofences] = useState(true);
  const [initialPositions, setInitialPositions] = useState<Map<string, VehiclePosition>>(new Map());

  // Vehicles management state
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [vehiclesLoading, setVehiclesLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  // Logs state
  const [logs, setLogs] = useState<VehicleLog[]>([]);
  const [inspectors, setInspectors] = useState<Inspector[]>([]);
  const [logsLoading, setLogsLoading] = useState(false);
  const [selectedVehicleFilter, setSelectedVehicleFilter] = useState<string>('');
  const [selectedInspector, setSelectedInspector] = useState<string>('');
  const [logsStartDate, setLogsStartDate] = useState<string>('');
  const [logsEndDate, setLogsEndDate] = useState<string>('');
  const [showFilters, setShowFilters] = useState(false);

  // History state
  const [historyVehicleId, setHistoryVehicleId] = useState<string>('');
  const [historyDate, setHistoryDate] = useState<string>(new Date().toISOString().split('T')[0]);
  const [routeData, setRouteData] = useState<RouteData | null>(null);
  const [historyLoading, setHistoryLoading] = useState(false);

  // Fetch initial data for live tracking
  useEffect(() => {
    async function fetchInitialData() {
      try {
        const posResponse = await fetch('/api/fleet/live');
        if (posResponse.ok) {
          const positions = await posResponse.json();
          const posMap = new Map<string, VehiclePosition>();
          positions.forEach((pos: VehiclePosition) => {
            posMap.set(pos.vehicleId, pos);
          });
          setInitialPositions(posMap);
        }

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

  // Fetch vehicles
  useEffect(() => {
    async function fetchVehicles() {
      try {
        const response = await fetch('/api/vehicles');
        if (response.ok) {
          const data = await response.json();
          setVehicles(data);
        }
      } catch (error) {
        console.error('Error fetching vehicles:', error);
      } finally {
        setVehiclesLoading(false);
      }
    }

    async function fetchInspectors() {
      try {
        const response = await fetch('/api/users?role=inspector');
        if (response.ok) {
          const data = await response.json();
          setInspectors(data);
        }
      } catch (error) {
        console.error('Error fetching inspectors:', error);
      }
    }

    fetchVehicles();
    fetchInspectors();
  }, []);

  // Fetch logs
  const fetchLogs = useCallback(async () => {
    setLogsLoading(true);
    try {
      const params = new URLSearchParams();
      if (selectedVehicleFilter) params.append('vehicleId', selectedVehicleFilter);
      if (selectedInspector) params.append('driverId', selectedInspector);
      if (logsStartDate) params.append('startDate', logsStartDate);
      if (logsEndDate) params.append('endDate', logsEndDate);

      const response = await fetch(`/api/vehicles/logs?${params.toString()}`);
      if (response.ok) {
        const data = await response.json();
        setLogs(data);
      }
    } catch (error) {
      console.error('Error fetching logs:', error);
    } finally {
      setLogsLoading(false);
    }
  }, [selectedVehicleFilter, selectedInspector, logsStartDate, logsEndDate]);

  useEffect(() => {
    if (activeTab === 'logs') {
      fetchLogs();
    }
  }, [activeTab, fetchLogs]);

  // Fetch route history
  async function fetchRoute() {
    if (!historyVehicleId || !historyDate) return;

    setHistoryLoading(true);
    try {
      const startDate = `${historyDate}T00:00:00`;
      const endDate = `${historyDate}T23:59:59`;

      const response = await fetch(
        `/api/fleet/history?vehicleId=${historyVehicleId}&startDate=${startDate}&endDate=${endDate}`
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
      setHistoryLoading(false);
    }
  }

  // Merge socket and initial positions
  const mergedVehicles = new Map(initialPositions);
  socketVehicles.forEach((v, k) => mergedVehicles.set(k, v));

  // Filter vehicles for management tab
  const filteredVehicles = vehicles.filter(vehicle => {
    if (!searchQuery) return true;
    const query = searchQuery.toLowerCase();
    return (
      vehicle.plate.toLowerCase().includes(query) ||
      vehicle.brand.toLowerCase().includes(query) ||
      vehicle.model.toLowerCase().includes(query)
    );
  });

  // Transform geofences for map
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

  const clearFilters = () => {
    setSelectedVehicleFilter('');
    setSelectedInspector('');
    setLogsStartDate('');
    setLogsEndDate('');
  };

  const exportToExcel = () => {
    const exportData = logs.map(log => ({
      'Patente': log.vehicle_plate,
      'Vehículo': `${log.vehicle_brand} ${log.vehicle_model}`,
      'Inspector': log.driver_name,
      'Tipo de Uso': usageTypeLabels[log.usage_type] || log.usage_type,
      'Propósito': log.purpose || '-',
      'Km Inicial': log.start_km,
      'Km Final': log.end_km || '-',
      'Distancia (km)': log.total_distance_km?.toFixed(1) || '-',
      'Inicio': format(new Date(log.start_time), 'dd/MM/yyyy HH:mm', { locale: es }),
      'Fin': log.end_time ? format(new Date(log.end_time), 'dd/MM/yyyy HH:mm', { locale: es }) : 'En curso',
      'Observaciones': log.observations || '-',
    }));

    const worksheet = XLSX.utils.json_to_sheet(exportData);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Bitácora Vehículos');
    XLSX.writeFile(workbook, `bitacora_vehiculos_${format(new Date(), 'yyyyMMdd_HHmm')}.xlsx`);
  };

  const selectedHistoryVehicle = vehicles.find(v => v.id === historyVehicleId);

  const tabs = [
    { id: 'live' as TabType, name: 'Mapa en Vivo', icon: MapPinIcon },
    { id: 'logs' as TabType, name: 'Bitácora', icon: ClockIcon },
    { id: 'history' as TabType, name: 'Historial Rutas', icon: MapIcon },
    { id: 'vehicles' as TabType, name: 'Vehículos', icon: TruckIcon },
    { id: 'settings' as TabType, name: 'Zonas', icon: Cog6ToothIcon },
  ];

  return (
    <AppLayout>
      <div className="h-[calc(100vh-4rem)] flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between mb-4">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Gestión de Flota</h1>
            <p className="text-sm text-gray-500">
              Control y seguimiento de vehículos municipales
            </p>
          </div>
          <div className="flex items-center gap-3">
            {/* Connection Status - Only show on live tab */}
            {activeTab === 'live' && (
              <div className={`flex items-center gap-2 px-3 py-1.5 rounded-full text-sm ${
                isConnected ? 'bg-green-100 text-green-800' : 'bg-yellow-100 text-yellow-800'
              }`}>
                {isConnected ? (
                  <SignalIcon className="h-4 w-4" />
                ) : (
                  <SignalSlashIcon className="h-4 w-4" />
                )}
                {isConnected ? 'Tiempo Real' : 'Actualización cada 10s'}
              </div>
            )}

            {/* Stats Link */}
            <Link
              href="/fleet/stats"
              className="flex items-center gap-2 px-3 py-1.5 text-sm text-gray-700 hover:bg-gray-100 rounded-lg transition-colors border border-gray-200"
            >
              <ChartBarIcon className="h-4 w-4" />
              Estadísticas
            </Link>
          </div>
        </div>

        {/* Tabs */}
        <div className="border-b border-gray-200 mb-4">
          <nav className="-mb-px flex space-x-6 overflow-x-auto">
            {tabs.map((tab) => (
              <button
                key={tab.id}
                onClick={() => handleTabChange(tab.id)}
                className={`py-3 px-1 border-b-2 font-medium text-sm flex items-center gap-2 whitespace-nowrap ${
                  activeTab === tab.id
                    ? 'border-indigo-500 text-indigo-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                <tab.icon className="h-5 w-5" />
                {tab.name}
                {tab.id === 'live' && mergedVehicles.size > 0 && (
                  <span className="ml-1 px-2 py-0.5 text-xs bg-green-100 text-green-800 rounded-full">
                    {mergedVehicles.size}
                  </span>
                )}
              </button>
            ))}
          </nav>
        </div>

        {/* Tab Content */}
        <div className="flex-1 min-h-0">
          {/* LIVE TRACKING TAB */}
          {activeTab === 'live' && (
            <div className="h-full grid grid-cols-1 lg:grid-cols-4 gap-4">
              {/* Left Panel - Vehicle List */}
              <div className="lg:col-span-1 bg-white rounded-lg shadow overflow-hidden flex flex-col">
                <div className="p-3 border-b bg-gray-50">
                  <div className="flex items-center justify-between">
                    <h2 className="font-semibold text-gray-900 text-sm">Vehículos Activos</h2>
                    <button
                      onClick={refreshPositions}
                      className="p-1 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded"
                      title="Actualizar"
                    >
                      <ArrowPathIcon className="h-4 w-4" />
                    </button>
                  </div>
                </div>
                <div className="flex-1 overflow-y-auto">
                  <VehicleList
                    vehicles={mergedVehicles}
                    selectedVehicleId={selectedVehicleId}
                    onVehicleSelect={setSelectedVehicleId}
                  />
                </div>

                {/* Quick Stats */}
                <div className="p-3 border-t bg-gray-50">
                  <div className="grid grid-cols-2 gap-2">
                    <div className="p-2 bg-green-50 rounded text-center">
                      <p className="text-xs text-green-600">En Movimiento</p>
                      <p className="text-lg font-bold text-green-700">
                        {Array.from(mergedVehicles.values()).filter(v => v.status === 'moving').length}
                      </p>
                    </div>
                    <div className="p-2 bg-red-50 rounded text-center">
                      <p className="text-xs text-red-600">Detenidos</p>
                      <p className="text-lg font-bold text-red-700">
                        {Array.from(mergedVehicles.values()).filter(v => v.status === 'stopped').length}
                      </p>
                    </div>
                  </div>
                </div>
              </div>

              {/* Center - Map */}
              <div className="lg:col-span-2 bg-white rounded-lg shadow overflow-hidden">
                {socketError && (
                  <div className="p-2 bg-yellow-50 text-yellow-700 text-xs text-center">
                    {socketError}
                  </div>
                )}
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

              {/* Right Panel - Alerts */}
              <div className="lg:col-span-1 flex flex-col gap-3">
                {/* Geofence Toggle */}
                <div className="bg-white rounded-lg shadow p-3">
                  <div className="flex items-center justify-between">
                    <div>
                      <h3 className="font-semibold text-gray-900 text-sm">Zonas Geofencing</h3>
                      <p className="text-xs text-gray-500">{geofences.length} zona{geofences.length !== 1 ? 's' : ''}</p>
                    </div>
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
                </div>

                {/* Geofence Events */}
                <div className="bg-white rounded-lg shadow overflow-hidden flex-1 flex flex-col">
                  <div className="p-3 border-b bg-gray-50">
                    <h3 className="font-semibold text-gray-900 text-sm">Alertas Recientes</h3>
                  </div>
                  <div className="flex-1 overflow-y-auto">
                    <GeofenceAlerts events={geofenceEvents} />
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* LOGS TAB */}
          {activeTab === 'logs' && (
            <div className="space-y-4 h-full overflow-y-auto">
              {/* Filters */}
              <div className="bg-white rounded-lg shadow p-4">
                <div className="flex items-center justify-between mb-4">
                  <button
                    onClick={() => setShowFilters(!showFilters)}
                    className="flex items-center gap-2 text-sm font-medium text-gray-700 hover:text-gray-900"
                  >
                    <FunnelIcon className="h-4 w-4" />
                    Filtros
                    {(selectedVehicleFilter || selectedInspector || logsStartDate || logsEndDate) && (
                      <span className="ml-1 px-2 py-0.5 text-xs bg-indigo-100 text-indigo-800 rounded-full">
                        Activos
                      </span>
                    )}
                  </button>
                  <div className="flex items-center gap-2">
                    <button
                      onClick={fetchLogs}
                      className="p-2 text-gray-500 hover:text-gray-700 hover:bg-gray-100 rounded-lg"
                      title="Actualizar"
                    >
                      <ArrowPathIcon className="h-4 w-4" />
                    </button>
                    <button
                      onClick={exportToExcel}
                      disabled={logs.length === 0}
                      className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50"
                    >
                      <DocumentArrowDownIcon className="h-4 w-4" />
                      Exportar Excel
                    </button>
                  </div>
                </div>

                {showFilters && (
                  <div className="grid grid-cols-1 md:grid-cols-4 gap-4 pt-4 border-t">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Vehículo</label>
                      <select
                        value={selectedVehicleFilter}
                        onChange={(e) => setSelectedVehicleFilter(e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500"
                      >
                        <option value="">Todos</option>
                        {vehicles.map((v) => (
                          <option key={v.id} value={v.id}>{v.plate} - {v.brand} {v.model}</option>
                        ))}
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Inspector</label>
                      <select
                        value={selectedInspector}
                        onChange={(e) => setSelectedInspector(e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500"
                      >
                        <option value="">Todos</option>
                        {inspectors.map((i) => (
                          <option key={i.id} value={i.id}>{i.first_name} {i.last_name}</option>
                        ))}
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Desde</label>
                      <input
                        type="date"
                        value={logsStartDate}
                        onChange={(e) => setLogsStartDate(e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">Hasta</label>
                      <input
                        type="date"
                        value={logsEndDate}
                        onChange={(e) => setLogsEndDate(e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500"
                      />
                    </div>
                    {(selectedVehicleFilter || selectedInspector || logsStartDate || logsEndDate) && (
                      <div className="md:col-span-4">
                        <button onClick={clearFilters} className="text-sm text-indigo-600 hover:text-indigo-800">
                          Limpiar filtros
                        </button>
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* Logs Table */}
              {logsLoading ? (
                <div className="bg-white rounded-lg shadow p-8 text-center">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600 mx-auto"></div>
                </div>
              ) : logs.length === 0 ? (
                <div className="bg-white rounded-lg shadow p-8 text-center">
                  <ClockIcon className="h-12 w-12 text-gray-300 mx-auto mb-3" />
                  <h3 className="text-lg font-medium text-gray-900 mb-1">Sin registros</h3>
                  <p className="text-sm text-gray-500">No hay registros de uso en el período seleccionado</p>
                </div>
              ) : (
                <div className="bg-white rounded-lg shadow overflow-hidden">
                  <div className="overflow-x-auto">
                    <table className="min-w-full divide-y divide-gray-200">
                      <thead className="bg-gray-50">
                        <tr>
                          <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Vehículo</th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Inspector</th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Tipo</th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Kilometraje</th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Fecha/Hora</th>
                          <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase">Estado</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-gray-200">
                        {logs.map((log) => (
                          <tr key={log.id} className="hover:bg-gray-50">
                            <td className="px-4 py-3 whitespace-nowrap">
                              <p className="text-sm font-medium text-gray-900 uppercase">{log.vehicle_plate}</p>
                              <p className="text-xs text-gray-500">{log.vehicle_brand} {log.vehicle_model}</p>
                            </td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm text-gray-900">{log.driver_name}</td>
                            <td className="px-4 py-3 whitespace-nowrap">
                              <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                                log.usage_type === 'emergency' ? 'bg-red-100 text-red-800' :
                                log.usage_type === 'official' ? 'bg-blue-100 text-blue-800' :
                                'bg-gray-100 text-gray-800'
                              }`}>
                                {usageTypeLabels[log.usage_type] || log.usage_type}
                              </span>
                            </td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm">
                              <span className="text-gray-900">{log.start_km}</span>
                              <span className="text-gray-400 mx-1">→</span>
                              <span className="text-gray-900">{log.end_km || '...'}</span>
                              {log.total_distance_km && (
                                <p className="text-xs text-green-600">+{log.total_distance_km.toFixed(1)} km</p>
                              )}
                            </td>
                            <td className="px-4 py-3 whitespace-nowrap text-sm">
                              <p className="text-gray-900">{format(new Date(log.start_time), 'dd/MM/yyyy', { locale: es })}</p>
                              <p className="text-xs text-gray-500">
                                {format(new Date(log.start_time), 'HH:mm', { locale: es })}
                                {log.end_time && <> - {format(new Date(log.end_time), 'HH:mm', { locale: es })}</>}
                              </p>
                            </td>
                            <td className="px-4 py-3 whitespace-nowrap">
                              {log.end_time ? (
                                <span className="px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">Finalizado</span>
                              ) : (
                                <span className="px-2 py-1 text-xs font-medium rounded-full bg-yellow-100 text-yellow-800 animate-pulse">En curso</span>
                              )}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* HISTORY TAB */}
          {activeTab === 'history' && (
            <div className="h-full grid grid-cols-1 lg:grid-cols-4 gap-4">
              {/* Left Panel - Filters & Stats */}
              <div className="lg:col-span-1 bg-white rounded-lg shadow p-4 space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    <TruckIcon className="h-4 w-4 inline mr-1" />
                    Vehículo
                  </label>
                  <select
                    value={historyVehicleId}
                    onChange={(e) => setHistoryVehicleId(e.target.value)}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value="">Seleccionar vehículo...</option>
                    {vehicles.map((v) => (
                      <option key={v.id} value={v.id}>{v.plate} - {v.brand} {v.model}</option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    <CalendarIcon className="h-4 w-4 inline mr-1" />
                    Fecha
                  </label>
                  <input
                    type="date"
                    value={historyDate}
                    onChange={(e) => setHistoryDate(e.target.value)}
                    max={new Date().toISOString().split('T')[0]}
                    className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500"
                  />
                </div>

                <button
                  onClick={fetchRoute}
                  disabled={!historyVehicleId || historyLoading}
                  className="w-full px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                >
                  <PlayIcon className="h-4 w-4" />
                  {historyLoading ? 'Cargando...' : 'Ver Recorrido'}
                </button>

                {/* Route Stats */}
                {routeData && routeData.points.length > 0 && (
                  <div className="pt-4 border-t space-y-3">
                    <h3 className="font-semibold text-gray-900">Estadísticas del Día</h3>
                    <div className="grid grid-cols-2 gap-2">
                      <div className="p-3 bg-gray-50 rounded-lg text-center">
                        <p className="text-xs text-gray-500">Distancia</p>
                        <p className="text-lg font-bold text-gray-900">{routeData.totalDistance.toFixed(1)} km</p>
                      </div>
                      <div className="p-3 bg-gray-50 rounded-lg text-center">
                        <p className="text-xs text-gray-500">Vel. Promedio</p>
                        <p className="text-lg font-bold text-gray-900">{routeData.avgSpeed.toFixed(0)} km/h</p>
                      </div>
                      <div className="p-3 bg-gray-50 rounded-lg text-center">
                        <p className="text-xs text-gray-500">Vel. Máxima</p>
                        <p className="text-lg font-bold text-gray-900">{routeData.maxSpeed.toFixed(0)} km/h</p>
                      </div>
                      <div className="p-3 bg-gray-50 rounded-lg text-center">
                        <p className="text-xs text-gray-500">Puntos GPS</p>
                        <p className="text-lg font-bold text-gray-900">{routeData.points.length}</p>
                      </div>
                    </div>
                    {routeData.startTime && routeData.endTime && (
                      <div className="p-3 bg-indigo-50 rounded-lg">
                        <p className="text-xs text-indigo-600 font-medium">Período de Actividad</p>
                        <p className="text-sm text-indigo-900 mt-1">
                          {new Date(routeData.startTime).toLocaleTimeString('es-CL', { hour: '2-digit', minute: '2-digit' })}
                          {' - '}
                          {new Date(routeData.endTime).toLocaleTimeString('es-CL', { hour: '2-digit', minute: '2-digit' })}
                        </p>
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* Map */}
              <div className="lg:col-span-3 bg-white rounded-lg shadow overflow-hidden">
                {routeData && routeData.points.length > 0 ? (
                  <RouteMap points={routeData.points} vehiclePlate={selectedHistoryVehicle?.plate || ''} />
                ) : (
                  <div className="h-full flex flex-col items-center justify-center text-gray-500">
                    <MapIcon className="h-16 w-16 text-gray-300 mb-3" />
                    <p className="text-sm font-medium">
                      {!historyVehicleId
                        ? 'Selecciona un vehículo para ver su historial'
                        : routeData === null
                        ? 'No hay datos de ruta para la fecha seleccionada'
                        : 'Selecciona un vehículo y fecha para consultar'
                      }
                    </p>
                    <p className="text-xs text-gray-400 mt-1">
                      Los recorridos se registran automáticamente cuando un inspector usa un vehículo
                    </p>
                  </div>
                )}
              </div>
            </div>
          )}

          {/* VEHICLES TAB */}
          {activeTab === 'vehicles' && (
            <div className="space-y-4 h-full overflow-y-auto">
              {/* Search & Actions */}
              <div className="bg-white rounded-lg shadow p-4">
                <div className="flex items-center justify-between gap-4">
                  <div className="relative flex-1 max-w-md">
                    <MagnifyingGlassIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                    <input
                      type="text"
                      placeholder="Buscar por patente, marca, modelo..."
                      value={searchQuery}
                      onChange={(e) => setSearchQuery(e.target.value)}
                      className="w-full pl-9 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500"
                    />
                  </div>
                  <Link
                    href="/vehicles/new"
                    className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700"
                  >
                    <PlusIcon className="h-4 w-4" />
                    Registrar Vehículo
                  </Link>
                </div>
              </div>

              {/* Results */}
              <div className="text-sm text-gray-500">
                {filteredVehicles.length} vehículo{filteredVehicles.length !== 1 ? 's' : ''} registrado{filteredVehicles.length !== 1 ? 's' : ''}
              </div>

              {/* Vehicles Grid */}
              {vehiclesLoading ? (
                <div className="bg-white rounded-lg shadow p-8 text-center">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600 mx-auto"></div>
                </div>
              ) : filteredVehicles.length === 0 ? (
                <div className="bg-white rounded-lg shadow p-8 text-center">
                  <TruckIcon className="h-12 w-12 text-gray-300 mx-auto mb-3" />
                  <h3 className="text-lg font-medium text-gray-900 mb-1">No hay vehículos</h3>
                  <p className="text-sm text-gray-500 mb-4">
                    {searchQuery ? 'No se encontraron vehículos' : 'Aún no se han registrado vehículos'}
                  </p>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {filteredVehicles.map((vehicle) => (
                    <div key={vehicle.id} className="bg-white rounded-lg shadow p-4 hover:shadow-md transition-shadow">
                      <div className="flex items-start justify-between">
                        <div className="flex items-center gap-3">
                          <div className={`p-3 rounded-full ${vehicle.is_active ? 'bg-green-100' : 'bg-gray-100'}`}>
                            <TruckIcon className={`h-6 w-6 ${vehicle.is_active ? 'text-green-600' : 'text-gray-400'}`} />
                          </div>
                          <div>
                            <p className="text-lg font-bold text-gray-900 uppercase">{vehicle.plate}</p>
                            <p className="text-sm text-gray-600">{vehicle.brand} {vehicle.model}</p>
                          </div>
                        </div>
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                          vehicle.is_active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-600'
                        }`}>
                          {vehicle.is_active ? 'Activo' : 'Inactivo'}
                        </span>
                      </div>
                      <div className="mt-4 pt-4 border-t text-sm text-gray-500 space-y-1">
                        {vehicle.year && <p>Año: {vehicle.year}</p>}
                        {vehicle.color && <p>Color: {vehicle.color}</p>}
                        {vehicle.vehicle_type && <p>Tipo: {vehicle.vehicle_type}</p>}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* SETTINGS TAB - Geofences */}
          {activeTab === 'settings' && (
            <div className="h-full flex flex-col">
              <div className="bg-white rounded-lg shadow p-4 mb-4">
                <div className="flex items-center justify-between">
                  <div>
                    <h2 className="text-lg font-semibold text-gray-900">Zonas de Geofencing</h2>
                    <p className="text-sm text-gray-500">Configure zonas para recibir alertas cuando los vehículos entren o salgan</p>
                  </div>
                  <Link
                    href="/fleet/geofences"
                    className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700"
                  >
                    <Cog6ToothIcon className="h-4 w-4" />
                    Administrar Zonas
                  </Link>
                </div>
              </div>

              {/* Geofences List */}
              <div className="flex-1 bg-white rounded-lg shadow overflow-hidden">
                {geofences.length === 0 ? (
                  <div className="h-full flex flex-col items-center justify-center text-gray-500">
                    <MapIcon className="h-16 w-16 text-gray-300 mb-3" />
                    <p className="text-sm font-medium">No hay zonas configuradas</p>
                    <Link href="/fleet/geofences" className="text-sm text-indigo-600 hover:text-indigo-800 mt-2">
                      Crear primera zona
                    </Link>
                  </div>
                ) : (
                  <div className="divide-y">
                    {geofences.map((geofence) => (
                      <div key={geofence.id} className="p-4 hover:bg-gray-50 flex items-center justify-between">
                        <div className="flex items-center gap-3">
                          <div className={`p-2 rounded-full ${geofence.is_active ? 'bg-green-100' : 'bg-gray-100'}`}>
                            <MapPinIcon className={`h-5 w-5 ${geofence.is_active ? 'text-green-600' : 'text-gray-400'}`} />
                          </div>
                          <div>
                            <p className="text-sm font-medium text-gray-900">{geofence.name}</p>
                            <p className="text-xs text-gray-500">
                              {geofence.geofence_type === 'circle'
                                ? `Círculo - Radio: ${geofence.radius_meters}m`
                                : 'Polígono'}
                            </p>
                          </div>
                        </div>
                        <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                          geofence.is_active ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-600'
                        }`}>
                          {geofence.is_active ? 'Activa' : 'Inactiva'}
                        </span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </div>
    </AppLayout>
  );
}

export default function FleetPage() {
  return (
    <Suspense fallback={
      <AppLayout>
        <div className="flex items-center justify-center min-h-96">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
        </div>
      </AppLayout>
    }>
      <FleetPageContent />
    </Suspense>
  );
}
