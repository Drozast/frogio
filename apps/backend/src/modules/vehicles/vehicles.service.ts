import prisma from '../../config/database.js';
import type { CreateVehicleDto, UpdateVehicleDto, StartVehicleUsageDto, EndVehicleUsageDto } from './vehicles.types.js';

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
       (owner_id, plate, brand, model, year, color, vehicle_type, vin, is_active,
        ownership_type, vehicle_status, notes, insurance_expiry, technical_review_expiry, acquisition_date,
        created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, NOW(), NOW())
       RETURNING *`,
      data.ownerId,
      data.plate.toUpperCase(),
      data.brand || null,
      data.model || null,
      data.year || null,
      data.color || null,
      data.vehicleType || null,
      data.vin || null,
      true,
      data.ownershipType || 'propio',
      data.vehicleStatus || 'activo',
      data.notes || null,
      data.insuranceExpiry ? new Date(data.insuranceExpiry) : null,
      data.technicalReviewExpiry ? new Date(data.technicalReviewExpiry) : null,
      data.acquisitionDate ? new Date(data.acquisitionDate) : null
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

    if (data.ownershipType !== undefined) {
      updates.push(`ownership_type = $${paramIndex}`);
      params.push(data.ownershipType);
      paramIndex++;
    }

    if (data.vehicleStatus !== undefined) {
      updates.push(`vehicle_status = $${paramIndex}`);
      params.push(data.vehicleStatus);
      paramIndex++;
    }

    if (data.notes !== undefined) {
      updates.push(`notes = $${paramIndex}`);
      params.push(data.notes);
      paramIndex++;
    }

    if (data.insuranceExpiry !== undefined) {
      updates.push(`insurance_expiry = $${paramIndex}`);
      params.push(data.insuranceExpiry ? new Date(data.insuranceExpiry) : null);
      paramIndex++;
    }

    if (data.technicalReviewExpiry !== undefined) {
      updates.push(`technical_review_expiry = $${paramIndex}`);
      params.push(data.technicalReviewExpiry ? new Date(data.technicalReviewExpiry) : null);
      paramIndex++;
    }

    if (data.acquisitionDate !== undefined) {
      updates.push(`acquisition_date = $${paramIndex}`);
      params.push(data.acquisitionDate ? new Date(data.acquisitionDate) : null);
      paramIndex++;
    }

    if (data.disposalDate !== undefined) {
      updates.push(`disposal_date = $${paramIndex}`);
      params.push(data.disposalDate ? new Date(data.disposalDate) : null);
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

  // ===== VEHICLE LOGS =====

  async startVehicleUsage(data: StartVehicleUsageDto, tenantId: string) {
    // Check if vehicle exists
    const [vehicle] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT id, plate FROM "${tenantId}".vehicles WHERE id = $1 LIMIT 1`,
      data.vehicleId
    );

    if (!vehicle) {
      throw new Error('Vehículo no encontrado');
    }

    // Check if there's already an active log for this vehicle
    const [activeLog] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT id FROM "${tenantId}".vehicle_logs WHERE vehicle_id = $1 AND status = 'active' LIMIT 1`,
      data.vehicleId
    );

    if (activeLog) {
      throw new Error('Este vehículo ya tiene un uso activo. Debe finalizarlo primero.');
    }

    const [log] = await prisma.$queryRawUnsafe<any[]>(
      `INSERT INTO "${tenantId}".vehicle_logs
       (vehicle_id, driver_id, driver_name, usage_type, purpose, start_km, status, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, 'active', NOW(), NOW())
       RETURNING *`,
      data.vehicleId,
      data.driverId,
      data.driverName,
      data.usageType,
      data.purpose || null,
      data.startKm
    );

    return log;
  }

  async endVehicleUsage(logId: string, data: EndVehicleUsageDto, tenantId: string) {
    // Check if log exists and is active
    const [log] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT * FROM "${tenantId}".vehicle_logs WHERE id = $1 LIMIT 1`,
      logId
    );

    if (!log) {
      throw new Error('Registro de uso no encontrado');
    }

    if (log.status !== 'active') {
      throw new Error('Este registro de uso ya fue finalizado');
    }

    if (data.endKm < log.start_km) {
      throw new Error('El kilometraje final no puede ser menor al inicial');
    }

    const [updatedLog] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".vehicle_logs
       SET end_km = $1, end_time = NOW(), observations = $2, status = 'completed', updated_at = NOW()
       WHERE id = $3
       RETURNING *`,
      data.endKm,
      data.observations || null,
      logId
    );

    return updatedLog;
  }

  async getVehicleLogs(vehicleId: string, tenantId: string, limit: number = 50) {
    const logs = await prisma.$queryRawUnsafe<any[]>(
      `SELECT vl.*,
       v.plate, v.brand, v.model,
       u.first_name as driver_first_name, u.last_name as driver_last_name
       FROM "${tenantId}".vehicle_logs vl
       LEFT JOIN "${tenantId}".vehicles v ON vl.vehicle_id = v.id
       LEFT JOIN "${tenantId}".users u ON vl.driver_id = u.id
       WHERE vl.vehicle_id = $1
       ORDER BY vl.start_time DESC
       LIMIT $2`,
      vehicleId,
      limit
    );

    return logs;
  }

  async getLogsByDriver(driverId: string, tenantId: string, limit: number = 50) {
    const logs = await prisma.$queryRawUnsafe<any[]>(
      `SELECT vl.*,
       v.plate, v.brand, v.model
       FROM "${tenantId}".vehicle_logs vl
       LEFT JOIN "${tenantId}".vehicles v ON vl.vehicle_id = v.id
       WHERE vl.driver_id = $1
       ORDER BY vl.start_time DESC
       LIMIT $2`,
      driverId,
      limit
    );

    return logs;
  }

  async getActiveVehicleUsage(tenantId: string) {
    const logs = await prisma.$queryRawUnsafe<any[]>(
      `SELECT vl.*,
       v.plate, v.brand, v.model,
       u.first_name as driver_first_name, u.last_name as driver_last_name
       FROM "${tenantId}".vehicle_logs vl
       LEFT JOIN "${tenantId}".vehicles v ON vl.vehicle_id = v.id
       LEFT JOIN "${tenantId}".users u ON vl.driver_id = u.id
       WHERE vl.status = 'active'
       ORDER BY vl.start_time DESC`
    );

    return logs;
  }

  async getLogById(logId: string, tenantId: string) {
    const [log] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT vl.*,
       v.plate, v.brand, v.model,
       u.first_name as driver_first_name, u.last_name as driver_last_name
       FROM "${tenantId}".vehicle_logs vl
       LEFT JOIN "${tenantId}".vehicles v ON vl.vehicle_id = v.id
       LEFT JOIN "${tenantId}".users u ON vl.driver_id = u.id
       WHERE vl.id = $1 LIMIT 1`,
      logId
    );

    if (!log) {
      throw new Error('Registro de uso no encontrado');
    }

    return log;
  }

  async cancelVehicleUsage(logId: string, tenantId: string) {
    const [log] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".vehicle_logs
       SET status = 'cancelled', updated_at = NOW()
       WHERE id = $1 AND status = 'active'
       RETURNING *`,
      logId
    );

    if (!log) {
      throw new Error('Registro de uso no encontrado o ya finalizado');
    }

    return log;
  }

  // Get all logs with filters (for admin dashboard)
  async getAllLogs(
    tenantId: string,
    filters?: {
      vehicleId?: string;
      driverId?: string;
      startDate?: string;
      endDate?: string;
      status?: string;
    }
  ) {
    let query = `
      SELECT
        vl.id,
        vl.vehicle_id,
        v.plate as vehicle_plate,
        v.brand as vehicle_brand,
        v.model as vehicle_model,
        vl.driver_id,
        vl.driver_name,
        vl.usage_type,
        vl.purpose,
        vl.start_km,
        vl.end_km,
        vl.start_time,
        vl.end_time,
        vl.observations,
        vl.status,
        vl.total_distance_km,
        vl.created_at
      FROM "${tenantId}".vehicle_logs vl
      LEFT JOIN "${tenantId}".vehicles v ON vl.vehicle_id::uuid = v.id::uuid
      WHERE 1=1
    `;

    const params: (string | Date)[] = [];
    let paramIndex = 1;

    if (filters?.vehicleId) {
      query += ` AND vl.vehicle_id = $${paramIndex}::uuid`;
      params.push(filters.vehicleId);
      paramIndex++;
    }

    if (filters?.driverId) {
      query += ` AND vl.driver_id = $${paramIndex}::uuid`;
      params.push(filters.driverId);
      paramIndex++;
    }

    if (filters?.startDate) {
      query += ` AND vl.start_time >= $${paramIndex}`;
      params.push(new Date(filters.startDate));
      paramIndex++;
    }

    if (filters?.endDate) {
      query += ` AND vl.start_time <= $${paramIndex}`;
      params.push(new Date(filters.endDate + 'T23:59:59'));
      paramIndex++;
    }

    if (filters?.status) {
      query += ` AND vl.status = $${paramIndex}`;
      params.push(filters.status);
      paramIndex++;
    }

    query += ` ORDER BY vl.start_time DESC LIMIT 500`;

    console.log('📋 getAllLogs query:', query);
    console.log('📋 getAllLogs params:', params);

    const logs = await prisma.$queryRawUnsafe<unknown[]>(query, ...params);
    return logs;
  }
}
