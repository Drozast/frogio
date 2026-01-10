export interface CreatePanicAlertDto {
  latitude: number;
  longitude: number;
  address?: string;
  message?: string;
  contactPhone?: string;
}

export interface UpdatePanicAlertDto {
  status?: 'active' | 'responding' | 'resolved' | 'cancelled';
  responderId?: string;
  notes?: string;
}

export interface PanicAlertFilters {
  status?: string;
  userId?: string;
  startDate?: Date;
  endDate?: Date;
}
