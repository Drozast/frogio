import { Request, Response } from 'express';
import { GeofencesService } from './geofences.service';
import { CreateGeofenceDto, UpdateGeofenceDto } from './geofences.types';

interface AuthRequest extends Request {
  user?: {
    userId: string;
    email: string;
    role: string;
    tenantId: string;
  };
}

export class GeofencesController {
  private geofencesService: GeofencesService;

  constructor() {
    this.geofencesService = new GeofencesService();
  }

  // POST /api/geofences - Create geofence
  async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const data: CreateGeofenceDto = req.body;

      if (!data.name || !data.geofenceType) {
        res.status(400).json({ error: 'Se requiere name y geofenceType' });
        return;
      }

      const geofence = await this.geofencesService.create(tenantId, data);

      // Emit socket event
      const io = req.app.get('io');
      if (io) {
        io.of('/fleet').to(`tenant:${tenantId}`).emit('geofence:created', geofence);
      }

      res.status(201).json(geofence);
    } catch (error) {
      console.error('Error creating geofence:', error);
      const message = error instanceof Error ? error.message : 'Error al crear geofence';
      res.status(500).json({ error: message });
    }
  }

  // GET /api/geofences - List all geofences
  async findAll(req: AuthRequest, res: Response) {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const activeOnly = req.query.active === 'true';

      const geofences = await this.geofencesService.findAll(tenantId, activeOnly);

      res.json(geofences);
    } catch (error) {
      console.error('Error listing geofences:', error);
      res.status(500).json({ error: 'Error al listar geofences' });
    }
  }

  // GET /api/geofences/:id - Get geofence by ID
  async findById(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const { id } = req.params;

      const geofence = await this.geofencesService.findById(tenantId, id);

      if (!geofence) {
        res.status(404).json({ error: 'Geofence no encontrado' });
        return;
      }

      res.json(geofence);
    } catch (error) {
      console.error('Error getting geofence:', error);
      res.status(500).json({ error: 'Error al obtener geofence' });
    }
  }

  // PATCH /api/geofences/:id - Update geofence
  async update(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const { id } = req.params;
      const data: UpdateGeofenceDto = req.body;

      const geofence = await this.geofencesService.update(tenantId, id, data);

      if (!geofence) {
        res.status(404).json({ error: 'Geofence no encontrado' });
        return;
      }

      // Emit socket event
      const io = req.app.get('io');
      if (io) {
        io.of('/fleet').to(`tenant:${tenantId}`).emit('geofence:updated', geofence);
      }

      res.json(geofence);
    } catch (error) {
      console.error('Error updating geofence:', error);
      res.status(500).json({ error: 'Error al actualizar geofence' });
    }
  }

  // DELETE /api/geofences/:id - Delete geofence
  async delete(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const { id } = req.params;

      const deleted = await this.geofencesService.delete(tenantId, id);

      if (!deleted) {
        res.status(404).json({ error: 'Geofence no encontrado' });
        return;
      }

      // Emit socket event
      const io = req.app.get('io');
      if (io) {
        io.of('/fleet').to(`tenant:${tenantId}`).emit('geofence:deleted', { id });
      }

      res.json({ success: true });
    } catch (error) {
      console.error('Error deleting geofence:', error);
      res.status(500).json({ error: 'Error al eliminar geofence' });
    }
  }

  // GET /api/geofences/events/recent - Get recent events
  async getRecentEvents(req: AuthRequest, res: Response) {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const limit = req.query.limit ? parseInt(req.query.limit as string) : 50;

      const events = await this.geofencesService.getRecentEvents(tenantId, limit);

      res.json(events);
    } catch (error) {
      console.error('Error getting recent events:', error);
      res.status(500).json({ error: 'Error al obtener eventos recientes' });
    }
  }

  // GET /api/geofences/:id/events - Get events for a geofence
  async getGeofenceEvents(req: AuthRequest, res: Response) {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const { id } = req.params;
      const limit = req.query.limit ? parseInt(req.query.limit as string) : 100;

      const events = await this.geofencesService.getGeofenceEvents(tenantId, id, limit);

      res.json(events);
    } catch (error) {
      console.error('Error getting geofence events:', error);
      res.status(500).json({ error: 'Error al obtener eventos del geofence' });
    }
  }

  // POST /api/geofences/check - Check if a point is inside geofences
  async checkPoint(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user?.tenantId || 'santa_juana';
      const { latitude, longitude } = req.body;

      if (latitude === undefined || longitude === undefined) {
        res.status(400).json({ error: 'Se requiere latitude y longitude' });
        return;
      }

      const results = await this.geofencesService.checkPoint(tenantId, latitude, longitude);

      res.json(results);
    } catch (error) {
      console.error('Error checking point:', error);
      res.status(500).json({ error: 'Error al verificar punto' });
    }
  }
}
