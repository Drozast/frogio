import prisma from '../config/database.js';
import { NotificationsService } from './notifications.service.js';
import { logger } from '../config/logger.js';

const notificationsService = new NotificationsService();

export interface AlertConfig {
  type: AlertType;
  enabled: boolean;
  recipients: ('admin' | 'inspector' | 'citizen' | 'assigned')[];
  priority: 'low' | 'normal' | 'high' | 'urgent';
}

export type AlertType =
  | 'new_report'
  | 'report_status_change'
  | 'new_infraction'
  | 'infraction_paid'
  | 'panic_alert'
  | 'panic_resolved'
  | 'vehicle_usage_start'
  | 'vehicle_usage_end'
  | 'citation_created'
  | 'daily_summary';

// Default alert configurations
const DEFAULT_ALERT_CONFIGS: Record<AlertType, AlertConfig> = {
  new_report: {
    type: 'new_report',
    enabled: true,
    recipients: ['admin', 'inspector'],
    priority: 'normal',
  },
  report_status_change: {
    type: 'report_status_change',
    enabled: true,
    recipients: ['assigned', 'citizen'],
    priority: 'normal',
  },
  new_infraction: {
    type: 'new_infraction',
    enabled: true,
    recipients: ['admin', 'citizen'],
    priority: 'high',
  },
  infraction_paid: {
    type: 'infraction_paid',
    enabled: true,
    recipients: ['admin', 'citizen'],
    priority: 'normal',
  },
  panic_alert: {
    type: 'panic_alert',
    enabled: true,
    recipients: ['admin', 'inspector'],
    priority: 'urgent',
  },
  panic_resolved: {
    type: 'panic_resolved',
    enabled: true,
    recipients: ['admin', 'citizen'],
    priority: 'normal',
  },
  vehicle_usage_start: {
    type: 'vehicle_usage_start',
    enabled: true,
    recipients: ['admin'],
    priority: 'low',
  },
  vehicle_usage_end: {
    type: 'vehicle_usage_end',
    enabled: true,
    recipients: ['admin'],
    priority: 'low',
  },
  citation_created: {
    type: 'citation_created',
    enabled: true,
    recipients: ['citizen'],
    priority: 'high',
  },
  daily_summary: {
    type: 'daily_summary',
    enabled: true,
    recipients: ['admin'],
    priority: 'low',
  },
};

export class AlertsService {
  /**
   * Sends automatic alert based on type
   */
  async sendAlert(
    alertType: AlertType,
    tenantId: string,
    data: Record<string, any>,
    specificUserIds?: string[]
  ): Promise<void> {
    const config = DEFAULT_ALERT_CONFIGS[alertType];

    if (!config.enabled) {
      logger.info(`Alert ${alertType} is disabled, skipping`);
      return;
    }

    try {
      const { title, message } = this.buildAlertMessage(alertType, data);

      // Get recipient user IDs
      const recipients = specificUserIds || await this.getRecipients(config.recipients, tenantId, data);

      // Send notification to each recipient
      for (const userId of recipients) {
        await notificationsService.sendPushNotification(
          userId,
          title,
          message,
          config.priority === 'urgent' ? 'urgent' : 'general',
          tenantId,
          { alertType, ...data }
        );
      }

      logger.info(`Alert ${alertType} sent to ${recipients.length} recipients`);
    } catch (error) {
      logger.error(`Error sending alert ${alertType}:`, error);
    }
  }

  /**
   * Alert for new report created
   */
  async onNewReport(tenantId: string, report: any): Promise<void> {
    await this.sendAlert('new_report', tenantId, {
      reportId: report.id,
      title: report.title,
      type: report.type,
      priority: report.priority,
      address: report.address,
      latitude: report.latitude,
      longitude: report.longitude,
    });
  }

  /**
   * Alert for report status change
   */
  async onReportStatusChange(
    tenantId: string,
    report: any,
    oldStatus: string,
    newStatus: string
  ): Promise<void> {
    const userIds: string[] = [];
    if (report.reporterId) userIds.push(report.reporterId);
    if (report.assignedTo) userIds.push(report.assignedTo);

    await this.sendAlert('report_status_change', tenantId, {
      reportId: report.id,
      title: report.title,
      oldStatus,
      newStatus,
    }, userIds);
  }

  /**
   * Alert for new infraction
   */
  async onNewInfraction(tenantId: string, infraction: any): Promise<void> {
    const userIds = infraction.userId ? [infraction.userId] : [];

    await this.sendAlert('new_infraction', tenantId, {
      infractionId: infraction.id,
      type: infraction.type,
      amount: infraction.amount,
      vehiclePlate: infraction.vehiclePlate,
      address: infraction.address,
    }, userIds);
  }

  /**
   * Alert for paid infraction
   */
  async onInfractionPaid(tenantId: string, infraction: any): Promise<void> {
    const userIds = infraction.userId ? [infraction.userId] : [];

    await this.sendAlert('infraction_paid', tenantId, {
      infractionId: infraction.id,
      amount: infraction.amount,
      paidAt: new Date().toISOString(),
    }, userIds);
  }

  /**
   * Alert for panic alert created
   */
  async onPanicAlert(tenantId: string, panic: any): Promise<void> {
    await this.sendAlert('panic_alert', tenantId, {
      panicId: panic.id,
      userId: panic.userId,
      latitude: panic.latitude,
      longitude: panic.longitude,
      address: panic.address,
      message: panic.message,
    });
  }

  /**
   * Alert for panic resolved
   */
  async onPanicResolved(tenantId: string, panic: any, userId: string): Promise<void> {
    await this.sendAlert('panic_resolved', tenantId, {
      panicId: panic.id,
      resolvedBy: panic.respondedById,
      resolution: panic.resolution,
    }, [userId]);
  }

  /**
   * Alert for vehicle usage start
   */
  async onVehicleUsageStart(tenantId: string, log: any): Promise<void> {
    await this.sendAlert('vehicle_usage_start', tenantId, {
      logId: log.id,
      vehicleId: log.vehicleId,
      driverId: log.driverId,
      driverName: log.driverName,
      purpose: log.purpose,
    });
  }

  /**
   * Alert for vehicle usage end
   */
  async onVehicleUsageEnd(tenantId: string, log: any): Promise<void> {
    await this.sendAlert('vehicle_usage_end', tenantId, {
      logId: log.id,
      vehicleId: log.vehicleId,
      driverId: log.driverId,
      totalKm: log.endKm ? log.endKm - log.startKm : 0,
    });
  }

  /**
   * Alert for citation created
   */
  async onCitationCreated(tenantId: string, citation: any): Promise<void> {
    const userIds = citation.citedUserId ? [citation.citedUserId] : [];

    await this.sendAlert('citation_created', tenantId, {
      citationId: citation.id,
      reason: citation.reason,
      date: citation.citationDate,
      location: citation.location,
    }, userIds);
  }

  /**
   * Send daily summary to admins
   */
  async sendDailySummary(tenantId: string): Promise<void> {
    try {
      // Get today's statistics
      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const [reportCount] = await prisma.$queryRawUnsafe<any[]>(
        `SELECT COUNT(*) as count FROM "${tenantId}".reports WHERE created_at >= $1`,
        today
      );

      const [infractionCount] = await prisma.$queryRawUnsafe<any[]>(
        `SELECT COUNT(*) as count FROM "${tenantId}".infractions WHERE created_at >= $1`,
        today
      );

      const [panicCount] = await prisma.$queryRawUnsafe<any[]>(
        `SELECT COUNT(*) as count FROM "${tenantId}".panic_alerts WHERE created_at >= $1`,
        today
      );

      await this.sendAlert('daily_summary', tenantId, {
        date: today.toISOString().split('T')[0],
        newReports: parseInt(reportCount?.count || '0'),
        newInfractions: parseInt(infractionCount?.count || '0'),
        panicAlerts: parseInt(panicCount?.count || '0'),
      });
    } catch (error) {
      logger.error('Error sending daily summary:', error);
    }
  }

  /**
   * Build alert title and message based on type
   */
  private buildAlertMessage(alertType: AlertType, data: Record<string, any>): { title: string; message: string } {
    switch (alertType) {
      case 'new_report':
        return {
          title: '📋 Nuevo Reporte',
          message: `Se ha creado un nuevo reporte: "${data.title}" en ${data.address || 'ubicación no especificada'}`,
        };

      case 'report_status_change':
        return {
          title: '📝 Estado de Reporte Actualizado',
          message: `El reporte "${data.title}" cambió de "${data.oldStatus}" a "${data.newStatus}"`,
        };

      case 'new_infraction':
        return {
          title: '⚠️ Nueva Infracción',
          message: `Se ha registrado una infracción de tipo "${data.type}" por $${data.amount?.toLocaleString('es-CL') || 0}`,
        };

      case 'infraction_paid':
        return {
          title: '✅ Infracción Pagada',
          message: `Tu infracción ha sido marcada como pagada ($${data.amount?.toLocaleString('es-CL') || 0})`,
        };

      case 'panic_alert':
        return {
          title: '🚨 ALERTA DE PÁNICO',
          message: `¡Alerta de emergencia! ${data.address || 'Ver ubicación en el mapa'}. ${data.message || ''}`,
        };

      case 'panic_resolved':
        return {
          title: '✅ Alerta de Pánico Resuelta',
          message: `Tu alerta de emergencia ha sido atendida. Resolución: ${data.resolution || 'Ver detalles'}`,
        };

      case 'vehicle_usage_start':
        return {
          title: '🚗 Vehículo en Uso',
          message: `${data.driverName} ha iniciado uso del vehículo. Propósito: ${data.purpose || 'No especificado'}`,
        };

      case 'vehicle_usage_end':
        return {
          title: '🅿️ Vehículo Devuelto',
          message: `Vehículo devuelto. Distancia recorrida: ${data.totalKm || 0} km`,
        };

      case 'citation_created':
        return {
          title: '📄 Nueva Citación',
          message: `Has recibido una citación: ${data.reason}. Fecha: ${new Date(data.date).toLocaleDateString('es-CL')}`,
        };

      case 'daily_summary':
        return {
          title: '📊 Resumen Diario',
          message: `Resumen del ${data.date}: ${data.newReports} reportes, ${data.newInfractions} infracciones, ${data.panicAlerts} alertas de pánico`,
        };

      default:
        return {
          title: 'Notificación',
          message: 'Tienes una nueva notificación',
        };
    }
  }

  /**
   * Get recipient user IDs based on roles
   */
  private async getRecipients(
    recipientTypes: ('admin' | 'inspector' | 'citizen' | 'assigned')[],
    tenantId: string,
    data?: Record<string, any>
  ): Promise<string[]> {
    const userIds: string[] = [];

    for (const type of recipientTypes) {
      if (type === 'assigned' && data?.assignedTo) {
        userIds.push(data.assignedTo);
      } else if (type !== 'assigned') {
        const users = await prisma.$queryRawUnsafe<any[]>(
          `SELECT id FROM "${tenantId}".users WHERE role = $1 AND is_active = true`,
          type
        );
        userIds.push(...users.map(u => u.id));
      }
    }

    // Remove duplicates
    return [...new Set(userIds)];
  }
}

// Export singleton instance
export const alertsService = new AlertsService();
