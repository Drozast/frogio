'use client';

import { useEffect, useState, useCallback } from 'react';
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
}

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';
const TENANT_ID = 'santa_juana';

export function useFleetSocket(): UseFleetSocketReturn {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [isConnected, setIsConnected] = useState(false);
  const [vehicles, setVehicles] = useState<Map<string, VehiclePosition>>(new Map());
  const [geofenceEvents, setGeofenceEvents] = useState<GeofenceEvent[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const newSocket = io(`${API_URL}/fleet`, {
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
    });

    newSocket.on('disconnect', () => {
      console.log('Fleet socket disconnected');
      setIsConnected(false);
    });

    newSocket.on('connect_error', (err: Error) => {
      console.error('Fleet socket connection error:', err);
      setError('Error de conexión al servidor');
      setIsConnected(false);
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

    return () => {
      newSocket.emit('leave:tenant', TENANT_ID);
      newSocket.disconnect();
    };
  }, []);

  return {
    isConnected,
    vehicles,
    geofenceEvents,
    error,
  };
}
