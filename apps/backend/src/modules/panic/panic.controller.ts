import { Response } from 'express';
import { PanicService } from './panic.service.js';
import type { AuthRequest } from '../../middleware/auth.middleware.js';
import type { CreatePanicAlertDto } from './panic.types.js';

const panicService = new PanicService();

export class PanicController {
  async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      const data: CreatePanicAlertDto = req.body;
      const userId = req.user?.userId;
      const tenantId = req.user?.tenantId;

      if (!tenantId || !userId) {
        res.status(400).json({ error: 'Datos de autenticación inválidos' });
        return;
      }

      if (!data.latitude || !data.longitude) {
        res.status(400).json({ error: 'Ubicación (latitude/longitude) requerida' });
        return;
      }

      const alert = await panicService.create(data, userId, tenantId);
      res.status(201).json(alert);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al crear alerta';
      res.status(400).json({ error: message });
    }
  }

  async findAll(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId;
      const { status, userId } = req.query;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID no disponible' });
        return;
      }

      const alerts = await panicService.findAll(tenantId, {
        status: status as string,
        userId: userId as string,
      });

      res.json(alerts);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener alertas';
      res.status(500).json({ error: message });
    }
  }

  async findActive(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID no disponible' });
        return;
      }

      const alerts = await panicService.findActive(tenantId);
      res.json(alerts);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener alertas activas';
      res.status(500).json({ error: message });
    }
  }

  async findById(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user?.tenantId;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID no disponible' });
        return;
      }

      const alert = await panicService.findById(id, tenantId);
      res.json(alert);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener alerta';
      res.status(404).json({ error: message });
    }
  }

  async respond(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const responderId = req.user?.userId;
      const tenantId = req.user?.tenantId;

      if (!tenantId || !responderId) {
        res.status(400).json({ error: 'Datos de autenticación inválidos' });
        return;
      }

      const alert = await panicService.respond(id, responderId, tenantId);
      res.json(alert);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al responder alerta';
      res.status(400).json({ error: message });
    }
  }

  async resolve(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const { notes } = req.body;
      const tenantId = req.user?.tenantId;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID no disponible' });
        return;
      }

      const alert = await panicService.resolve(id, notes, tenantId);
      res.json(alert);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al resolver alerta';
      res.status(400).json({ error: message });
    }
  }

  async cancel(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const userId = req.user?.userId;
      const tenantId = req.user?.tenantId;

      if (!tenantId || !userId) {
        res.status(400).json({ error: 'Datos de autenticación inválidos' });
        return;
      }

      const alert = await panicService.cancel(id, userId, tenantId);
      res.json(alert);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al cancelar alerta';
      res.status(400).json({ error: message });
    }
  }

  async getStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID no disponible' });
        return;
      }

      const stats = await panicService.getStats(tenantId);
      res.json(stats);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener estadísticas';
      res.status(500).json({ error: message });
    }
  }
}
