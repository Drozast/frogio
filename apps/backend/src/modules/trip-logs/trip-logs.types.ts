export interface CreateTripLogDto {
  vehicleId?: string;
  title: string;
  description?: string;
  purpose?: string;
  startLocationLat?: number;
  startLocationLng?: number;
  startAddress?: string;
  startKm?: number;
}

export interface EndTripLogDto {
  endLocationLat?: number;
  endLocationLng?: number;
  endAddress?: string;
  endKm?: number;
  notes?: string;
}

export interface CreateTripEntryDto {
  entryType: 'checkpoint' | 'incident' | 'note' | 'photo' | 'report_link';
  latitude?: number;
  longitude?: number;
  address?: string;
  description: string;
  linkedReportId?: string;
  linkedInfractionId?: string;
}

export interface TripLogFilters {
  inspectorId?: string;
  vehicleId?: string;
  status?: string;
  startDate?: Date;
  endDate?: Date;
}
