import prisma from '../../config/database.js';
import type { CreateCitationDto, UpdateCitationDto, CitationFilters, Citation } from './citations.types.js';

export class CitationsService {
  async create(data: CreateCitationDto, tenantId: string, issuedBy: string): Promise<Citation> {
    const [citation] = await prisma.$queryRawUnsafe<Citation[]>(
      `INSERT INTO "${tenantId}".court_citations
       (citation_type, target_type, target_name, target_rut, target_address, target_phone, target_plate,
        location_address, latitude, longitude, citation_number, reason, notes, photos,
        user_id, infraction_id, court_name, hearing_date, address, notification_method,
        status, issued_by, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22::uuid, NOW(), NOW())
       RETURNING *`,
      data.citationType || 'citacion',
      data.targetType || 'persona',
      data.targetName || null,
      data.targetRut || null,
      data.targetAddress || null,
      data.targetPhone || null,
      data.targetPlate || null,
      data.locationAddress || null,
      data.latitude || null,
      data.longitude || null,
      data.citationNumber,
      data.reason,
      data.notes || null,
      data.photos || null,
      data.userId || null,
      data.infractionId || null,
      data.courtName || null,
      data.hearingDate || null,
      data.address || null,
      data.notificationMethod || null,
      'pendiente',
      issuedBy
    );

    return citation;
  }

  async findAll(tenantId: string, filters?: CitationFilters): Promise<Citation[]> {
    let query = `SELECT cc.*,
                 issuer.first_name as issuer_first_name, issuer.last_name as issuer_last_name,
                 u.first_name as user_first_name, u.last_name as user_last_name, u.email as user_email, u.phone as user_phone, u.rut as user_rut,
                 i.description as infraction_description, i.amount as infraction_amount
                 FROM "${tenantId}".court_citations cc
                 LEFT JOIN "${tenantId}".users issuer ON cc.issued_by = issuer.id
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

    if (filters?.citationType) {
      query += ` AND cc.citation_type = $${paramIndex}`;
      params.push(filters.citationType);
      paramIndex++;
    }

    if (filters?.targetType) {
      query += ` AND cc.target_type = $${paramIndex}`;
      params.push(filters.targetType);
      paramIndex++;
    }

    if (filters?.userId) {
      query += ` AND cc.user_id = $${paramIndex}`;
      params.push(filters.userId);
      paramIndex++;
    }

    if (filters?.issuedBy) {
      query += ` AND cc.issued_by = $${paramIndex}`;
      params.push(filters.issuedBy);
      paramIndex++;
    }

    if (filters?.search) {
      query += ` AND (
        cc.target_name ILIKE $${paramIndex} OR
        cc.target_rut ILIKE $${paramIndex} OR
        cc.target_plate ILIKE $${paramIndex} OR
        cc.citation_number ILIKE $${paramIndex} OR
        cc.reason ILIKE $${paramIndex} OR
        cc.location_address ILIKE $${paramIndex}
      )`;
      params.push(`%${filters.search}%`);
      paramIndex++;
    }

    if (filters?.fromDate) {
      query += ` AND cc.created_at >= $${paramIndex}`;
      params.push(filters.fromDate);
      paramIndex++;
    }

    if (filters?.toDate) {
      query += ` AND cc.created_at <= $${paramIndex}`;
      params.push(filters.toDate);
      paramIndex++;
    }

    query += ` ORDER BY cc.created_at DESC`;

    const citations = await prisma.$queryRawUnsafe<Citation[]>(query, ...params);
    return citations;
  }

  async findById(id: string, tenantId: string): Promise<Citation> {
    const [citation] = await prisma.$queryRawUnsafe<Citation[]>(
      `SELECT cc.*,
       issuer.first_name as issuer_first_name, issuer.last_name as issuer_last_name,
       u.first_name as user_first_name, u.last_name as user_last_name, u.email as user_email, u.phone as user_phone, u.rut as user_rut,
       i.description as infraction_description, i.amount as infraction_amount, i.type as infraction_type
       FROM "${tenantId}".court_citations cc
       LEFT JOIN "${tenantId}".users issuer ON cc.issued_by = issuer.id
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

  async update(id: string, data: UpdateCitationDto, tenantId: string): Promise<Citation> {
    const updates: string[] = [];
    const params: any[] = [];
    let paramIndex = 1;

    if (data.status !== undefined) {
      updates.push(`status = $${paramIndex}`);
      params.push(data.status);
      paramIndex++;

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

    if (data.targetName !== undefined) {
      updates.push(`target_name = $${paramIndex}`);
      params.push(data.targetName);
      paramIndex++;
    }

    if (data.targetRut !== undefined) {
      updates.push(`target_rut = $${paramIndex}`);
      params.push(data.targetRut);
      paramIndex++;
    }

    if (data.targetAddress !== undefined) {
      updates.push(`target_address = $${paramIndex}`);
      params.push(data.targetAddress);
      paramIndex++;
    }

    if (data.targetPhone !== undefined) {
      updates.push(`target_phone = $${paramIndex}`);
      params.push(data.targetPhone);
      paramIndex++;
    }

    if (data.targetPlate !== undefined) {
      updates.push(`target_plate = $${paramIndex}`);
      params.push(data.targetPlate);
      paramIndex++;
    }

    if (data.locationAddress !== undefined) {
      updates.push(`location_address = $${paramIndex}`);
      params.push(data.locationAddress);
      paramIndex++;
    }

    if (data.latitude !== undefined) {
      updates.push(`latitude = $${paramIndex}`);
      params.push(data.latitude);
      paramIndex++;
    }

    if (data.longitude !== undefined) {
      updates.push(`longitude = $${paramIndex}`);
      params.push(data.longitude);
      paramIndex++;
    }

    if (data.photos !== undefined) {
      updates.push(`photos = $${paramIndex}`);
      params.push(data.photos);
      paramIndex++;
    }

    if (updates.length === 0) {
      throw new Error('No hay datos para actualizar');
    }

    updates.push(`updated_at = NOW()`);
    params.push(id);

    const [updatedCitation] = await prisma.$queryRawUnsafe<Citation[]>(
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

  async delete(id: string, tenantId: string): Promise<{ message: string }> {
    const [deletedCitation] = await prisma.$queryRawUnsafe<{ id: string }[]>(
      `DELETE FROM "${tenantId}".court_citations WHERE id = $1 RETURNING id`,
      id
    );

    if (!deletedCitation) {
      throw new Error('Citación no encontrada');
    }

    return { message: 'Citación eliminada exitosamente' };
  }

  async getStats(tenantId: string): Promise<{
    total: number;
    byType: { type: string; count: number }[];
    byStatus: { status: string; count: number }[];
    byTargetType: { targetType: string; count: number }[];
  }> {
    const [totalResult] = await prisma.$queryRawUnsafe<{ count: string }[]>(
      `SELECT COUNT(*) as count FROM "${tenantId}".court_citations`
    );

    const byType = await prisma.$queryRawUnsafe<{ type: string; count: string }[]>(
      `SELECT citation_type as type, COUNT(*) as count
       FROM "${tenantId}".court_citations
       GROUP BY citation_type`
    );

    const byStatus = await prisma.$queryRawUnsafe<{ status: string; count: string }[]>(
      `SELECT status, COUNT(*) as count
       FROM "${tenantId}".court_citations
       GROUP BY status`
    );

    const byTargetType = await prisma.$queryRawUnsafe<{ target_type: string; count: string }[]>(
      `SELECT target_type, COUNT(*) as count
       FROM "${tenantId}".court_citations
       GROUP BY target_type`
    );

    return {
      total: parseInt(totalResult.count),
      byType: byType.map(r => ({ type: r.type, count: parseInt(r.count) })),
      byStatus: byStatus.map(r => ({ status: r.status, count: parseInt(r.count) })),
      byTargetType: byTargetType.map(r => ({ targetType: r.target_type, count: parseInt(r.count) })),
    };
  }

  async getUpcoming(tenantId: string, userId?: string): Promise<Citation[]> {
    let query = `SELECT cc.*,
                 issuer.first_name as issuer_first_name, issuer.last_name as issuer_last_name,
                 u.first_name as user_first_name, u.last_name as user_last_name, u.email as user_email
                 FROM "${tenantId}".court_citations cc
                 LEFT JOIN "${tenantId}".users issuer ON cc.issued_by = issuer.id
                 LEFT JOIN "${tenantId}".users u ON cc.user_id = u.id
                 WHERE cc.hearing_date > NOW()
                 AND cc.status NOT IN ('asistio', 'cancelado')`;

    const params: any[] = [];
    if (userId) {
      query += ` AND cc.user_id = $1`;
      params.push(userId);
    }

    query += ` ORDER BY cc.hearing_date ASC LIMIT 10`;

    const citations = await prisma.$queryRawUnsafe<Citation[]>(query, ...params);
    return citations;
  }

  async bulkImport(
    records: Array<{
      citationType?: string;
      targetType?: string;
      targetName?: string;
      targetRut?: string;
      targetAddress?: string;
      targetPhone?: string;
      targetPlate?: string;
      locationAddress?: string;
      citationNumber: string;
      reason: string;
      notes?: string;
      status?: string;
      createdAt?: string;
    }>,
    tenantId: string,
    issuedBy: string
  ): Promise<{ imported: number; errors: string[] }> {
    const errors: string[] = [];
    let imported = 0;

    for (let i = 0; i < records.length; i++) {
      const record = records[i];
      try {
        if (!record.citationNumber || !record.reason) {
          errors.push(`Fila ${i + 1}: Número de notificación y motivo son requeridos`);
          continue;
        }

        await prisma.$queryRawUnsafe(
          `INSERT INTO "${tenantId}".court_citations
           (citation_type, target_type, target_name, target_rut, target_address, target_phone, target_plate,
            location_address, citation_number, reason, notes, status, issued_by, created_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13::uuid,
                   COALESCE($14::timestamp, NOW()), NOW())`,
          record.citationType || 'citacion',
          record.targetType || 'persona',
          record.targetName || null,
          record.targetRut || null,
          record.targetAddress || null,
          record.targetPhone || null,
          record.targetPlate || null,
          record.locationAddress || null,
          record.citationNumber,
          record.reason,
          record.notes || null,
          record.status || 'pendiente',
          issuedBy,
          record.createdAt || null
        );
        imported++;
      } catch (error) {
        const message = error instanceof Error ? error.message : 'Error desconocido';
        errors.push(`Fila ${i + 1}: ${message}`);
      }
    }

    return { imported, errors };
  }
}
