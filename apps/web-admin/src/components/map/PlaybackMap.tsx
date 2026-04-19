'use client';

/**
 * Route playback map.
 * - Light-gray full route polyline
 * - Bright green animated polyline up to currentIndex
 * - Start/end flags
 * - Rotating green vehicle marker based on heading
 */

import { useEffect, useMemo, useRef } from 'react';
import { MapContainer, TileLayer, Polyline, Marker, useMap } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

import { FROGIO_COLORS } from '@/lib/theme';
import type { RoutePoint } from '@/app/fleet/playback/[logId]/page';

const TILE_URL =
  'https://maps.supertools.cl/styles/osm-bright/{z}/{x}/{y}.png';

interface Props {
  points: RoutePoint[];
  currentIndex: number;
  autoPan?: boolean;
}

function flagIcon(color: string, emoji: string): L.DivIcon {
  return L.divIcon({
    className: 'playback-flag-marker',
    html: `<div style="color:${color}; font-size:26px; filter: drop-shadow(0 2px 3px rgba(0,0,0,.3));">${emoji}</div>`,
    iconSize: [28, 28],
    iconAnchor: [14, 24],
  });
}

function vehicleMarkerIcon(heading: number): L.DivIcon {
  return L.divIcon({
    className: 'playback-vehicle-marker',
    html: `
      <div style="
        width: 48px; height: 48px; border-radius: 50%;
        background: ${FROGIO_COLORS.primary};
        border: 3px solid #fff;
        display:flex; align-items:center; justify-content:center;
        box-shadow: 0 0 18px ${FROGIO_COLORS.primary}99;
        transform: rotate(${heading}deg);
      ">
        <svg width="26" height="26" viewBox="0 0 24 24" fill="white"
             style="transform: rotate(-45deg);">
          <path d="M12 2L4 20l8-4 8 4L12 2z"/>
        </svg>
      </div>
    `,
    iconSize: [48, 48],
    iconAnchor: [24, 24],
  });
}

function FitBounds({ points }: { points: RoutePoint[] }) {
  const map = useMap();
  const didFitRef = useRef(false);
  useEffect(() => {
    if (didFitRef.current || points.length === 0) return;
    const t = setTimeout(() => {
      map.invalidateSize();
      if (points.length === 1) {
        map.setView([points[0].lat, points[0].lng], 15);
      } else {
        const bounds = L.latLngBounds(points.map((p) => [p.lat, p.lng]));
        map.fitBounds(bounds, { padding: [60, 60] });
      }
      didFitRef.current = true;
    }, 150);
    return () => clearTimeout(t);
  }, [map, points]);
  return null;
}

function AutoPan({
  current,
  autoPan,
}: {
  current: RoutePoint | null;
  autoPan: boolean;
}) {
  const map = useMap();
  useEffect(() => {
    if (!autoPan || !current) return;
    const c = map.getCenter();
    const target = L.latLng(current.lat, current.lng);
    if (c.distanceTo(target) > 80) {
      map.panTo(target, { animate: true, duration: 0.35 });
    }
  }, [map, current, autoPan]);
  return null;
}

export default function PlaybackMap({
  points,
  currentIndex,
  autoPan = true,
}: Props) {
  const fullCoords = useMemo(
    () => points.map((p) => [p.lat, p.lng] as [number, number]),
    [points]
  );
  const progressCoords = useMemo(
    () =>
      points
        .slice(0, Math.max(1, currentIndex + 1))
        .map((p) => [p.lat, p.lng] as [number, number]),
    [points, currentIndex]
  );

  if (points.length === 0) {
    return (
      <div className="h-full w-full flex items-center justify-center bg-gray-50">
        <p className="text-sm text-muted-foreground">Sin puntos de ruta</p>
      </div>
    );
  }

  const start = points[0];
  const end = points[points.length - 1];
  const current = points[currentIndex] ?? points[0];

  return (
    <MapContainer
      center={[start.lat, start.lng]}
      zoom={15}
      style={{ height: '100%', width: '100%' }}
    >
      <TileLayer
        attribution='&copy; OpenStreetMap | Tiles: FROGIO'
        url={TILE_URL}
      />
      <FitBounds points={points} />
      <AutoPan current={current} autoPan={autoPan} />

      {/* Full route */}
      {fullCoords.length >= 2 && (
        <Polyline
          positions={fullCoords}
          pathOptions={{ color: FROGIO_COLORS.border, weight: 4, opacity: 0.9 }}
        />
      )}

      {/* Animated progress */}
      {progressCoords.length >= 2 && (
        <Polyline
          positions={progressCoords}
          pathOptions={{
            color: FROGIO_COLORS.primary,
            weight: 6,
            opacity: 1,
          }}
        />
      )}

      {/* Start */}
      <Marker
        position={[start.lat, start.lng]}
        icon={flagIcon(FROGIO_COLORS.success, '🏁')}
      />

      {/* End */}
      <Marker
        position={[end.lat, end.lng]}
        icon={flagIcon(FROGIO_COLORS.emergency, '🏁')}
      />

      {/* Moving vehicle */}
      <Marker
        key={`cursor-${currentIndex}`}
        position={[current.lat, current.lng]}
        icon={vehicleMarkerIcon(current.heading ?? 0)}
      />
    </MapContainer>
  );
}
