import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock prisma
vi.mock('../../src/config/database.js', () => ({
  default: {
    $queryRawUnsafe: vi.fn(),
  },
}));

import prisma from '../../src/config/database.js';
import { VehiclesService } from '../../src/modules/vehicles/vehicles.service.js';

describe('VehiclesService', () => {
  let vehiclesService: VehiclesService;
  const tenantId = 'santa_juana';

  beforeEach(() => {
    vehiclesService = new VehiclesService();
    vi.clearAllMocks();
  });

  describe('create', () => {
    it('should create a new vehicle successfully', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // No existing vehicle
      mockQueries.mockResolvedValueOnce([]);

      // Vehicle creation
      mockQueries.mockResolvedValueOnce([{
        id: '123',
        plate: 'ABCD-12',
        brand: 'Toyota',
        model: 'Hilux',
        owner_id: 'owner-123',
      }]);

      const result = await vehiclesService.create({
        plate: 'ABCD-12',
        brand: 'Toyota',
        model: 'Hilux',
        ownerId: 'owner-123',
      }, tenantId);

      expect(result.plate).toBe('ABCD-12');
      expect(result.brand).toBe('Toyota');
    });

    it('should throw error if plate already exists', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Existing vehicle found
      mockQueries.mockResolvedValueOnce([{ id: 'existing-id' }]);

      await expect(
        vehiclesService.create({
          plate: 'ABCD-12',
          ownerId: 'owner-123',
        }, tenantId)
      ).rejects.toThrow('Ya existe un vehículo registrado con esta patente');
    });
  });

  describe('findByPlate', () => {
    it('should find vehicle by plate', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{
        id: '123',
        plate: 'ABCD-12',
        brand: 'Toyota',
        model: 'Hilux',
      }]);

      const result = await vehiclesService.findByPlate('abcd-12', tenantId);

      expect(result).not.toBeNull();
      expect(result.plate).toBe('ABCD-12');
      // Should convert to uppercase
      expect(mockQueries).toHaveBeenCalledWith(
        expect.any(String),
        'ABCD-12'
      );
    });

    it('should return null if vehicle not found', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      const result = await vehiclesService.findByPlate('XXXX-99', tenantId);

      expect(result).toBeNull();
    });
  });

  describe('startVehicleUsage', () => {
    it('should start vehicle usage successfully', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Vehicle exists
      mockQueries.mockResolvedValueOnce([{ id: 'vehicle-123', plate: 'ABCD-12' }]);

      // No active log
      mockQueries.mockResolvedValueOnce([]);

      // Insert log
      mockQueries.mockResolvedValueOnce([{
        id: 'log-123',
        vehicle_id: 'vehicle-123',
        driver_id: 'driver-123',
        driver_name: 'Juan Pérez',
        usage_type: 'official',
        start_km: 50000,
        status: 'active',
      }]);

      const result = await vehiclesService.startVehicleUsage({
        vehicleId: 'vehicle-123',
        driverId: 'driver-123',
        driverName: 'Juan Pérez',
        usageType: 'official',
        startKm: 50000,
      }, tenantId);

      expect(result.status).toBe('active');
      expect(result.start_km).toBe(50000);
    });

    it('should throw error if vehicle not found', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Vehicle not found
      mockQueries.mockResolvedValueOnce([]);

      await expect(
        vehiclesService.startVehicleUsage({
          vehicleId: 'nonexistent',
          driverId: 'driver-123',
          driverName: 'Juan Pérez',
          usageType: 'official',
          startKm: 50000,
        }, tenantId)
      ).rejects.toThrow('Vehículo no encontrado');
    });

    it('should throw error if vehicle already has active usage', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Vehicle exists
      mockQueries.mockResolvedValueOnce([{ id: 'vehicle-123', plate: 'ABCD-12' }]);

      // Active log exists
      mockQueries.mockResolvedValueOnce([{ id: 'active-log-123' }]);

      await expect(
        vehiclesService.startVehicleUsage({
          vehicleId: 'vehicle-123',
          driverId: 'driver-123',
          driverName: 'Juan Pérez',
          usageType: 'official',
          startKm: 50000,
        }, tenantId)
      ).rejects.toThrow('Este vehículo ya tiene un uso activo');
    });
  });

  describe('endVehicleUsage', () => {
    it('should end vehicle usage successfully', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Log exists and is active
      mockQueries.mockResolvedValueOnce([{
        id: 'log-123',
        status: 'active',
        start_km: 50000,
      }]);

      // Update log
      mockQueries.mockResolvedValueOnce([{
        id: 'log-123',
        status: 'completed',
        start_km: 50000,
        end_km: 50150,
        total_distance_km: 150,
      }]);

      const result = await vehiclesService.endVehicleUsage('log-123', {
        endKm: 50150,
        observations: 'Viaje sin novedad',
      }, tenantId);

      expect(result.status).toBe('completed');
      expect(result.total_distance_km).toBe(150);
    });

    it('should throw error if log not found', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      await expect(
        vehiclesService.endVehicleUsage('nonexistent', {
          endKm: 50150,
        }, tenantId)
      ).rejects.toThrow('Registro de uso no encontrado');
    });

    it('should throw error if log already completed', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{
        id: 'log-123',
        status: 'completed',
        start_km: 50000,
      }]);

      await expect(
        vehiclesService.endVehicleUsage('log-123', {
          endKm: 50150,
        }, tenantId)
      ).rejects.toThrow('Este registro de uso ya fue finalizado');
    });

    it('should throw error if end km is less than start km', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{
        id: 'log-123',
        status: 'active',
        start_km: 50000,
      }]);

      await expect(
        vehiclesService.endVehicleUsage('log-123', {
          endKm: 49000, // Less than start
        }, tenantId)
      ).rejects.toThrow('El kilometraje final no puede ser menor al inicial');
    });
  });

  describe('getActiveVehicleUsage', () => {
    it('should return all active vehicle usage logs', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'log-1', status: 'active', plate: 'ABCD-12' },
        { id: 'log-2', status: 'active', plate: 'EFGH-34' },
      ]);

      const result = await vehiclesService.getActiveVehicleUsage(tenantId);

      expect(result).toHaveLength(2);
      expect(result[0].status).toBe('active');
    });

    it('should return empty array if no active usage', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      const result = await vehiclesService.getActiveVehicleUsage(tenantId);

      expect(result).toHaveLength(0);
    });
  });

  describe('getAllLogs', () => {
    it('should filter logs by date range', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'log-1', start_time: '2025-01-01T10:00:00Z' },
        { id: 'log-2', start_time: '2025-01-02T10:00:00Z' },
      ]);

      const result = await vehiclesService.getAllLogs(tenantId, {
        startDate: '2025-01-01',
        endDate: '2025-01-31',
      });

      expect(result).toHaveLength(2);
      expect(mockQueries).toHaveBeenCalledWith(
        expect.stringContaining('start_time >='),
        expect.any(Date),
        expect.any(Date)
      );
    });

    it('should filter logs by status', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'log-1', status: 'completed' },
      ]);

      const result = await vehiclesService.getAllLogs(tenantId, {
        status: 'completed',
      });

      expect(result).toHaveLength(1);
    });
  });
});
