'use client';

import { useState, useEffect, useCallback } from 'react';
import dynamic from 'next/dynamic';
import {
  XMarkIcon,
  TruckIcon,
  UserIcon,
  ClockIcon,
  MapPinIcon,
  DocumentArrowDownIcon,
  ArrowPathIcon,
} from '@heroicons/react/24/outline';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import * as XLSX from 'xlsx';
import { jsPDF } from 'jspdf';
import 'jspdf-autotable';

// Extend jsPDF type for autotable
declare module 'jspdf' {
  interface jsPDF {
    autoTable: (options: Record<string, unknown>) => jsPDF;
    lastAutoTable?: { finalY: number };
  }
}

// Dynamic import for map (client-side only)
const RouteMap = dynamic(() => import('./RouteMap'), {
  ssr: false,
  loading: () => (
    <div className="w-full h-64 flex items-center justify-center bg-gray-100 rounded-lg">
      <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600" />
    </div>
  ),
});

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
  status?: string;
}

interface RoutePoint {
  latitude: number;
  longitude: number;
  speed: number | null;
  recorded_at: string;
}

interface LogDetailModalProps {
  isOpen: boolean;
  onClose: () => void;
  log: VehicleLog;
}

const usageTypeLabels: Record<string, string> = {
  'official': 'Servicio Oficial',
  'emergency': 'Emergencia',
  'maintenance': 'Mantención',
  'transfer': 'Traslado',
  'other': 'Otro',
};

export default function LogDetailModal({ isOpen, onClose, log }: LogDetailModalProps) {
  const [routePoints, setRoutePoints] = useState<RoutePoint[]>([]);
  const [loadingRoute, setLoadingRoute] = useState(false);
  const [routeStats, setRouteStats] = useState<{
    totalDistance: number;
    avgSpeed: number;
    maxSpeed: number;
  } | null>(null);

  // Fetch route points when modal opens
  useEffect(() => {
    async function fetchRoutePoints() {
      if (!isOpen || !log.vehicle_id) return;

      setLoadingRoute(true);
      try {
        // Try to get route for the log's date range
        const logDate = log.start_time.split('T')[0];
        const response = await fetch(
          `/api/fleet/history?vehicleId=${log.vehicle_id}&startDate=${logDate}&endDate=${logDate}`
        );

        if (response.ok) {
          const data = await response.json();

          // Filter points to match the log's time range
          let filteredPoints = data.points || [];
          if (log.start_time && log.end_time) {
            const startTime = new Date(log.start_time).getTime();
            const endTime = new Date(log.end_time).getTime();
            filteredPoints = filteredPoints.filter((p: RoutePoint) => {
              const pointTime = new Date(p.recorded_at).getTime();
              return pointTime >= startTime && pointTime <= endTime;
            });
          }

          setRoutePoints(filteredPoints);

          // Calculate stats from filtered points
          if (filteredPoints.length > 0) {
            const speeds = filteredPoints
              .map((p: RoutePoint) => p.speed)
              .filter((s: number | null): s is number => s !== null);

            setRouteStats({
              totalDistance: data.totalDistance || log.total_distance_km || 0,
              avgSpeed: speeds.length > 0
                ? speeds.reduce((a: number, b: number) => a + b, 0) / speeds.length
                : 0,
              maxSpeed: speeds.length > 0 ? Math.max(...speeds) : 0,
            });
          }
        }
      } catch (error) {
        console.error('Error fetching route:', error);
      } finally {
        setLoadingRoute(false);
      }
    }

    fetchRoutePoints();
  }, [isOpen, log]);

  // Calculate duration
  const getDuration = () => {
    if (!log.start_time) return 'N/A';
    const start = new Date(log.start_time);
    const end = log.end_time ? new Date(log.end_time) : new Date();
    const diffMs = end.getTime() - start.getTime();
    const hours = Math.floor(diffMs / (1000 * 60 * 60));
    const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));
    return `${hours}h ${minutes}m`;
  };

  // Export to Excel
  const exportToExcel = () => {
    const workbook = XLSX.utils.book_new();

    // Main info sheet
    const infoData = [
      { Campo: 'Patente', Valor: log.vehicle_plate },
      { Campo: 'Vehículo', Valor: `${log.vehicle_brand} ${log.vehicle_model}` },
      { Campo: 'Conductor', Valor: log.driver_name },
      { Campo: 'Tipo de Uso', Valor: usageTypeLabels[log.usage_type] || log.usage_type },
      { Campo: 'Propósito', Valor: log.purpose || 'No especificado' },
      { Campo: 'Fecha Inicio', Valor: format(new Date(log.start_time), 'dd/MM/yyyy HH:mm', { locale: es }) },
      { Campo: 'Fecha Fin', Valor: log.end_time ? format(new Date(log.end_time), 'dd/MM/yyyy HH:mm', { locale: es }) : 'En curso' },
      { Campo: 'Duración', Valor: getDuration() },
      { Campo: 'Km Inicial', Valor: log.start_km.toString() },
      { Campo: 'Km Final', Valor: log.end_km?.toString() || 'N/A' },
      { Campo: 'Distancia Total', Valor: log.total_distance_km ? `${Number(log.total_distance_km).toFixed(1)} km` : 'N/A' },
      { Campo: 'Observaciones', Valor: log.observations || 'Sin observaciones' },
    ];

    if (routeStats) {
      infoData.push(
        { Campo: 'Velocidad Promedio', Valor: `${Number(routeStats.avgSpeed).toFixed(1)} km/h` },
        { Campo: 'Velocidad Máxima', Valor: `${Number(routeStats.maxSpeed).toFixed(1)} km/h` },
        { Campo: 'Puntos GPS', Valor: routePoints.length.toString() }
      );
    }

    const infoSheet = XLSX.utils.json_to_sheet(infoData);
    XLSX.utils.book_append_sheet(workbook, infoSheet, 'Información');

    // Route points sheet (if available)
    if (routePoints.length > 0) {
      const routeData = routePoints.map((point, index) => ({
        '#': index + 1,
        'Fecha/Hora': format(new Date(point.recorded_at), 'dd/MM/yyyy HH:mm:ss', { locale: es }),
        'Latitud': point.latitude.toFixed(6),
        'Longitud': point.longitude.toFixed(6),
        'Velocidad (km/h)': point.speed?.toFixed(1) || 'N/A',
      }));
      const routeSheet = XLSX.utils.json_to_sheet(routeData);
      XLSX.utils.book_append_sheet(workbook, routeSheet, 'Puntos GPS');
    }

    XLSX.writeFile(workbook, `bitacora_${log.vehicle_plate}_${format(new Date(log.start_time), 'yyyyMMdd_HHmm')}.xlsx`);
  };

  // Export to PDF
  const exportToPDF = () => {
    const doc = new jsPDF();
    const pageWidth = doc.internal.pageSize.getWidth();

    // Header
    doc.setFillColor(79, 70, 229); // indigo-600
    doc.rect(0, 0, pageWidth, 40, 'F');

    doc.setTextColor(255, 255, 255);
    doc.setFontSize(20);
    doc.setFont('helvetica', 'bold');
    doc.text('BITÁCORA DE VEHÍCULO', pageWidth / 2, 20, { align: 'center' });

    doc.setFontSize(12);
    doc.setFont('helvetica', 'normal');
    doc.text(`Municipalidad de Santa Juana`, pageWidth / 2, 30, { align: 'center' });

    // Reset text color
    doc.setTextColor(0, 0, 0);

    // Vehicle info box
    doc.setFillColor(249, 250, 251); // gray-50
    doc.rect(14, 50, pageWidth - 28, 30, 'F');
    doc.setDrawColor(229, 231, 235); // gray-200
    doc.rect(14, 50, pageWidth - 28, 30, 'S');

    doc.setFontSize(16);
    doc.setFont('helvetica', 'bold');
    doc.text(log.vehicle_plate, 20, 62);

    doc.setFontSize(11);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(107, 114, 128); // gray-500
    doc.text(`${log.vehicle_brand} ${log.vehicle_model}`, 20, 72);

    // Status badge
    const statusText = log.end_time ? 'FINALIZADO' : 'EN CURSO';
    const statusColor = log.end_time ? [34, 197, 94] : [234, 179, 8]; // green-500 / yellow-500
    doc.setFillColor(statusColor[0], statusColor[1], statusColor[2]);
    doc.roundedRect(pageWidth - 50, 55, 36, 8, 2, 2, 'F');
    doc.setFontSize(8);
    doc.setTextColor(255, 255, 255);
    doc.text(statusText, pageWidth - 32, 60.5, { align: 'center' });

    // Reset
    doc.setTextColor(0, 0, 0);

    // Main details table
    const detailsData = [
      ['Conductor', log.driver_name],
      ['Tipo de Uso', usageTypeLabels[log.usage_type] || log.usage_type],
      ['Propósito', log.purpose || 'No especificado'],
      ['Fecha Inicio', format(new Date(log.start_time), 'dd/MM/yyyy HH:mm', { locale: es })],
      ['Fecha Fin', log.end_time ? format(new Date(log.end_time), 'dd/MM/yyyy HH:mm', { locale: es }) : 'En curso'],
      ['Duración', getDuration()],
      ['Km Inicial', log.start_km.toString()],
      ['Km Final', log.end_km?.toString() || 'N/A'],
      ['Distancia Total', log.total_distance_km ? `${Number(log.total_distance_km).toFixed(1)} km` : 'N/A'],
    ];

    if (routeStats) {
      detailsData.push(
        ['Velocidad Promedio', `${Number(routeStats.avgSpeed).toFixed(1)} km/h`],
        ['Velocidad Máxima', `${Number(routeStats.maxSpeed).toFixed(1)} km/h`],
        ['Puntos GPS', routePoints.length.toString()]
      );
    }

    doc.autoTable({
      head: [['Campo', 'Valor']],
      body: detailsData,
      startY: 90,
      theme: 'striped',
      headStyles: { fillColor: [79, 70, 229] },
      styles: { fontSize: 10 },
      columnStyles: {
        0: { fontStyle: 'bold', cellWidth: 50 },
        1: { cellWidth: 'auto' },
      },
    });

    // Observations section
    const finalY = (doc as jsPDF & { lastAutoTable?: { finalY: number } }).lastAutoTable?.finalY || 180;

    if (log.observations) {
      doc.setFontSize(12);
      doc.setFont('helvetica', 'bold');
      doc.text('Observaciones:', 14, finalY + 15);

      doc.setFontSize(10);
      doc.setFont('helvetica', 'normal');
      const observationLines = doc.splitTextToSize(log.observations, pageWidth - 28);
      doc.text(observationLines, 14, finalY + 25);
    }

    // Route points (if available and fits on page)
    if (routePoints.length > 0 && routePoints.length <= 50) {
      doc.addPage();

      doc.setFontSize(14);
      doc.setFont('helvetica', 'bold');
      doc.text('Registro de Puntos GPS', 14, 20);

      const routeTableData = routePoints.slice(0, 50).map((point, index) => [
        (index + 1).toString(),
        format(new Date(point.recorded_at), 'HH:mm:ss'),
        point.latitude.toFixed(6),
        point.longitude.toFixed(6),
        point.speed?.toFixed(1) || 'N/A',
      ]);

      doc.autoTable({
        head: [['#', 'Hora', 'Latitud', 'Longitud', 'Velocidad']],
        body: routeTableData,
        startY: 30,
        theme: 'striped',
        headStyles: { fillColor: [79, 70, 229] },
        styles: { fontSize: 8 },
      });
    }

    // Footer on all pages
    const pageCount = doc.internal.pages.length - 1;
    for (let i = 1; i <= pageCount; i++) {
      doc.setPage(i);
      doc.setFontSize(8);
      doc.setTextColor(156, 163, 175); // gray-400
      doc.text(
        `Generado el ${format(new Date(), 'dd/MM/yyyy HH:mm', { locale: es })} - Página ${i} de ${pageCount}`,
        pageWidth / 2,
        doc.internal.pageSize.getHeight() - 10,
        { align: 'center' }
      );
    }

    doc.save(`bitacora_${log.vehicle_plate}_${format(new Date(log.start_time), 'yyyyMMdd_HHmm')}.pdf`);
  };

  // Handle escape key
  const handleKeyDown = useCallback((e: KeyboardEvent) => {
    if (e.key === 'Escape') {
      onClose();
    }
  }, [onClose]);

  useEffect(() => {
    if (isOpen) {
      document.addEventListener('keydown', handleKeyDown);
      document.body.style.overflow = 'hidden';
    }
    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, handleKeyDown]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/50 transition-opacity"
        onClick={onClose}
      />

      {/* Modal container */}
      <div className="fixed inset-0 overflow-y-auto">
        <div className="flex min-h-full items-center justify-center p-4">
          <div className="w-full max-w-4xl transform overflow-hidden rounded-2xl bg-white shadow-xl transition-all">
            {/* Header */}
            <div className="bg-indigo-600 px-6 py-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-white/20 rounded-lg">
                    <TruckIcon className="h-6 w-6 text-white" />
                  </div>
                  <div>
                    <h2 className="text-xl font-bold text-white">
                      {log.vehicle_plate}
                    </h2>
                    <p className="text-indigo-200 text-sm">
                      {log.vehicle_brand} {log.vehicle_model}
                    </p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  <span className={`px-3 py-1 rounded-full text-sm font-medium ${
                    log.end_time
                      ? 'bg-green-500 text-white'
                      : 'bg-yellow-500 text-white animate-pulse'
                  }`}>
                    {log.end_time ? 'Finalizado' : 'En curso'}
                  </span>
                  <button
                    onClick={onClose}
                    className="p-2 hover:bg-white/20 rounded-lg transition-colors"
                  >
                    <XMarkIcon className="h-5 w-5 text-white" />
                  </button>
                </div>
              </div>
            </div>

            {/* Content */}
            <div className="p-6 max-h-[70vh] overflow-y-auto">
                  {/* Quick Stats */}
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6">
                    <div className="bg-gray-50 rounded-lg p-4">
                      <div className="flex items-center gap-2 text-gray-500 text-sm mb-1">
                        <UserIcon className="h-4 w-4" />
                        Conductor
                      </div>
                      <p className="font-semibold text-gray-900">{log.driver_name}</p>
                    </div>

                    <div className="bg-gray-50 rounded-lg p-4">
                      <div className="flex items-center gap-2 text-gray-500 text-sm mb-1">
                        <ClockIcon className="h-4 w-4" />
                        Duración
                      </div>
                      <p className="font-semibold text-gray-900">{getDuration()}</p>
                    </div>

                    <div className="bg-gray-50 rounded-lg p-4">
                      <div className="flex items-center gap-2 text-gray-500 text-sm mb-1">
                        <MapPinIcon className="h-4 w-4" />
                        Distancia
                      </div>
                      <p className="font-semibold text-gray-900">
                        {log.total_distance_km ? `${Number(log.total_distance_km).toFixed(1)} km` : 'N/A'}
                      </p>
                    </div>

                    <div className="bg-gray-50 rounded-lg p-4">
                      <div className="text-gray-500 text-sm mb-1">Tipo</div>
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                        log.usage_type === 'emergency' ? 'bg-red-100 text-red-800' :
                        log.usage_type === 'official' ? 'bg-blue-100 text-blue-800' :
                        log.usage_type === 'maintenance' ? 'bg-orange-100 text-orange-800' :
                        'bg-gray-100 text-gray-800'
                      }`}>
                        {usageTypeLabels[log.usage_type] || log.usage_type}
                      </span>
                    </div>
                  </div>

                  {/* Details Grid */}
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                    {/* Left Column - Details */}
                    <div className="space-y-4">
                      <h3 className="font-semibold text-gray-900 border-b pb-2">Detalles del Viaje</h3>

                      <div className="grid grid-cols-2 gap-4 text-sm">
                        <div>
                          <p className="text-gray-500">Fecha Inicio</p>
                          <p className="font-medium">
                            {format(new Date(log.start_time), 'dd/MM/yyyy HH:mm', { locale: es })}
                          </p>
                        </div>
                        <div>
                          <p className="text-gray-500">Fecha Fin</p>
                          <p className="font-medium">
                            {log.end_time
                              ? format(new Date(log.end_time), 'dd/MM/yyyy HH:mm', { locale: es })
                              : 'En curso'
                            }
                          </p>
                        </div>
                        <div>
                          <p className="text-gray-500">Km Inicial</p>
                          <p className="font-medium">{log.start_km.toLocaleString()}</p>
                        </div>
                        <div>
                          <p className="text-gray-500">Km Final</p>
                          <p className="font-medium">
                            {log.end_km ? log.end_km.toLocaleString() : 'N/A'}
                          </p>
                        </div>
                      </div>

                      {log.purpose && (
                        <div>
                          <p className="text-gray-500 text-sm">Propósito</p>
                          <p className="text-gray-900">{log.purpose}</p>
                        </div>
                      )}

                      {log.observations && (
                        <div>
                          <p className="text-gray-500 text-sm">Observaciones</p>
                          <p className="text-gray-900 bg-gray-50 p-3 rounded-lg">{log.observations}</p>
                        </div>
                      )}

                      {routeStats && (
                        <div className="bg-indigo-50 rounded-lg p-4">
                          <h4 className="font-medium text-indigo-900 mb-2">Estadísticas GPS</h4>
                          <div className="grid grid-cols-3 gap-2 text-sm">
                            <div>
                              <p className="text-indigo-600">Vel. Promedio</p>
                              <p className="font-bold text-indigo-900">{Number(routeStats.avgSpeed).toFixed(1)} km/h</p>
                            </div>
                            <div>
                              <p className="text-indigo-600">Vel. Máxima</p>
                              <p className="font-bold text-indigo-900">{Number(routeStats.maxSpeed).toFixed(1)} km/h</p>
                            </div>
                            <div>
                              <p className="text-indigo-600">Puntos GPS</p>
                              <p className="font-bold text-indigo-900">{routePoints.length}</p>
                            </div>
                          </div>
                        </div>
                      )}
                    </div>

                    {/* Right Column - Map */}
                    <div>
                      <h3 className="font-semibold text-gray-900 border-b pb-2 mb-4">Recorrido</h3>
                      {loadingRoute ? (
                        <div className="h-64 flex items-center justify-center bg-gray-100 rounded-lg">
                          <div className="text-center">
                            <ArrowPathIcon className="h-8 w-8 text-gray-400 animate-spin mx-auto mb-2" />
                            <p className="text-sm text-gray-500">Cargando ruta...</p>
                          </div>
                        </div>
                      ) : routePoints.length > 0 ? (
                        <div className="h-64 rounded-lg overflow-hidden border">
                          <RouteMap points={routePoints} vehiclePlate={log.vehicle_plate} />
                        </div>
                      ) : (
                        <div className="h-64 flex items-center justify-center bg-gray-100 rounded-lg">
                          <div className="text-center">
                            <MapPinIcon className="h-12 w-12 text-gray-300 mx-auto mb-2" />
                            <p className="text-sm text-gray-500">Sin datos de ruta GPS</p>
                            <p className="text-xs text-gray-400">El recorrido no fue registrado</p>
                          </div>
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                {/* Footer with export buttons */}
                <div className="bg-gray-50 px-6 py-4 flex items-center justify-between border-t">
                  <p className="text-xs text-gray-500">
                    ID: {log.id.slice(0, 8)}...
                  </p>
                  <div className="flex items-center gap-3">
                    <button
                      onClick={exportToExcel}
                      className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
                    >
                      <DocumentArrowDownIcon className="h-4 w-4" />
                      Excel
                    </button>
                    <button
                      onClick={exportToPDF}
                      className="inline-flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-lg hover:bg-red-700"
                    >
                      <DocumentArrowDownIcon className="h-4 w-4" />
                      PDF
                    </button>
                    <button
                      onClick={onClose}
                      className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50"
                    >
                      Cerrar
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
  );
}
