import { Response } from 'express';
import { UsersService } from './users.service.js';
import type { AuthRequest } from '../../middleware/auth.middleware.js';
import type { CreateUserDto, UpdateUserDto } from './users.types.js';

const usersService = new UsersService();

export class UsersController {
  async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      const data: CreateUserDto = req.body;
      const tenantId = req.user!.tenantId;

      const user = await usersService.create(data, tenantId);

      res.status(201).json(user);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al crear usuario';
      res.status(400).json({ error: message });
    }
  }

  async findAll(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user!.tenantId;
      const { role, isActive, search } = req.query;

      const users = await usersService.findAll(tenantId, {
        role: role as string,
        isActive: isActive === 'true' ? true : isActive === 'false' ? false : undefined,
        search: search as string,
      });

      res.json(users);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener usuarios';
      res.status(400).json({ error: message });
    }
  }

  async findById(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const user = await usersService.findById(id, tenantId);

      res.json(user);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener usuario';
      res.status(400).json({ error: message });
    }
  }

  async update(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const data: UpdateUserDto = req.body;
      const tenantId = req.user!.tenantId;

      const user = await usersService.update(id, data, tenantId);

      res.json(user);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al actualizar usuario';
      res.status(400).json({ error: message });
    }
  }

  async toggleStatus(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const user = await usersService.toggleStatus(id, tenantId);

      res.json(user);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al cambiar estado';
      res.status(400).json({ error: message });
    }
  }

  async delete(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      // Prevent self-deletion
      if (id === req.user!.userId) {
        res.status(400).json({ error: 'No puedes eliminar tu propio usuario' });
        return;
      }

      const result = await usersService.delete(id, tenantId);

      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al eliminar usuario';
      res.status(400).json({ error: message });
    }
  }

  async updatePassword(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const { password } = req.body;
      const tenantId = req.user!.tenantId;

      if (!password || password.length < 8) {
        res.status(400).json({ error: 'La contraseña debe tener al menos 8 caracteres' });
        return;
      }

      const result = await usersService.updatePassword(id, password, tenantId);

      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al actualizar contraseña';
      res.status(400).json({ error: message });
    }
  }

  async getStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user!.tenantId;

      const stats = await usersService.getStats(tenantId);

      res.json(stats);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener estadísticas';
      res.status(400).json({ error: message });
    }
  }
}
