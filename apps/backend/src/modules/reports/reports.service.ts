import prisma from '../../config/database.js';
import type { CreateReportDto, UpdateReportDto } from './reports.types.js';

export class ReportsService {
  async create(data: CreateReportDto, userId: string, tenantId: string) {
    const [report] = await prisma.$queryRawUnsafe<any[]>(
      `INSERT INTO "${tenantId}".reports
       (user_id, type, title, description, address, latitude, longitude, priority, status, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
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
      `SELECT r.*, u.first_name, u.last_name, u.email, u.phone
       FROM "${tenantId}".reports r
       LEFT JOIN "${tenantId}".users u ON r.user_id = u.id
       WHERE r.id = $1 LIMIT 1`,
      id
    );

    if (!report) {
      throw new Error('Reporte no encontrado');
    }

    return report;
  }

  async update(id: string, data: UpdateReportDto, tenantId: string) {
    const updates: string[] = [];
    const params: any[] = [];
    let paramIndex = 1;

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

    if (data.assignedTo !== undefined) {
      updates.push(`assigned_to = $${paramIndex}`);
      params.push(data.assignedTo);
      paramIndex++;
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
       WHERE id = $${paramIndex}
       RETURNING *`,
      ...params
    );

    if (!updatedReport) {
      throw new Error('Reporte no encontrado');
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
