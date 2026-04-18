import { Response } from 'express';
import { AdminImportsService } from './admin-imports.service.js';
import type { AuthRequest } from '../../middleware/auth.middleware.js';

const adminImportsService = new AdminImportsService();

function parseRows(req: AuthRequest, res: Response): Record<string, unknown>[] | null {
  const { rows } = req.body ?? {};
  if (!Array.isArray(rows)) {
    res.status(400).json({ error: 'Cuerpo inválido: se esperaba { rows: [...] }' });
    return null;
  }
  if (rows.length === 0) {
    res.status(400).json({ error: 'rows no puede estar vacío' });
    return null;
  }
  return rows as Record<string, unknown>[];
}

export class AdminImportsController {
  async importCitations(req: AuthRequest, res: Response): Promise<void> {
    try {
      const rows = parseRows(req, res);
      if (!rows) return;

      const tenantId = req.user!.tenantId;
      const adminUserId = req.user!.userId;

      const result = await adminImportsService.importCitations(rows, tenantId, adminUserId);
      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al importar citaciones';
      res.status(500).json({ error: message });
    }
  }

  async importReports(req: AuthRequest, res: Response): Promise<void> {
    try {
      const rows = parseRows(req, res);
      if (!rows) return;

      const tenantId = req.user!.tenantId;
      const adminUserId = req.user!.userId;

      const result = await adminImportsService.importReports(rows, tenantId, adminUserId);
      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al importar reportes';
      res.status(500).json({ error: message });
    }
  }

  async importVehicles(req: AuthRequest, res: Response): Promise<void> {
    try {
      const rows = parseRows(req, res);
      if (!rows) return;

      const tenantId = req.user!.tenantId;
      const adminUserId = req.user!.userId;

      const result = await adminImportsService.importVehicles(rows, tenantId, adminUserId);
      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al importar vehículos';
      res.status(500).json({ error: message });
    }
  }

  async importUsers(req: AuthRequest, res: Response): Promise<void> {
    try {
      const rows = parseRows(req, res);
      if (!rows) return;

      const tenantId = req.user!.tenantId;

      const result = await adminImportsService.importUsers(rows, tenantId);
      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al importar usuarios';
      res.status(500).json({ error: message });
    }
  }
}
