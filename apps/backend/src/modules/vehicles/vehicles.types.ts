export type OwnershipType = 'propio' | 'arrendado' | 'comodato';
export type VehicleStatus = 'activo' | 'dado_de_baja' | 'en_espera_de_remate' | 'rematado';

export interface CreateVehicleDto {
  ownerId: string;
  plate: string;
  brand?: string;
  model?: string;
  year?: number;
  color?: string;
  vehicleType?: 'auto' | 'moto' | 'camion' | 'camioneta' | 'bus' | 'otro';
  vin?: string;
  ownershipType?: OwnershipType;
  vehicleStatus?: VehicleStatus;
  notes?: string;
  insuranceExpiry?: string;
  technicalReviewExpiry?: string;
  acquisitionDate?: string;
}

export interface UpdateVehicleDto {
  ownerId?: string;
  brand?: string;
  model?: string;
  year?: number;
  color?: string;
  vehicleType?: 'auto' | 'moto' | 'camion' | 'camioneta' | 'bus' | 'otro';
  vin?: string;
  isActive?: boolean;
  ownershipType?: OwnershipType;
  vehicleStatus?: VehicleStatus;
  notes?: string;
  insuranceExpiry?: string;
  technicalReviewExpiry?: string;
  acquisitionDate?: string;
  disposalDate?: string;
}

// Vehicle Logs DTOs
export type UsageType = 'official' | 'emergency' | 'maintenance' | 'transfer' | 'other';

export interface StartVehicleUsageDto {
  vehicleId: string;
  driverId: string;
  driverName: string;
  startKm: number;
  usageType: UsageType;
  purpose?: string;
}

export interface EndVehicleUsageDto {
  endKm: number;
  observations?: string;
  attachments?: string[];
}

export interface VehicleLogResponse {
  id: string;
  vehicleId: string;
  driverId: string;
  driverName: string;
  usageType: UsageType;
  purpose?: string;
  startKm: number;
  endKm?: number;
  startTime: Date;
  endTime?: Date;
  observations?: string;
  status: 'active' | 'completed' | 'cancelled';
  createdAt: Date;
  updatedAt: Date;
  vehicle?: {
    plate: string;
    brand?: string;
    model?: string;
  };
}
