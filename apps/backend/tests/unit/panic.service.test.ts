import { describe, it, expect, vi, beforeEach } from 'vitest';

vi.mock('../../src/config/database.js', () => ({
  default: { $queryRawUnsafe: vi.fn() },
}));

vi.mock('../../src/config/env.js', () => ({
  env: {
    NTFY_URL: null, // Disable notifications in tests
  },
}));

vi.mock('../../src/modules/reports/reports.service.js', () => ({
  ReportsService: class {
    update = vi.fn().mockResolvedValue({});
  },
}));

import prisma from '../../src/config/database.js';
import { PanicService } from '../../src/modules/panic/panic.service.js';

describe('PanicService', () => {
  let panicService: PanicService;
  const tenantId = 'santa_juana';

  beforeEach(() => {
    panicService = new PanicService();
    vi.clearAllMocks();
  });

  describe('create', () => {
    it('should create a panic alert successfully', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Insert panic alert
      mockQueries.mockResolvedValueOnce([{
        id: 'alert-123',
        user_id: 'user-123',
        latitude: -37.1234,
        longitude: -72.5678,
        address: 'Av. Principal 123',
        message: 'Necesito ayuda',
        status: 'active',
        created_at: new Date(),
      }]);

      // Get user info
      mockQueries.mockResolvedValueOnce([{
        first_name: 'Juan',
        last_name: 'Pérez',
        phone: '+56912345678',
      }]);

      // Create notifications for inspectors
      mockQueries.mockResolvedValueOnce([]);

      // Create automatic report
      mockQueries.mockResolvedValueOnce([]);

      const result = await panicService.create({
        latitude: -37.1234,
        longitude: -72.5678,
        address: 'Av. Principal 123',
        message: 'Necesito ayuda',
      }, 'user-123', tenantId);

      expect(result.id).toBe('alert-123');
      expect(result.status).toBe('active');
    });

    it('should create alert with default message', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{
        id: 'alert-123',
        message: 'Alerta de emergencia',
        status: 'active',
      }]);
      mockQueries.mockResolvedValueOnce([{}]);
      mockQueries.mockResolvedValueOnce([]);
      mockQueries.mockResolvedValueOnce([]);

      const result = await panicService.create({
        latitude: -37.1234,
        longitude: -72.5678,
      }, 'user-123', tenantId);

      expect(result.message).toBe('Alerta de emergencia');
    });
  });

  describe('findAll', () => {
    it('should return all panic alerts', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'a1', status: 'active', first_name: 'Juan' },
        { id: 'a2', status: 'resolved', first_name: 'María' },
        { id: 'a3', status: 'cancelled', first_name: 'Pedro' },
      ]);

      const result = await panicService.findAll(tenantId);

      expect(result).toHaveLength(3);
    });

    it('should filter by status', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'a1', status: 'active' },
      ]);

      const result = await panicService.findAll(tenantId, { status: 'active' });

      expect(result).toHaveLength(1);
      expect(mockQueries).toHaveBeenCalledWith(
        expect.stringContaining('status = $'),
        'active'
      );
    });

    it('should filter by userId', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'a1', user_id: 'user-123' },
      ]);

      const result = await panicService.findAll(tenantId, { userId: 'user-123' });

      expect(result).toHaveLength(1);
    });
  });

  describe('findActive', () => {
    it('should return only active and responding alerts', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([
        { id: 'a1', status: 'active' },
        { id: 'a2', status: 'responding' },
      ]);

      const result = await panicService.findActive(tenantId);

      expect(result).toHaveLength(2);
      expect(mockQueries).toHaveBeenCalledWith(
        expect.stringContaining("status IN ('active', 'responding')")
      );
    });
  });

  describe('findById', () => {
    it('should return alert details', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{
        id: 'alert-123',
        user_id: 'user-123',
        first_name: 'Juan',
        last_name: 'Pérez',
        phone: '+56912345678',
        latitude: -37.1234,
        longitude: -72.5678,
        status: 'active',
      }]);

      const result = await panicService.findById('alert-123', tenantId);

      expect(result.id).toBe('alert-123');
      expect(result.first_name).toBe('Juan');
    });

    it('should throw error if alert not found', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      await expect(
        panicService.findById('nonexistent', tenantId)
      ).rejects.toThrow('Alerta no encontrada');
    });
  });

  describe('respond', () => {
    it('should mark alert as responding', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Update alert
      mockQueries.mockResolvedValueOnce([{
        id: 'alert-123',
        user_id: 'user-123',
        status: 'responding',
        responder_id: 'inspector-123',
        responded_at: new Date(),
      }]);

      // Find associated report (none found)
      mockQueries.mockResolvedValueOnce([]);

      // Create notification for user
      mockQueries.mockResolvedValueOnce([]);

      const result = await panicService.respond('alert-123', 'inspector-123', tenantId);

      expect(result.status).toBe('responding');
      expect(result.responder_id).toBe('inspector-123');
    });

    it('should throw error if alert not active', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      await expect(
        panicService.respond('alert-123', 'inspector-123', tenantId)
      ).rejects.toThrow('Alerta no encontrada o ya atendida');
    });
  });

  describe('resolve', () => {
    it('should resolve alert successfully', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Update alert
      mockQueries.mockResolvedValueOnce([{
        id: 'alert-123',
        user_id: 'user-123',
        status: 'resolved',
        notes: 'Situación controlada',
        resolved_at: new Date(),
      }]);

      // Find associated report
      mockQueries.mockResolvedValueOnce([]);

      // Notify user
      mockQueries.mockResolvedValueOnce([]);

      const result = await panicService.resolve('alert-123', 'Situación controlada', tenantId);

      expect(result.status).toBe('resolved');
      expect(result.notes).toBe('Situación controlada');
    });

    it('should throw error if alert already resolved', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      await expect(
        panicService.resolve('alert-123', 'Notas', tenantId)
      ).rejects.toThrow('Alerta no encontrada o ya resuelta');
    });
  });

  describe('cancel', () => {
    it('should cancel alert by user', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Update alert
      mockQueries.mockResolvedValueOnce([{
        id: 'alert-123',
        user_id: 'user-123',
        status: 'cancelled',
      }]);

      // Find associated report
      mockQueries.mockResolvedValueOnce([]);

      // Notify inspectors
      mockQueries.mockResolvedValueOnce([]);

      const result = await panicService.cancel('alert-123', 'user-123', tenantId);

      expect(result.status).toBe('cancelled');
    });

    it('should throw error if user is not owner', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      await expect(
        panicService.cancel('alert-123', 'wrong-user', tenantId)
      ).rejects.toThrow('No puedes cancelar esta alerta');
    });
  });

  describe('dismiss', () => {
    it('should dismiss alert with reason', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      // Update alert
      mockQueries.mockResolvedValueOnce([{
        id: 'alert-123',
        user_id: 'user-123',
        status: 'dismissed',
        notes: 'Falsa alarma',
      }]);

      // Find associated report
      mockQueries.mockResolvedValueOnce([]);

      // Notify user
      mockQueries.mockResolvedValueOnce([]);

      const result = await panicService.dismiss('alert-123', 'Falsa alarma', 'inspector-123', tenantId);

      expect(result.status).toBe('dismissed');
      expect(result.notes).toBe('Falsa alarma');
    });

    it('should throw error if alert not found', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([]);

      await expect(
        panicService.dismiss('nonexistent', 'Reason', 'inspector-123', tenantId)
      ).rejects.toThrow('Alerta no encontrada o ya resuelta');
    });
  });

  describe('getStats', () => {
    it('should return panic statistics', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{
        total: '50',
        active: '5',
        responding: '2',
        resolved: '35',
        cancelled: '5',
        dismissed: '3',
        last_24h: '3',
        last_7d: '12',
      }]);

      const result = await panicService.getStats(tenantId);

      expect(result.total).toBe(50);
      expect(result.active).toBe(5);
      expect(result.responding).toBe(2);
      expect(result.resolved).toBe(35);
      expect(result.cancelled).toBe(5);
      expect(result.dismissed).toBe(3);
      expect(result.last24h).toBe(3);
      expect(result.last7d).toBe(12);
    });

    it('should handle empty stats', async () => {
      const mockQueries = vi.mocked(prisma.$queryRawUnsafe);

      mockQueries.mockResolvedValueOnce([{}]);

      const result = await panicService.getStats(tenantId);

      expect(result.total).toBe(0);
      expect(result.active).toBe(0);
    });
  });
});
