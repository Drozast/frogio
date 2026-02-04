import { env } from '../config/env.js';
import { logger } from '../config/logger.js';
import prisma from '../config/database.js';

export class NotificationsService {
  private readonly NTFY_URL = env.NTFY_URL;

  async sendPushNotification(
    userId: string,
    title: string,
    message: string,
    type: 'report' | 'infraction' | 'citation' | 'general' | 'urgent',
    tenantId: string,
    metadata?: Record<string, any>
  ) {
    let notification = null;

    // Save notification to database (primary operation)
    try {
      const [result] = await prisma.$queryRawUnsafe<any[]>(
        `INSERT INTO "${tenantId}".notifications
         (user_id, title, message, type, is_read, metadata, created_at)
         VALUES ($1::uuid, $2, $3, $4, $5, $6, NOW())
         RETURNING *`,
        userId,
        title,
        message,
        type,
        false,
        metadata ? JSON.stringify(metadata) : null
      );
      notification = result;
    } catch (error) {
      logger.error(`Failed to save notification to database: ${error instanceof Error ? error.message : error}`);
      throw error;
    }

    // Send push notification via ntfy (secondary, non-blocking)
    if (this.NTFY_URL) {
      try {
        const topic = `${tenantId}_${userId}`;
        const priority = type === 'urgent' ? 5 : type === 'citation' || type === 'infraction' ? 4 : 3;

        await fetch(`${this.NTFY_URL}/${topic}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            topic,
            title,
            message,
            priority,
            tags: [type],
          }),
        });
      } catch (error) {
        // Log but don't fail - ntfy is optional
        logger.warn(`Failed to send ntfy push notification: ${error instanceof Error ? error.message : error}`);
      }
    }

    return notification;
  }

  async getUserNotifications(userId: string, tenantId: string, limit: number = 50) {
    const notifications = await prisma.$queryRawUnsafe<any[]>(
      `SELECT * FROM "${tenantId}".notifications
       WHERE user_id = $1::uuid
       ORDER BY created_at DESC
       LIMIT $2`,
      userId,
      limit
    );

    return notifications;
  }

  async markAsRead(notificationId: string, tenantId: string) {
    const [notification] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".notifications
       SET is_read = true
       WHERE id = $1::uuid
       RETURNING *`,
      notificationId
    );

    if (!notification) {
      throw new Error('Notificación no encontrada');
    }

    return notification;
  }

  async markAllAsRead(userId: string, tenantId: string) {
    await prisma.$queryRawUnsafe(
      `UPDATE "${tenantId}".notifications
       SET is_read = true
       WHERE user_id = $1::uuid AND is_read = false`,
      userId
    );

    return { message: 'Todas las notificaciones marcadas como leídas' };
  }

  async getUnreadCount(userId: string, tenantId: string): Promise<number> {
    const [result] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT COUNT(*) as count
       FROM "${tenantId}".notifications
       WHERE user_id = $1::uuid AND is_read = false`,
      userId
    );

    return parseInt(result?.count || '0');
  }

  async deleteNotification(notificationId: string, tenantId: string) {
    const [deleted] = await prisma.$queryRawUnsafe<any[]>(
      `DELETE FROM "${tenantId}".notifications WHERE id = $1::uuid RETURNING id`,
      notificationId
    );

    if (!deleted) {
      throw new Error('Notificación no encontrada');
    }

    return { message: 'Notificación eliminada exitosamente' };
  }
}
