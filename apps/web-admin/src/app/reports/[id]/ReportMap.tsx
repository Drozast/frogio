'use client';

import { useEffect, useRef, useState } from 'react';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

interface ReportMapProps {
  latitude: number;
  longitude: number;
}

export default function ReportMap({ latitude, longitude }: ReportMapProps) {
  const mapRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<L.Map | null>(null);
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    if (!mounted || !mapRef.current || mapInstanceRef.current) return;

    const map = L.map(mapRef.current, {
      center: [latitude, longitude],
      zoom: 16,
      zoomControl: true,
    });

    L.tileLayer('https://maps.drozast.xyz/styles/osm-bright/{z}/{x}/{y}.png', {
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> | Tiles: FROGIO',
    }).addTo(map);

    // Add marker
    const markerIcon = L.divIcon({
      className: 'report-marker',
      html: `
        <div style="
          background: #EF4444;
          width: 32px;
          height: 32px;
          border-radius: 50% 50% 50% 0;
          transform: rotate(-45deg);
          display: flex;
          align-items: center;
          justify-content: center;
          border: 3px solid white;
          box-shadow: 0 2px 6px rgba(0,0,0,0.3);
        ">
          <div style="
            transform: rotate(45deg);
            color: white;
            font-size: 14px;
          ">📍</div>
        </div>
      `,
      iconSize: [32, 32],
      iconAnchor: [16, 32],
    });

    L.marker([latitude, longitude], { icon: markerIcon }).addTo(map);

    mapInstanceRef.current = map;

    return () => {
      map.remove();
      mapInstanceRef.current = null;
    };
  }, [mounted, latitude, longitude]);

  if (!mounted) {
    return (
      <div className="aspect-video bg-gray-100 rounded-lg flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div
      ref={mapRef}
      className="aspect-video rounded-lg overflow-hidden"
      style={{ minHeight: '300px' }}
    />
  );
}
