import prisma from '../../config/database.js';
import { env } from '../../config/env.js';
import { logger } from '../../config/logger.js';
import type { CreatePanicAlertDto, PanicAlertFilters } from './panic.types.js';

export class PanicService {
  async create(data: CreatePanicAlertDto, userId: string, tenantId: string) {
    // Create panic alert
    const [alert] = await prisma.$queryRawUnsafe<any[]>(
      `INSERT INTO "${tenantId}".panic_alerts
       (user_id, latitude, longitude, address, message, contact_phone, status, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, 'active', NOW(), NOW())
       RETURNING *`,
      userId,
      data.latitude,
      data.longitude,
      data.address || null,
      data.message || 'Alerta de emergencia',
      data.contactPhone || null
    );

    // Get user info for notification
    const [user] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT first_name, last_name, phone FROM "${tenantId}".users WHERE id = $1`,
      userId
    );

    // Send notification to all inspectors/admins via ntfy
    if (env.NTFY_URL) {
      try {
        const userName = `${user?.first_name || ''} ${user?.last_name || ''}`.trim() || 'Usuario';
        await fetch(`${env.NTFY_URL}/frogio-panic`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Priority': 'urgent',
            'Tags': 'warning,sos'
          },
          body: JSON.stringify({
            topic: 'frogio-panic',
            title: '🚨 ALERTA DE PÁNICO',
            message: `${userName} necesita ayuda!\nUbicación: ${data.address || `${data.latitude}, ${data.longitude}`}\nMensaje: ${data.message || 'Emergencia'}`,
            priority: 5,
            tags: ['warning', 'sos'],
            click: `https://maps.google.com/?q=${data.latitude},${data.longitude}`,
          }),
        });
        logger.info(`Panic alert notification sent for user ${userId}`);
      } catch (e) {
        logger.warn('Could not send panic notification via ntfy');
      }
    }

    // Also create internal notification for all inspectors
    await prisma.$queryRawUnsafe(
      `INSERT INTO "${tenantId}".notifications (user_id, title, body, type, data, created_at)
       SELECT id, $1, $2, 'panic_alert', $3, NOW()
       FROM "${tenantId}".users WHERE role IN ('inspector', 'admin')`,
      '🚨 ALERTA DE PÁNICO',
      `Un ciudadano necesita ayuda urgente`,
      JSON.stringify({ alertId: alert.id, latitude: data.latitude, longitude: data.longitude })
    );

    return alert;
  }

  async findAll(tenantId: string, filters?: PanicAlertFilters) {
    let query = `SELECT pa.*,
                 u.first_name, u.last_name, u.phone, u.email,
                 r.first_name as responder_first_name, r.last_name as responder_last_name
                 FROM "${tenantId}".panic_alerts pa
                 LEFT JOIN "${tenantId}".users u ON pa.user_id = u.id
                 LEFT JOIN "${tenantId}".users r ON pa.responder_id = r.id
                 WHERE 1=1`;

    const params: any[] = [];
    let paramIndex = 1;

    if (filters?.status) {
      query += ` AND pa.status = $${paramIndex}`;
      params.push(filters.status);
      paramIndex++;
    }

    if (filters?.userId) {
      query += ` AND pa.user_id = $${paramIndex}`;
      params.push(filters.userId);
      paramIndex++;
    }

    query += ` ORDER BY pa.created_at DESC`;

    const alerts = await prisma.$queryRawUnsafe<any[]>(query, ...params);
    return alerts;
  }

  async findActive(tenantId: string) {
    const alerts = await prisma.$queryRawUnsafe<any[]>(
      `SELECT pa.*,
       u.first_name, u.last_name, u.phone, u.email
       FROM "${tenantId}".panic_alerts pa
       LEFT JOIN "${tenantId}".users u ON pa.user_id = u.id
       WHERE pa.status IN ('active', 'responding')
       ORDER BY pa.created_at DESC`
    );
    return alerts;
  }

  async findById(id: string, tenantId: string) {
    const [alert] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT pa.*,
       u.first_name, u.last_name, u.phone, u.email, u.address as user_address,
       r.first_name as responder_first_name, r.last_name as responder_last_name
       FROM "${tenantId}".panic_alerts pa
       LEFT JOIN "${tenantId}".users u ON pa.user_id = u.id
       LEFT JOIN "${tenantId}".users r ON pa.responder_id = r.id
       WHERE pa.id = $1`,
      id
    );

    if (!alert) {
      throw new Error('Alerta no encontrada');
    }

    return alert;
  }

  async respond(id: string, responderId: string, tenantId: string) {
    const [alert] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".panic_alerts
       SET status = 'responding', responder_id = $1, responded_at = NOW(), updated_at = NOW()
       WHERE id = $2 AND status = 'active'
       RETURNING *`,
      responderId,
      id
    );

    if (!alert) {
      throw new Error('Alerta no encontrada o ya atendida');
    }

    // Notify the user that help is on the way
    await prisma.$queryRawUnsafe(
      `INSERT INTO "${tenantId}".notifications (user_id, title, body, type, data, created_at)
       VALUES ($1, $2, $3, 'panic_response', $4, NOW())`,
      alert.user_id,
      '✅ Ayuda en camino',
      'Un inspector está respondiendo a tu alerta',
      JSON.stringify({ alertId: id })
    );

    return alert;
  }

  async resolve(id: string, notes: string | null, tenantId: string) {
    const [alert] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".panic_alerts
       SET status = 'resolved', notes = $1, resolved_at = NOW(), updated_at = NOW()
       WHERE id = $2 AND status IN ('active', 'responding')
       RETURNING *`,
      notes,
      id
    );

    if (!alert) {
      throw new Error('Alerta no encontrada o ya resuelta');
    }

    return alert;
  }

  async cancel(id: string, userId: string, tenantId: string) {
    const [alert] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".panic_alerts
       SET status = 'cancelled', updated_at = NOW()
       WHERE id = $1 AND user_id = $2 AND status = 'active'
       RETURNING *`,
      id,
      userId
    );

    if (!alert) {
      throw new Error('No puedes cancelar esta alerta');
    }

    return alert;
  }

  async getStats(tenantId: string) {
    const [stats] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE status = 'active') as active,
        COUNT(*) FILTER (WHERE status = 'responding') as responding,
        COUNT(*) FILTER (WHERE status = 'resolved') as resolved,
        COUNT(*) FILTER (WHERE status = 'cancelled') as cancelled,
        COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '24 hours') as last_24h,
        COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days') as last_7d
       FROM "${tenantId}".panic_alerts`
    );

    return {
      total: parseInt(stats?.total || '0'),
      active: parseInt(stats?.active || '0'),
      responding: parseInt(stats?.responding || '0'),
      resolved: parseInt(stats?.resolved || '0'),
      cancelled: parseInt(stats?.cancelled || '0'),
      last24h: parseInt(stats?.last_24h || '0'),
      last7d: parseInt(stats?.last_7d || '0'),
    };
  }
}
