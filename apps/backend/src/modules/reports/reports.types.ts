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
  title?: string;
  description?: string;
  type?: 'denuncia' | 'sugerencia' | 'emergencia' | 'infraestructura' | 'otro';
  status?: 'pendiente' | 'en_proceso' | 'resuelto' | 'rechazado';
  priority?: 'baja' | 'media' | 'alta' | 'urgente';
  address?: string;
  assignedTo?: string;
  resolution?: string;
  changeReason?: string;
}

export interface ReportVersion {
  id: string;
  report_id: string;
  version_number: number;
  title: string;
  description: string;
  type: string;
  status: string;
  priority: string;
  address: string | null;
  latitude: number | null;
  longitude: number | null;
  assigned_to: string | null;
  resolution: string | null;
  attachments: string[];
  is_follow_up: boolean;
  modified_by: string;
  modified_at: string;
  change_reason: string | null;
  modifier_first_name?: string;
  modifier_last_name?: string;
}

export interface FollowUpDto {
  comment: string;
  attachments?: string[];
}
