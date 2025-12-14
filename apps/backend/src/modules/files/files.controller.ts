import { Response } from 'express';
import { FilesService } from './files.service.js';
import type { AuthRequest } from '../../middleware/auth.middleware.js';

const filesService = new FilesService();

export class FilesController {
  async upload(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.file) {
        res.status(400).json({ error: 'No se proporcionó ningún archivo' });
        return;
      }

      const { entityType, entityId } = req.body;

      if (!entityType || !entityId) {
        res.status(400).json({ error: 'entityType y entityId son requeridos' });
        return;
      }

      const uploadedBy = req.user!.userId;
      const tenantId = req.user!.tenantId;

      const file = await filesService.uploadFile(
        req.file,
        entityType,
        entityId,
        uploadedBy,
        tenantId
      );

      res.status(201).json(file);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al subir archivo';
      res.status(400).json({ error: message });
    }
  }

  async getFileUrl(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const url = await filesService.getFileUrl(id, tenantId);

      res.json({ url });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener URL del archivo';
      res.status(400).json({ error: message });
    }
  }

  async getByEntity(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { entityType, entityId } = req.params;
      const tenantId = req.user!.tenantId;

      const files = await filesService.getFilesByEntity(entityType, entityId, tenantId);

      res.json(files);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener archivos';
      res.status(400).json({ error: message });
    }
  }

  async delete(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const result = await filesService.deleteFile(id, tenantId);

      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al eliminar archivo';
      res.status(400).json({ error: message });
    }
  }
}
