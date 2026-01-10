import { Response } from 'express';
import { TripLogsService } from './trip-logs.service.js';
import type { AuthRequest } from '../../middleware/auth.middleware.js';
import type { CreateTripLogDto, EndTripLogDto, CreateTripEntryDto } from './trip-logs.types.js';

const tripLogsService = new TripLogsService();

export class TripLogsController {
  async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      const data: CreateTripLogDto = req.body;
      const inspectorId = req.user?.userId;
      const tenantId = req.user?.tenantId;

      if (!tenantId || !inspectorId) {
        res.status(400).json({ error: 'Datos de autenticación inválidos' });
        return;
      }

      if (!data.title) {
        res.status(400).json({ error: 'Título requerido' });
        return;
      }

      const trip = await tripLogsService.create(data, inspectorId, tenantId);
      res.status(201).json(trip);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al crear bitácora';
      res.status(400).json({ error: message });
    }
  }

  async findAll(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId;
      const { inspectorId, vehicleId, status } = req.query;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID no disponible' });
        return;
      }

      const trips = await tripLogsService.findAll(tenantId, {
        inspectorId: inspectorId as string,
        vehicleId: vehicleId as string,
        status: status as string,
      });

      res.json(trips);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener bitácoras';
      res.status(500).json({ error: message });
    }
  }

  async findMyTrips(req: AuthRequest, res: Response): Promise<void> {
    try {
      const inspectorId = req.user?.userId;
      const tenantId = req.user?.tenantId;

      if (!tenantId || !inspectorId) {
        res.status(400).json({ error: 'Datos de autenticación inválidos' });
        return;
      }

      const trips = await tripLogsService.findAll(tenantId, { inspectorId });
      res.json(trips);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener mis bitácoras';
      res.status(500).json({ error: message });
    }
  }

  async findMyActive(req: AuthRequest, res: Response): Promise<void> {
    try {
      const inspectorId = req.user?.userId;
      const tenantId = req.user?.tenantId;

      if (!tenantId || !inspectorId) {
        res.status(400).json({ error: 'Datos de autenticación inválidos' });
        return;
      }

      const trip = await tripLogsService.findMyActive(inspectorId, tenantId);
      res.json(trip);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener bitácora activa';
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

      const trip = await tripLogsService.findById(id, tenantId);
      res.json(trip);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener bitácora';
      res.status(404).json({ error: message });
    }
  }

  async endTrip(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const data: EndTripLogDto = req.body;
      const inspectorId = req.user?.userId;
      const tenantId = req.user?.tenantId;

      if (!tenantId || !inspectorId) {
        res.status(400).json({ error: 'Datos de autenticación inválidos' });
        return;
      }

      const trip = await tripLogsService.endTrip(id, data, inspectorId, tenantId);
      res.json(trip);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al finalizar bitácora';
      res.status(400).json({ error: message });
    }
  }

  async cancelTrip(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const inspectorId = req.user?.userId;
      const tenantId = req.user?.tenantId;

      if (!tenantId || !inspectorId) {
        res.status(400).json({ error: 'Datos de autenticación inválidos' });
        return;
      }

      const trip = await tripLogsService.cancelTrip(id, inspectorId, tenantId);
      res.json(trip);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al cancelar bitácora';
      res.status(400).json({ error: message });
    }
  }

  async addEntry(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const data: CreateTripEntryDto = req.body;
      const inspectorId = req.user?.userId;
      const tenantId = req.user?.tenantId;

      if (!tenantId || !inspectorId) {
        res.status(400).json({ error: 'Datos de autenticación inválidos' });
        return;
      }

      if (!data.entryType || !data.description) {
        res.status(400).json({ error: 'Tipo de entrada y descripción requeridos' });
        return;
      }

      const entry = await tripLogsService.addEntry(id, data, inspectorId, tenantId);
      res.status(201).json(entry);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al agregar entrada';
      res.status(400).json({ error: message });
    }
  }

  async getStats(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId;
      const userRole = req.user?.role;
      const userId = req.user?.userId;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID no disponible' });
        return;
      }

      // Admins see all stats, inspectors see only their own
      const inspectorId = userRole === 'admin' ? undefined : userId;
      const stats = await tripLogsService.getStats(tenantId, inspectorId);
      res.json(stats);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener estadísticas';
      res.status(500).json({ error: message });
    }
  }
}
