import { Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config/index.js';
import { prisma } from '../config/database.js';
import { AuthRequest, JwtPayload } from '../types/index.js';
import { UserRole, UserStatus } from '@prisma/client';

// Middleware de autenticación
export async function authenticate(
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      res.status(401).json({
        success: false,
        error: 'Token de autenticación no proporcionado',
      });
      return;
    }

    const token = authHeader.split(' ')[1];

    const decoded = jwt.verify(token, config.jwt.secret) as JwtPayload;

    if (decoded.type !== 'access') {
      res.status(401).json({
        success: false,
        error: 'Tipo de token inválido',
      });
      return;
    }

    // Verificar que el usuario existe y está activo
    const user = await prisma.user.findUnique({
      where: { id: decoded.userId },
      select: {
        id: true,
        email: true,
        role: true,
        status: true,
        municipalityId: true,
      },
    });

    if (!user) {
      res.status(401).json({
        success: false,
        error: 'Usuario no encontrado',
      });
      return;
    }

    if (user.status !== UserStatus.ACTIVE) {
      res.status(403).json({
        success: false,
        error: 'Usuario no activo',
      });
      return;
    }

    req.user = user;
    next();
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      res.status(401).json({
        success: false,
        error: 'Token expirado',
      });
      return;
    }

    if (error instanceof jwt.JsonWebTokenError) {
      res.status(401).json({
        success: false,
        error: 'Token inválido',
      });
      return;
    }

    next(error);
  }
}

// Middleware opcional de autenticación (no falla si no hay token)
export async function optionalAuth(
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      next();
      return;
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, config.jwt.secret) as JwtPayload;

    if (decoded.type === 'access') {
      const user = await prisma.user.findUnique({
        where: { id: decoded.userId },
        select: {
          id: true,
          email: true,
          role: true,
          status: true,
          municipalityId: true,
        },
      });

      if (user && user.status === UserStatus.ACTIVE) {
        req.user = user;
      }
    }

    next();
  } catch {
    // Ignorar errores de token, continuar sin usuario
    next();
  }
}

// Middleware para requerir roles específicos
export function requireRoles(...roles: UserRole[]) {
  return (req: AuthRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({
        success: false,
        error: 'No autenticado',
      });
      return;
    }

    if (!roles.includes(req.user.role)) {
      res.status(403).json({
        success: false,
        error: 'No tienes permisos para realizar esta acción',
      });
      return;
    }

    next();
  };
}

// Middleware para requerir pertenencia a municipalidad
export function requireMunicipality(
  req: AuthRequest,
  res: Response,
  next: NextFunction
): void {
  if (!req.user) {
    res.status(401).json({
      success: false,
      error: 'No autenticado',
    });
    return;
  }

  if (!req.user.municipalityId) {
    res.status(403).json({
      success: false,
      error: 'Usuario no asociado a ninguna municipalidad',
    });
    return;
  }

  next();
}

// Middleware para verificar acceso a municipalidad específica
export function verifyMunicipalityAccess(
  req: AuthRequest,
  res: Response,
  next: NextFunction
): void {
  if (!req.user) {
    res.status(401).json({
      success: false,
      error: 'No autenticado',
    });
    return;
  }

  const { municipalityId } = req.params;

  // Super admin puede acceder a cualquier municipalidad
  if (req.user.role === UserRole.SUPER_ADMIN) {
    next();
    return;
  }

  // Otros usuarios solo pueden acceder a su municipalidad
  if (req.user.municipalityId !== municipalityId) {
    res.status(403).json({
      success: false,
      error: 'No tienes acceso a esta municipalidad',
    });
    return;
  }

  next();
}
