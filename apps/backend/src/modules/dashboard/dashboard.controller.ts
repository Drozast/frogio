import { Response } from 'express';
import { DashboardService } from './dashboard.service.js';
import type { AuthRequest } from '../../middleware/auth.middleware.js';

const dashboardService = new DashboardService();

export class DashboardController {
  async getStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId;
      const userRole = req.user?.role;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID no disponible' });
        return;
      }

      const stats = await dashboardService.getStats(tenantId, userRole || 'citizen');
      res.json(stats);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener estadísticas';
      res.status(500).json({ error: message });
    }
  }
}
