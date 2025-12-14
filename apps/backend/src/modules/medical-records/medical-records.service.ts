import prisma from '../../config/database.js';
import type { CreateMedicalRecordDto, UpdateMedicalRecordDto } from './medical-records.types.js';

export class MedicalRecordsService {
  async create(data: CreateMedicalRecordDto, tenantId: string) {
    const [record] = await prisma.$queryRawUnsafe<any[]>(
      `INSERT INTO "${tenantId}".medical_records
       (household_head_id, address, family_members, chronic_conditions, allergies, medications, emergency_contact_name, emergency_contact_phone, notes, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
       RETURNING *`,
      data.householdHeadId,
      data.address,
      JSON.stringify(data.familyMembers),
      data.chronicConditions ? JSON.stringify(data.chronicConditions) : null,
      data.allergies ? JSON.stringify(data.allergies) : null,
      data.medications ? JSON.stringify(data.medications) : null,
      data.emergencyContactName || null,
      data.emergencyContactPhone || null,
      data.notes || null
    );

    return record;
  }

  async findAll(tenantId: string, householdHeadId?: string) {
    let query = `SELECT mr.*,
                 u.first_name as household_head_first_name, u.last_name as household_head_last_name, u.email as household_head_email, u.phone as household_head_phone
                 FROM "${tenantId}".medical_records mr
                 LEFT JOIN "${tenantId}".users u ON mr.household_head_id = u.id
                 WHERE 1=1`;

    const params: any[] = [];
    if (householdHeadId) {
      query += ` AND mr.household_head_id = $1`;
      params.push(householdHeadId);
    }

    query += ` ORDER BY mr.created_at DESC`;

    const records = await prisma.$queryRawUnsafe<any[]>(query, ...params);
    return records;
  }

  async findById(id: string, tenantId: string) {
    const [record] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT mr.*,
       u.first_name as household_head_first_name, u.last_name as household_head_last_name, u.email as household_head_email, u.phone as household_head_phone, u.rut as household_head_rut
       FROM "${tenantId}".medical_records mr
       LEFT JOIN "${tenantId}".users u ON mr.household_head_id = u.id
       WHERE mr.id = $1 LIMIT 1`,
      id
    );

    if (!record) {
      throw new Error('Ficha médica no encontrada');
    }

    return record;
  }

  async findByHouseholdHead(householdHeadId: string, tenantId: string) {
    const [record] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT mr.*,
       u.first_name as household_head_first_name, u.last_name as household_head_last_name, u.email as household_head_email, u.phone as household_head_phone
       FROM "${tenantId}".medical_records mr
       LEFT JOIN "${tenantId}".users u ON mr.household_head_id = u.id
       WHERE mr.household_head_id = $1
       ORDER BY mr.created_at DESC
       LIMIT 1`,
      householdHeadId
    );

    return record || null;
  }

  async update(id: string, data: UpdateMedicalRecordDto, tenantId: string) {
    const updates: string[] = [];
    const params: any[] = [];
    let paramIndex = 1;

    if (data.address !== undefined) {
      updates.push(`address = $${paramIndex}`);
      params.push(data.address);
      paramIndex++;
    }

    if (data.familyMembers !== undefined) {
      updates.push(`family_members = $${paramIndex}`);
      params.push(JSON.stringify(data.familyMembers));
      paramIndex++;
    }

    if (data.chronicConditions !== undefined) {
      updates.push(`chronic_conditions = $${paramIndex}`);
      params.push(JSON.stringify(data.chronicConditions));
      paramIndex++;
    }

    if (data.allergies !== undefined) {
      updates.push(`allergies = $${paramIndex}`);
      params.push(JSON.stringify(data.allergies));
      paramIndex++;
    }

    if (data.medications !== undefined) {
      updates.push(`medications = $${paramIndex}`);
      params.push(JSON.stringify(data.medications));
      paramIndex++;
    }

    if (data.emergencyContactName !== undefined) {
      updates.push(`emergency_contact_name = $${paramIndex}`);
      params.push(data.emergencyContactName);
      paramIndex++;
    }

    if (data.emergencyContactPhone !== undefined) {
      updates.push(`emergency_contact_phone = $${paramIndex}`);
      params.push(data.emergencyContactPhone);
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

    const [updatedRecord] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".medical_records
       SET ${updates.join(', ')}
       WHERE id = $${paramIndex}
       RETURNING *`,
      ...params
    );

    if (!updatedRecord) {
      throw new Error('Ficha médica no encontrada');
    }

    return updatedRecord;
  }

  async delete(id: string, tenantId: string) {
    const [deletedRecord] = await prisma.$queryRawUnsafe<any[]>(
      `DELETE FROM "${tenantId}".medical_records WHERE id = $1 RETURNING id`,
      id
    );

    if (!deletedRecord) {
      throw new Error('Ficha médica no encontrada');
    }

    return { message: 'Ficha médica eliminada exitosamente' };
  }
}
