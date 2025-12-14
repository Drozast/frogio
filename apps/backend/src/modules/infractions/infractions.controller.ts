import { Response } from 'express';
import { InfractionsService } from './infractions.service.js';
import type { AuthRequest } from '../../middleware/auth.middleware.js';
import type { CreateInfractionDto, UpdateInfractionDto } from './infractions.types.js';

const infractionsService = new InfractionsService();

export class InfractionsController {
  async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      const data: CreateInfractionDto = req.body;
      const issuedBy = req.user!.userId;
      const tenantId = req.user!.tenantId;

      const infraction = await infractionsService.create(data, issuedBy, tenantId);

      res.status(201).json(infraction);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al crear infracción';
      res.status(400).json({ error: message });
    }
  }

  async findAll(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user!.tenantId;
      const { status } = req.query;

      // Citizens can only see their own infractions
      const userId = req.user!.role === 'citizen' ? req.user!.userId : undefined;

      const infractions = await infractionsService.findAll(tenantId, {
        status: status as string,
        userId,
      });

      res.json(infractions);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener infracciones';
      res.status(400).json({ error: message });
    }
  }

  async findById(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const infraction = await infractionsService.findById(id, tenantId);

      // Citizens can only see their own infractions
      if (req.user!.role === 'citizen' && infraction.user_id !== req.user!.userId) {
        res.status(403).json({ error: 'No tienes permiso para ver esta infracción' });
        return;
      }

      res.json(infraction);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener infracción';
      res.status(400).json({ error: message });
    }
  }

  async update(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const data: UpdateInfractionDto = req.body;
      const tenantId = req.user!.tenantId;

      const infraction = await infractionsService.update(id, data, tenantId);

      res.json(infraction);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al actualizar infracción';
      res.status(400).json({ error: message });
    }
  }

  async delete(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const result = await infractionsService.delete(id, tenantId);

      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al eliminar infracción';
      res.status(400).json({ error: message });
    }
  }

  async getStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user!.tenantId;
      const userId = req.user!.role === 'citizen' ? req.user!.userId : undefined;

      const stats = await infractionsService.getStats(tenantId, userId);

      res.json(stats);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener estadísticas';
      res.status(400).json({ error: message });
    }
  }
}
