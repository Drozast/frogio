export class AppError extends Error {
  public readonly statusCode: number;
  public readonly code: string;
  public readonly isOperational: boolean;

  constructor(message: string, statusCode: number, code: string, isOperational = true) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.isOperational = isOperational;
    Object.setPrototypeOf(this, AppError.prototype);
  }
}

// Common error factories
export const Errors = {
  // Auth errors (1xxx)
  invalidCredentials: () => new AppError('Credenciales inválidas', 401, 'AUTH_INVALID_CREDENTIALS'),
  tokenExpired: () => new AppError('Token expirado', 401, 'AUTH_TOKEN_EXPIRED'),
  tokenInvalid: () => new AppError('Token inválido', 401, 'AUTH_TOKEN_INVALID'),
  unauthorized: () => new AppError('No autenticado', 401, 'AUTH_UNAUTHORIZED'),
  forbidden: () => new AppError('No tienes permisos', 403, 'AUTH_FORBIDDEN'),
  userInactive: () => new AppError('Usuario desactivado', 403, 'AUTH_USER_INACTIVE'),

  // Validation errors (2xxx)
  validationFailed: (details: string) => new AppError(details, 400, 'VALIDATION_FAILED'),
  missingField: (field: string) => new AppError(`Campo requerido: ${field}`, 400, 'VALIDATION_MISSING_FIELD'),
  invalidFormat: (field: string) => new AppError(`Formato inválido: ${field}`, 400, 'VALIDATION_INVALID_FORMAT'),
  duplicateEntry: (field: string) => new AppError(`Ya existe un registro con este ${field}`, 409, 'VALIDATION_DUPLICATE'),

  // Resource errors (3xxx)
  notFound: (resource: string) => new AppError(`${resource} no encontrado`, 404, 'RESOURCE_NOT_FOUND'),
  alreadyExists: (resource: string) => new AppError(`${resource} ya existe`, 409, 'RESOURCE_ALREADY_EXISTS'),

  // Rate limiting (4xxx)
  rateLimited: () => new AppError('Demasiadas solicitudes', 429, 'RATE_LIMIT_EXCEEDED'),

  // Server errors (5xxx)
  internal: (details?: string) => new AppError(details || 'Error interno del servidor', 500, 'INTERNAL_ERROR', false),
  serviceUnavailable: (service: string) => new AppError(`Servicio no disponible: ${service}`, 503, 'SERVICE_UNAVAILABLE'),

  // Tenant errors
  tenantRequired: () => new AppError('Tenant ID requerido', 400, 'TENANT_REQUIRED'),
  tenantMismatch: () => new AppError('Tenant ID no coincide', 403, 'TENANT_MISMATCH'),
};

// Error response formatter
export function formatErrorResponse(error: AppError | Error) {
  if (error instanceof AppError) {
    return {
      error: error.message,
      code: error.code,
      statusCode: error.statusCode,
    };
  }

  return {
    error: 'Error interno del servidor',
    code: 'INTERNAL_ERROR',
    statusCode: 500,
  };
}
