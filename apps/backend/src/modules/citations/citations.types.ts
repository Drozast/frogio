export interface CreateCitationDto {
  userId: string;
  infractionId?: string;
  citationNumber: string;
  courtName: string;
  hearingDate: Date | string;
  address: string;
  reason: string;
  notificationMethod?: 'email' | 'sms' | 'carta' | 'en_persona';
}

export interface UpdateCitationDto {
  status?: 'pendiente' | 'notificado' | 'asistio' | 'no_asistio' | 'cancelado';
  notificationMethod?: 'email' | 'sms' | 'carta' | 'en_persona';
  notes?: string;
}
