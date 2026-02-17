import { Request, Response } from 'express';
import { GpsTrackingService } from './gps-tracking.service.js';
import { GpsBatchDto } from './gps-tracking.types.js';

interface AuthRequest extends Request {
  user?: {
    userId: string;
    email: string;
    role: string;
    tenantId: string;
  };
}

export class GpsTrackingController {
  private gpsService: GpsTrackingService;

  constructor() {
    this.gpsService = new GpsTrackingService();
  }

  // POST /api/gps/batch - Receive batch of GPS points
  async insertBatch(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const inspectorId = req.user?.userId;

      if (!inspectorId) {
        res.status(401).json({ error: 'No autorizado' });
        return;
      }

      const batch: GpsBatchDto = req.body;

      if (!batch.vehicleId || !batch.points || !Array.isArray(batch.points)) {
        res.status(400).json({ error: 'Datos inválidos: se requiere vehicleId y points' });
        return;
      }

      const result = await this.gpsService.insertBatch(tenantId, inspectorId, batch);

      // Emit socket event for real-time update
      const io = req.app.get('io');
      if (io && batch.points.length > 0) {
        const lastPoint = batch.points[batch.points.length - 1];
        io.of('/fleet').to(`tenant:${tenantId}`).emit('vehicle:position', {
          vehicleId: batch.vehicleId,
          inspectorId,
          latitude: lastPoint.latitude,
          longitude: lastPoint.longitude,
          speed: lastPoint.speed,
          heading: lastPoint.heading,
          timestamp: lastPoint.recordedAt,
        });
      }

      res.json({
        success: true,
        inserted: result.inserted,
        vehicleLogId: result.vehicleLogId,
      });
    } catch (error) {
      console.error('Error inserting GPS batch:', error);
      res.status(500).json({ error: 'Error al insertar puntos GPS' });
    }
  }

  // GET /api/gps/vehicles/live - Get live positions of all active vehicles
  async getLivePositions(req: AuthRequest, res: Response) {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';

      const positions = await this.gpsService.getLivePositions(tenantId);

      res.json(positions);
    } catch (error) {
      console.error('Error getting live positions:', error);
      res.status(500).json({ error: 'Error al obtener posiciones' });
    }
  }

  // GET /api/gps/vehicle/:vehicleId/live - Get live position of a specific vehicle
  async getVehiclePosition(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const { vehicleId } = req.params;

      const position = await this.gpsService.getVehiclePosition(tenantId, vehicleId);

      if (!position) {
        res.status(404).json({ error: 'Vehículo no encontrado o sin posición activa' });
        return;
      }

      res.json(position);
    } catch (error) {
      console.error('Error getting vehicle position:', error);
      res.status(500).json({ error: 'Error al obtener posición del vehículo' });
    }
  }

  // GET /api/gps/log/:logId/route - Get route for a specific vehicle log
  async getRouteHistory(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const { logId } = req.params;

      const route = await this.gpsService.getRouteHistory(tenantId, logId);

      if (!route) {
        res.status(404).json({ error: 'Ruta no encontrada' });
        return;
      }

      res.json(route);
    } catch (error) {
      console.error('Error getting route history:', error);
      res.status(500).json({ error: 'Error al obtener historial de ruta' });
    }
  }

  // GET /api/gps/vehicle/:vehicleId/history - Get route history by date range
  async getVehicleHistory(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const { vehicleId } = req.params;
      const { startDate, endDate } = req.query;

      if (!startDate || !endDate) {
        res.status(400).json({ error: 'Se requiere startDate y endDate' });
        return;
      }

      const routes = await this.gpsService.getRoutesByDateRange(tenantId, {
        vehicleId,
        startDate: startDate as string,
        endDate: endDate as string,
      });

      res.json(routes);
    } catch (error) {
      console.error('Error getting vehicle history:', error);
      res.status(500).json({ error: 'Error al obtener historial del vehículo' });
    }
  }

  // GET /api/gps/vehicle/:vehicleId/activity-days - Get days with activity for calendar
  async getActivityDays(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const { vehicleId } = req.params;
      const { year, month } = req.query;

      const yearNum = year ? parseInt(year as string) : new Date().getFullYear();
      const monthNum = month ? parseInt(month as string) : new Date().getMonth() + 1;

      if (monthNum < 1 || monthNum > 12) {
        res.status(400).json({ error: 'Mes inválido (1-12)' });
        return;
      }

      const result = await this.gpsService.getActivityDays(tenantId, vehicleId, yearNum, monthNum);
      res.json(result);
    } catch (error) {
      console.error('Error getting activity days:', error);
      res.status(500).json({ error: 'Error al obtener días con actividad' });
    }
  }

  // GET /api/gps/stats - Get GPS statistics
  async getStats(req: AuthRequest, res: Response) {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const { startDate, endDate } = req.query;

      const stats = await this.gpsService.getStats(
        tenantId,
        startDate as string | undefined,
        endDate as string | undefined
      );

      res.json(stats);
    } catch (error) {
      console.error('Error getting GPS stats:', error);
      res.status(500).json({ error: 'Error al obtener estadísticas' });
    }
  }

  // DELETE /api/gps/cleanup - Cleanup old GPS points (admin only)
  async cleanup(req: AuthRequest, res: Response) {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const { days } = req.query;

      const daysToKeep = days ? parseInt(days as string) : 90;
      const deleted = await this.gpsService.cleanupOldPoints(tenantId, daysToKeep);

      res.json({ success: true, deleted });
    } catch (error) {
      console.error('Error cleaning up GPS points:', error);
      res.status(500).json({ error: 'Error al limpiar puntos GPS' });
    }
  }
}
