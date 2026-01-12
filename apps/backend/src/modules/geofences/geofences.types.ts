// Geofence types
export type GeofenceType = 'circle' | 'polygon';

// Create/Update geofence DTO
export interface CreateGeofenceDto {
  name: string;
  description?: string;
  geofenceType: GeofenceType;
  // For circle
  centerLat?: number;
  centerLng?: number;
  radiusMeters?: number;
  // For polygon (array of [lat, lng] pairs)
  polygonCoordinates?: [number, number][];
  // Settings
  isActive?: boolean;
  alertOnEnter?: boolean;
  alertOnExit?: boolean;
}

export interface UpdateGeofenceDto extends Partial<CreateGeofenceDto> {}

// Stored geofence
export interface Geofence {
  id: string;
  name: string;
  description: string | null;
  geofenceType: GeofenceType;
  centerLat: number | null;
  centerLng: number | null;
  radiusMeters: number | null;
  polygonCoordinates: [number, number][] | null;
  isActive: boolean;
  alertOnEnter: boolean;
  alertOnExit: boolean;
  createdAt: Date;
  updatedAt: Date;
}

// Geofence event types
export type GeofenceEventType = 'enter' | 'exit';

// Geofence event
export interface GeofenceEvent {
  id: string;
  geofenceId: string;
  geofenceName: string;
  vehicleId: string;
  vehiclePlate: string;
  inspectorId: string;
  inspectorName: string;
  eventType: GeofenceEventType;
  latitude: number;
  longitude: number;
  recordedAt: Date;
  createdAt: Date;
}

// For real-time geofence checking
export interface GeofenceCheckResult {
  geofenceId: string;
  geofenceName: string;
  isInside: boolean;
}

// Socket events
export interface GeofenceEnterEvent {
  geofenceId: string;
  geofenceName: string;
  vehicleId: string;
  vehiclePlate: string;
  inspectorId: string;
  inspectorName: string;
  latitude: number;
  longitude: number;
  timestamp: string;
}

export interface GeofenceExitEvent extends GeofenceEnterEvent {}
