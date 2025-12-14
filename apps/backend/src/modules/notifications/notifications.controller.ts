import { Response } from 'express';
import { NotificationsService } from '../../services/notifications.service.js';
import type { AuthRequest } from '../../middleware/auth.middleware.js';

const notificationsService = new NotificationsService();

export class NotificationsController {
  async getMyNotifications(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const tenantId = req.user!.tenantId;
      const limit = req.query.limit ? parseInt(req.query.limit as string) : 50;

      const notifications = await notificationsService.getUserNotifications(userId, tenantId, limit);

      res.json(notifications);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener notificaciones';
      res.status(400).json({ error: message });
    }
  }

  async getUnreadCount(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const tenantId = req.user!.tenantId;

      const count = await notificationsService.getUnreadCount(userId, tenantId);

      res.json({ count });
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al obtener contador';
      res.status(400).json({ error: message });
    }
  }

  async markAsRead(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const notification = await notificationsService.markAsRead(id, tenantId);

      res.json(notification);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al marcar como leída';
      res.status(400).json({ error: message });
    }
  }

  async markAllAsRead(req: AuthRequest, res: Response): Promise<void> {
    try {
      const userId = req.user!.userId;
      const tenantId = req.user!.tenantId;

      const result = await notificationsService.markAllAsRead(userId, tenantId);

      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al marcar todas como leídas';
      res.status(400).json({ error: message });
    }
  }

  async deleteNotification(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const tenantId = req.user!.tenantId;

      const result = await notificationsService.deleteNotification(id, tenantId);

      res.json(result);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al eliminar notificación';
      res.status(400).json({ error: message });
    }
  }

  async sendTestNotification(req: AuthRequest, res: Response): Promise<void> {
    try {
      const { title, message } = req.body;
      const userId = req.user!.userId;
      const tenantId = req.user!.tenantId;

      const notification = await notificationsService.sendPushNotification(
        userId,
        title || 'Notificación de prueba',
        message || 'Esta es una notificación de prueba desde FROGIO',
        'general',
        tenantId
      );

      res.json(notification);
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Error al enviar notificación';
      res.status(400).json({ error: message });
    }
  }
}
