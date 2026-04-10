import { Request, Response } from 'express';
import { AuthService } from './auth.service.js';
import type { RegisterDto, LoginDto, ForgotPasswordDto, ResetPasswordDto, UpdateProfileDto } from './auth.types.js';
import type { AuthRequest } from '../../middleware/auth.middleware.js';
import { logger } from '../../config/logger.js';

const authService = new AuthService();

export class AuthController {
  async register(req: Request, res: Response): Promise<void> {
    try {
      const data: RegisterDto = req.body;
      const tenantId = req.headers['x-tenant-id'] as string;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido en headers' });
        return;
      }

      const result = await authService.register(data, tenantId);

      res.status(201).json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al registrar usuario';
      res.status(400).json({ error: message });
    }
  }

  async login(req: Request, res: Response): Promise<void> {
    try {
      logger.info('Backend received login request');
      logger.info(`Raw body type: ${typeof req.body}`);
      logger.info(`Raw body: ${JSON.stringify(req.body)}`);

      const data: LoginDto = req.body;
      const tenantId = req.headers['x-tenant-id'] as string;

      logger.info(`Parsed data: ${JSON.stringify({ email: data.email, tenantId })}`);

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido en headers' });
        return;
      }

      const result = await authService.login(data, tenantId);

      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al iniciar sesión';
      res.status(401).json({ error: message });
    }
  }

  async refreshToken(req: Request, res: Response): Promise<void> {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        res.status(400).json({ error: 'Refresh token requerido' });
        return;
      }

      const result = await authService.refreshToken(refreshToken);

      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al renovar token';
      res.status(401).json({ error: message });
    }
  }

  async logout(req: Request, res: Response): Promise<void> {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        res.status(400).json({ error: 'Refresh token requerido' });
        return;
      }

      await authService.logout(refreshToken);

      res.json({ message: 'Sesión cerrada exitosamente' });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al cerrar sesión';
      res.status(400).json({ error: message });
    }
  }

  async me(req: Request, res: Response): Promise<void> {
    // User data is already attached by auth middleware
    res.json({ user: (req as any).user });
  }

  async forgotPassword(req: Request, res: Response): Promise<void> {
    try {
      const data: ForgotPasswordDto = req.body;
      const tenantId = req.headers['x-tenant-id'] as string;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido en headers' });
        return;
      }

      if (!data.email) {
        res.status(400).json({ error: 'Email requerido' });
        return;
      }

      const result = await authService.forgotPassword(data, tenantId);
      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al procesar solicitud';
      res.status(400).json({ error: message });
    }
  }

  async resetPassword(req: Request, res: Response): Promise<void> {
    try {
      const data: ResetPasswordDto = req.body;

      if (!data.token || !data.password) {
        res.status(400).json({ error: 'Token y nueva contraseña requeridos' });
        return;
      }

      if (data.password.length < 8) {
        res.status(400).json({ error: 'La contraseña debe tener al menos 8 caracteres' });
        return;
      }

      const result = await authService.resetPassword(data);
      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al restablecer contraseña';
      res.status(400).json({ error: message });
    }
  }

  async updateProfile(req: AuthRequest, res: Response): Promise<void> {
    try {
      const data: UpdateProfileDto = req.body;
      const userId = req.user?.userId;
      const tenantId = req.user?.tenantId;

      if (!userId || !tenantId) {
        res.status(401).json({ error: 'No autorizado' });
        return;
      }

      const result = await authService.updateProfile(userId, tenantId, data);
      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al actualizar perfil';
      res.status(400).json({ error: message });
    }
  }

  async getProfile(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user?.userId;
      const tenantId = req.user?.tenantId;

      if (!userId || !tenantId) {
        res.status(401).json({ error: 'No autorizado' });
        return;
      }

      const result = await authService.getProfile(userId, tenantId);
      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener perfil';
      res.status(400).json({ error: message });
    }
  }
}
