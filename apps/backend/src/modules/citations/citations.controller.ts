import { Response } from 'express';
import { CitationsService } from './citations.service.js';
import type { AuthRequest } from '../../middleware/auth.middleware.js';
import type { CreateCitationDto, UpdateCitationDto, CitationFilters } from './citations.types.js';

const citationsService = new CitationsService();

export class CitationsController {
  async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      const data: CreateCitationDto = req.body;
      const tenantId = req.user!.tenantId;
      const issuedBy = req.user!.userId;

      const citation = await citationsService.create(data, tenantId, issuedBy);

      res.status(201).json(citation);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al crear citación';
      res.status(400).json({ error: message });
    }
  }

  async findAll(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user!.tenantId;
      const { status, citationType, targetType, search, fromDate, toDate } = req.query;

      // Citizens can only see their own citations
      const userId = req.user!.role === 'citizen' ? req.user!.userId : undefined;

      const filters: CitationFilters = {
        status: status as CitationFilters['status'],
        citationType: citationType as CitationFilters['citationType'],
        targetType: targetType as CitationFilters['targetType'],
        search: search as string,
        fromDate: fromDate as string,
        toDate: toDate as string,
        userId,
      };

      const citations = await citationsService.findAll(tenantId, filters);

      res.json(citations);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener citaciones';
      res.status(400).json({ error: message });
    }
  }

  async findById(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const citation = await citationsService.findById(id, tenantId);

      // Citizens can only see their own citations
      if (req.user!.role === 'citizen' && citation.user_id !== req.user!.userId) {
        res.status(403).json({ error: 'No tienes permiso para ver esta citación' });
        return;
      }

      res.json(citation);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener citación';
      res.status(400).json({ error: message });
    }
  }

  async update(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const data: UpdateCitationDto = req.body;
      const tenantId = req.user!.tenantId;

      const citation = await citationsService.update(id, data, tenantId);

      res.json(citation);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al actualizar citación';
      res.status(400).json({ error: message });
    }
  }

  async delete(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const result = await citationsService.delete(id, tenantId);

      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al eliminar citación';
      res.status(400).json({ error: message });
    }
  }

  async getStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user!.tenantId;

      const stats = await citationsService.getStats(tenantId);

      res.json(stats);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener estadísticas';
      res.status(400).json({ error: message });
    }
  }

  async getUpcoming(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user!.tenantId;
      const userId = req.user!.role === 'citizen' ? req.user!.userId : undefined;

      const citations = await citationsService.getUpcoming(tenantId, userId);

      res.json(citations);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener citaciones próximas';
      res.status(400).json({ error: message });
    }
  }
}
