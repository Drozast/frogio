import { Request } from 'express';
import { UserRole, UserStatus } from '@prisma/client';

// Usuario autenticado en el request
export interface AuthUser {
  id: string;
  email: string;
  role: UserRole;
  status: UserStatus;
  municipalityId: string | null;
}

// Request con usuario autenticado
export interface AuthRequest extends Request {
  user?: AuthUser;
}

// Payload del JWT
export interface JwtPayload {
  userId: string;
  email: string;
  role: UserRole;
  status: UserStatus;
  municipalityId: string | null;
  type: 'access' | 'refresh';
}

// Respuesta estándar de la API
export interface ApiResponse<T = unknown> {
  success: boolean;
  message?: string;
  data?: T;
  error?: string;
  errors?: Record<string, string[]>;
  meta?: {
    page?: number;
    limit?: number;
    total?: number;
    totalPages?: number;
  };
}

// Parámetros de paginación
export interface PaginationParams {
  page: number;
  limit: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

// Filtros para reportes
export interface ReportFilters {
  status?: string;
  category?: string;
  priority?: string;
  zoneId?: string;
  startDate?: Date;
  endDate?: Date;
  search?: string;
}

// Filtros para citaciones
export interface CitationFilters {
  status?: string;
  startDate?: Date;
  endDate?: Date;
  search?: string;
}

// Datos de ubicación
export interface LocationData {
  latitude: number;
  longitude: number;
  address?: string;
}

// Estadísticas del dashboard
export interface DashboardStats {
  reports: {
    total: number;
    pending: number;
    inProgress: number;
    resolved: number;
    byCategory: Record<string, number>;
  };
  citations: {
    total: number;
    issued: number;
    paid: number;
    totalAmount: number;
  };
  alerts: {
    total: number;
    panic: number;
    resolved: number;
  };
  users: {
    total: number;
    citizens: number;
    inspectors: number;
    active: number;
  };
}
