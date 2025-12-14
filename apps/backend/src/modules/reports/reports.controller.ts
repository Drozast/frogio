import { Response } from 'express';
import { ReportsService } from './reports.service';
import type { AuthRequest } from '../../middleware/auth.middleware';
import type { CreateReportDto, UpdateReportDto } from './reports.types';

const reportsService = new ReportsService();

export class ReportsController {
  async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      const data: CreateReportDto = req.body;
      const userId = req.user!.userId;
      const tenantId = req.user!.tenantId;

      const report = await reportsService.create(data, userId, tenantId);

      res.status(201).json(report);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al crear reporte';
      res.status(400).json({ error: message });
    }
  }

  async findAll(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user!.tenantId;
      const { status, type } = req.query;

      // Citizens can only see their own reports
      const userId = req.user!.role === 'citizen' ? req.user!.userId : undefined;

      const reports = await reportsService.findAll(tenantId, {
        status: status as string,
        type: type as string,
        userId,
      });

      res.json(reports);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener reportes';
      res.status(400).json({ error: message });
    }
  }

  async findById(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const report = await reportsService.findById(id, tenantId);

      // Citizens can only see their own reports
      if (req.user!.role === 'citizen' && report.user_id !== req.user!.userId) {
        res.status(403).json({ error: 'No tienes permiso para ver este reporte' });
        return;
      }

      res.json(report);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener reporte';
      res.status(400).json({ error: message });
    }
  }

  async update(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const data: UpdateReportDto = req.body;
      const tenantId = req.user!.tenantId;

      const report = await reportsService.update(id, data, tenantId);

      res.json(report);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al actualizar reporte';
      res.status(400).json({ error: message });
    }
  }

  async delete(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const result = await reportsService.delete(id, tenantId);

      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al eliminar reporte';
      res.status(400).json({ error: message });
    }
  }
}
