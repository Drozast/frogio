import { prisma } from '../../config/database.js';
import type { CreateInfractionDto, UpdateInfractionDto } from './infractions.types.js';

export class InfractionsService {
  async create(data: CreateInfractionDto, issuedBy: string, tenantId: string) {
    const [infraction] = await prisma.$queryRawUnsafe<any[]>(
      `INSERT INTO "${tenantId}".infractions
       (user_id, type, description, address, latitude, longitude, amount, vehicle_plate, status, issued_by, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, NOW(), NOW())
       RETURNING *`,
      data.userId,
      data.type,
      data.description,
      data.address,
      data.latitude || null,
      data.longitude || null,
      data.amount,
      data.vehiclePlate || null,
      'pendiente',
      issuedBy
    );

    return infraction;
  }

  async findAll(tenantId: string, filters?: { status?: string; userId?: string }) {
    let query = `SELECT i.*,
                 u.first_name as user_first_name, u.last_name as user_last_name, u.email as user_email,
                 issuer.first_name as issuer_first_name, issuer.last_name as issuer_last_name
                 FROM "${tenantId}".infractions i
                 LEFT JOIN "${tenantId}".users u ON i.user_id = u.id
                 LEFT JOIN "${tenantId}".users issuer ON i.issued_by = issuer.id
                 WHERE 1=1`;

    const params: any[] = [];
    let paramIndex = 1;

    if (filters?.status) {
      query += ` AND i.status = $${paramIndex}`;
      params.push(filters.status);
      paramIndex++;
    }

    if (filters?.userId) {
      query += ` AND i.user_id = $${paramIndex}`;
      params.push(filters.userId);
      paramIndex++;
    }

    query += ` ORDER BY i.created_at DESC`;

    const infractions = await prisma.$queryRawUnsafe<any[]>(query, ...params);
    return infractions;
  }

  async findById(id: string, tenantId: string) {
    const [infraction] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT i.*,
       u.first_name as user_first_name, u.last_name as user_last_name, u.email as user_email, u.phone as user_phone, u.rut as user_rut,
       issuer.first_name as issuer_first_name, issuer.last_name as issuer_last_name
       FROM "${tenantId}".infractions i
       LEFT JOIN "${tenantId}".users u ON i.user_id = u.id
       LEFT JOIN "${tenantId}".users issuer ON i.issued_by = issuer.id
       WHERE i.id = $1 LIMIT 1`,
      id
    );

    if (!infraction) {
      throw new Error('Infracción no encontrada');
    }

    return infraction;
  }

  async update(id: string, data: UpdateInfractionDto, tenantId: string) {
    const updates: string[] = [];
    const params: any[] = [];
    let paramIndex = 1;

    if (data.status !== undefined) {
      updates.push(`status = $${paramIndex}`);
      params.push(data.status);
      paramIndex++;

      // If status is paid, set paid_at timestamp
      if (data.status === 'pagada') {
        updates.push(`paid_at = NOW()`);
      }
    }

    if (data.paymentMethod !== undefined) {
      updates.push(`payment_method = $${paramIndex}`);
      params.push(data.paymentMethod);
      paramIndex++;
    }

    if (data.paymentReference !== undefined) {
      updates.push(`payment_reference = $${paramIndex}`);
      params.push(data.paymentReference);
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

    const [updatedInfraction] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".infractions
       SET ${updates.join(', ')}
       WHERE id = $${paramIndex}
       RETURNING *`,
      ...params
    );

    if (!updatedInfraction) {
      throw new Error('Infracción no encontrada');
    }

    return updatedInfraction;
  }

  async delete(id: string, tenantId: string) {
    const [deletedInfraction] = await prisma.$queryRawUnsafe<any[]>(
      `DELETE FROM "${tenantId}".infractions WHERE id = $1 RETURNING id`,
      id
    );

    if (!deletedInfraction) {
      throw new Error('Infracción no encontrada');
    }

    return { message: 'Infracción eliminada exitosamente' };
  }

  async getStats(tenantId: string, userId?: string) {
    let query = `SELECT
      COUNT(*) as total,
      COUNT(CASE WHEN status = 'pendiente' THEN 1 END) as pendientes,
      COUNT(CASE WHEN status = 'pagada' THEN 1 END) as pagadas,
      COUNT(CASE WHEN status = 'anulada' THEN 1 END) as anuladas,
      COALESCE(SUM(CASE WHEN status = 'pendiente' THEN amount ELSE 0 END), 0) as monto_pendiente,
      COALESCE(SUM(CASE WHEN status = 'pagada' THEN amount ELSE 0 END), 0) as monto_pagado
      FROM "${tenantId}".infractions
      WHERE 1=1`;

    const params: any[] = [];
    if (userId) {
      query += ` AND user_id = $1`;
      params.push(userId);
    }

    const [stats] = await prisma.$queryRawUnsafe<any[]>(query, ...params);
    return stats;
  }
}
