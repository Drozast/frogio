import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('../../src/config/database.js', () => ({
  default: { $queryRawUnsafe: vi.fn() },
}));

import prisma from '../../src/config/database.js';
import { CitationsService } from '../../src/modules/citations/citations.service.js';

describe('CitationsService', () => {
  let citationsService: CitationsService;
  const tenantId = 'santa_juana';

  beforeEach(() => {
    citationsService = new CitationsService();
    vi.clearAllMocks();
  });

  describe('create', () => {
    it('should create a citation successfully', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{
        id: 'citation-123',
        citation_type: 'citacion',
        target_type: 'persona',
        target_name: 'Juan Pérez',
        target_rut: '12.345.678-9',
        citation_number: 'CIT-2025-001',
        reason: 'Infracción de tránsito',
        status: 'pendiente',
        issued_by: 'inspector-123',
      }]);

      const result = await citationsService.create({
        citationType: 'citacion',
        targetType: 'persona',
        targetName: 'Juan Pérez',
        targetRut: '12.345.678-9',
        citationNumber: 'CIT-2025-001',
        reason: 'Infracción de tránsito',
      }, tenantId, 'inspector-123');

      expect(result.status).toBe('pendiente');
      expect(result.target_name).toBe('Juan Pérez');
    });
  });

  describe('findAll', () => {
    it('should return all citations', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'c1', citation_number: 'CIT-001', status: 'pendiente' },
        { id: 'c2', citation_number: 'CIT-002', status: 'notificado' },
      ]);

      const result = await citationsService.findAll(tenantId);

      expect(result).toHaveLength(2);
    });

    it('should filter by status', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'c1', citation_number: 'CIT-001', status: 'pendiente' },
      ]);

      const result = await citationsService.findAll(tenantId, { status: 'pendiente' });

      expect(result).toHaveLength(1);
      expect(mockQueries).toHaveBeenCalledWith(
        expect.stringContaining('status = $'),
        'pendiente'
      );
    });

    it('should filter by issuedBy', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'c1', issued_by: 'inspector-123' },
      ]);

      const result = await citationsService.findAll(tenantId, { issuedBy: 'inspector-123' });

      expect(result).toHaveLength(1);
    });

    it('should filter by search term', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'c1', target_name: 'Juan Pérez', target_rut: '12.345.678-9' },
      ]);

      const result = await citationsService.findAll(tenantId, { search: 'Juan' });

      expect(result).toHaveLength(1);
      expect(mockQueries).toHaveBeenCalledWith(
        expect.stringContaining('ILIKE'),
        '%Juan%'
      );
    });

    it('should filter by date range', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'c1', created_at: '2025-01-15' },
      ]);

      const result = await citationsService.findAll(tenantId, {
        fromDate: '2025-01-01',
        toDate: '2025-01-31',
      });

      expect(result).toHaveLength(1);
    });
  });

  describe('findById', () => {
    it('should return citation with details', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{
        id: 'citation-123',
        citation_number: 'CIT-001',
        target_name: 'Juan Pérez',
        status: 'pendiente',
        issuer_first_name: 'Inspector',
        issuer_last_name: 'Test',
      }]);

      const result = await citationsService.findById('citation-123', tenantId);

      expect(result.citation_number).toBe('CIT-001');
    });

    it('should throw error if not found', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);
      mockQueries.mockResolvedValueOnce([]);

      await expect(
        citationsService.findById('nonexistent', tenantId)
      ).rejects.toThrow('Citación no encontrada');
    });
  });

  describe('update', () => {
    it('should update status to notificado', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries
        .mockResolvedValueOnce([{
          id: 'citation-123',
          status: 'notificado',
          notification_method: 'personal',
        }])
        .mockResolvedValueOnce([{ next_version: '1' }])
        .mockResolvedValueOnce([{ id: 'citation-123', status: 'notificado' }])
        .mockResolvedValueOnce([]);

      const result = await citationsService.update('citation-123', {
        status: 'notificado',
        notificationMethod: 'personal',
      }, 'inspector-123', tenantId);

      expect(result.status).toBe('notificado');
    });

    it('should throw error when no data to update', async () => {
      await expect(
        citationsService.update('citation-123', {}, 'inspector-123', tenantId)
      ).rejects.toThrow('No hay datos para actualizar');
    });
  });

  describe('delete', () => {
    it('should delete citation', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);
      mockQueries.mockResolvedValueOnce([{ id: 'citation-123' }]);

      const result = await citationsService.delete('citation-123', tenantId);

      expect(result.message).toBe('Citación eliminada exitosamente');
    });

    it('should throw error if not found', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);
      mockQueries.mockResolvedValueOnce([]);

      await expect(
        citationsService.delete('nonexistent', tenantId)
      ).rejects.toThrow('Citación no encontrada');
    });
  });

  describe('getStats', () => {
    it('should return statistics', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries
        .mockResolvedValueOnce([{ count: '100' }])
        .mockResolvedValueOnce([
          { type: 'citacion', count: '80' },
          { type: 'notificacion', count: '20' },
        ])
        .mockResolvedValueOnce([
          { status: 'pendiente', count: '30' },
          { status: 'notificado', count: '70' },
        ])
        .mockResolvedValueOnce([
          { target_type: 'persona', count: '60' },
          { target_type: 'vehiculo', count: '40' },
        ]);

      const result = await citationsService.getStats(tenantId);

      expect(result.total).toBe(100);
      expect(result.byType).toHaveLength(2);
      expect(result.byStatus).toHaveLength(2);
      expect(result.byTargetType).toHaveLength(2);
    });
  });

  describe('getMyCitations', () => {
    it('should return citations issued by inspector', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'c1', issued_by: 'inspector-123' },
        { id: 'c2', issued_by: 'inspector-123' },
      ]);

      const result = await citationsService.getMyCitations(tenantId, 'inspector-123');

      expect(result).toHaveLength(2);
    });
  });

  describe('getUpcoming', () => {
    it('should return upcoming citations with hearing dates', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'c1', hearing_date: new Date('2025-02-01'), status: 'notificado' },
      ]);

      const result = await citationsService.getUpcoming(tenantId);

      expect(result).toHaveLength(1);
    });
  });

  describe('bulkImport', () => {
    it('should import multiple citations', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries
        .mockResolvedValueOnce([])
        .mockResolvedValueOnce([]);

      const result = await citationsService.bulkImport([
        { citationNumber: 'CIT-001', reason: 'Infracción 1' },
        { citationNumber: 'CIT-002', reason: 'Infracción 2' },
      ], tenantId, 'inspector-123');

      expect(result.imported).toBe(2);
      expect(result.errors).toHaveLength(0);
    });

    it('should report errors for invalid records', async () => {
      const result = await citationsService.bulkImport([
        { citationNumber: '', reason: '' }, // Invalid
        { citationNumber: 'CIT-001', reason: 'Valid' },
      ], tenantId, 'inspector-123');

      expect(result.errors.length).toBeGreaterThan(0);
    });
  });

  describe('getVersionHistory', () => {
    it('should return version history', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries
        .mockResolvedValueOnce([{
          id: 'citation-123',
          citation_type: 'citacion',
          target_type: 'persona',
          target_name: 'Juan',
          issued_by: 'inspector-123',
          issuer_first_name: 'Inspector',
          issuer_last_name: 'Test',
          created_at: new Date(),
        }])
        .mockResolvedValueOnce([
          {
            version_number: 1,
            status: 'notificado',
            modified_at: new Date(),
          },
        ]);

      const result = await citationsService.getVersionHistory('citation-123', tenantId);

      expect(result).toHaveLength(2);
      expect(result[1].is_creation).toBe(true);
    });
  });
});
