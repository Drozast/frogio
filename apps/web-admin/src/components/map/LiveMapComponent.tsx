'use client';

import { useEffect, useMemo, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap, Circle } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

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

interface LiveMapComponentProps {
  reports: Report[];
  inspectors: Inspector[];
  vehicles: Vehicle[];
  panicAlerts: PanicAlert[];
}

// Custom icons
const createIcon = (color: string, iconHtml: string) => {
  return L.divIcon({
    className: 'custom-marker',
    html: `
      <div style="
        background: ${color};
        width: 32px;
        height: 32px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        border: 3px solid white;
        box-shadow: 0 2px 6px rgba(0,0,0,0.3);
      ">
        ${iconHtml}
      </div>
    `,
    iconSize: [32, 32],
    iconAnchor: [16, 16],
    popupAnchor: [0, -16],
  });
};

const reportIcon = createIcon('#3B82F6', '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="white" viewBox="0 0 24 24"><path d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"/></svg>');

const reportPendingIcon = createIcon('#F59E0B', '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="white" viewBox="0 0 24 24"><path d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z"/></svg>');

const reportUrgentIcon = createIcon('#EF4444', '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="white" viewBox="0 0 24 24"><path d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z"/></svg>');

const inspectorIcon = createIcon('#10B981', '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="white" viewBox="0 0 24 24"><path d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z"/></svg>');

const vehicleIcon = createIcon('#6366F1', '<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="white" viewBox="0 0 24 24"><path d="M8.25 18.75a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 01-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 00-3.213-9.193 2.056 2.056 0 00-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 00-10.026 0 1.106 1.106 0 00-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"/></svg>');

const panicIcon = L.divIcon({
  className: 'panic-marker',
  html: `
    <div style="position: relative;">
      <div class="panic-pulse" style="
        position: absolute;
        width: 60px;
        height: 60px;
        top: -14px;
        left: -14px;
        background: rgba(239, 68, 68, 0.4);
        border-radius: 50%;
        animation: panic-pulse 1s ease-out infinite;
      "></div>
      <div style="
        position: relative;
        background: #DC2626;
        width: 32px;
        height: 32px;
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        border: 3px solid white;
        box-shadow: 0 2px 10px rgba(220, 38, 38, 0.5);
        z-index: 1;
      ">
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" fill="white" viewBox="0 0 24 24">
          <path d="M12 9v3.75m9-.75a9 9 0 11-18 0 9 9 0 0118 0zm-9 3.75h.008v.008H12v-.008z"/>
        </svg>
      </div>
    </div>
  `,
  iconSize: [32, 32],
  iconAnchor: [16, 16],
  popupAnchor: [0, -20],
});

// Component to fit bounds
function FitBounds({ positions }: { positions: [number, number][] }) {
  const map = useMap();

  useEffect(() => {
    if (positions.length > 0) {
      const bounds = L.latLngBounds(positions);
      map.fitBounds(bounds, { padding: [50, 50], maxZoom: 15 });
    }
  }, []);

  return null;
}

export default function LiveMapComponent({
  reports,
  inspectors,
  vehicles,
  panicAlerts,
}: LiveMapComponentProps) {
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  // Default center: Santa Juana, Chile
  const defaultCenter: [number, number] = [-37.1736, -72.9386];

  // Collect all positions for bounds
  const allPositions = useMemo(() => {
    const positions: [number, number][] = [];

    reports.forEach(r => {
      if (r.latitude && r.longitude) {
        positions.push([r.latitude, r.longitude]);
      }
    });

    inspectors.forEach(i => {
      if (i.latitude && i.longitude) {
        positions.push([i.latitude, i.longitude]);
      }
    });

    vehicles.forEach(v => {
      if (v.latitude && v.longitude) {
        positions.push([v.latitude, v.longitude]);
      }
    });

    panicAlerts.forEach(p => {
      positions.push([p.latitude, p.longitude]);
    });

    return positions;
  }, [reports, inspectors, vehicles, panicAlerts]);

  const getReportIcon = (report: Report) => {
    if (report.priority === 'urgente' || report.type === 'emergencia') {
      return reportUrgentIcon;
    }
    if (report.status === 'pendiente') {
      return reportPendingIcon;
    }
    return reportIcon;
  };

  if (!mounted) {
    return (
      <div className="flex items-center justify-center h-full bg-gray-100">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary"></div>
      </div>
    );
  }

  return (
    <>
      <style jsx global>{`
        @keyframes panic-pulse {
          0% {
            transform: scale(0.5);
            opacity: 1;
          }
          100% {
            transform: scale(2);
            opacity: 0;
          }
        }
        .panic-marker .panic-pulse {
          animation: panic-pulse 1s ease-out infinite;
        }
        .leaflet-popup-content-wrapper {
          border-radius: 12px;
        }
        .leaflet-popup-content {
          margin: 12px;
        }
      `}</style>

      <MapContainer
        center={defaultCenter}
        zoom={13}
        style={{ height: '100%', width: '100%' }}
        zoomControl={true}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        {allPositions.length > 0 && <FitBounds positions={allPositions} />}

        {/* Panic Alert Markers with pulsing effect */}
        {panicAlerts.map(alert => (
          <Marker
            key={`panic-${alert.id}`}
            position={[alert.latitude, alert.longitude]}
            icon={panicIcon}
          >
            <Popup>
              <div className="min-w-[200px]">
                <div className="bg-red-600 text-white px-3 py-2 -mx-3 -mt-3 rounded-t-lg mb-3">
                  <p className="font-bold">🚨 ALERTA SOS</p>
                </div>
                <p className="font-semibold text-gray-900">
                  {alert.first_name} {alert.last_name}
                </p>
                {alert.address && (
                  <p className="text-sm text-gray-600 mt-1">{alert.address}</p>
                )}
                {alert.message && (
                  <p className="text-sm text-gray-500 mt-2 italic">"{alert.message}"</p>
                )}
                <p className="text-xs text-gray-400 mt-2">
                  {new Date(alert.created_at).toLocaleString('es-CL')}
                </p>
                <a
                  href={`https://maps.google.com/?q=${alert.latitude},${alert.longitude}`}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="mt-3 block text-center bg-red-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-red-700"
                >
                  Abrir en Google Maps
                </a>
              </div>
            </Popup>
            <Circle
              center={[alert.latitude, alert.longitude]}
              radius={200}
              pathOptions={{
                color: '#DC2626',
                fillColor: '#DC2626',
                fillOpacity: 0.1,
              }}
            />
          </Marker>
        ))}

        {/* Report Markers */}
        {reports.map(report => {
          if (!report.latitude || !report.longitude) return null;
          return (
            <Marker
              key={`report-${report.id}`}
              position={[report.latitude, report.longitude]}
              icon={getReportIcon(report)}
            >
              <Popup>
                <div className="min-w-[200px]">
                  <p className="font-semibold text-gray-900">{report.title}</p>
                  <div className="flex items-center gap-2 mt-2">
                    <span className={`px-2 py-0.5 text-xs rounded-full ${
                      report.status === 'pendiente'
                        ? 'bg-yellow-100 text-yellow-800'
                        : report.status === 'en_proceso'
                        ? 'bg-blue-100 text-blue-800'
                        : 'bg-green-100 text-green-800'
                    }`}>
                      {report.status}
                    </span>
                    <span className="text-xs text-gray-500">{report.type}</span>
                  </div>
                  {report.address && (
                    <p className="text-sm text-gray-600 mt-2">{report.address}</p>
                  )}
                  <p className="text-xs text-gray-400 mt-2">
                    {new Date(report.created_at).toLocaleDateString('es-CL')}
                  </p>
                </div>
              </Popup>
            </Marker>
          );
        })}

        {/* Inspector Markers */}
        {inspectors.map(inspector => {
          if (!inspector.latitude || !inspector.longitude) return null;
          return (
            <Marker
              key={`inspector-${inspector.id}`}
              position={[inspector.latitude, inspector.longitude]}
              icon={inspectorIcon}
            >
              <Popup>
                <div className="min-w-[150px]">
                  <p className="font-semibold text-gray-900">
                    {inspector.first_name} {inspector.last_name}
                  </p>
                  <p className="text-xs text-emerald-600 mt-1">Inspector activo</p>
                  {inspector.last_location_update && (
                    <p className="text-xs text-gray-400 mt-2">
                      Última ubicación: {new Date(inspector.last_location_update).toLocaleTimeString('es-CL')}
                    </p>
                  )}
                </div>
              </Popup>
            </Marker>
          );
        })}

        {/* Vehicle Markers */}
        {vehicles.map(vehicle => {
          if (!vehicle.latitude || !vehicle.longitude) return null;
          return (
            <Marker
              key={`vehicle-${vehicle.id}`}
              position={[vehicle.latitude, vehicle.longitude]}
              icon={vehicleIcon}
            >
              <Popup>
                <div className="min-w-[150px]">
                  <p className="font-semibold text-gray-900">{vehicle.plate}</p>
                  <p className="text-sm text-gray-600">{vehicle.model}</p>
                  {vehicle.current_user_name && (
                    <p className="text-xs text-indigo-600 mt-1">
                      En uso por: {vehicle.current_user_name}
                    </p>
                  )}
                  {vehicle.last_location_update && (
                    <p className="text-xs text-gray-400 mt-2">
                      Última ubicación: {new Date(vehicle.last_location_update).toLocaleTimeString('es-CL')}
                    </p>
                  )}
                </div>
              </Popup>
            </Marker>
          );
        })}
      </MapContainer>
    </>
  );
}
