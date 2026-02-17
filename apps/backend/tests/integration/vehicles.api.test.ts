import { describe, it, expect, vi, beforeAll, afterAll } from 'vitest';
import express, { Express } from 'express';
import request from 'supertest';

// Mock the database and auth middleware
vi.mock('../../src/config/database.js', () => ({
  default: {
    $queryRawUnsafe: vi.fn(),
  },
}));

vi.mock('../../src/middleware/auth.middleware.js', () => ({
  authMiddleware: (req: any, _res: any, next: any) => {
    req.user = {
      id: 'test-inspector-id',
      email: 'inspector@test.cl',
      role: 'inspector',
      tenantId: 'santa_juana',
    };
    next();
  },
  roleGuard: (..._roles: string[]) => (_req: any, _res: any, next: any) => next(),
}));

import prisma from '../../src/config/database.js';
import vehiclesRoutes from '../../src/modules/vehicles/vehicles.routes.js';

describe('Vehicles API Integration Tests', () => {
  let app: Express;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/vehicles', vehiclesRoutes);
  });

  afterAll(() => {
    vi.clearAllMocks();
  });

  describe('GET /api/vehicles', () => {
    it('should return list of vehicles', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        {
          id: 'vehicle-1',
          plate: 'ABCD-12',
          brand: 'Toyota',
          model: 'Hilux',
          year: 2022,
          is_active: true,
        },
        {
          id: 'vehicle-2',
          plate: 'EFGH-34',
          brand: 'Nissan',
          model: 'Frontier',
          year: 2021,
          is_active: true,
        },
      ]);

      const response = await request(app)
        .get('/api/vehicles')
        .expect(200);

      expect(response.body).toHaveLength(2);
      expect(response.body[0].plate).toBe('ABCD-12');
      expect(response.body[1].plate).toBe('EFGH-34');
    });
  });

  describe('GET /api/vehicles/plate/:plate', () => {
    it('should find vehicle by plate', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{
        id: 'vehicle-1',
        plate: 'ABCD-12',
        brand: 'Toyota',
        model: 'Hilux',
        owner_first_name: 'Juan',
        owner_last_name: 'Pérez',
      }]);

      const response = await request(app)
        .get('/api/vehicles/plate/abcd-12')
        .expect(200);

      expect(response.body.plate).toBe('ABCD-12');
      expect(response.body.brand).toBe('Toyota');
    });

    it('should return 404 if vehicle not found', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      await request(app)
        .get('/api/vehicles/plate/XXXX-99')
        .expect(404);
    });
  });

  describe('POST /api/vehicles/logs/start', () => {
    it('should start vehicle usage', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Vehicle exists
      mockQueries.mockResolvedValueOnce([{ id: 'vehicle-1', plate: 'ABCD-12' }]);

      // No active log
      mockQueries.mockResolvedValueOnce([]);

      // Create log
      mockQueries.mockResolvedValueOnce([{
        id: 'log-1',
        vehicle_id: 'vehicle-1',
        driver_id: 'test-inspector-id',
        driver_name: 'Inspector Test',
        usage_type: 'official',
        start_km: 50000,
        status: 'active',
      }]);

      const response = await request(app)
        .post('/api/vehicles/logs/start')
        .send({
          vehicleId: 'vehicle-1',
          driverId: 'test-inspector-id',
          driverName: 'Inspector Test',
          usageType: 'official',
          startKm: 50000,
        })
        .expect(201);

      expect(response.body.status).toBe('active');
      expect(response.body.start_km).toBe(50000);
    });

    it('should return 400 if vehicle already in use', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Vehicle exists
      mockQueries.mockResolvedValueOnce([{ id: 'vehicle-1', plate: 'ABCD-12' }]);

      // Active log exists
      mockQueries.mockResolvedValueOnce([{ id: 'active-log-1' }]);

      const response = await request(app)
        .post('/api/vehicles/logs/start')
        .send({
          vehicleId: 'vehicle-1',
          driverId: 'test-inspector-id',
          driverName: 'Inspector Test',
          usageType: 'official',
          startKm: 50000,
        })
        .expect(400);

      expect(response.body.error).toContain('ya tiene un uso activo');
    });
  });

  describe('PATCH /api/vehicles/logs/:logId/end', () => {
    it('should end vehicle usage', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Log exists and is active
      mockQueries.mockResolvedValueOnce([{
        id: 'log-1',
        status: 'active',
        start_km: 50000,
      }]);

      // Update log
      mockQueries.mockResolvedValueOnce([{
        id: 'log-1',
        status: 'completed',
        start_km: 50000,
        end_km: 50150,
        total_distance_km: 150,
      }]);

      const response = await request(app)
        .patch('/api/vehicles/logs/log-1/end')
        .send({
          endKm: 50150,
          observations: 'Viaje completado sin novedad',
        })
        .expect(200);

      expect(response.body.status).toBe('completed');
      expect(response.body.total_distance_km).toBe(150);
    });

    it('should return 400 if end km is less than start km', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{
        id: 'log-1',
        status: 'active',
        start_km: 50000,
      }]);

      const response = await request(app)
        .patch('/api/vehicles/logs/log-1/end')
        .send({
          endKm: 49000, // Less than start
        })
        .expect(400);

      expect(response.body.error).toContain('kilometraje final no puede ser menor');
    });
  });

  describe('GET /api/vehicles/logs/active', () => {
    it('should return active vehicle usage logs', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        {
          id: 'log-1',
          vehicle_id: 'vehicle-1',
          plate: 'ABCD-12',
          driver_name: 'Juan Pérez',
          status: 'active',
          start_time: '2025-01-15T10:00:00Z',
        },
        {
          id: 'log-2',
          vehicle_id: 'vehicle-2',
          plate: 'EFGH-34',
          driver_name: 'María González',
          status: 'active',
          start_time: '2025-01-15T11:00:00Z',
        },
      ]);

      const response = await request(app)
        .get('/api/vehicles/logs/active')
        .expect(200);

      expect(response.body).toHaveLength(2);
      expect(response.body[0].status).toBe('active');
      expect(response.body[1].status).toBe('active');
    });
  });

  describe('GET /api/vehicles/logs', () => {
    it('should return filtered logs by date range', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        {
          id: 'log-1',
          vehicle_plate: 'ABCD-12',
          driver_name: 'Juan Pérez',
          status: 'completed',
          start_time: '2025-01-10T10:00:00Z',
          end_time: '2025-01-10T12:00:00Z',
          total_distance_km: 50,
        },
      ]);

      const response = await request(app)
        .get('/api/vehicles/logs')
        .query({
          startDate: '2025-01-01',
          endDate: '2025-01-31',
        })
        .expect(200);

      expect(response.body).toHaveLength(1);
      expect(response.body[0].total_distance_km).toBe(50);
    });
  });
});
