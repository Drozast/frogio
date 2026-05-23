import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { config } from '../config/index.js';

// Clase personalizada de error
export class AppError extends Error {
  statusCode: number;
  isOperational: boolean;

  constructor(message: string, statusCode: number = 500) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;

    Error.captureStackTrace(this, this.constructor);
  }
}

// Errores específicos
export class NotFoundError extends AppError {
  constructor(message: string = 'Recurso no encontrado') {
    super(message, 404);
  }
}

export class UnauthorizedError extends AppError {
  constructor(message: string = 'No autorizado') {
    super(message, 401);
  }
}

export class ForbiddenError extends AppError {
  constructor(message: string = 'Acceso denegado') {
    super(message, 403);
  }
}

export class ValidationError extends AppError {
  errors: Record<string, string[]>;

  constructor(message: string = 'Error de validación', errors: Record<string, string[]> = {}) {
    super(message, 400);
    this.errors = errors;
  }
}

export class ConflictError extends AppError {
  constructor(message: string = 'Conflicto de recursos') {
    super(message, 409);
  }
}

// Middleware de manejo de errores
export function errorHandler(
  err: Error,
  _req: Request,
  res: Response,
  _next: NextFunction
): void {
  console.error('Error:', err);

  // Error de Zod (validación)
  if (err instanceof ZodError) {
    const errors: Record<string, string[]> = {};
    err.errors.forEach((e) => {
      const path = e.path.join('.');
      if (!errors[path]) {
        errors[path] = [];
      }
      errors[path].push(e.message);
    });

    res.status(400).json({
      success: false,
      error: 'Error de validación',
      errors,
    });
    return;
  }

  // Error de validación personalizado
  if (err instanceof ValidationError) {
    res.status(err.statusCode).json({
      success: false,
      error: err.message,
      errors: err.errors,
    });
    return;
  }

  // Error operacional (AppError)
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      success: false,
      error: err.message,
    });
    return;
  }

  // Error de Prisma - Registro no encontrado
  if (err.name === 'PrismaClientKnownRequestError') {
    const prismaError = err as { code?: string };
    if (prismaError.code === 'P2025') {
      res.status(404).json({
        success: false,
        error: 'Registro no encontrado',
      });
      return;
    }

    // Violación de constraint único
    if (prismaError.code === 'P2002') {
      res.status(409).json({
        success: false,
        error: 'Ya existe un registro con estos datos',
      });
      return;
    }
  }

  // Error no manejado
  res.status(500).json({
    success: false,
    error: config.env === 'development' ? err.message : 'Error interno del servidor',
    ...(config.env === 'development' && { stack: err.stack }),
  });
}

// Middleware para rutas no encontradas
export function notFoundHandler(_req: Request, res: Response): void {
  res.status(404).json({
    success: false,
    error: 'Ruta no encontrada',
  });
}
