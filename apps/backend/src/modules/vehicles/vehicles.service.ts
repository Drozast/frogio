import prisma from '../../config/database.js';
import type { CreateVehicleDto, UpdateVehicleDto } from './vehicles.types.js';

export class VehiclesService {
  async create(data: CreateVehicleDto, tenantId: string) {
    // Check if plate already exists
    const [existing] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT id FROM "${tenantId}".vehicles WHERE plate = $1 LIMIT 1`,
      data.plate
    );

    if (existing) {
      throw new Error('Ya existe un vehículo registrado con esta patente');
    }

    const [vehicle] = await prisma.$queryRawUnsafe<any[]>(
      `INSERT INTO "${tenantId}".vehicles
       (owner_id, plate, brand, model, year, color, vehicle_type, vin, is_active, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, NOW(), NOW())
       RETURNING *`,
      data.ownerId,
      data.plate.toUpperCase(),
      data.brand || null,
      data.model || null,
      data.year || null,
      data.color || null,
      data.vehicleType || null,
      data.vin || null,
      true
    );

    return vehicle;
  }

  async findAll(tenantId: string, filters?: { ownerId?: string; isActive?: boolean }) {
    let query = `SELECT v.*,
                 u.first_name as owner_first_name, u.last_name as owner_last_name, u.email as owner_email, u.phone as owner_phone, u.rut as owner_rut
                 FROM "${tenantId}".vehicles v
                 LEFT JOIN "${tenantId}".users u ON v.owner_id = u.id
                 WHERE 1=1`;

    const params: any[] = [];
    let paramIndex = 1;

    if (filters?.ownerId) {
      query += ` AND v.owner_id = $${paramIndex}`;
      params.push(filters.ownerId);
      paramIndex++;
    }

    if (filters?.isActive !== undefined) {
      query += ` AND v.is_active = $${paramIndex}`;
      params.push(filters.isActive);
      paramIndex++;
    }

    query += ` ORDER BY v.created_at DESC`;

    const vehicles = await prisma.$queryRawUnsafe<any[]>(query, ...params);
    return vehicles;
  }

  async findById(id: string, tenantId: string) {
    const [vehicle] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT v.*,
       u.first_name as owner_first_name, u.last_name as owner_last_name, u.email as owner_email, u.phone as owner_phone, u.rut as owner_rut, u.address as owner_address
       FROM "${tenantId}".vehicles v
       LEFT JOIN "${tenantId}".users u ON v.owner_id = u.id
       WHERE v.id = $1 LIMIT 1`,
      id
    );

    if (!vehicle) {
      throw new Error('Vehículo no encontrado');
    }

    return vehicle;
  }

  async findByPlate(plate: string, tenantId: string) {
    const [vehicle] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT v.*,
       u.first_name as owner_first_name, u.last_name as owner_last_name, u.email as owner_email, u.phone as owner_phone, u.rut as owner_rut
       FROM "${tenantId}".vehicles v
       LEFT JOIN "${tenantId}".users u ON v.owner_id = u.id
       WHERE v.plate = $1 LIMIT 1`,
      plate.toUpperCase()
    );

    return vehicle || null;
  }

  async update(id: string, data: UpdateVehicleDto, tenantId: string) {
    const updates: string[] = [];
    const params: any[] = [];
    let paramIndex = 1;

    if (data.ownerId !== undefined) {
      updates.push(`owner_id = $${paramIndex}`);
      params.push(data.ownerId);
      paramIndex++;
    }

    if (data.brand !== undefined) {
      updates.push(`brand = $${paramIndex}`);
      params.push(data.brand);
      paramIndex++;
    }

    if (data.model !== undefined) {
      updates.push(`model = $${paramIndex}`);
      params.push(data.model);
      paramIndex++;
    }

    if (data.year !== undefined) {
      updates.push(`year = $${paramIndex}`);
      params.push(data.year);
      paramIndex++;
    }

    if (data.color !== undefined) {
      updates.push(`color = $${paramIndex}`);
      params.push(data.color);
      paramIndex++;
    }

    if (data.vehicleType !== undefined) {
      updates.push(`vehicle_type = $${paramIndex}`);
      params.push(data.vehicleType);
      paramIndex++;
    }

    if (data.vin !== undefined) {
      updates.push(`vin = $${paramIndex}`);
      params.push(data.vin);
      paramIndex++;
    }

    if (data.isActive !== undefined) {
      updates.push(`is_active = $${paramIndex}`);
      params.push(data.isActive);
      paramIndex++;
    }

    if (updates.length === 0) {
      throw new Error('No hay datos para actualizar');
    }

    updates.push(`updated_at = NOW()`);
    params.push(id);

    const [updatedVehicle] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".vehicles
       SET ${updates.join(', ')}
       WHERE id = $${paramIndex}
       RETURNING *`,
      ...params
    );

    if (!updatedVehicle) {
      throw new Error('Vehículo no encontrado');
    }

    return updatedVehicle;
  }

  async delete(id: string, tenantId: string) {
    const [deletedVehicle] = await prisma.$queryRawUnsafe<any[]>(
      `DELETE FROM "${tenantId}".vehicles WHERE id = $1 RETURNING id`,
      id
    );

    if (!deletedVehicle) {
      throw new Error('Vehículo no encontrado');
    }

    return { message: 'Vehículo eliminado exitosamente' };
  }
}
