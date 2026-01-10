export type CitationType = 'advertencia' | 'citacion';
export type TargetType = 'persona' | 'domicilio' | 'vehiculo' | 'comercio' | 'otro';
export type NotificationMethod = 'email' | 'sms' | 'carta' | 'en_persona';
export type CitationStatus = 'pendiente' | 'notificado' | 'asistio' | 'no_asistio' | 'cancelado';

export interface CreateCitationDto {
  // Tipo de citación
  citationType: CitationType;

  // Tipo y datos del objetivo
  targetType: TargetType;
  targetName?: string;
  targetRut?: string;
  targetAddress?: string;
  targetPhone?: string;
  targetPlate?: string;

  // Ubicación
  locationAddress?: string;
  latitude?: number;
  longitude?: number;

  // Detalles
  citationNumber: string;
  reason: string;
  notes?: string;

  // Multimedia
  photos?: string[];

  // Campos legacy (opcionales para retrocompatibilidad)
  userId?: string;
  infractionId?: string;
  courtName?: string;
  hearingDate?: Date | string;
  address?: string;
  notificationMethod?: NotificationMethod;
}

export interface UpdateCitationDto {
  status?: CitationStatus;
  notificationMethod?: NotificationMethod;
  notes?: string;

  // Permitir actualizar datos del objetivo
  targetName?: string;
  targetRut?: string;
  targetAddress?: string;
  targetPhone?: string;
  targetPlate?: string;

  // Permitir actualizar ubicación
  locationAddress?: string;
  latitude?: number;
  longitude?: number;

  // Permitir agregar fotos
  photos?: string[];
}

export interface Citation {
  id: string;
  citation_type: CitationType;
  target_type: TargetType;
  target_name: string | null;
  target_rut: string | null;
  target_address: string | null;
  target_phone: string | null;
  target_plate: string | null;
  location_address: string | null;
  latitude: number | null;
  longitude: number | null;
  citation_number: string;
  reason: string;
  notes: string | null;
  photos: string[] | null;
  status: CitationStatus;
  notification_method: NotificationMethod | null;
  notified_at: Date | null;
  issued_by: string | null;
  created_at: Date;
  updated_at: Date;

  // Legacy fields
  user_id: string | null;
  infraction_id: string | null;
  court_name: string | null;
  hearing_date: Date | null;
  address: string | null;

  // Joined fields
  issuer_first_name?: string;
  issuer_last_name?: string;
  user_first_name?: string;
  user_last_name?: string;
  user_email?: string;
  user_phone?: string;
  user_rut?: string;
}

export interface CitationFilters {
  status?: CitationStatus;
  citationType?: CitationType;
  targetType?: TargetType;
  userId?: string;
  issuedBy?: string;
  search?: string;
  fromDate?: string;
  toDate?: string;
}
