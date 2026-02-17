import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('../../src/config/database.js', () => ({
  default: { $queryRawUnsafe: vi.fn() },
}));

vi.mock('../../src/services/alerts.service.js', () => ({
  alertsService: {
    onNewReport: vi.fn(),
    onReportStatusChange: vi.fn(),
  },
}));

import prisma from '../../src/config/database.js';
import { ReportsService } from '../../src/modules/reports/reports.service.js';

describe('ReportsService', () => {
  let reportsService: ReportsService;
  const tenantId = 'santa_juana';

  beforeEach(() => {
    reportsService = new ReportsService();
    vi.clearAllMocks();
  });

  describe('create', () => {
    it('should create a report successfully', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{
        id: 'report-123',
        user_id: 'user-123',
        type: 'infraestructura',
        title: 'Bache en calle',
        description: 'Hay un bache grande',
        status: 'pendiente',
        priority: 'media',
        created_at: new Date(),
      }]);

      const result = await reportsService.create({
        type: 'infraestructura',
        title: 'Bache en calle',
        description: 'Hay un bache grande',
      }, 'user-123', tenantId);

      expect(result.status).toBe('pendiente');
      expect(result.title).toBe('Bache en calle');
    });
  });

  describe('findAll', () => {
    it('should return all reports', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'r1', title: 'Report 1', status: 'pendiente' },
        { id: 'r2', title: 'Report 2', status: 'resuelto' },
      ]);

      const result = await reportsService.findAll(tenantId);

      expect(result).toHaveLength(2);
    });

    it('should filter by status', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'r1', title: 'Report 1', status: 'pendiente' },
      ]);

      const result = await reportsService.findAll(tenantId, { status: 'pendiente' });

      expect(result).toHaveLength(1);
      expect(mockQueries).toHaveBeenCalledWith(
        expect.stringContaining('status = $'),
        'pendiente'
      );
    });

    it('should filter by userId', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'r1', title: 'My Report', user_id: 'user-123' },
      ]);

      const result = await reportsService.findAll(tenantId, { userId: 'user-123' });

      expect(result).toHaveLength(1);
    });
  });

  describe('findById', () => {
    it('should return report with details', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries
        .mockResolvedValueOnce([{
          id: 'report-123',
          title: 'Test Report',
          status: 'pendiente',
          user_id: 'user-123',
          first_name: 'Juan',
          last_name: 'Pérez',
          created_at: new Date(),
          updated_at: new Date(),
        }])
        .mockResolvedValueOnce([]); // versions

      const result = await reportsService.findById('report-123', tenantId);

      expect(result.title).toBe('Test Report');
      expect(result.statusHistory).toBeDefined();
    });

    it('should throw error if not found', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);
      mockQueries.mockResolvedValueOnce([]);

      await expect(
        reportsService.findById('nonexistent', tenantId)
      ).rejects.toThrow('Reporte no encontrado');
    });
  });

  describe('update', () => {
    it('should update status to resuelto', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // findById calls
      mockQueries
        .mockResolvedValueOnce([{
          id: 'report-123',
          status: 'pendiente',
          user_id: 'user-123',
          created_at: new Date(),
          updated_at: new Date(),
        }])
        .mockResolvedValueOnce([]) // versions
        .mockResolvedValueOnce([{ // update
          id: 'report-123',
          status: 'resuelto',
          resolution: 'Trabajo completado',
        }])
        .mockResolvedValueOnce([{ next_version: '1' }]) // version count
        .mockResolvedValueOnce([{ // get updated report for version
          id: 'report-123',
          status: 'resuelto',
        }])
        .mockResolvedValueOnce([]); // insert version

      const result = await reportsService.update('report-123', {
        status: 'resolved',
        resolution: 'Trabajo completado',
      }, 'inspector-123', tenantId);

      expect(result.status).toBe('resuelto');
    });

    it('should normalize English status to Spanish', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries
        .mockResolvedValueOnce([{
          id: 'report-123',
          status: 'pendiente',
          user_id: 'user-123',
          created_at: new Date(),
          updated_at: new Date(),
        }])
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([{ id: 'report-123', status: 'en_proceso' }])
        .mockResolvedValueOnce([{ next_version: '1' }])
        .mockResolvedValueOnce([{ id: 'report-123', status: 'en_proceso' }])
        .mockResolvedValueOnce([]);

      const result = await reportsService.update('report-123', {
        status: 'in_progress',
      }, 'inspector-123', tenantId);

      expect(result.status).toBe('en_proceso');
    });

    it('should throw error when no data to update', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries
        .mockResolvedValueOnce([{
          id: 'report-123',
          status: 'pendiente',
          created_at: new Date(),
          updated_at: new Date(),
        }])
        .mockResolvedValueOnce([]);

      await expect(
        reportsService.update('report-123', {}, 'inspector-123', tenantId)
      ).rejects.toThrow('No hay datos para actualizar');
    });
  });

  describe('delete', () => {
    it('should delete report', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);
      mockQueries.mockResolvedValueOnce([{ id: 'report-123' }]);

      const result = await reportsService.delete('report-123', tenantId);

      expect(result.message).toBe('Reporte eliminado exitosamente');
    });

    it('should throw error if not found', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);
      mockQueries.mockResolvedValueOnce([]);

      await expect(
        reportsService.delete('nonexistent', tenantId)
      ).rejects.toThrow('Reporte no encontrado');
    });
  });

  describe('getVersionHistory', () => {
    it('should return version history with creation', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries
        .mockResolvedValueOnce([{
          id: 'report-123',
          title: 'Test',
          type: 'infraestructura',
          priority: 'media',
          user_id: 'user-123',
          creator_first_name: 'Juan',
          creator_last_name: 'Pérez',
          created_at: new Date(),
        }])
        .mockResolvedValueOnce([
          {
            version_number: 1,
            status: 'en_proceso',
            modified_at: new Date(),
            modifier_first_name: 'Inspector',
            modifier_last_name: 'Test',
          },
        ]);

      const result = await reportsService.getVersionHistory('report-123', tenantId);

      expect(result).toHaveLength(2);
      expect(result[1].is_creation).toBe(true);
      expect(result[0].version_number).toBe(1);
    });
  });
});
