'use client';

import { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import { useFleetSocket, VehiclePosition } from '@/hooks/useFleetSocket';
import { format } from 'date-fns';
import { es } from 'date-fns/locale';

// Fix default marker icon
delete (L.Icon.Default.prototype as { _getIconUrl?: () => string })._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
});

interface VehicleMarkerData {
  marker: L.Marker;
  popup: L.Popup;
}

export default function VehicleTrackingMap() {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markersRef = useRef<Map<string, VehicleMarkerData>>(new Map());
  const [selectedVehicle, setSelectedVehicle] = useState<string | null>(null);

  const { isConnected, vehicles, geofenceEvents, error } = useFleetSocket();

  // Initialize map
  useEffect(() => {
    if (!mapRef.current || mapInstanceRef.current) return;

    const map = L.map(mapRef.current, {
      center: [-37.1738, -72.4598], // Santa Juana center
      zoom: 13,
    });

    L.tileLayer('https://maps.drozast.xyz/styles/osm-bright/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> | Tiles: FROGIO',
    }).addTo(map);

    mapInstanceRef.current = map;

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, []);

  // Update markers when vehicles change
  useEffect(() => {
    if (!mapInstanceRef.current) return;

    const map = mapInstanceRef.current;
    const currentVehicleIds = new Set<string>();

    vehicles.forEach((position, vehicleId) => {
      currentVehicleIds.add(vehicleId);

      const existingData = markersRef.current.get(vehicleId);
      const latLng = L.latLng(position.latitude, position.longitude);

      if (existingData) {
        // Update existing marker
        existingData.marker.setLatLng(latLng);
        updatePopupContent(existingData.popup, position);
        updateMarkerRotation(existingData.marker, position.heading);
      } else {
        // Create new marker
        const marker = createVehicleMarker(position);
        marker.addTo(map);

        const popup = L.popup({
          closeButton: true,
          autoClose: false,
        }).setContent(createPopupContent(position));

        marker.bindPopup(popup);
        marker.on('click', () => setSelectedVehicle(vehicleId));

        markersRef.current.set(vehicleId, { marker, popup });
      }
    });

    // Remove markers for vehicles that are no longer active
    markersRef.current.forEach((data, vehicleId) => {
      if (!currentVehicleIds.has(vehicleId)) {
        data.marker.remove();
        markersRef.current.delete(vehicleId);
      }
    });

    // Fit bounds if we have vehicles
    if (vehicles.size > 0) {
      const bounds = L.latLngBounds(
        Array.from(vehicles.values()).map(v => L.latLng(v.latitude, v.longitude))
      );

      // Only fit bounds on first load or when a new vehicle appears
      if (markersRef.current.size === vehicles.size && vehicles.size <= 2) {
        map.fitBounds(bounds, { padding: [50, 50], maxZoom: 15 });
      }
    }
  }, [vehicles]);

  function createVehicleMarker(position: VehiclePosition): L.Marker {
    const color = getStatusColor(position.status);

    const icon = L.divIcon({
      className: 'vehicle-marker',
      html: `
        <div style="
          width: 36px;
          height: 36px;
          background-color: ${color};
          border: 3px solid white;
          border-radius: 50%;
          box-shadow: 0 2px 8px rgba(0,0,0,0.3);
          display: flex;
          align-items: center;
          justify-content: center;
          transform: rotate(${position.heading || 0}deg);
        ">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="white">
            <path d="M18.92 6.01C18.72 5.42 18.16 5 17.5 5h-11c-.66 0-1.21.42-1.42 1.01L3 12v8c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-1h12v1c0 .55.45 1 1 1h1c.55 0 1-.45 1-1v-8l-2.08-5.99zM6.5 16c-.83 0-1.5-.67-1.5-1.5S5.67 13 6.5 13s1.5.67 1.5 1.5S7.33 16 6.5 16zm11 0c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5zM5 11l1.5-4.5h11L19 11H5z"/>
          </svg>
        </div>
      `,
      iconSize: [36, 36],
      iconAnchor: [18, 18],
    });

    return L.marker([position.latitude, position.longitude], { icon });
  }

  function updateMarkerRotation(marker: L.Marker, heading: number | null) {
    if (heading === null) return;

    const icon = marker.getIcon() as L.DivIcon;
    if (icon && icon.options.html) {
      const html = icon.options.html as string;
      const updatedHtml = html.replace(
        /transform: rotate\(\d+deg\)/,
        `transform: rotate(${heading}deg)`
      );
      marker.setIcon(L.divIcon({
        ...icon.options,
        html: updatedHtml,
      }));
    }
  }

  function getStatusColor(status: string): string {
    switch (status) {
      case 'moving':
        return '#22c55e'; // green
      case 'slow':
        return '#f59e0b'; // amber
      case 'stopped':
        return '#ef4444'; // red
      default:
        return '#6b7280'; // gray
    }
  }

  function createPopupContent(position: VehiclePosition): string {
    return `
      <div style="min-width: 200px; font-family: system-ui, sans-serif;">
        <div style="font-weight: 600; font-size: 14px; margin-bottom: 8px; color: #111827;">
          ${position.vehiclePlate}
        </div>
        <div style="font-size: 12px; color: #6b7280; margin-bottom: 4px;">
          ${position.vehicleBrand} ${position.vehicleModel}
        </div>
        <div style="font-size: 12px; color: #374151; margin-bottom: 4px;">
          <strong>Inspector:</strong> ${position.inspectorName}
        </div>
        ${position.speed !== null ? `
          <div style="font-size: 12px; color: #374151; margin-bottom: 4px;">
            <strong>Velocidad:</strong> ${position.speed.toFixed(1)} km/h
          </div>
        ` : ''}
        <div style="font-size: 11px; color: #9ca3af; margin-top: 8px;">
          Actualizado: ${format(new Date(position.recordedAt), 'HH:mm:ss', { locale: es })}
        </div>
      </div>
    `;
  }

  function updatePopupContent(popup: L.Popup, position: VehiclePosition) {
    popup.setContent(createPopupContent(position));
  }

  const vehicleList = Array.from(vehicles.values());

  return (
    <div className="h-full flex">
      {/* Map */}
      <div className="flex-1 relative">
        <div ref={mapRef} className="absolute inset-0" />

        {/* Connection Status */}
        <div className="absolute top-4 left-4 z-[1000]">
          <div className={`px-3 py-1.5 rounded-full text-xs font-medium flex items-center gap-2 ${
            isConnected
              ? 'bg-green-100 text-green-800'
              : 'bg-red-100 text-red-800'
          }`}>
            <div className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-500' : 'bg-red-500'}`} />
            {isConnected ? 'Conectado' : 'Desconectado'}
          </div>
          {error && (
            <div className="mt-2 px-3 py-1.5 bg-red-100 text-red-800 rounded text-xs">
              {error}
            </div>
          )}
        </div>
      </div>

      {/* Sidebar */}
      <div className="w-80 border-l bg-white overflow-hidden flex flex-col">
        {/* Header */}
        <div className="p-4 border-b">
          <h3 className="font-medium text-gray-900">Vehículos Activos</h3>
          <p className="text-sm text-gray-500">
            {vehicleList.length} vehículo{vehicleList.length !== 1 ? 's' : ''} en ruta
          </p>
        </div>

        {/* Vehicle List */}
        <div className="flex-1 overflow-y-auto">
          {vehicleList.length === 0 ? (
            <div className="p-4 text-center text-gray-500 text-sm">
              No hay vehículos activos en este momento
            </div>
          ) : (
            <div className="divide-y">
              {vehicleList.map((vehicle) => (
                <button
                  key={vehicle.vehicleId}
                  onClick={() => {
                    setSelectedVehicle(vehicle.vehicleId);
                    if (mapInstanceRef.current) {
                      mapInstanceRef.current.setView(
                        [vehicle.latitude, vehicle.longitude],
                        16
                      );
                      const markerData = markersRef.current.get(vehicle.vehicleId);
                      if (markerData) {
                        markerData.marker.openPopup();
                      }
                    }
                  }}
                  className={`w-full p-4 text-left hover:bg-gray-50 transition-colors ${
                    selectedVehicle === vehicle.vehicleId ? 'bg-indigo-50' : ''
                  }`}
                >
                  <div className="flex items-start gap-3">
                    <div
                      className="w-3 h-3 rounded-full mt-1.5 flex-shrink-0"
                      style={{ backgroundColor: getStatusColor(vehicle.status) }}
                    />
                    <div className="flex-1 min-w-0">
                      <p className="font-medium text-gray-900 uppercase">
                        {vehicle.vehiclePlate}
                      </p>
                      <p className="text-sm text-gray-500 truncate">
                        {vehicle.vehicleBrand} {vehicle.vehicleModel}
                      </p>
                      <p className="text-xs text-gray-400 mt-1">
                        {vehicle.inspectorName}
                      </p>
                      <div className="flex items-center gap-3 mt-2 text-xs text-gray-500">
                        {vehicle.speed !== null && (
                          <span>{vehicle.speed.toFixed(0)} km/h</span>
                        )}
                        <span>
                          {format(new Date(vehicle.recordedAt), 'HH:mm')}
                        </span>
                      </div>
                    </div>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Recent Events */}
        {geofenceEvents.length > 0 && (
          <div className="border-t">
            <div className="p-3 bg-gray-50 border-b">
              <h4 className="text-sm font-medium text-gray-700">Alertas Recientes</h4>
            </div>
            <div className="max-h-40 overflow-y-auto">
              {geofenceEvents.slice(0, 5).map((event) => (
                <div key={event.id} className="p-3 border-b last:border-b-0 text-xs">
                  <div className="flex items-center gap-2">
                    <span className={`px-1.5 py-0.5 rounded ${
                      event.eventType === 'enter'
                        ? 'bg-green-100 text-green-700'
                        : 'bg-red-100 text-red-700'
                    }`}>
                      {event.eventType === 'enter' ? 'Entrada' : 'Salida'}
                    </span>
                    <span className="font-medium">{event.vehiclePlate}</span>
                  </div>
                  <p className="text-gray-500 mt-1">
                    {event.geofenceName}
                  </p>
                  <p className="text-gray-400 mt-0.5">
                    {format(new Date(event.recordedAt), 'dd/MM HH:mm')}
                  </p>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
