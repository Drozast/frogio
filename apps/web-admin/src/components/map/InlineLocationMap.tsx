'use client';

/**
 * Small inline map that shows a single marker at the given coordinates.
 * Uses the FROGIO self-hosted tile server. Dynamic-imported leaflet so
 * it never hits SSR (leaflet breaks on the server).
 */
import dynamic from 'next/dynamic';

const TILE_URL = 'https://maps.supertools.cl/styles/osm-bright/{z}/{x}/{y}.png';

const InlineMap = dynamic(() => import('./InlineLocationMapInner'), {
  ssr: false,
  loading: () => (
    <div className="h-[260px] w-full rounded-lg bg-gray-100 animate-pulse" />
  ),
});

export default function InlineLocationMap({
  lat,
  lng,
  address,
  height = 260,
  label,
}: {
  lat: number;
  lng: number;
  address?: string;
  height?: number;
  label?: string;
}) {
  return (
    <InlineMap
      lat={lat}
      lng={lng}
      address={address}
      height={height}
      label={label}
      tileUrl={TILE_URL}
    />
  );
}
