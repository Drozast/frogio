'use client';

/**
 * AdminLiveMap — mirrors apps/mobile/lib/features/admin/presentation/pages/admin_live_map_screen.dart
 *
 * Three layers:
 *   - Vehicles (green pulsing/bouncing car)
 *   - SOS (stacked red pulse circles + white SOS)
 *   - Reports (blue pin colored by status, category icon inside)
 *
 * Tap any marker → opens a side panel with full info.
 */

import { useEffect, useImperativeHandle, useMemo, useRef, forwardRef } from 'react';
import { MapContainer, TileLayer, Marker, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

export interface MapVehicle {
  id?: string;
  vehicleId?: string;
  vehiclePlate?: string;
  plate?: string;
  driverName?: string;
  driver_name?: string;
  latitude?: number | string | null;
  longitude?: number | string | null;
  speed?: number | string | null;
  lastUpdate?: string | null;
  last_update?: string | null;
}

export interface MapSos {
  id?: string;
  first_name?: string;
  last_name?: string;
  contact_phone?: string;
  address?: string;
  status?: string;
  message?: string;
  latitude: number;
  longitude: number;
  created_at?: string;
}

export interface MapReport {
  id?: string;
  title?: string;
  category?: string;
  report_type?: string;
  status?: string;
  address?: string;
  citizen_name?: string;
  latitude: number;
  longitude: number;
  created_at?: string;
}

interface Props {
  vehicles: MapVehicle[];
  sos: MapSos[];
  reports: MapReport[];
  showVehicles: boolean;
  showSos: boolean;
  showReports: boolean;
  onVehicleClick: (v: MapVehicle) => void;
  onSosClick: (s: MapSos) => void;
  onReportClick: (r: MapReport) => void;
}

export interface AdminLiveMapHandle {
  fitToMarkers: () => void;
}

const TILE_URL =
  'https://maps.supertools.cl/styles/osm-bright/{z}/{x}/{y}.png';
const DEFAULT_CENTER: [number, number] = [-37.1769, -72.9386];
const DEFAULT_ZOOM = 14;

function toNum(v: unknown): number | null {
  if (v == null) return null;
  if (typeof v === 'number') return Number.isFinite(v) ? v : null;
  const n = parseFloat(String(v));
  return Number.isFinite(n) ? n : null;
}

// Mobile mapping for report category → emoji icon
function reportEmoji(cat?: string): string {
  switch ((cat ?? '').toLowerCase()) {
    case 'infraestructura':
      return '🚧';
    case 'seguridad':
      return '🛡️';
    case 'salud':
      return '🏥';
    case 'medio_ambiente':
      return '🌿';
    case 'transito':
    case 'tránsito':
      return '🚦';
    case 'ruido':
      return '🔊';
    case 'limpieza':
      return '🧹';
    default:
      return '⚠️';
  }
}

function reportColor(status?: string): string {
  switch ((status ?? '').toLowerCase()) {
    case 'pendiente':
      return '#FB8C00'; // orange
    case 'en_proceso':
      return '#1976D2'; // blue
    case 'resuelto':
      return '#388E3C'; // green
    case 'rechazado':
      return '#D32F2F'; // red
    default:
      return '#757575';
  }
}

// Vehicle (bouncing green car) -------------------------------------------------
const vehicleIcon = (): L.DivIcon =>
  L.divIcon({
    className: 'admin-vehicle-marker',
    html: `
      <div class="vehicle-bounce">
        <div class="vehicle-circle">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="white">
            <path d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.21.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z"/>
          </svg>
        </div>
        <div class="vehicle-dot"></div>
      </div>
    `,
    iconSize: [40, 50],
    iconAnchor: [20, 25],
    popupAnchor: [0, -25],
  });

// SOS (stacked pulse) ----------------------------------------------------------
const sosIcon = (): L.DivIcon =>
  L.divIcon({
    className: 'admin-sos-marker',
    html: `
      <div class="sos-pulse">
        <div class="sos-ring1"></div>
        <div class="sos-ring2"></div>
        <div class="sos-core">
          <span class="sos-text">SOS</span>
        </div>
      </div>
    `,
    iconSize: [70, 70],
    iconAnchor: [35, 35],
    popupAnchor: [0, -35],
  });

// Report pin -------------------------------------------------------------------
const reportIcon = (color: string, emoji: string): L.DivIcon =>
  L.divIcon({
    className: 'admin-report-marker',
    html: `
      <div class="report-circle" style="background:${color}; box-shadow:0 6px 12px ${color}66;">
        <span class="report-emoji">${emoji}</span>
      </div>
    `,
    iconSize: [40, 40],
    iconAnchor: [20, 20],
    popupAnchor: [0, -20],
  });

function MapResizer() {
  const map = useMap();
  useEffect(() => {
    const t = setTimeout(() => map.invalidateSize(), 200);
    return () => clearTimeout(t);
  }, [map]);
  return null;
}

const AdminLiveMap = forwardRef<AdminLiveMapHandle, Props>(function AdminLiveMap(
  {
    vehicles,
    sos,
    reports,
    showVehicles,
    showSos,
    showReports,
    onVehicleClick,
    onSosClick,
    onReportClick,
  },
  ref
) {
  const mapRef = useRef<L.Map | null>(null);

  useImperativeHandle(
    ref,
    () => ({
      fitToMarkers: () => {
        const map = mapRef.current;
        if (!map) return;
        const points: L.LatLng[] = [];
        if (showVehicles) {
          vehicles.forEach((v) => {
            const lat = toNum(v.latitude);
            const lng = toNum(v.longitude);
            if (lat != null && lng != null) points.push(L.latLng(lat, lng));
          });
        }
        if (showSos) {
          sos.forEach((s) =>
            points.push(L.latLng(s.latitude, s.longitude))
          );
        }
        if (showReports) {
          reports.forEach((r) =>
            points.push(L.latLng(r.latitude, r.longitude))
          );
        }
        if (points.length === 0) {
          map.setView(DEFAULT_CENTER, DEFAULT_ZOOM);
          return;
        }
        if (points.length === 1) {
          map.setView(points[0], 16);
          return;
        }
        const bounds = L.latLngBounds(points);
        map.fitBounds(bounds, { padding: [60, 60] });
      },
    }),
    [vehicles, sos, reports, showVehicles, showSos, showReports]
  );

  const styles = useMemo(
    () => `
      .admin-vehicle-marker { background: transparent !important; border: 0 !important; }
      .admin-sos-marker { background: transparent !important; border: 0 !important; }
      .admin-report-marker { background: transparent !important; border: 0 !important; }

      .vehicle-bounce {
        display: flex; flex-direction: column; align-items: center;
        animation: vbounce 1.4s ease-in-out infinite;
      }
      @keyframes vbounce {
        0%, 100% { transform: translateY(0); }
        50% { transform: translateY(-6px); }
      }
      .vehicle-circle {
        width: 36px; height: 36px; border-radius: 50%;
        background: #4CAF50; border: 2px solid #fff;
        display: flex; align-items: center; justify-content: center;
        box-shadow: 0 0 12px rgba(76, 175, 80, 0.55);
      }
      .vehicle-dot {
        width: 8px; height: 8px; margin-top: 2px; border-radius: 50%;
        background: #4CAF50;
      }

      .sos-pulse {
        position: relative; width: 60px; height: 60px;
        display: flex; align-items: center; justify-content: center;
        animation: sosScale 1.2s ease-in-out infinite;
      }
      @keyframes sosScale {
        0%, 100% { transform: scale(1.0); }
        50%      { transform: scale(1.2); }
      }
      .sos-ring1 {
        position: absolute; inset: 0; width: 60px; height: 60px;
        border-radius: 50%; background: rgba(211, 47, 47, 0.30);
      }
      .sos-ring2 {
        position: absolute; width: 45px; height: 45px;
        border-radius: 50%; background: rgba(211, 47, 47, 0.50);
        border: 2px solid #fff;
      }
      .sos-core {
        position: relative; width: 35px; height: 35px;
        border-radius: 50%; background: #D32F2F; border: 2px solid #fff;
        display: flex; align-items: center; justify-content: center;
        box-shadow: 0 0 14px rgba(211, 47, 47, 0.7);
      }
      .sos-text {
        color: #fff; font-weight: 800; font-size: 10px; letter-spacing: 0.5px;
      }

      .report-circle {
        width: 40px; height: 40px; border-radius: 50%;
        border: 2px solid rgba(255,255,255,0.85);
        display: flex; align-items: center; justify-content: center;
      }
      .report-emoji { font-size: 20px; line-height: 1; }

      .leaflet-container { font-family: inherit; }
    `,
    []
  );

  return (
    <>
      <style>{styles}</style>
      <MapContainer
        center={DEFAULT_CENTER}
        zoom={DEFAULT_ZOOM}
        style={{ height: '100%', width: '100%' }}
        ref={(instance) => {
          // react-leaflet v4 forwards Map directly via ref
          mapRef.current = instance ?? null;
        }}
      >
        <MapResizer />
        <TileLayer
          attribution='&copy; OpenStreetMap | Tiles: FROGIO'
          url={TILE_URL}
        />

        {showVehicles &&
          vehicles.map((v, i) => {
            const lat = toNum(v.latitude);
            const lng = toNum(v.longitude);
            if (lat == null || lng == null) return null;
            return (
              <Marker
                key={`veh-${v.id ?? v.vehicleId ?? i}`}
                position={[lat, lng]}
                icon={vehicleIcon()}
                eventHandlers={{ click: () => onVehicleClick(v) }}
              />
            );
          })}

        {showReports &&
          reports.map((r, i) => {
            const color = reportColor(r.status);
            const emoji = reportEmoji(r.report_type ?? r.category);
            return (
              <Marker
                key={`rep-${r.id ?? i}`}
                position={[r.latitude, r.longitude]}
                icon={reportIcon(color, emoji)}
                eventHandlers={{ click: () => onReportClick(r) }}
              />
            );
          })}

        {showSos &&
          sos.map((s, i) => (
            <Marker
              key={`sos-${s.id ?? i}`}
              position={[s.latitude, s.longitude]}
              icon={sosIcon()}
              eventHandlers={{ click: () => onSosClick(s) }}
            />
          ))}
      </MapContainer>
    </>
  );
});

export default AdminLiveMap;
