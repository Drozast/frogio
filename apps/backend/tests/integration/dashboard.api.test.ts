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
      id: 'test-user-id',
      email: 'admin@test.cl',
      role: 'admin',
      tenantId: 'santa_juana',
    };
    next();
  },
  roleGuard: (..._roles: string[]) => (_req: any, _res: any, next: any) => next(),
}));

import prisma from '../../src/config/database.js';
import dashboardRoutes from '../../src/modules/dashboard/dashboard.routes.js';

describe('Dashboard API Integration Tests', () => {
  let app: Express;

  beforeAll(() => {
    app = express();
    app.use(express.json());
    app.use('/api/dashboard', dashboardRoutes);
  });

  afterAll(() => {
    vi.clearAllMocks();
  });

  describe('GET /api/dashboard/stats', () => {
    it('should return dashboard statistics for admin', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Setup comprehensive mock responses
      mockQueries
        .mockResolvedValueOnce([{ count: '500' }])    // users
        .mockResolvedValueOnce([{ count: '100' }])    // infractions
        .mockResolvedValueOnce([{ count: '200' }])    // reports
        .mockResolvedValueOnce([{ count: '15' }])     // vehicles
        .mockResolvedValueOnce([                       // infractions by status
          { status: 'pending', count: '30' },
          { status: 'confirmed', count: '70' },
        ])
        .mockResolvedValueOnce([                       // reports by status
          { status: 'pending', count: '50' },
          { status: 'in_progress', count: '75' },
          { status: 'resolved', count: '75' },
        ])
        .mockResolvedValueOnce([{ count: '20' }])     // recent infractions
        .mockResolvedValueOnce([{ count: '30' }])     // recent reports
        .mockResolvedValueOnce([                       // infractions by type
          { type: 'estacionamiento', count: '40' },
          { type: 'velocidad', count: '30' },
        ])
        .mockResolvedValueOnce([                       // daily activity
          { date: '2025-01-01', count: '5' },
        ])
        .mockResolvedValueOnce([{ count: '3' }])      // active logs
        .mockResolvedValueOnce([{ count: '10' }])     // completed today
        .mockResolvedValueOnce([{ total: '250.5' }])  // total km today
        .mockResolvedValueOnce([])                     // recent logs
        .mockResolvedValueOnce([{ count: '12' }])     // inspectors
        .mockResolvedValueOnce([{ count: '480' }])    // citizens
        .mockResolvedValueOnce([])                     // top inspectors
        .mockResolvedValueOnce([]);                    // top drivers

      const response = await request(app)
        .get('/api/dashboard/stats')
        .expect(200);

      expect(response.body).toHaveProperty('summary');
      expect(response.body.summary.totalUsers).toBe(500);
      expect(response.body.summary.totalInfractions).toBe(100);
      expect(response.body.summary.totalReports).toBe(200);
      expect(response.body.summary.totalVehicles).toBe(15);
      expect(response.body).toHaveProperty('recentActivity');
      expect(response.body).toHaveProperty('bitacora');
      expect(response.body.bitacora.activeTrips).toBe(3);
      expect(response.body.bitacora.totalKmToday).toBeCloseTo(250.5);
      // Admin-only data
      expect(response.body.inspectorsCount).toBe(12);
      expect(response.body.citizensCount).toBe(480);
    });

    it('should return status breakdown correctly', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries
        .mockResolvedValueOnce([{ count: '100' }])
        .mockResolvedValueOnce([{ count: '50' }])
        .mockResolvedValueOnce([{ count: '75' }])
        .mockResolvedValueOnce([{ count: '10' }])
        .mockResolvedValueOnce([
          { status: 'pending', count: '10' },
          { status: 'confirmed', count: '30' },
          { status: 'cancelled', count: '10' },
        ])
        .mockResolvedValueOnce([
          { status: 'pending', count: '20' },
          { status: 'in_progress', count: '25' },
          { status: 'resolved', count: '30' },
        ])
        .mockResolvedValueOnce([{ count: '5' }])
        .mockResolvedValueOnce([{ count: '10' }])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ count: '0' }])
        .mockResolvedValueOnce([{ count: '0' }])
        .mockResolvedValueOnce([{ total: '0' }])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ count: '5' }])
        .mockResolvedValueOnce([{ count: '90' }])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([]);

      const response = await request(app)
        .get('/api/dashboard/stats')
        .expect(200);

      expect(response.body.infractionsByStatus).toEqual({
        pending: 10,
        confirmed: 30,
        cancelled: 10,
      });
      expect(response.body.reportsByStatus).toEqual({
        pending: 20,
        in_progress: 25,
        resolved: 30,
      });
    });
  });
});
