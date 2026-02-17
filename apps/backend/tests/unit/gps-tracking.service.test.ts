import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('../../src/config/database.js', () => ({
  default: { $queryRawUnsafe: vi.fn() },
}));

import prisma from '../../src/config/database.js';
import { GpsTrackingService } from '../../src/modules/gps-tracking/gps-tracking.service.js';

describe('GpsTrackingService', () => {
  let gpsService: GpsTrackingService;
  const tenantId = 'santa_juana';

  beforeEach(() => {
    gpsService = new GpsTrackingService();
    vi.clearAllMocks();
  });

  describe('insertBatch', () => {
    it('should insert GPS points successfully', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Insert returns ids
      mockQueries.mockResolvedValueOnce([
        { id: 'point-1' },
        { id: 'point-2' },
        { id: 'point-3' },
      ]);

      // Update log stats
      mockQueries.mockResolvedValueOnce([]);

      const result = await gpsService.insertBatch(tenantId, 'inspector-123', {
        vehicleId: 'vehicle-123',
        vehicleLogId: 'log-123',
        points: [
          { latitude: -37.1234, longitude: -72.5678, recordedAt: '2025-01-15T10:00:00Z' },
          { latitude: -37.1235, longitude: -72.5679, recordedAt: '2025-01-15T10:01:00Z' },
          { latitude: -37.1236, longitude: -72.5680, recordedAt: '2025-01-15T10:02:00Z' },
        ],
      });

      expect(result.inserted).toBe(3);
      expect(result.vehicleLogId).toBe('log-123');
    });

    it('should return 0 for empty points array', async () => {
      const result = await gpsService.insertBatch(tenantId, 'inspector-123', {
        vehicleId: 'vehicle-123',
        vehicleLogId: 'log-123',
        points: [],
      });

      expect(result.inserted).toBe(0);
      expect(prisma.$queryRawUnsafe).not.toHaveBeenCalled();
    });

    it('should include optional point data', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{ id: 'point-1' }]);
      mockQueries.mockResolvedValueOnce([]);

      const result = await gpsService.insertBatch(tenantId, 'inspector-123', {
        vehicleId: 'vehicle-123',
        vehicleLogId: 'log-123',
        points: [
          {
            latitude: -37.1234,
            longitude: -72.5678,
            altitude: 150.5,
            speed: 45.0,
            heading: 180.0,
            accuracy: 5.0,
            recordedAt: '2025-01-15T10:00:00Z',
          },
        ],
      });

      expect(result.inserted).toBe(1);
    });
  });

  describe('getLivePositions', () => {
    it('should return live vehicle positions', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        {
          vehicleId: 'vehicle-1',
          vehiclePlate: 'ABCD-12',
          vehicleBrand: 'Toyota',
          vehicleModel: 'Hilux',
          inspectorId: 'inspector-1',
          inspectorName: 'Juan Pérez',
          latitude: -37.1234,
          longitude: -72.5678,
          speed: 45.0,
          heading: 180.0,
          lastUpdate: new Date(),
          vehicleLogId: 'log-1',
          startTime: new Date(),
          status: 'moving',
        },
        {
          vehicleId: 'vehicle-2',
          vehiclePlate: 'EFGH-34',
          vehicleBrand: 'Nissan',
          vehicleModel: 'Navara',
          inspectorId: 'inspector-2',
          inspectorName: 'María López',
          latitude: -37.2000,
          longitude: -72.6000,
          speed: 0,
          heading: 90.0,
          lastUpdate: new Date(),
          vehicleLogId: 'log-2',
          startTime: new Date(),
          status: 'stopped',
        },
      ]);

      const result = await gpsService.getLivePositions(tenantId);

      expect(result).toHaveLength(2);
      expect(result[0].vehiclePlate).toBe('ABCD-12');
      expect(result[0].status).toBe('moving');
      expect(result[1].status).toBe('stopped');
    });

    it('should filter out positions without coordinates', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        {
          vehicleId: 'vehicle-1',
          latitude: -37.1234,
          longitude: -72.5678,
        },
        {
          vehicleId: 'vehicle-2',
          latitude: null,
          longitude: null,
        },
      ]);

      const result = await gpsService.getLivePositions(tenantId);

      expect(result).toHaveLength(1);
      expect(result[0].vehicleId).toBe('vehicle-1');
    });
  });

  describe('getVehiclePosition', () => {
    it('should return position for specific vehicle', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        {
          vehicleId: 'vehicle-1',
          vehiclePlate: 'ABCD-12',
          latitude: -37.1234,
          longitude: -72.5678,
        },
        {
          vehicleId: 'vehicle-2',
          vehiclePlate: 'EFGH-34',
          latitude: -37.2000,
          longitude: -72.6000,
        },
      ]);

      const result = await gpsService.getVehiclePosition(tenantId, 'vehicle-1');

      expect(result).not.toBeNull();
      expect(result!.vehicleId).toBe('vehicle-1');
    });

    it('should return null if vehicle not found', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        {
          vehicleId: 'vehicle-1',
          latitude: -37.1234,
          longitude: -72.5678,
        },
      ]);

      const result = await gpsService.getVehiclePosition(tenantId, 'nonexistent');

      expect(result).toBeNull();
    });
  });

  describe('getRouteHistory', () => {
    it('should return route history with points', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Log info
      mockQueries.mockResolvedValueOnce([{
        vehicleLogId: 'log-123',
        vehicleId: 'vehicle-123',
        vehiclePlate: 'ABCD-12',
        inspectorId: 'inspector-123',
        inspectorName: 'Juan Pérez',
        startTime: new Date('2025-01-15T08:00:00Z'),
        endTime: new Date('2025-01-15T12:00:00Z'),
        totalKm: 45.5,
        avgSpeed: 35.0,
        maxSpeed: 80.0,
      }]);

      // GPS points
      mockQueries.mockResolvedValueOnce([
        { latitude: -37.1234, longitude: -72.5678, speed: 40, recordedAt: new Date('2025-01-15T08:00:00Z') },
        { latitude: -37.1235, longitude: -72.5679, speed: 50, recordedAt: new Date('2025-01-15T08:30:00Z') },
        { latitude: -37.1236, longitude: -72.5680, speed: 35, recordedAt: new Date('2025-01-15T09:00:00Z') },
      ]);

      const result = await gpsService.getRouteHistory(tenantId, 'log-123');

      expect(result).not.toBeNull();
      expect(result!.vehiclePlate).toBe('ABCD-12');
      expect(result!.totalKm).toBe(45.5);
      expect(result!.points).toHaveLength(3);
    });

    it('should return null if log not found', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      const result = await gpsService.getRouteHistory(tenantId, 'nonexistent');

      expect(result).toBeNull();
    });
  });

  describe('getRoutesByDateRange', () => {
    it('should return routes within date range', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Logs query
      mockQueries.mockResolvedValueOnce([
        { vehicleLogId: 'log-1', vehicleId: 'vehicle-1', startTime: new Date('2025-01-15T08:00:00Z') },
        { vehicleLogId: 'log-2', vehicleId: 'vehicle-1', startTime: new Date('2025-01-16T08:00:00Z') },
      ]);

      // First route details
      mockQueries.mockResolvedValueOnce([{
        vehicleLogId: 'log-1',
        vehicleId: 'vehicle-1',
        vehiclePlate: 'ABCD-12',
        inspectorId: 'inspector-1',
        inspectorName: 'Juan',
        startTime: new Date('2025-01-15T08:00:00Z'),
        totalKm: 30.0,
      }]);
      mockQueries.mockResolvedValueOnce([
        { latitude: -37.1234, longitude: -72.5678, speed: 40, recordedAt: new Date('2025-01-15T08:00:00Z') },
      ]);

      // Second route details
      mockQueries.mockResolvedValueOnce([{
        vehicleLogId: 'log-2',
        vehicleId: 'vehicle-1',
        vehiclePlate: 'ABCD-12',
        inspectorId: 'inspector-1',
        inspectorName: 'Juan',
        startTime: new Date('2025-01-16T08:00:00Z'),
        totalKm: 25.0,
      }]);
      mockQueries.mockResolvedValueOnce([
        { latitude: -37.2000, longitude: -72.6000, speed: 35, recordedAt: new Date('2025-01-16T08:00:00Z') },
      ]);

      const result = await gpsService.getRoutesByDateRange(tenantId, {
        vehicleId: 'vehicle-1',
        startDate: '2025-01-01',
        endDate: '2025-01-31',
      });

      expect(result).toHaveLength(2);
    });
  });

  describe('getStats', () => {
    it('should return GPS statistics', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Overall stats
      mockQueries.mockResolvedValueOnce([{
        totalKm: 500.5,
        totalTrips: '25',
        avgSpeed: 42.3,
        maxSpeed: 95.0,
        totalDuration: 1500,
      }]);

      // By vehicle
      mockQueries.mockResolvedValueOnce([
        { vehicleId: 'v1', vehiclePlate: 'ABCD-12', totalKm: 300.0, totalTrips: '15' },
        { vehicleId: 'v2', vehiclePlate: 'EFGH-34', totalKm: 200.5, totalTrips: '10' },
      ]);

      // By inspector
      mockQueries.mockResolvedValueOnce([
        { inspectorId: 'i1', inspectorName: 'Juan Pérez', totalKm: 350.0, totalTrips: '18' },
        { inspectorId: 'i2', inspectorName: 'María López', totalKm: 150.5, totalTrips: '7' },
      ]);

      const result = await gpsService.getStats(tenantId);

      expect(result.totalKm).toBe(500.5);
      expect(result.totalTrips).toBe(25);
      expect(result.avgSpeed).toBe(42.3);
      expect(result.byVehicle).toHaveLength(2);
      expect(result.byInspector).toHaveLength(2);
    });

    it('should filter stats by date range', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{
        totalKm: 100.0,
        totalTrips: '5',
        avgSpeed: 40.0,
        maxSpeed: 80.0,
        totalDuration: 300,
      }]);
      mockQueries.mockResolvedValueOnce([]);
      mockQueries.mockResolvedValueOnce([]);

      const result = await gpsService.getStats(tenantId, '2025-01-01', '2025-01-31');

      expect(result.totalKm).toBe(100.0);
      expect(mockQueries).toHaveBeenCalledWith(
        expect.stringContaining('start_time >= $1'),
        '2025-01-01',
        '2025-01-31'
      );
    });
  });

  describe('getActivityDays', () => {
    it('should return days with activity for a vehicle', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { activity_date: new Date('2025-01-15'), trips: '2', total_km: 45.5 },
        { activity_date: new Date('2025-01-17'), trips: '1', total_km: 23.2 },
        { activity_date: new Date('2025-01-20'), trips: '3', total_km: 67.8 },
      ]);

      const result = await gpsService.getActivityDays(tenantId, 'vehicle-123', 2025, 1);

      expect(result.dates).toHaveLength(3);
      expect(result.dates).toContain('2025-01-15');
      expect(result.dates).toContain('2025-01-17');
      expect(result.dates).toContain('2025-01-20');
      expect(result.activityByDate['2025-01-15']).toEqual({ trips: 2, totalKm: 45.5 });
      expect(result.activityByDate['2025-01-17']).toEqual({ trips: 1, totalKm: 23.2 });
      expect(result.activityByDate['2025-01-20']).toEqual({ trips: 3, totalKm: 67.8 });
    });

    it('should return empty arrays if no activity', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      const result = await gpsService.getActivityDays(tenantId, 'vehicle-123', 2025, 2);

      expect(result.dates).toHaveLength(0);
      expect(Object.keys(result.activityByDate)).toHaveLength(0);
    });

    it('should query the correct month range', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      await gpsService.getActivityDays(tenantId, 'vehicle-123', 2025, 2);

      expect(mockQueries).toHaveBeenCalledWith(
        expect.stringContaining('vehicle_logs'),
        'vehicle-123',
        expect.any(String), // Start date ISO string
        expect.any(String)  // End date ISO string
      );

      // Verify the query includes the correct table and fields
      const calledQuery = mockQueries.mock.calls[0][0] as string;
      expect(calledQuery).toContain('vehicle_logs');
      expect(calledQuery).toContain('start_time');
    });
  });

  describe('cleanupOldPoints', () => {
    it('should delete old GPS points', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'point-1' },
        { id: 'point-2' },
        { id: 'point-3' },
      ]);

      const result = await gpsService.cleanupOldPoints(tenantId, 90);

      expect(result).toBe(3);
      expect(mockQueries).toHaveBeenCalledWith(
        expect.stringContaining('DELETE FROM'),
        90
      );
    });

    it('should use default 90 days if not specified', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      await gpsService.cleanupOldPoints(tenantId);

      expect(mockQueries).toHaveBeenCalledWith(
        expect.any(String),
        90
      );
    });

    it('should handle minimum 1 day', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      await gpsService.cleanupOldPoints(tenantId, -5);

      expect(mockQueries).toHaveBeenCalledWith(
        expect.any(String),
        1
      );
    });
  });
});
