import { Response } from 'express';
import { ExportsService } from './exports.service.js';
import type { AuthRequest } from '../../middleware/auth.middleware.js';

const exportsService = new ExportsService();

export class ExportsController {
  async exportReports(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId;
      const { format = 'json', status, startDate, endDate } = req.query;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID no disponible' });
        return;
      }

      const data = await exportsService.exportReports(
        tenantId,
        format as 'json' | 'csv',
        { status: status as string, startDate: startDate as string, endDate: endDate as string }
      );

      if (format === 'csv') {
        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename=reportes_${new Date().toISOString().split('T')[0]}.csv`);
        res.send(data);
      } else {
        res.json(data);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al exportar reportes';
      res.status(500).json({ error: message });
    }
  }

  async exportInfractions(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId;
      const { format = 'json', status, type, startDate, endDate } = req.query;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID no disponible' });
        return;
      }

      const data = await exportsService.exportInfractions(
        tenantId,
        format as 'json' | 'csv',
        { status: status as string, type: type as string, startDate: startDate as string, endDate: endDate as string }
      );

      if (format === 'csv') {
        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename=infracciones_${new Date().toISOString().split('T')[0]}.csv`);
        res.send(data);
      } else {
        res.json(data);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al exportar infracciones';
      res.status(500).json({ error: message });
    }
  }

  async exportUsers(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId;
      const { format = 'json', role, isActive } = req.query;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID no disponible' });
        return;
      }

      const data = await exportsService.exportUsers(
        tenantId,
        format as 'json' | 'csv',
        { role: role as string, isActive: isActive === 'true' ? true : isActive === 'false' ? false : undefined }
      );

      if (format === 'csv') {
        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename=usuarios_${new Date().toISOString().split('T')[0]}.csv`);
        res.send(data);
      } else {
        res.json(data);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al exportar usuarios';
      res.status(500).json({ error: message });
    }
  }

  async exportVehicles(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId;
      const { format = 'json' } = req.query;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID no disponible' });
        return;
      }

      const data = await exportsService.exportVehicles(tenantId, format as 'json' | 'csv');

      if (format === 'csv') {
        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', `attachment; filename=vehiculos_${new Date().toISOString().split('T')[0]}.csv`);
        res.send(data);
      } else {
        res.json(data);
      }
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al exportar vehículos';
      res.status(500).json({ error: message });
    }
  }

  async getStatisticsReport(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID no disponible' });
        return;
      }

      const stats = await exportsService.getStatisticsReport(tenantId);
      res.json(stats);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al generar reporte';
      res.status(500).json({ error: message });
    }
  }
}
