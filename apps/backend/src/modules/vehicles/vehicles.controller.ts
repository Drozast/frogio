import { Response } from 'express';
import { VehiclesService } from './vehicles.service.js';
import type { AuthRequest } from '../../middleware/auth.middleware.js';
import type { CreateVehicleDto, UpdateVehicleDto, StartVehicleUsageDto, EndVehicleUsageDto } from './vehicles.types.js';

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

  // ===== VEHICLE LOGS =====

  async startUsage(req: AuthRequest, res: Response): Promise<void> {
    try {
      const data: StartVehicleUsageDto = {
        ...req.body,
        driverId: req.user!.userId,
        driverName: `${req.body.driverName || req.user!.email}`,
      };
      const tenantId = req.user!.tenantId;

      const log = await vehiclesService.startVehicleUsage(data, tenantId);

      res.status(201).json(log);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al iniciar uso del vehículo';
      res.status(400).json({ error: message });
    }
  }

  async endUsage(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { logId } = req.params;
      const data: EndVehicleUsageDto = req.body;
      const tenantId = req.user!.tenantId;

      const log = await vehiclesService.endVehicleUsage(logId, data, tenantId);

      res.json(log);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al finalizar uso del vehículo';
      res.status(400).json({ error: message });
    }
  }

  async getVehicleLogs(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { vehicleId } = req.params;
      const { limit } = req.query;
      const tenantId = req.user!.tenantId;

      const logs = await vehiclesService.getVehicleLogs(
        vehicleId,
        tenantId,
        limit ? parseInt(limit as string) : 50
      );

      res.json(logs);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener registros';
      res.status(400).json({ error: message });
    }
  }

  async getMyLogs(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { limit } = req.query;
      const tenantId = req.user!.tenantId;
      const driverId = req.user!.userId;

      const logs = await vehiclesService.getLogsByDriver(
        driverId,
        tenantId,
        limit ? parseInt(limit as string) : 50
      );

      res.json(logs);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener mis registros';
      res.status(400).json({ error: message });
    }
  }

  async getActiveUsage(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user!.tenantId;

      const logs = await vehiclesService.getActiveVehicleUsage(tenantId);

      res.json(logs);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener usos activos';
      res.status(400).json({ error: message });
    }
  }

  async getLogById(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { logId } = req.params;
      const tenantId = req.user!.tenantId;

      const log = await vehiclesService.getLogById(logId, tenantId);

      res.json(log);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener registro';
      res.status(400).json({ error: message });
    }
  }

  async cancelUsage(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { logId } = req.params;
      const tenantId = req.user!.tenantId;

      const log = await vehiclesService.cancelVehicleUsage(logId, tenantId);

      res.json(log);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al cancelar uso';
      res.status(400).json({ error: message });
    }
  }

  // Get all logs with filters (admin only)
  async getAllLogs(req: AuthRequest, res: Response): Promise<void> {
    try {
      const tenantId = req.user!.tenantId;
      const { vehicleId, driverId, startDate, endDate, status } = req.query;

      const logs = await vehiclesService.getAllLogs(tenantId, {
        vehicleId: vehicleId as string | undefined,
        driverId: driverId as string | undefined,
        startDate: startDate as string | undefined,
        endDate: endDate as string | undefined,
        status: status as string | undefined,
      });

      res.json(logs);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener bitácora';
      res.status(400).json({ error: message });
    }
  }
}
