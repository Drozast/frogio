import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock prisma
vi.mock('../../src/config/database.js', () => ({
  default: {
    $queryRawUnsafe: vi.fn(),
  },
}));

import prisma from '../../src/config/database.js';
import { DashboardService } from '../../src/modules/dashboard/dashboard.service.js';

describe('DashboardService', () => {
  let dashboardService: DashboardService;

  beforeEach(() => {
    dashboardService = new DashboardService();
    vi.clearAllMocks();
  });

  describe('getStats', () => {
    it('should return statistics for admin role', async () => {
      // Mock all the database queries
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Setup mock responses in order of calls
      mockQueries
        .mockResolvedValueOnce([{ count: '100' }]) // usersCount
        .mockResolvedValueOnce([{ count: '50' }])  // infractionsCount
        .mockResolvedValueOnce([{ count: '75' }])  // reportsCount
        .mockResolvedValueOnce([{ count: '10' }])  // vehiclesCount
        .mockResolvedValueOnce([                    // infractionsByStatus
          { status: 'pending', count: '20' },
          { status: 'confirmed', count: '30' },
        ])
        .mockResolvedValueOnce([                    // reportsByStatus
          { status: 'pending', count: '25' },
          { status: 'in_progress', count: '20' },
          { status: 'resolved', count: '30' },
        ])
        .mockResolvedValueOnce([{ count: '10' }])  // recentInfractions
        .mockResolvedValueOnce([{ count: '15' }])  // recentReports
        .mockResolvedValueOnce([                    // infractionsByType
          { type: 'estacionamiento', count: '15' },
          { type: 'velocidad', count: '10' },
        ])
        .mockResolvedValueOnce([                    // dailyActivity
          { date: '2025-01-01', count: '5' },
          { date: '2025-01-02', count: '8' },
        ])
        .mockResolvedValueOnce([{ count: '2' }])   // activeLogsCount
        .mockResolvedValueOnce([{ count: '5' }])   // completedLogsToday
        .mockResolvedValueOnce([{ total: '150.5' }]) // totalDistanceToday
        .mockResolvedValueOnce([])                  // recentLogs
        .mockResolvedValueOnce([{ count: '8' }])   // inspectorsCount
        .mockResolvedValueOnce([{ count: '90' }])  // citizensCount
        .mockResolvedValueOnce([])                  // topInspectors
        .mockResolvedValueOnce([]);                 // topDrivers

      const stats = await dashboardService.getStats('santa_juana', 'admin');

      expect(stats.summary).toBeDefined();
      expect(stats.summary.totalUsers).toBe(100);
      expect(stats.summary.totalInfractions).toBe(50);
      expect(stats.summary.totalReports).toBe(75);
      expect(stats.summary.totalVehicles).toBe(10);
      expect(stats.recentActivity).toBeDefined();
      expect(stats.recentActivity.infractionsLast7Days).toBe(10);
      expect(stats.recentActivity.reportsLast7Days).toBe(15);
      expect(stats.bitacora).toBeDefined();
      expect(stats.bitacora.activeTrips).toBe(2);
      expect(stats.bitacora.totalKmToday).toBeCloseTo(150.5);
      // Admin-only stats
      expect(stats.inspectorsCount).toBe(8);
      expect(stats.citizensCount).toBe(90);
    });

    it('should not return admin-only stats for inspector role', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Setup mock responses (fewer calls for non-admin)
      mockQueries
        .mockResolvedValueOnce([{ count: '100' }])
        .mockResolvedValueOnce([{ count: '50' }])
        .mockResolvedValueOnce([{ count: '75' }])
        .mockResolvedValueOnce([{ count: '10' }])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ count: '10' }])
        .mockResolvedValueOnce([{ count: '15' }])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ count: '0' }])
        .mockResolvedValueOnce([{ count: '0' }])
        .mockResolvedValueOnce([{ total: '0' }])
        .mockResolvedValueOnce([]);

      const stats = await dashboardService.getStats('santa_juana', 'inspector');

      expect(stats.summary).toBeDefined();
      expect(stats.inspectorsCount).toBeUndefined();
      expect(stats.citizensCount).toBeUndefined();
      expect(stats.topInspectors).toBeUndefined();
    });

    it('should handle empty database gracefully', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Setup mock responses with empty/null values
      mockQueries
        .mockResolvedValueOnce([{ count: '0' }])
        .mockResolvedValueOnce([{ count: '0' }])
        .mockResolvedValueOnce([{ count: '0' }])
        .mockResolvedValueOnce([{ count: '0' }])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ count: '0' }])
        .mockResolvedValueOnce([{ count: '0' }])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ count: '0' }])
        .mockResolvedValueOnce([{ count: '0' }])
        .mockResolvedValueOnce([{ total: null }])
        .mockResolvedValueOnce([]);

      const stats = await dashboardService.getStats('santa_juana', 'citizen');

      expect(stats.summary.totalUsers).toBe(0);
      expect(stats.summary.totalInfractions).toBe(0);
      expect(stats.summary.totalReports).toBe(0);
      expect(stats.bitacora.totalKmToday).toBe(0);
    });
  });
});
