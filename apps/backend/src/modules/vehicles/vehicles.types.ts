export interface CreateVehicleDto {
  ownerId: string;
  plate: string;
  brand?: string;
  model?: string;
  year?: number;
  color?: string;
  vehicleType?: 'auto' | 'moto' | 'camion' | 'camioneta' | 'bus' | 'otro';
  vin?: string;
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
}
