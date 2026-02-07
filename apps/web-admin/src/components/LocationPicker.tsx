'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import { MapPinIcon, MagnifyingGlassIcon, XMarkIcon } from '@heroicons/react/24/outline';

interface LocationPickerProps {
  latitude?: number | null;
  longitude?: number | null;
  address?: string;
  onLocationChange: (lat: number, lng: number, address?: string) => void;
  onAddressChange?: (address: string) => void;
}

// Santa Juana default coordinates
const DEFAULT_CENTER = { lat: -37.1708, lng: -72.9406 };
const DEFAULT_ZOOM = 14;

export default function LocationPicker({
  latitude,
  longitude,
  address,
  onLocationChange,
  onAddressChange,
}: LocationPickerProps) {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const markerRef = useRef<L.Marker | null>(null);
  const [isMapReady, setIsMapReady] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [searching, setSearching] = useState(false);
  const [searchResults, setSearchResults] = useState<Array<{
    display_name: string;
    lat: string;
    lon: string;
  }>>([]);
  const [showResults, setShowResults] = useState(false);

  // Initialize map
  useEffect(() => {
    if (typeof window === 'undefined' || !mapRef.current || mapInstanceRef.current) return;

    const initMap = async () => {
      const L = (await import('leaflet')).default;
      // CSS is imported via link tag in layout

      // Fix default marker icon
      delete (L.Icon.Default.prototype as unknown as { _getIconUrl?: unknown })._getIconUrl;
      L.Icon.Default.mergeOptions({
        iconRetinaUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon-2x.png',
        iconUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-icon.png',
        shadowUrl: 'https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.9.4/images/marker-shadow.png',
      });

      const initialCenter = latitude && longitude
        ? { lat: latitude, lng: longitude }
        : DEFAULT_CENTER;

      const map = L.map(mapRef.current!, {
        center: [initialCenter.lat, initialCenter.lng],
        zoom: latitude && longitude ? 16 : DEFAULT_ZOOM,
      });

      L.tileLayer('https://maps.drozast.xyz/styles/osm-bright/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> | Tiles: FROGIO',
      }).addTo(map);

      // Add marker if location exists
      if (latitude && longitude) {
        markerRef.current = L.marker([latitude, longitude], { draggable: true }).addTo(map);

        markerRef.current.on('dragend', () => {
          const pos = markerRef.current!.getLatLng();
          onLocationChange(pos.lat, pos.lng);
          reverseGeocode(pos.lat, pos.lng);
        });
      }

      // Click handler
      map.on('click', (e: L.LeafletMouseEvent) => {
        const { lat, lng } = e.latlng;

        if (markerRef.current) {
          markerRef.current.setLatLng([lat, lng]);
        } else {
          markerRef.current = L.marker([lat, lng], { draggable: true }).addTo(map);

          markerRef.current.on('dragend', () => {
            const pos = markerRef.current!.getLatLng();
            onLocationChange(pos.lat, pos.lng);
            reverseGeocode(pos.lat, pos.lng);
          });
        }

        onLocationChange(lat, lng);
        reverseGeocode(lat, lng);
      });

      mapInstanceRef.current = map;
      setIsMapReady(true);
    };

    initMap();

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
        markerRef.current = null;
      }
    };
  }, []);

  // Update marker when props change
  useEffect(() => {
    if (!mapInstanceRef.current || !isMapReady) return;

    const updateMarker = async () => {
      const L = (await import('leaflet')).default;

      if (latitude && longitude) {
        if (markerRef.current) {
          markerRef.current.setLatLng([latitude, longitude]);
        } else {
          markerRef.current = L.marker([latitude, longitude], { draggable: true }).addTo(mapInstanceRef.current!);

          markerRef.current.on('dragend', () => {
            if (markerRef.current) {
              const pos = markerRef.current.getLatLng();
              onLocationChange(pos.lat, pos.lng);
              reverseGeocode(pos.lat, pos.lng);
            }
          });
        }
        mapInstanceRef.current?.setView([latitude, longitude], 16);
      }
    };

    updateMarker();
  }, [latitude, longitude, isMapReady]);

  const reverseGeocode = async (lat: number, lng: number) => {
    if (!onAddressChange) return;

    try {
      const response = await fetch(
        `https://nominatim.openstreetmap.org/reverse?format=json&lat=${lat}&lon=${lng}&zoom=18&addressdetails=1`,
        { headers: { 'Accept-Language': 'es' } }
      );
      const data = await response.json();
      if (data.display_name) {
        onAddressChange(data.display_name);
      }
    } catch {
      // Ignore geocoding errors
    }
  };

  const searchAddress = useCallback(async () => {
    if (!searchQuery.trim()) return;

    setSearching(true);
    setShowResults(true);

    try {
      const query = searchQuery.includes('Santa Juana')
        ? searchQuery
        : `${searchQuery}, Santa Juana, Chile`;

      const response = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=5`,
        { headers: { 'Accept-Language': 'es' } }
      );
      const data = await response.json();
      setSearchResults(data);
    } catch {
      setSearchResults([]);
    } finally {
      setSearching(false);
    }
  }, [searchQuery]);

  const selectSearchResult = (result: { lat: string; lon: string; display_name: string }) => {
    const lat = parseFloat(result.lat);
    const lng = parseFloat(result.lon);

    onLocationChange(lat, lng, result.display_name);
    if (onAddressChange) {
      onAddressChange(result.display_name);
    }

    setShowResults(false);
    setSearchQuery('');
    setSearchResults([]);
  };

  const clearLocation = () => {
    if (markerRef.current && mapInstanceRef.current) {
      mapInstanceRef.current.removeLayer(markerRef.current);
      markerRef.current = null;
    }
    onLocationChange(0, 0);
    if (onAddressChange) {
      onAddressChange('');
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      searchAddress();
    }
  };

  return (
    <div className="space-y-3">
      {/* Search bar */}
      <div className="relative">
        <div className="flex gap-2">
          <div className="relative flex-1">
            <MagnifyingGlassIcon className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              onKeyDown={handleKeyDown}
              placeholder="Buscar dirección..."
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500"
            />
          </div>
          <button
            type="button"
            onClick={searchAddress}
            disabled={searching || !searchQuery.trim()}
            className="px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            {searching ? 'Buscando...' : 'Buscar'}
          </button>
        </div>

        {/* Search results */}
        {showResults && searchResults.length > 0 && (
          <div className="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-lg max-h-60 overflow-y-auto">
            {searchResults.map((result, index) => (
              <button
                key={index}
                type="button"
                onClick={() => selectSearchResult(result)}
                className="w-full px-4 py-3 text-left hover:bg-gray-50 border-b border-gray-100 last:border-b-0"
              >
                <p className="text-sm text-gray-900 line-clamp-2">{result.display_name}</p>
              </button>
            ))}
          </div>
        )}

        {showResults && searchResults.length === 0 && !searching && searchQuery && (
          <div className="absolute z-50 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-lg p-4">
            <p className="text-sm text-gray-500">No se encontraron resultados</p>
          </div>
        )}
      </div>

      {/* Map */}
      <div className="relative">
        <div
          ref={mapRef}
          className="w-full h-64 rounded-lg border border-gray-200 bg-gray-100"
          style={{ minHeight: '256px' }}
        />

        {!isMapReady && (
          <div className="absolute inset-0 flex items-center justify-center bg-gray-100 rounded-lg">
            <div className="flex items-center gap-2 text-gray-500">
              <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-indigo-600"></div>
              <span>Cargando mapa...</span>
            </div>
          </div>
        )}
      </div>

      {/* Selected location info */}
      {latitude && longitude && latitude !== 0 && longitude !== 0 && (
        <div className="flex items-start justify-between p-3 bg-indigo-50 rounded-lg">
          <div className="flex items-start gap-2">
            <MapPinIcon className="h-5 w-5 text-indigo-600 mt-0.5 flex-shrink-0" />
            <div>
              <p className="text-sm font-medium text-indigo-900">Ubicación seleccionada</p>
              {address && (
                <p className="text-xs text-indigo-700 mt-0.5 line-clamp-2">{address}</p>
              )}
              <p className="text-xs text-indigo-600 mt-1">
                {latitude.toFixed(6)}, {longitude.toFixed(6)}
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={clearLocation}
            className="p-1 hover:bg-indigo-100 rounded transition-colors"
            title="Quitar ubicación"
          >
            <XMarkIcon className="h-4 w-4 text-indigo-600" />
          </button>
        </div>
      )}

      {/* Instructions */}
      {(!latitude || !longitude || latitude === 0) && (
        <p className="text-xs text-gray-500 text-center">
          Haga clic en el mapa para seleccionar la ubicación o busque una dirección
        </p>
      )}
    </div>
  );
}
