import cron, { ScheduledTask } from 'node-cron';
import prisma from '../config/database.js';
import { logger } from '../config/logger.js';
import { NotificationsService } from './notifications.service.js';

const notificationsService = new NotificationsService();

/**
 * Thresholds for automatic alerts.
 * Centralized so they can be tuned later without code spelunking.
 */
const THRESHOLDS = {
  STALE_REPORT_HOURS: 24,
  UNRESPONDED_PANIC_MINUTES: 5,
  INCOMPLETE_TRIP_LOG_HOURS: 12,
};

async function getTenantSchemas(): Promise<string[]> {
  const schemas = await prisma.$queryRaw<{ nspname: string }[]>`
    SELECT nspname FROM pg_namespace
    WHERE nspname NOT IN ('public', 'pg_catalog', 'information_schema', 'pg_toast')
    AND nspname NOT LIKE 'pg_%'
  `;
  return schemas.map(s => s.nspname);
}

async function getStaffUserIds(tenantId: string, roles: string[] = ['admin']): Promise<string[]> {
  try {
    const rows = await prisma.$queryRawUnsafe<{ id: string }[]>(
      `SELECT id FROM "${tenantId}".users WHERE role = ANY($1::text[]) AND is_active = true`,
      roles
    );
    return rows.map(r => r.id);
  } catch {
    return [];
  }
}

export class StaleAlertsService {
  private tasks: ScheduledTask[] = [];

  /**
   * Denuncias en estado pendiente sin inspector asignado que llevan más de
   * STALE_REPORT_HOURS horas. Notifica a todos los admins una sola vez por reporte.
   */
  async checkStaleReports(tenantId: string): Promise<number> {
    try {
      const staleReports = await prisma.$queryRawUnsafe<any[]>(
        `SELECT id, title, address, created_at, user_id
         FROM "${tenantId}".reports
         WHERE status IN ('pendiente', 'pending')
         AND assigned_to IS NULL
         AND type != 'emergencia'
         AND created_at < NOW() - INTERVAL '${THRESHOLDS.STALE_REPORT_HOURS} hours'
         AND stale_alert_sent_at IS NULL`
      );

      if (staleReports.length === 0) return 0;

      const adminIds = await getStaffUserIds(tenantId, ['admin']);
      if (adminIds.length === 0) {
        logger.warn(`[stale-alerts] No admins found for tenant ${tenantId}`);
        return 0;
      }

      for (const report of staleReports) {
        const hoursAgo = Math.floor(
          (Date.now() - new Date(report.created_at).getTime()) / (1000 * 60 * 60)
        );
        const title = '⏰ Denuncia sin atender';
        const message = `"${report.title}" lleva ${hoursAgo}h sin asignar. ${report.address ? `Dirección: ${report.address}` : ''}`;

        for (const adminId of adminIds) {
          try {
            await notificationsService.sendPushNotification(
              adminId,
              title,
              message,
              'urgent',
              tenantId,
              { alertType: 'report_stale_24h', reportId: report.id, hoursSinceCreated: hoursAgo }
            );
          } catch (e) {
            logger.warn(`[stale-alerts] Failed to notify admin ${adminId} about report ${report.id}: ${e}`);
          }
        }

        await prisma.$executeRawUnsafe(
          `UPDATE "${tenantId}".reports SET stale_alert_sent_at = NOW() WHERE id = $1::uuid`,
          report.id
        );
      }

      logger.info(`[stale-alerts] Tenant ${tenantId}: alerted on ${staleReports.length} stale reports`);
      return staleReports.length;
    } catch (e) {
      logger.error(`[stale-alerts] checkStaleReports(${tenantId}) failed: ${e}`);
      return 0;
    }
  }

  /**
   * Alertas de pánico activas que llevan más de UNRESPONDED_PANIC_MINUTES minutos
   * sin ningún inspector asignado. Notifica con prioridad urgente.
   */
  async checkUnrespondedPanics(tenantId: string): Promise<number> {
    try {
      const staleAlerts = await prisma.$queryRawUnsafe<any[]>(
        `SELECT pa.id, pa.user_id, pa.address, pa.message, pa.latitude, pa.longitude, pa.created_at,
         u.first_name, u.last_name
         FROM "${tenantId}".panic_alerts pa
         LEFT JOIN "${tenantId}".users u ON pa.user_id = u.id
         WHERE pa.status = 'active'
         AND pa.created_at < NOW() - INTERVAL '${THRESHOLDS.UNRESPONDED_PANIC_MINUTES} minutes'
         AND pa.unresponded_alert_sent_at IS NULL`
      );

      if (staleAlerts.length === 0) return 0;

      const staffIds = await getStaffUserIds(tenantId, ['admin', 'inspector']);
      if (staffIds.length === 0) return 0;

      for (const alert of staleAlerts) {
        const userName = `${alert.first_name || ''} ${alert.last_name || ''}`.trim() || 'Ciudadano';
        const minutesAgo = Math.floor(
          (Date.now() - new Date(alert.created_at).getTime()) / (1000 * 60)
        );
        const title = '🚨 SOS SIN RESPUESTA';
        const message = `${userName} lleva ${minutesAgo} min esperando. Ubicación: ${alert.address || 'ver mapa'}`;

        for (const userId of staffIds) {
          try {
            await notificationsService.sendPushNotification(
              userId,
              title,
              message,
              'urgent',
              tenantId,
              {
                alertType: 'panic_unresponded_5min',
                alertId: alert.id,
                latitude: alert.latitude,
                longitude: alert.longitude,
                minutesSinceCreated: minutesAgo,
              }
            );
          } catch (e) {
            logger.warn(`[stale-alerts] Failed to notify ${userId} about panic ${alert.id}: ${e}`);
          }
        }

        await prisma.$executeRawUnsafe(
          `UPDATE "${tenantId}".panic_alerts SET unresponded_alert_sent_at = NOW() WHERE id = $1::uuid`,
          alert.id
        );
      }

      logger.warn(`[stale-alerts] Tenant ${tenantId}: ${staleAlerts.length} panic alerts unresponded for >${THRESHOLDS.UNRESPONDED_PANIC_MINUTES}min`);
      return staleAlerts.length;
    } catch (e) {
      logger.error(`[stale-alerts] checkUnrespondedPanics(${tenantId}) failed: ${e}`);
      return 0;
    }
  }

  /**
   * Bitácoras de viaje activas que no se han cerrado en más de INCOMPLETE_TRIP_LOG_HOURS.
   * Notifica al inspector y además a los admins (para visibilidad).
   */
  async checkIncompleteTripLogs(tenantId: string): Promise<number> {
    try {
      const staleLogs = await prisma.$queryRawUnsafe<any[]>(
        `SELECT tl.id, tl.inspector_id, tl.created_at, tl.title,
         u.first_name, u.last_name
         FROM "${tenantId}".trip_logs tl
         LEFT JOIN "${tenantId}".users u ON tl.inspector_id = u.id
         WHERE tl.status = 'active'
         AND tl.created_at < NOW() - INTERVAL '${THRESHOLDS.INCOMPLETE_TRIP_LOG_HOURS} hours'
         AND tl.incomplete_alert_sent_at IS NULL`
      );

      if (staleLogs.length === 0) return 0;

      const adminIds = await getStaffUserIds(tenantId, ['admin']);

      for (const log of staleLogs) {
        const hoursAgo = Math.floor(
          (Date.now() - new Date(log.created_at).getTime()) / (1000 * 60 * 60)
        );
        const inspectorName = `${log.first_name || ''} ${log.last_name || ''}`.trim();

        // Notify inspector: reminder
        if (log.inspector_id) {
          try {
            await notificationsService.sendPushNotification(
              log.inspector_id,
              '📋 Bitácora sin cerrar',
              `Tu bitácora lleva ${hoursAgo}h abierta. Recuerda cerrarla con el kilometraje final.`,
              'general',
              tenantId,
              { alertType: 'trip_log_incomplete', tripLogId: log.id, hoursSinceCreated: hoursAgo }
            );
          } catch (e) {
            logger.warn(`[stale-alerts] Failed to notify inspector ${log.inspector_id}: ${e}`);
          }
        }

        // Notify admins: visibility
        for (const adminId of adminIds) {
          try {
            await notificationsService.sendPushNotification(
              adminId,
              '📋 Bitácora incompleta',
              `${inspectorName || 'Un inspector'} tiene una bitácora abierta hace ${hoursAgo}h sin cerrar.`,
              'general',
              tenantId,
              { alertType: 'trip_log_incomplete_admin', tripLogId: log.id, inspectorId: log.inspector_id }
            );
          } catch (e) {
            logger.warn(`[stale-alerts] Failed to notify admin ${adminId}: ${e}`);
          }
        }

        await prisma.$executeRawUnsafe(
          `UPDATE "${tenantId}".trip_logs SET incomplete_alert_sent_at = NOW() WHERE id = $1::uuid`,
          log.id
        );
      }

      logger.info(`[stale-alerts] Tenant ${tenantId}: ${staleLogs.length} incomplete trip logs alerted`);
      return staleLogs.length;
    } catch (e) {
      logger.error(`[stale-alerts] checkIncompleteTripLogs(${tenantId}) failed: ${e}`);
      return 0;
    }
  }

  async runAllChecks(): Promise<void> {
    const schemas = await getTenantSchemas();
    for (const tenantId of schemas) {
      await this.checkStaleReports(tenantId);
      await this.checkIncompleteTripLogs(tenantId);
    }
  }

  async runPanicChecks(): Promise<void> {
    const schemas = await getTenantSchemas();
    for (const tenantId of schemas) {
      await this.checkUnrespondedPanics(tenantId);
    }
  }

  /**
   * Registra los cron jobs:
   *  - Cada 1 minuto: pánicos sin respuesta (crítico)
   *  - Cada 15 minutos: denuncias viejas y bitácoras incompletas
   */
  start(): void {
    // Urgent: panics every minute
    const panicTask = cron.schedule('* * * * *', async () => {
      try {
        await this.runPanicChecks();
      } catch (e) {
        logger.error(`[stale-alerts] panic cron error: ${e}`);
      }
    });

    // Regular: reports + trip logs every 15 minutes
    const regularTask = cron.schedule('*/15 * * * *', async () => {
      try {
        await this.runAllChecks();
      } catch (e) {
        logger.error(`[stale-alerts] regular cron error: ${e}`);
      }
    });

    this.tasks = [panicTask, regularTask];
    logger.info('✅ Stale alerts cron jobs started (panic: 1min, reports+logs: 15min)');

    // Run once on startup so admins see stale items without waiting
    setTimeout(() => {
      this.runAllChecks().catch(e => logger.error(`[stale-alerts] startup run failed: ${e}`));
      this.runPanicChecks().catch(e => logger.error(`[stale-alerts] startup panic run failed: ${e}`));
    }, 5000);
  }

  stop(): void {
    for (const task of this.tasks) {
      task.stop();
    }
    this.tasks = [];
  }
}

export const staleAlertsService = new StaleAlertsService();
