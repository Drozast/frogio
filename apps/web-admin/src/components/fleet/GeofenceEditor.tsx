'use client';

import { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import 'leaflet-draw/dist/leaflet.draw.css';

interface Geofence {
  id: string;
  name: string;
  geofence_type: 'circle' | 'polygon';
  center_lat: number | null;
  center_lng: number | null;
  radius_meters: number | null;
  polygon_coordinates: { lat: number; lng: number }[] | null;
  is_active: boolean;
}

interface GeofenceEditorProps {
  geofences?: Geofence[];
  selectedGeofenceId?: string | null;
  readOnly?: boolean;
  onSave?: (data: {
    name: string;
    description?: string;
    geofenceType: 'circle' | 'polygon';
    centerLat?: number;
    centerLng?: number;
    radiusMeters?: number;
    polygonCoordinates?: { lat: number; lng: number }[];
    alertOnEnter: boolean;
    alertOnExit: boolean;
  }) => void;
  onCancel?: () => void;
}

export default function GeofenceEditor({
  geofences = [],
  selectedGeofenceId,
  readOnly = false,
  onSave,
  onCancel,
}: GeofenceEditorProps) {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const drawnItemsRef = useRef<L.FeatureGroup | null>(null);
  const geofenceLayersRef = useRef<Map<string, L.Circle | L.Polygon>>(new Map());
  const [mapReady, setMapReady] = useState(false);

  // Form state (only used when not readOnly)
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    geofenceType: 'circle' as 'circle' | 'polygon',
    alertOnEnter: true,
    alertOnExit: true,
  });
  const [drawnGeometry, setDrawnGeometry] = useState<{
    type: 'circle' | 'polygon';
    center?: { lat: number; lng: number };
    radius?: number;
    coordinates?: { lat: number; lng: number }[];
  } | null>(null);

  // Initialize map
  useEffect(() => {
    if (!mapRef.current || mapInstanceRef.current) return;

    const map = L.map(mapRef.current, {
      center: [-37.1738, -72.4598],
      zoom: 14,
    });

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(map);

    // Create feature group for drawn items
    const drawnItems = new L.FeatureGroup();
    map.addLayer(drawnItems);
    drawnItemsRef.current = drawnItems;

    if (!readOnly) {
      // Add draw controls
      import('leaflet-draw').then(() => {
        const drawControl = new L.Control.Draw({
          position: 'topright',
          draw: {
            polyline: false,
            rectangle: false,
            marker: false,
            circlemarker: false,
            circle: {
              shapeOptions: {
                color: '#6366f1',
                fillColor: '#6366f1',
                fillOpacity: 0.2,
              },
            },
            polygon: {
              allowIntersection: false,
              shapeOptions: {
                color: '#6366f1',
                fillColor: '#6366f1',
                fillOpacity: 0.2,
              },
            },
          },
          edit: {
            featureGroup: drawnItems,
            remove: true,
          },
        });
        map.addControl(drawControl);

        // Handle draw events
        map.on(L.Draw.Event.CREATED, (e: unknown) => {
          const event = e as L.DrawEvents.Created;
          drawnItems.clearLayers();
          const layer = event.layer;
          drawnItems.addLayer(layer);

          if (event.layerType === 'circle') {
            const circle = layer as L.Circle;
            const center = circle.getLatLng();
            setDrawnGeometry({
              type: 'circle',
              center: { lat: center.lat, lng: center.lng },
              radius: circle.getRadius(),
            });
            setFormData(prev => ({ ...prev, geofenceType: 'circle' }));
          } else if (event.layerType === 'polygon') {
            const polygon = layer as L.Polygon;
            const latLngs = polygon.getLatLngs()[0] as L.LatLng[];
            setDrawnGeometry({
              type: 'polygon',
              coordinates: latLngs.map(ll => ({ lat: ll.lat, lng: ll.lng })),
            });
            setFormData(prev => ({ ...prev, geofenceType: 'polygon' }));
          }
        });

        map.on(L.Draw.Event.DELETED, () => {
          setDrawnGeometry(null);
        });
      });
    }

    mapInstanceRef.current = map;
    setMapReady(true);

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, [readOnly]);

  // Display existing geofences
  useEffect(() => {
    if (!mapInstanceRef.current || !mapReady) return;

    const map = mapInstanceRef.current;

    // Clear old layers
    geofenceLayersRef.current.forEach(layer => layer.remove());
    geofenceLayersRef.current.clear();

    // Add geofences
    geofences.forEach((geofence) => {
      if (!geofence.is_active && readOnly) return;

      const isSelected = selectedGeofenceId === geofence.id;
      const color = isSelected ? '#4f46e5' : '#6b7280';

      if (geofence.geofence_type === 'circle' && geofence.center_lat && geofence.center_lng && geofence.radius_meters) {
        const circle = L.circle([geofence.center_lat, geofence.center_lng], {
          radius: geofence.radius_meters,
          color,
          fillColor: color,
          fillOpacity: isSelected ? 0.3 : 0.1,
          weight: isSelected ? 3 : 2,
        });
        circle.bindPopup(`<strong>${geofence.name}</strong>`);
        circle.addTo(map);
        geofenceLayersRef.current.set(geofence.id, circle);

        if (isSelected) {
          map.fitBounds(circle.getBounds(), { padding: [50, 50] });
        }
      } else if (geofence.geofence_type === 'polygon' && geofence.polygon_coordinates) {
        const latLngs = geofence.polygon_coordinates.map(c => [c.lat, c.lng] as L.LatLngTuple);
        const polygon = L.polygon(latLngs, {
          color,
          fillColor: color,
          fillOpacity: isSelected ? 0.3 : 0.1,
          weight: isSelected ? 3 : 2,
        });
        polygon.bindPopup(`<strong>${geofence.name}</strong>`);
        polygon.addTo(map);
        geofenceLayersRef.current.set(geofence.id, polygon);

        if (isSelected) {
          map.fitBounds(polygon.getBounds(), { padding: [50, 50] });
        }
      }
    });
  }, [geofences, selectedGeofenceId, mapReady, readOnly]);

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!drawnGeometry || !formData.name.trim() || !onSave) return;

    onSave({
      name: formData.name,
      description: formData.description || undefined,
      geofenceType: drawnGeometry.type,
      centerLat: drawnGeometry.center?.lat,
      centerLng: drawnGeometry.center?.lng,
      radiusMeters: drawnGeometry.radius,
      polygonCoordinates: drawnGeometry.coordinates,
      alertOnEnter: formData.alertOnEnter,
      alertOnExit: formData.alertOnExit,
    });
  }

  if (readOnly) {
    return (
      <div
        ref={mapRef}
        className="w-full h-full"
        style={{ minHeight: '400px' }}
      />
    );
  }

  return (
    <div className="h-full flex flex-col">
      {/* Form */}
      <div className="p-4 border-b bg-gray-50">
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Nombre de la Zona
              </label>
              <input
                type="text"
                value={formData.name}
                onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                placeholder="Ej: Centro de la ciudad"
                required
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">
                Descripción (opcional)
              </label>
              <input
                type="text"
                value={formData.description}
                onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                placeholder="Descripción breve"
                className="w-full px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
              />
            </div>
          </div>

          <div className="flex items-center gap-6">
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={formData.alertOnEnter}
                onChange={(e) => setFormData(prev => ({ ...prev, alertOnEnter: e.target.checked }))}
                className="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
              />
              <span className="text-sm text-gray-700">Alertar al entrar</span>
            </label>
            <label className="flex items-center gap-2">
              <input
                type="checkbox"
                checked={formData.alertOnExit}
                onChange={(e) => setFormData(prev => ({ ...prev, alertOnExit: e.target.checked }))}
                className="w-4 h-4 text-indigo-600 border-gray-300 rounded focus:ring-indigo-500"
              />
              <span className="text-sm text-gray-700">Alertar al salir</span>
            </label>
          </div>

          <div className="flex items-center justify-between pt-2">
            <p className="text-sm text-gray-500">
              {drawnGeometry
                ? `${drawnGeometry.type === 'circle' ? 'Círculo' : 'Polígono'} dibujado`
                : 'Dibuja un círculo o polígono en el mapa'
              }
            </p>
            <div className="flex gap-2">
              <button
                type="button"
                onClick={onCancel}
                className="px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 rounded-lg transition-colors"
              >
                Cancelar
              </button>
              <button
                type="submit"
                disabled={!drawnGeometry || !formData.name.trim()}
                className="px-4 py-2 bg-indigo-600 text-white text-sm font-medium rounded-lg hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Guardar Zona
              </button>
            </div>
          </div>
        </form>
      </div>

      {/* Map */}
      <div
        ref={mapRef}
        className="flex-1"
        style={{ minHeight: '300px' }}
      />
    </div>
  );
}
