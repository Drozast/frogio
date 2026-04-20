'use client';

import 'leaflet/dist/leaflet.css';
import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet';
import L from 'leaflet';

// Fix leaflet default marker icons in Next.js
const defaultIcon = L.icon({
  iconUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon.png',
  iconRetinaUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png',
  shadowUrl: 'https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png',
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
});

export default function InlineLocationMapInner({
  lat,
  lng,
  address,
  height = 260,
  label,
  tileUrl,
}: {
  lat: number;
  lng: number;
  address?: string;
  height?: number;
  label?: string;
  tileUrl: string;
}) {
  return (
    <div
      className="overflow-hidden rounded-lg border border-gray-200"
      style={{ height }}
    >
      <MapContainer
        center={[lat, lng]}
        zoom={16}
        scrollWheelZoom={false}
        style={{ height: '100%', width: '100%' }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> | Tiles: FROGIO'
          url={tileUrl}
        />
        <Marker position={[lat, lng]} icon={defaultIcon}>
          <Popup>
            <div className="text-xs">
              {label && <div className="font-semibold mb-1">{label}</div>}
              {address && <div>{address}</div>}
              <div className="text-gray-500 mt-1">
                {lat.toFixed(6)}, {lng.toFixed(6)}
              </div>
            </div>
          </Popup>
        </Marker>
      </MapContainer>
    </div>
  );
}
