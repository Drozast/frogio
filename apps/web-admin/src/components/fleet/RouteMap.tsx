'use client';

import { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

interface RoutePoint {
  latitude: number;
  longitude: number;
  speed: number | null;
  recorded_at: string;
}

interface RouteMapProps {
  points: RoutePoint[];
  vehiclePlate: string;
}

export default function RouteMap({ points, vehiclePlate }: RouteMapProps) {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const [mapReady, setMapReady] = useState(false);

  useEffect(() => {
    if (!mapRef.current || mapInstanceRef.current) return;

    const map = L.map(mapRef.current, {
      center: [-37.174650, -72.936815], // Municipalidad de Santa Juana
      zoom: 15,
    });

    L.tileLayer('https://maps.drozast.xyz/styles/osm-bright/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> | Tiles: FROGIO',
    }).addTo(map);

    mapInstanceRef.current = map;
    setMapReady(true);

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, []);

  useEffect(() => {
    if (!mapInstanceRef.current || !mapReady || points.length === 0) return;

    const map = mapInstanceRef.current;

    // Clear existing layers
    map.eachLayer((layer) => {
      if (layer instanceof L.Polyline || layer instanceof L.Marker || layer instanceof L.CircleMarker) {
        map.removeLayer(layer);
      }
    });

    // Draw route polyline
    const latLngs = points.map(p => [p.latitude, p.longitude] as L.LatLngTuple);

    // Create gradient polyline based on speed
    const polyline = L.polyline(latLngs, {
      color: '#4f46e5',
      weight: 4,
      opacity: 0.8,
    }).addTo(map);

    // Start marker
    const startPoint = points[0];
    L.marker([startPoint.latitude, startPoint.longitude], {
      icon: L.divIcon({
        className: 'start-marker',
        html: `
          <div style="
            width: 24px;
            height: 24px;
            background: #22c55e;
            border-radius: 50%;
            border: 3px solid white;
            box-shadow: 0 2px 6px rgba(0,0,0,0.3);
            display: flex;
            align-items: center;
            justify-content: center;
          ">
            <span style="color: white; font-size: 10px; font-weight: bold;">I</span>
          </div>
        `,
        iconSize: [24, 24],
        iconAnchor: [12, 12],
      }),
    })
      .bindPopup(`
        <strong>Inicio</strong><br>
        ${vehiclePlate}<br>
        <span style="color: #6b7280; font-size: 12px;">
          ${new Date(startPoint.recorded_at).toLocaleString('es-CL')}
        </span>
      `)
      .addTo(map);

    // End marker
    const endPoint = points[points.length - 1];
    L.marker([endPoint.latitude, endPoint.longitude], {
      icon: L.divIcon({
        className: 'end-marker',
        html: `
          <div style="
            width: 24px;
            height: 24px;
            background: #ef4444;
            border-radius: 50%;
            border: 3px solid white;
            box-shadow: 0 2px 6px rgba(0,0,0,0.3);
            display: flex;
            align-items: center;
            justify-content: center;
          ">
            <span style="color: white; font-size: 10px; font-weight: bold;">F</span>
          </div>
        `,
        iconSize: [24, 24],
        iconAnchor: [12, 12],
      }),
    })
      .bindPopup(`
        <strong>Fin</strong><br>
        ${vehiclePlate}<br>
        <span style="color: #6b7280; font-size: 12px;">
          ${new Date(endPoint.recorded_at).toLocaleString('es-CL')}
        </span>
      `)
      .addTo(map);

    // Add intermediate points (every 10th point) for speed info
    points.forEach((point, index) => {
      if (index % 10 === 0 && index !== 0 && index !== points.length - 1) {
        L.circleMarker([point.latitude, point.longitude], {
          radius: 4,
          fillColor: point.speed && point.speed > 50 ? '#ef4444' : '#6366f1',
          color: 'white',
          weight: 2,
          fillOpacity: 0.8,
        })
          .bindPopup(`
            <strong>${new Date(point.recorded_at).toLocaleTimeString('es-CL')}</strong><br>
            Velocidad: ${point.speed ? `${point.speed.toFixed(0)} km/h` : 'N/A'}
          `)
          .addTo(map);
      }
    });

    // Fit bounds
    map.fitBounds(polyline.getBounds(), { padding: [50, 50] });
  }, [points, vehiclePlate, mapReady]);

  return (
    <div
      ref={mapRef}
      className="w-full h-full"
      style={{ minHeight: '400px' }}
    />
  );
}
