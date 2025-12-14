export interface CreateReportDto {
  type: 'denuncia' | 'sugerencia' | 'emergencia' | 'infraestructura' | 'otro';
  title: string;
  description: string;
  address?: string;
  latitude?: number;
  longitude?: number;
  priority?: 'baja' | 'media' | 'alta' | 'urgente';
}

export interface UpdateReportDto {
  status?: 'pendiente' | 'en_proceso' | 'resuelto' | 'rechazado';
  priority?: 'baja' | 'media' | 'alta' | 'urgente';
  assignedTo?: string;
  resolution?: string;
}
