'use client';

import { useEffect, useState, useCallback, useRef } from 'react';
import { io, Socket } from 'socket.io-client';

export interface VehiclePosition {
  vehicleId: string;
  vehiclePlate: string;
  vehicleBrand: string;
  vehicleModel: string;
  inspectorId: string;
  inspectorName: string;
  latitude: number;
  longitude: number;
  speed: number | null;
  heading: number | null;
  accuracy: number | null;
  recordedAt: string;
  status: 'moving' | 'slow' | 'stopped';
  vehicleLogId: string | null;
}

export interface GeofenceEvent {
  id: string;
  geofenceId: string;
  geofenceName: string;
  vehicleId: string;
  vehiclePlate: string;
  inspectorName: string;
  eventType: 'enter' | 'exit';
  latitude: number;
  longitude: number;
  recordedAt: string;
}

interface UseFleetSocketReturn {
  isConnected: boolean;
  vehicles: Map<string, VehiclePosition>;
  geofenceEvents: GeofenceEvent[];
  error: string | null;
  refreshPositions: () => Promise<void>;
}

const TENANT_ID = 'santa_juana';

// Get the socket URL for WebSocket connections (CLIENT-SIDE ONLY)
function getSocketUrl(): string {
  // This should only be called on the client
  if (typeof window === 'undefined') {
    return ''; // Return empty, we'll handle this in useEffect
  }

  const host = window.location.hostname;

  // Local development
  if (host === 'localhost' || /^\d+\.\d+\.\d+\.\d+$/.test(host)) {
    return `http://${host}:3000`;
  }

  // Production: derive API URL from current domain
  // e.g., admin-frogio.drozast.xyz -> api-frogio.drozast.xyz
  const apiHost = host.replace('admin-', 'api-');
  return `https://${apiHost}`;
}

export function useFleetSocket(): UseFleetSocketReturn {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [vehicles, setVehicles] = useState<Map<string, VehiclePosition>>(new Map());
  const [geofenceEvents, setGeofenceEvents] = useState<GeofenceEvent[]>([]);
  const [error, setError] = useState<string | null>(null);
  const pollingInterval = useRef<NodeJS.Timeout | null>(null);

  // Function to fetch live positions via REST API as fallback
  const refreshPositions = useCallback(async () => {
    try {
      const response = await fetch('/api/fleet/live');
      if (response.ok) {
        const positions: VehiclePosition[] = await response.json();
        setVehicles(new Map(positions.map(p => [p.vehicleId, p])));
        setError(null);
      }
    } catch (err) {
      console.error('Error fetching live positions:', err);
    }
  }, []);

  useEffect(() => {
    // Only run on client side
    if (typeof window === 'undefined') return;

    const socketUrl = getSocketUrl();
    if (!socketUrl) return;

    console.log('Connecting to fleet socket:', socketUrl);

    const newSocket = io(`${socketUrl}/fleet`, {
      transports: ['websocket', 'polling'],
      reconnection: true,
      reconnectionAttempts: 5,
      reconnectionDelay: 1000,
    });

    newSocket.on('connect', () => {
      console.log('Fleet socket connected');
      setIsConnected(true);
      setError(null);
      newSocket.emit('join:tenant', TENANT_ID);
      // Clear polling when socket connects
      if (pollingInterval.current) {
        clearInterval(pollingInterval.current);
        pollingInterval.current = null;
      }
    });

    newSocket.on('disconnect', () => {
      console.log('Fleet socket disconnected');
      setIsConnected(false);
      // Start polling when disconnected
      if (!pollingInterval.current) {
        pollingInterval.current = setInterval(refreshPositions, 10000);
      }
    });

    newSocket.on('connect_error', (err: Error) => {
      console.error('Fleet socket connection error:', err);
      setError('Modo offline - actualizando cada 10s');
      setIsConnected(false);
      // Start polling on connection error
      if (!pollingInterval.current) {
        refreshPositions(); // Fetch immediately
        pollingInterval.current = setInterval(refreshPositions, 10000);
      }
    });

    // Vehicle position updates
    newSocket.on('vehicle:position', (position: VehiclePosition) => {
      setVehicles((prev) => {
        const updated = new Map(prev);
        updated.set(position.vehicleId, position);
        return updated;
      });
    });

    // Vehicle started usage
    newSocket.on('vehicle:started', (data: { vehicleId: string; vehiclePlate: string; inspectorName: string }) => {
      console.log('Vehicle started:', data);
    });

    // Vehicle stopped usage
    newSocket.on('vehicle:stopped', (data: { vehicleId: string }) => {
      setVehicles((prev) => {
        const updated = new Map(prev);
        updated.delete(data.vehicleId);
        return updated;
      });
    });

    // Geofence events
    newSocket.on('geofence:enter', (event: GeofenceEvent) => {
      setGeofenceEvents((prev) => [event, ...prev].slice(0, 50));
    });

    newSocket.on('geofence:exit', (event: GeofenceEvent) => {
      setGeofenceEvents((prev) => [event, ...prev].slice(0, 50));
    });

    setSocket(newSocket);

    // Initial fetch of positions
    refreshPositions();

    return () => {
      newSocket.emit('leave:tenant', TENANT_ID);
      newSocket.disconnect();
      if (pollingInterval.current) {
        clearInterval(pollingInterval.current);
      }
    };
  }, [refreshPositions]);

  return {
    isConnected,
    vehicles,
    geofenceEvents,
    error,
    refreshPositions,
  };
}
