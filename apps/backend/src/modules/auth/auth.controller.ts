import { Request, Response } from 'express';
import { AuthService } from './auth.service.js';
import type { RegisterDto, LoginDto } from './auth.types.js';

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
      console.log('🎯 Backend received login request');
      console.log('📦 Raw body type:', typeof req.body);
      console.log('📦 Raw body:', req.body);

      const data: LoginDto = req.body;
      const tenantId = req.headers['x-tenant-id'] as string;

      console.log('🔑 Parsed data:', { email: data.email, password: data.password?.substring(0, 8) + '...', tenantId });

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
}
