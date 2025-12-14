import prisma from '../../config/database.js';
import type { CreateCitationDto, UpdateCitationDto } from './citations.types.js';

export class CitationsService {
  async create(data: CreateCitationDto, tenantId: string) {
    const [citation] = await prisma.$queryRawUnsafe<any[]>(
      `INSERT INTO "${tenantId}".court_citations
       (user_id, infraction_id, citation_number, court_name, hearing_date, address, reason, notification_method, status, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
       RETURNING *`,
      data.userId,
      data.infractionId || null,
      data.citationNumber,
      data.courtName,
      data.hearingDate,
      data.address,
      data.reason,
      data.notificationMethod || null,
      'pendiente'
    );

    return citation;
  }

  async findAll(tenantId: string, filters?: { status?: string; userId?: string }) {
    let query = `SELECT cc.*,
                 u.first_name as user_first_name, u.last_name as user_last_name, u.email as user_email, u.phone as user_phone,
                 i.description as infraction_description, i.amount as infraction_amount
                 FROM "${tenantId}".court_citations cc
                 LEFT JOIN "${tenantId}".users u ON cc.user_id = u.id
                 LEFT JOIN "${tenantId}".infractions i ON cc.infraction_id = i.id
                 WHERE 1=1`;

    const params: any[] = [];
    let paramIndex = 1;

    if (filters?.status) {
      query += ` AND cc.status = $${paramIndex}`;
      params.push(filters.status);
      paramIndex++;
    }

    if (filters?.userId) {
      query += ` AND cc.user_id = $${paramIndex}`;
      params.push(filters.userId);
      paramIndex++;
    }

    query += ` ORDER BY cc.hearing_date ASC`;

    const citations = await prisma.$queryRawUnsafe<any[]>(query, ...params);
    return citations;
  }

  async findById(id: string, tenantId: string) {
    const [citation] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT cc.*,
       u.first_name as user_first_name, u.last_name as user_last_name, u.email as user_email, u.phone as user_phone, u.rut as user_rut,
       i.description as infraction_description, i.amount as infraction_amount, i.type as infraction_type
       FROM "${tenantId}".court_citations cc
       LEFT JOIN "${tenantId}".users u ON cc.user_id = u.id
       LEFT JOIN "${tenantId}".infractions i ON cc.infraction_id = i.id
       WHERE cc.id = $1 LIMIT 1`,
      id
    );

    if (!citation) {
      throw new Error('Citación no encontrada');
    }

    return citation;
  }

  async update(id: string, data: UpdateCitationDto, tenantId: string) {
    const updates: string[] = [];
    const params: any[] = [];
    let paramIndex = 1;

    if (data.status !== undefined) {
      updates.push(`status = $${paramIndex}`);
      params.push(data.status);
      paramIndex++;

      // If status is notified, set notified_at timestamp
      if (data.status === 'notificado') {
        updates.push(`notified_at = NOW()`);
      }
    }

    if (data.notificationMethod !== undefined) {
      updates.push(`notification_method = $${paramIndex}`);
      params.push(data.notificationMethod);
      paramIndex++;
    }

    if (data.notes !== undefined) {
      updates.push(`notes = $${paramIndex}`);
      params.push(data.notes);
      paramIndex++;
    }

    if (updates.length === 0) {
      throw new Error('No hay datos para actualizar');
    }

    updates.push(`updated_at = NOW()`);
    params.push(id);

    const [updatedCitation] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".court_citations
       SET ${updates.join(', ')}
       WHERE id = $${paramIndex}
       RETURNING *`,
      ...params
    );

    if (!updatedCitation) {
      throw new Error('Citación no encontrada');
    }

    return updatedCitation;
  }

  async delete(id: string, tenantId: string) {
    const [deletedCitation] = await prisma.$queryRawUnsafe<any[]>(
      `DELETE FROM "${tenantId}".court_citations WHERE id = $1 RETURNING id`,
      id
    );

    if (!deletedCitation) {
      throw new Error('Citación no encontrada');
    }

    return { message: 'Citación eliminada exitosamente' };
  }

  async getUpcoming(tenantId: string, userId?: string) {
    let query = `SELECT cc.*,
                 u.first_name as user_first_name, u.last_name as user_last_name, u.email as user_email
                 FROM "${tenantId}".court_citations cc
                 LEFT JOIN "${tenantId}".users u ON cc.user_id = u.id
                 WHERE cc.hearing_date > NOW()
                 AND cc.status NOT IN ('asistio', 'cancelado')`;

    const params: any[] = [];
    if (userId) {
      query += ` AND cc.user_id = $1`;
      params.push(userId);
    }

    query += ` ORDER BY cc.hearing_date ASC LIMIT 10`;

    const citations = await prisma.$queryRawUnsafe<any[]>(query, ...params);
    return citations;
  }
}
