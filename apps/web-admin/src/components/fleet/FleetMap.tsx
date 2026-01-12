'use client';

import { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { VehiclePosition } from '@/hooks/useFleetSocket';

interface FleetMapProps {
  vehicles: Map<string, VehiclePosition>;
  selectedVehicleId?: string | null;
  onVehicleClick?: (vehicleId: string) => void;
  geofences?: Geofence[];
  showGeofences?: boolean;
}

interface Geofence {
  id: string;
  name: string;
  geofenceType: 'circle' | 'polygon';
  centerLat?: number;
  centerLng?: number;
  radiusMeters?: number;
  polygonCoordinates?: { lat: number; lng: number }[];
  isActive: boolean;
}

const statusColors = {
  moving: '#22c55e', // green
  slow: '#eab308',   // yellow
  stopped: '#ef4444', // red
};

const createVehicleIcon = (status: 'moving' | 'slow' | 'stopped', heading?: number | null) => {
  const color = statusColors[status];
  const rotation = heading ?? 0;

  return L.divIcon({
    className: 'vehicle-marker',
    html: `
      <div style="
        width: 36px;
        height: 36px;
        display: flex;
        align-items: center;
        justify-content: center;
        background: ${color};
        border-radius: 50%;
        border: 3px solid white;
        box-shadow: 0 2px 6px rgba(0,0,0,0.3);
        transform: rotate(${rotation}deg);
      ">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="white">
          <path d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.21.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z"/>
        </svg>
      </div>
    `,
    iconSize: [36, 36],
    iconAnchor: [18, 18],
    popupAnchor: [0, -18],
  });
};

export default function FleetMap({
  vehicles,
  selectedVehicleId,
  onVehicleClick,
  geofences = [],
  showGeofences = true,
}: FleetMapProps) {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markersRef = useRef<Map<string, L.Marker>>(new Map());
  const geofenceLayersRef = useRef<Map<string, L.Circle | L.Polygon>>(new Map());
  const [mapReady, setMapReady] = useState(false);

  // Initialize map
  useEffect(() => {
    if (!mapRef.current || mapInstanceRef.current) return;

    const map = L.map(mapRef.current, {
      center: [-37.1738, -72.4598], // Santa Juana, Chile
      zoom: 14,
      zoomControl: true,
    });

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(map);

    mapInstanceRef.current = map;
    setMapReady(true);

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, []);

  // Update vehicle markers
  useEffect(() => {
    if (!mapInstanceRef.current || !mapReady) return;

    const map = mapInstanceRef.current;
    const currentVehicleIds = new Set(vehicles.keys());

    // Remove markers for vehicles no longer in the list
    markersRef.current.forEach((marker, vehicleId) => {
      if (!currentVehicleIds.has(vehicleId)) {
        marker.remove();
        markersRef.current.delete(vehicleId);
      }
    });

    // Update or create markers
    vehicles.forEach((vehicle, vehicleId) => {
      const existingMarker = markersRef.current.get(vehicleId);
      const position: L.LatLngExpression = [vehicle.latitude, vehicle.longitude];

      if (existingMarker) {
        existingMarker.setLatLng(position);
        existingMarker.setIcon(createVehicleIcon(vehicle.status, vehicle.heading));
      } else {
        const marker = L.marker(position, {
          icon: createVehicleIcon(vehicle.status, vehicle.heading),
        });

        marker.bindPopup(`
          <div style="min-width: 200px;">
            <h3 style="margin: 0 0 8px 0; font-weight: 600; font-size: 14px;">
              ${vehicle.vehiclePlate}
            </h3>
            <p style="margin: 0 0 4px 0; color: #6b7280; font-size: 12px;">
              ${vehicle.vehicleBrand} ${vehicle.vehicleModel}
            </p>
            <p style="margin: 0 0 8px 0; color: #374151; font-size: 13px;">
              <strong>Conductor:</strong> ${vehicle.inspectorName}
            </p>
            <div style="display: flex; gap: 12px; font-size: 12px; color: #6b7280;">
              <span>
                <strong>Velocidad:</strong> ${vehicle.speed ? `${vehicle.speed.toFixed(0)} km/h` : 'N/A'}
              </span>
            </div>
            <p style="margin: 8px 0 0 0; font-size: 11px; color: #9ca3af;">
              Última actualización: ${vehicle.recordedAt ? new Date(vehicle.recordedAt).toLocaleTimeString('es-CL') : 'N/A'}
            </p>
          </div>
        `);

        marker.on('click', () => {
          if (onVehicleClick) {
            onVehicleClick(vehicleId);
          }
        });

        marker.addTo(map);
        markersRef.current.set(vehicleId, marker);
      }

      // Highlight selected vehicle
      if (selectedVehicleId === vehicleId) {
        const marker = markersRef.current.get(vehicleId);
        if (marker) {
          marker.openPopup();
          map.setView(position, 16);
        }
      }
    });
  }, [vehicles, selectedVehicleId, onVehicleClick, mapReady]);

  // Update geofences
  useEffect(() => {
    if (!mapInstanceRef.current || !mapReady || !showGeofences) return;

    const map = mapInstanceRef.current;
    const currentGeofenceIds = new Set(geofences.map(g => g.id));

    // Remove old geofences
    geofenceLayersRef.current.forEach((layer, id) => {
      if (!currentGeofenceIds.has(id)) {
        layer.remove();
        geofenceLayersRef.current.delete(id);
      }
    });

    // Add or update geofences
    geofences.forEach((geofence) => {
      if (!geofence.isActive) return;

      const existingLayer = geofenceLayersRef.current.get(geofence.id);
      if (existingLayer) return; // Already exists

      if (geofence.geofenceType === 'circle' && geofence.centerLat && geofence.centerLng && geofence.radiusMeters) {
        const circle = L.circle([geofence.centerLat, geofence.centerLng], {
          radius: geofence.radiusMeters,
          color: '#6366f1',
          fillColor: '#6366f1',
          fillOpacity: 0.1,
          weight: 2,
        });
        circle.bindPopup(`<strong>${geofence.name}</strong>`);
        circle.addTo(map);
        geofenceLayersRef.current.set(geofence.id, circle);
      } else if (geofence.geofenceType === 'polygon' && geofence.polygonCoordinates) {
        const latLngs = geofence.polygonCoordinates.map(c => [c.lat, c.lng] as L.LatLngTuple);
        const polygon = L.polygon(latLngs, {
          color: '#6366f1',
          fillColor: '#6366f1',
          fillOpacity: 0.1,
          weight: 2,
        });
        polygon.bindPopup(`<strong>${geofence.name}</strong>`);
        polygon.addTo(map);
        geofenceLayersRef.current.set(geofence.id, polygon);
      }
    });
  }, [geofences, showGeofences, mapReady]);

  return (
    <div
      ref={mapRef}
      className="w-full h-full rounded-lg overflow-hidden"
      style={{ minHeight: '400px' }}
    />
  );
}
