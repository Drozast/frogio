import { Response } from 'express';
import { VehiclesService } from './vehicles.service.js';
import type { AuthRequest } from '../../middleware/auth.middleware.js';
import type { CreateVehicleDto, UpdateVehicleDto } from './vehicles.types.js';

const vehiclesService = new VehiclesService();

export class VehiclesController {
  async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      const data: CreateVehicleDto = req.body;
      const tenantId = req.user!.tenantId;

      const vehicle = await vehiclesService.create(data, tenantId);

      res.status(201).json(vehicle);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al crear vehículo';
      res.status(400).json({ error: message });
    }
  }

  async findAll(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user!.tenantId;
      const { isActive } = req.query;

      // Citizens can only see their own vehicles
      const ownerId = req.user!.role === 'citizen' ? req.user!.userId : undefined;

      const vehicles = await vehiclesService.findAll(tenantId, {
        ownerId,
        isActive: isActive === 'true' ? true : isActive === 'false' ? false : undefined,
      });

      res.json(vehicles);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener vehículos';
      res.status(400).json({ error: message });
    }
  }

  async findById(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const vehicle = await vehiclesService.findById(id, tenantId);

      // Citizens can only see their own vehicles
      if (req.user!.role === 'citizen' && vehicle.owner_id !== req.user!.userId) {
        res.status(403).json({ error: 'No tienes permiso para ver este vehículo' });
        return;
      }

      res.json(vehicle);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener vehículo';
      res.status(400).json({ error: message });
    }
  }

  async findByPlate(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { plate } = req.params;
      const tenantId = req.user!.tenantId;

      const vehicle = await vehiclesService.findByPlate(plate, tenantId);

      if (!vehicle) {
        res.status(404).json({ error: 'Vehículo no encontrado' });
        return;
      }

      // Citizens can only see their own vehicles
      if (req.user!.role === 'citizen' && vehicle.owner_id !== req.user!.userId) {
        res.status(403).json({ error: 'No tienes permiso para ver este vehículo' });
        return;
      }

      res.json(vehicle);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al buscar vehículo';
      res.status(400).json({ error: message });
    }
  }

  async update(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const data: UpdateVehicleDto = req.body;
      const tenantId = req.user!.tenantId;

      // Citizens can only update their own vehicles
      if (req.user!.role === 'citizen') {
        const existingVehicle = await vehiclesService.findById(id, tenantId);
        if (existingVehicle.owner_id !== req.user!.userId) {
          res.status(403).json({ error: 'No tienes permiso para actualizar este vehículo' });
          return;
        }
      }

      const vehicle = await vehiclesService.update(id, data, tenantId);

      res.json(vehicle);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al actualizar vehículo';
      res.status(400).json({ error: message });
    }
  }

  async delete(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const result = await vehiclesService.delete(id, tenantId);

      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al eliminar vehículo';
      res.status(400).json({ error: message });
    }
  }
}
