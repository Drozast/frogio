import prisma from '../../config/database.js';
import { alertsService } from '../../services/alerts.service.js';
import type { CreateReportDto, UpdateReportDto, ReportVersion } from './reports.types.js';

export class ReportsService {
  // Save current state as a version before updating
  private async saveVersion(reportId: string, modifiedBy: string, tenantId: string, changeReason?: string): Promise<void> {
    // Get next version number
    const [versionCount] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT COALESCE(MAX(version_number), 0) + 1 as next_version
       FROM "${tenantId}".report_versions WHERE report_id = $1::uuid`,
      reportId
    );
    const nextVersion = parseInt(versionCount?.next_version || '1');

    // Get current report state
    const [currentReport] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT * FROM "${tenantId}".reports WHERE id = $1::uuid`,
      reportId
    );

    if (!currentReport) return;

    // Insert version snapshot
    await prisma.$queryRawUnsafe(
      `INSERT INTO "${tenantId}".report_versions
       (report_id, version_number, title, description, type, status, priority, address,
        latitude, longitude, assigned_to, resolution, modified_by, modified_at, change_reason)
       VALUES ($1::uuid, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11::uuid, $12, $13::uuid, NOW(), $14)`,
      reportId,
      nextVersion,
      currentReport.title,
      currentReport.description,
      currentReport.type,
      currentReport.status,
      currentReport.priority,
      currentReport.address,
      currentReport.latitude,
      currentReport.longitude,
      currentReport.assigned_to,
      currentReport.resolution,
      modifiedBy,
      changeReason || null
    );
  }

  // Get version history for a report
  async getVersionHistory(reportId: string, tenantId: string): Promise<ReportVersion[]> {
    const versions = await prisma.$queryRawUnsafe<ReportVersion[]>(
      `SELECT rv.*, u.first_name as modifier_first_name, u.last_name as modifier_last_name
       FROM "${tenantId}".report_versions rv
       LEFT JOIN "${tenantId}".users u ON rv.modified_by = u.id
       WHERE rv.report_id = $1::uuid
       ORDER BY rv.version_number DESC`,
      reportId
    );
    return versions;
  }

  // Get a specific version
  async getVersion(reportId: string, versionNumber: number, tenantId: string): Promise<ReportVersion | null> {
    const [version] = await prisma.$queryRawUnsafe<ReportVersion[]>(
      `SELECT rv.*, u.first_name as modifier_first_name, u.last_name as modifier_last_name
       FROM "${tenantId}".report_versions rv
       LEFT JOIN "${tenantId}".users u ON rv.modified_by = u.id
       WHERE rv.report_id = $1::uuid AND rv.version_number = $2`,
      reportId,
      versionNumber
    );
    return version || null;
  }

  async create(data: CreateReportDto, userId: string, tenantId: string) {
    const [report] = await prisma.$queryRawUnsafe<any[]>(
      `INSERT INTO "${tenantId}".reports
       (user_id, type, title, description, address, latitude, longitude, priority, status, created_at, updated_at)
       VALUES ($1::uuid, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
       RETURNING *`,
      userId,
      data.type,
      data.title,
      data.description,
      data.address || null,
      data.latitude || null,
      data.longitude || null,
      data.priority || 'media',
      'pendiente'
    );

    // Send automatic alert
    await alertsService.onNewReport(tenantId, report);

    return report;
  }

  async findAll(tenantId: string, filters?: { status?: string; type?: string; userId?: string }) {
    let query = `SELECT r.*, u.first_name, u.last_name, u.email
                 FROM "${tenantId}".reports r
                 LEFT JOIN "${tenantId}".users u ON r.user_id = u.id
                 WHERE 1=1`;

    const params: any[] = [];
    let paramIndex = 1;

    if (filters?.status) {
      query += ` AND r.status = $${paramIndex}`;
      params.push(filters.status);
      paramIndex++;
    }

    if (filters?.type) {
      query += ` AND r.type = $${paramIndex}`;
      params.push(filters.type);
      paramIndex++;
    }

    if (filters?.userId) {
      query += ` AND r.user_id = $${paramIndex}`;
      params.push(filters.userId);
      paramIndex++;
    }

    query += ` ORDER BY r.created_at DESC`;

    const reports = await prisma.$queryRawUnsafe<any[]>(query, ...params);
    return reports;
  }

  async findById(id: string, tenantId: string) {
    const [report] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT r.*, u.first_name, u.last_name, u.email, u.phone,
       a.first_name as assigned_first_name, a.last_name as assigned_last_name
       FROM "${tenantId}".reports r
       LEFT JOIN "${tenantId}".users u ON r.user_id = u.id
       LEFT JOIN "${tenantId}".users a ON r.assigned_to = a.id
       WHERE r.id = $1::uuid LIMIT 1`,
      id
    );

    if (!report) {
      throw new Error('Reporte no encontrado');
    }

    return report;
  }

  async update(id: string, data: UpdateReportDto, modifiedBy: string, tenantId: string) {
    // Get current status for comparison
    const currentReport = await this.findById(id, tenantId);
    const oldStatus = currentReport.status;

    // Save current state as a version before updating
    await this.saveVersion(id, modifiedBy, tenantId, data.changeReason);

    const updates: string[] = [];
    const params: any[] = [];
    let paramIndex = 1;

    if (data.title !== undefined) {
      updates.push(`title = $${paramIndex}`);
      params.push(data.title);
      paramIndex++;
    }

    if (data.description !== undefined) {
      updates.push(`description = $${paramIndex}`);
      params.push(data.description);
      paramIndex++;
    }

    if (data.type !== undefined) {
      updates.push(`type = $${paramIndex}`);
      params.push(data.type);
      paramIndex++;
    }

    if (data.status !== undefined) {
      updates.push(`status = $${paramIndex}`);
      params.push(data.status);
      paramIndex++;
    }

    if (data.priority !== undefined) {
      updates.push(`priority = $${paramIndex}`);
      params.push(data.priority);
      paramIndex++;
    }

    if (data.address !== undefined) {
      updates.push(`address = $${paramIndex}`);
      params.push(data.address);
      paramIndex++;
    }

    if (data.assignedTo !== undefined) {
      if (data.assignedTo === null || data.assignedTo === '') {
        updates.push(`assigned_to = NULL`);
      } else {
        updates.push(`assigned_to = $${paramIndex}::uuid`);
        params.push(data.assignedTo);
        paramIndex++;
      }
    }

    if (data.resolution !== undefined) {
      updates.push(`resolution = $${paramIndex}`);
      params.push(data.resolution);
      paramIndex++;
    }

    if (updates.length === 0) {
      throw new Error('No hay datos para actualizar');
    }

    updates.push(`updated_at = NOW()`);
    params.push(id);

    const [updatedReport] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".reports
       SET ${updates.join(', ')}
       WHERE id = $${paramIndex}::uuid
       RETURNING *`,
      ...params
    );

    if (!updatedReport) {
      throw new Error('Reporte no encontrado');
    }

    // Send alert if status changed
    if (data.status && data.status !== oldStatus) {
      await alertsService.onReportStatusChange(tenantId, {
        ...updatedReport,
        reporterId: currentReport.user_id,
      }, oldStatus, data.status);
    }

    return updatedReport;
  }

  async delete(id: string, tenantId: string) {
    const [deletedReport] = await prisma.$queryRawUnsafe<any[]>(
      `DELETE FROM "${tenantId}".reports WHERE id = $1 RETURNING id`,
      id
    );

    if (!deletedReport) {
      throw new Error('Reporte no encontrado');
    }

    return { message: 'Reporte eliminado exitosamente' };
  }
}
