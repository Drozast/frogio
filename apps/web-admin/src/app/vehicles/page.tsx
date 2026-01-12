'use client';

import { useState, useEffect, useCallback } from 'react';
import Link from 'next/link';
import dynamic from 'next/dynamic';
import AppLayout from '@/components/layout/AppLayout';
import {
  PlusIcon,
  TruckIcon,
  MagnifyingGlassIcon,
  ClockIcon,
  MapIcon,
  DocumentArrowDownIcon,
  FunnelIcon,
  ArrowPathIcon,
} from '@heroicons/react/24/outline';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import * as XLSX from 'xlsx';

// Dynamic import for map component (client-side only)
const VehicleTrackingMap = dynamic(
  () => import('@/components/vehicles/VehicleTrackingMap'),
  { ssr: false, loading: () => <div className="h-96 bg-gray-100 animate-pulse rounded-lg" /> }
);

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

type TabType = 'vehicles' | 'logs' | 'tracking';

export default function VehiclesPage() {
  const [activeTab, setActiveTab] = useState<TabType>('vehicles');
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [logs, setLogs] = useState<VehicleLog[]>([]);
  const [inspectors, setInspectors] = useState<Inspector[]>([]);
  const [loading, setLoading] = useState(true);
  const [logsLoading, setLogsLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  // Filters for logs
  const [selectedVehicle, setSelectedVehicle] = useState<string>('');
  const [selectedInspector, setSelectedInspector] = useState<string>('');
  const [startDate, setStartDate] = useState<string>('');
  const [endDate, setEndDate] = useState<string>('');
  const [showFilters, setShowFilters] = useState(false);

  useEffect(() => {
    fetchVehicles();
    fetchInspectors();
  }, []);

  const fetchLogs = useCallback(async () => {
    setLogsLoading(true);
    try {
      const params = new URLSearchParams();
      if (selectedVehicle) params.append('vehicleId', selectedVehicle);
      if (selectedInspector) params.append('driverId', selectedInspector);
      if (startDate) params.append('startDate', startDate);
      if (endDate) params.append('endDate', endDate);

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
  }, [selectedVehicle, selectedInspector, startDate, endDate]);

  useEffect(() => {
    if (activeTab === 'logs') {
      fetchLogs();
    }
  }, [activeTab, fetchLogs]);

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
      setLoading(false);
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

  const filteredVehicles = vehicles.filter(vehicle => {
    if (!searchQuery) return true;
    const query = searchQuery.toLowerCase();
    return (
      vehicle.plate.toLowerCase().includes(query) ||
      vehicle.brand.toLowerCase().includes(query) ||
      vehicle.model.toLowerCase().includes(query) ||
      vehicle.owner_first_name.toLowerCase().includes(query) ||
      vehicle.owner_last_name.toLowerCase().includes(query) ||
      vehicle.owner_rut.toLowerCase().includes(query)
    );
  });

  const clearFilters = () => {
    setSelectedVehicle('');
    setSelectedInspector('');
    setStartDate('');
    setEndDate('');
  };

  const exportToExcel = () => {
    const exportData = logs.map(log => ({
      'Patente': log.vehicle_plate,
      'Vehículo': `${log.vehicle_brand} ${log.vehicle_model}`,
      'Inspector': log.driver_name,
      'Tipo de Uso': log.usage_type === 'patrol' ? 'Patrullaje' : log.usage_type === 'inspection' ? 'Inspección' : log.usage_type,
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

    // Auto-size columns
    const colWidths = Object.keys(exportData[0] || {}).map(key => ({
      wch: Math.max(key.length, 15)
    }));
    worksheet['!cols'] = colWidths;

    XLSX.writeFile(workbook, `bitacora_vehiculos_${format(new Date(), 'yyyyMMdd_HHmm')}.xlsx`);
  };

  const exportToPDF = async () => {
    // Simple PDF generation using browser print
    const printContent = `
      <html>
        <head>
          <title>Bitácora de Vehículos - FROGIO</title>
          <style>
            body { font-family: Arial, sans-serif; padding: 20px; }
            h1 { color: #4f46e5; }
            table { width: 100%; border-collapse: collapse; margin-top: 20px; }
            th, td { border: 1px solid #ddd; padding: 8px; text-align: left; font-size: 12px; }
            th { background-color: #4f46e5; color: white; }
            tr:nth-child(even) { background-color: #f9f9f9; }
            .header { display: flex; justify-content: space-between; margin-bottom: 20px; }
            .date { color: #666; }
          </style>
        </head>
        <body>
          <div class="header">
            <h1>Bitácora de Vehículos</h1>
            <p class="date">Generado: ${format(new Date(), "dd/MM/yyyy HH:mm", { locale: es })}</p>
          </div>
          <table>
            <thead>
              <tr>
                <th>Patente</th>
                <th>Vehículo</th>
                <th>Inspector</th>
                <th>Tipo</th>
                <th>Km Inicial</th>
                <th>Km Final</th>
                <th>Distancia</th>
                <th>Inicio</th>
                <th>Fin</th>
              </tr>
            </thead>
            <tbody>
              ${logs.map(log => `
                <tr>
                  <td>${log.vehicle_plate}</td>
                  <td>${log.vehicle_brand} ${log.vehicle_model}</td>
                  <td>${log.driver_name}</td>
                  <td>${log.usage_type === 'patrol' ? 'Patrullaje' : log.usage_type === 'inspection' ? 'Inspección' : log.usage_type}</td>
                  <td>${log.start_km}</td>
                  <td>${log.end_km || '-'}</td>
                  <td>${log.total_distance_km?.toFixed(1) || '-'} km</td>
                  <td>${format(new Date(log.start_time), 'dd/MM/yyyy HH:mm', { locale: es })}</td>
                  <td>${log.end_time ? format(new Date(log.end_time), 'dd/MM/yyyy HH:mm', { locale: es }) : 'En curso'}</td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </body>
      </html>
    `;

    const printWindow = window.open('', '_blank');
    if (printWindow) {
      printWindow.document.write(printContent);
      printWindow.document.close();
      printWindow.print();
    }
  };

  if (loading) {
    return (
      <AppLayout>
        <div className="flex items-center justify-center min-h-96">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
        </div>
      </AppLayout>
    );
  }

  return (
    <AppLayout>
      <div className="space-y-6">
        {/* Header */}
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900">Vehículos</h1>
            <p className="text-sm text-gray-500 mt-1">
              Gestión de vehículos, bitácora y seguimiento GPS
            </p>
          </div>
          <Link
            href="/vehicles/new"
            className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 transition-colors"
          >
            <PlusIcon className="h-4 w-4" />
            Registrar Vehículo
          </Link>
        </div>

        {/* Tabs */}
        <div className="border-b border-gray-200">
          <nav className="-mb-px flex space-x-8">
            <button
              onClick={() => setActiveTab('vehicles')}
              className={`py-4 px-1 border-b-2 font-medium text-sm flex items-center gap-2 ${
                activeTab === 'vehicles'
                  ? 'border-indigo-500 text-indigo-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <TruckIcon className="h-5 w-5" />
              Vehículos
            </button>
            <button
              onClick={() => setActiveTab('logs')}
              className={`py-4 px-1 border-b-2 font-medium text-sm flex items-center gap-2 ${
                activeTab === 'logs'
                  ? 'border-indigo-500 text-indigo-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <ClockIcon className="h-5 w-5" />
              Bitácora
            </button>
            <button
              onClick={() => setActiveTab('tracking')}
              className={`py-4 px-1 border-b-2 font-medium text-sm flex items-center gap-2 ${
                activeTab === 'tracking'
                  ? 'border-indigo-500 text-indigo-600'
                  : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
              }`}
            >
              <MapIcon className="h-5 w-5" />
              Seguimiento GPS
            </button>
          </nav>
        </div>

        {/* Tab Content */}
        {activeTab === 'vehicles' && (
          <>
            {/* Search */}
            <div className="bg-white rounded-lg shadow p-4">
              <div className="relative">
                <MagnifyingGlassIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Buscar por patente, marca, modelo, propietario..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                />
              </div>
            </div>

            {/* Results Count */}
            <div className="text-sm text-gray-500">
              {filteredVehicles.length} vehículo{filteredVehicles.length !== 1 ? 's' : ''} encontrado{filteredVehicles.length !== 1 ? 's' : ''}
            </div>

            {/* Vehicles List */}
            {filteredVehicles.length === 0 ? (
              <div className="bg-white rounded-lg shadow p-8 text-center">
                <TruckIcon className="h-12 w-12 text-gray-300 mx-auto mb-3" />
                <h3 className="text-lg font-medium text-gray-900 mb-1">
                  No hay vehículos
                </h3>
                <p className="text-sm text-gray-500 mb-4">
                  {searchQuery
                    ? 'No se encontraron vehículos con los criterios de búsqueda'
                    : 'Aún no se han registrado vehículos'}
                </p>
                {!searchQuery && (
                  <Link
                    href="/vehicles/new"
                    className="inline-flex items-center gap-2 text-sm text-indigo-600 hover:text-indigo-800"
                  >
                    <PlusIcon className="h-4 w-4" />
                    Registrar el primer vehículo
                  </Link>
                )}
              </div>
            ) : (
              <div className="bg-white rounded-lg shadow overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Patente
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Vehículo
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Tipo
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Propietario
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          RUT
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Estado
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {filteredVehicles.map((vehicle) => (
                        <tr key={vehicle.id} className="hover:bg-gray-50">
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className="text-sm font-medium text-gray-900 uppercase">
                              {vehicle.plate}
                            </span>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div className="flex items-center gap-3">
                              <div className="p-2 bg-gray-100 rounded-full">
                                <TruckIcon className="h-5 w-5 text-gray-600" />
                              </div>
                              <div>
                                <p className="text-sm font-medium text-gray-900">
                                  {vehicle.brand} {vehicle.model}
                                </p>
                                <p className="text-xs text-gray-500">
                                  {vehicle.year && `${vehicle.year}`} {vehicle.color && `• ${vehicle.color}`}
                                </p>
                              </div>
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {vehicle.vehicle_type || '-'}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            {vehicle.owner_first_name} {vehicle.owner_last_name}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                            {vehicle.owner_rut}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            {vehicle.is_active ? (
                              <span className="px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">
                                Activo
                              </span>
                            ) : (
                              <span className="px-2 py-1 text-xs font-medium rounded-full bg-gray-100 text-gray-800">
                                Inactivo
                              </span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </>
        )}

        {activeTab === 'logs' && (
          <>
            {/* Filters */}
            <div className="bg-white rounded-lg shadow p-4">
              <div className="flex items-center justify-between mb-4">
                <button
                  onClick={() => setShowFilters(!showFilters)}
                  className="flex items-center gap-2 text-sm font-medium text-gray-700 hover:text-gray-900"
                >
                  <FunnelIcon className="h-4 w-4" />
                  Filtros
                  {(selectedVehicle || selectedInspector || startDate || endDate) && (
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
                    className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <DocumentArrowDownIcon className="h-4 w-4" />
                    Excel
                  </button>
                  <button
                    onClick={exportToPDF}
                    disabled={logs.length === 0}
                    className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
                  >
                    <DocumentArrowDownIcon className="h-4 w-4" />
                    PDF
                  </button>
                </div>
              </div>

              {showFilters && (
                <div className="grid grid-cols-1 md:grid-cols-4 gap-4 pt-4 border-t">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Vehículo
                    </label>
                    <select
                      value={selectedVehicle}
                      onChange={(e) => setSelectedVehicle(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    >
                      <option value="">Todos</option>
                      {vehicles.map((v) => (
                        <option key={v.id} value={v.id}>
                          {v.plate} - {v.brand} {v.model}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Inspector
                    </label>
                    <select
                      value={selectedInspector}
                      onChange={(e) => setSelectedInspector(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    >
                      <option value="">Todos</option>
                      {inspectors.map((i) => (
                        <option key={i.id} value={i.id}>
                          {i.first_name} {i.last_name}
                        </option>
                      ))}
                    </select>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Desde
                    </label>
                    <input
                      type="date"
                      value={startDate}
                      onChange={(e) => setStartDate(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      Hasta
                    </label>
                    <input
                      type="date"
                      value={endDate}
                      onChange={(e) => setEndDate(e.target.value)}
                      className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
                    />
                  </div>
                  {(selectedVehicle || selectedInspector || startDate || endDate) && (
                    <div className="md:col-span-4">
                      <button
                        onClick={clearFilters}
                        className="text-sm text-indigo-600 hover:text-indigo-800"
                      >
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
                <p className="text-sm text-gray-500 mt-2">Cargando bitácora...</p>
              </div>
            ) : logs.length === 0 ? (
              <div className="bg-white rounded-lg shadow p-8 text-center">
                <ClockIcon className="h-12 w-12 text-gray-300 mx-auto mb-3" />
                <h3 className="text-lg font-medium text-gray-900 mb-1">
                  Sin registros
                </h3>
                <p className="text-sm text-gray-500">
                  No hay registros de uso de vehículos en el período seleccionado
                </p>
              </div>
            ) : (
              <div className="bg-white rounded-lg shadow overflow-hidden">
                <div className="px-4 py-3 border-b bg-gray-50">
                  <p className="text-sm text-gray-500">
                    {logs.length} registro{logs.length !== 1 ? 's' : ''} encontrado{logs.length !== 1 ? 's' : ''}
                  </p>
                </div>
                <div className="overflow-x-auto">
                  <table className="min-w-full divide-y divide-gray-200">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Vehículo
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Inspector
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Tipo de Uso
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Kilometraje
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Fecha/Hora
                        </th>
                        <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                          Estado
                        </th>
                      </tr>
                    </thead>
                    <tbody className="bg-white divide-y divide-gray-200">
                      {logs.map((log) => (
                        <tr key={log.id} className="hover:bg-gray-50">
                          <td className="px-6 py-4 whitespace-nowrap">
                            <div>
                              <p className="text-sm font-medium text-gray-900 uppercase">
                                {log.vehicle_plate}
                              </p>
                              <p className="text-xs text-gray-500">
                                {log.vehicle_brand} {log.vehicle_model}
                              </p>
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                            {log.driver_name}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                              log.usage_type === 'patrol'
                                ? 'bg-blue-100 text-blue-800'
                                : log.usage_type === 'inspection'
                                ? 'bg-purple-100 text-purple-800'
                                : 'bg-gray-100 text-gray-800'
                            }`}>
                              {log.usage_type === 'patrol' ? 'Patrullaje' :
                               log.usage_type === 'inspection' ? 'Inspección' :
                               log.usage_type}
                            </span>
                            {log.purpose && (
                              <p className="text-xs text-gray-500 mt-1 max-w-xs truncate">
                                {log.purpose}
                              </p>
                            )}
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm">
                            <div>
                              <span className="text-gray-900">{log.start_km}</span>
                              <span className="text-gray-400 mx-1">→</span>
                              <span className="text-gray-900">{log.end_km || '...'}</span>
                              {log.total_distance_km && (
                                <p className="text-xs text-green-600">
                                  +{log.total_distance_km.toFixed(1)} km
                                </p>
                              )}
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap text-sm">
                            <div>
                              <p className="text-gray-900">
                                {format(new Date(log.start_time), 'dd/MM/yyyy', { locale: es })}
                              </p>
                              <p className="text-xs text-gray-500">
                                {format(new Date(log.start_time), 'HH:mm', { locale: es })}
                                {log.end_time && (
                                  <> - {format(new Date(log.end_time), 'HH:mm', { locale: es })}</>
                                )}
                              </p>
                            </div>
                          </td>
                          <td className="px-6 py-4 whitespace-nowrap">
                            {log.end_time ? (
                              <span className="px-2 py-1 text-xs font-medium rounded-full bg-green-100 text-green-800">
                                Finalizado
                              </span>
                            ) : (
                              <span className="px-2 py-1 text-xs font-medium rounded-full bg-yellow-100 text-yellow-800">
                                En curso
                              </span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            )}
          </>
        )}

        {activeTab === 'tracking' && (
          <div className="bg-white rounded-lg shadow overflow-hidden">
            <div className="p-4 border-b">
              <h3 className="text-lg font-medium text-gray-900">Seguimiento en Tiempo Real</h3>
              <p className="text-sm text-gray-500">
                Monitorea la ubicación de los vehículos activos
              </p>
            </div>
            <div className="h-[600px]">
              <VehicleTrackingMap />
            </div>
          </div>
        )}
      </div>
    </AppLayout>
  );
}
