// GPS Point DTO for receiving from mobile
export interface GpsPointDto {
  latitude: number;
  longitude: number;
  altitude?: number;
  speed?: number;
  heading?: number;
  accuracy?: number;
  recordedAt: string; // ISO timestamp
}

// Batch of GPS points from mobile
export interface GpsBatchDto {
  vehicleId: string;
  vehicleLogId?: string;
  points: GpsPointDto[];
}

// Stored GPS point
export interface GpsPoint {
  id: string;
  vehicleId: string;
  vehicleLogId: string | null;
  inspectorId: string;
  latitude: number;
  longitude: number;
  altitude: number | null;
  speed: number | null;
  heading: number | null;
  accuracy: number | null;
  recordedAt: Date;
  createdAt: Date;
}

// Live vehicle position for dashboard
export interface LiveVehiclePosition {
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
  lastUpdate: string;
  vehicleLogId: string;
  startTime: string;
  status: 'moving' | 'slow' | 'stopped';
}

// GPS History query params
export interface GpsHistoryQuery {
  vehicleId: string;
  startDate: string;
  endDate: string;
  simplify?: boolean; // Simplify polyline using Douglas-Peucker
}

// GPS Statistics
export interface GpsStats {
  totalKm: number;
  totalTrips: number;
  avgSpeed: number;
  maxSpeed: number;
  totalDuration: number; // in minutes
  byVehicle: Array<{
    vehicleId: string;
    vehiclePlate: string;
    totalKm: number;
    totalTrips: number;
  }>;
  byInspector: Array<{
    inspectorId: string;
    inspectorName: string;
    totalKm: number;
    totalTrips: number;
  }>;
}

// Route history response
export interface RouteHistory {
  vehicleLogId: string;
  vehicleId: string;
  vehiclePlate: string;
  inspectorId: string;
  inspectorName: string;
  startTime: string;
  endTime: string | null;
  totalKm: number;
  avgSpeed: number;
  maxSpeed: number;
  points: Array<{
    latitude: number;
    longitude: number;
    speed: number | null;
    recordedAt: string;
  }>;
  polyline?: string; // Encoded polyline for efficient transfer
}

// Socket events
export interface VehiclePositionEvent {
  vehicleId: string;
  vehiclePlate: string;
  inspectorId: string;
  inspectorName: string;
  latitude: number;
  longitude: number;
  speed: number | null;
  heading: number | null;
  timestamp: string;
}

export interface VehicleStartedEvent {
  vehicleId: string;
  vehiclePlate: string;
  inspectorId: string;
  inspectorName: string;
  vehicleLogId: string;
  startTime: string;
}

export interface VehicleStoppedEvent {
  vehicleId: string;
  vehiclePlate: string;
  inspectorId: string;
  inspectorName: string;
  vehicleLogId: string;
  endTime: string;
  totalKm: number;
}

// GPS Configuration
export const GPS_CONFIG = {
  TRACKING_INTERVAL_MS: 10000,    // 10 seconds
  BATCH_SIZE: 6,                   // 6 points = 1 minute
  BATCH_SEND_INTERVAL_MS: 60000,  // Send every 60 seconds
  MIN_DISTANCE_METERS: 10,         // Ignore if didn't move 10m
  SIMPLIFY_TOLERANCE: 0.00001,    // Douglas-Peucker tolerance
};
