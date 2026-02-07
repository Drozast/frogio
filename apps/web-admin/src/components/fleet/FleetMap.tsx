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

  // SVG de auto sedan visto desde arriba
  return L.divIcon({
    className: 'vehicle-marker',
    html: `
      <div style="
        width: 40px;
        height: 40px;
        display: flex;
        align-items: center;
        justify-content: center;
        transform: rotate(${rotation}deg);
        filter: drop-shadow(0 2px 4px rgba(0,0,0,0.3));
      ">
        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <!-- Cuerpo del auto -->
          <rect x="6" y="2" width="12" height="20" rx="4" fill="${color}" stroke="white" stroke-width="1.5"/>
          <!-- Ventanas -->
          <rect x="8" y="5" width="8" height="4" rx="1" fill="white" opacity="0.9"/>
          <rect x="8" y="15" width="8" height="3" rx="1" fill="white" opacity="0.9"/>
          <!-- Ruedas -->
          <rect x="4" y="6" width="3" height="5" rx="1" fill="#333"/>
          <rect x="17" y="6" width="3" height="5" rx="1" fill="#333"/>
          <rect x="4" y="13" width="3" height="5" rx="1" fill="#333"/>
          <rect x="17" y="13" width="3" height="5" rx="1" fill="#333"/>
          <!-- Luces delanteras -->
          <circle cx="9" cy="3.5" r="1" fill="#fff59d"/>
          <circle cx="15" cy="3.5" r="1" fill="#fff59d"/>
        </svg>
      </div>
    `,
    iconSize: [40, 40],
    iconAnchor: [20, 20],
    popupAnchor: [0, -20],
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
      center: [-37.174650, -72.936815], // Municipalidad de Santa Juana
      zoom: 15,
      zoomControl: true,
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
