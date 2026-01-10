import prisma from '../../config/database.js';
import type { CreateTripLogDto, EndTripLogDto, CreateTripEntryDto, TripLogFilters } from './trip-logs.types.js';

export class TripLogsService {
  async create(data: CreateTripLogDto, inspectorId: string, tenantId: string) {
    // Check if inspector has an active trip
    const [activeTrip] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT id FROM "${tenantId}".trip_logs WHERE inspector_id = $1 AND status = 'active' LIMIT 1`,
      inspectorId
    );

    if (activeTrip) {
      throw new Error('Ya tienes un viaje activo. Finalízalo antes de iniciar uno nuevo.');
    }

    const [trip] = await prisma.$queryRawUnsafe<any[]>(
      `INSERT INTO "${tenantId}".trip_logs
       (inspector_id, vehicle_id, title, description, purpose, start_location_lat, start_location_lng, start_address, start_km, status, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'active', NOW(), NOW())
       RETURNING *`,
      inspectorId,
      data.vehicleId || null,
      data.title,
      data.description || null,
      data.purpose || null,
      data.startLocationLat || null,
      data.startLocationLng || null,
      data.startAddress || null,
      data.startKm || null
    );

    return trip;
  }

  async findAll(tenantId: string, filters?: TripLogFilters) {
    let query = `SELECT tl.*,
                 u.first_name as inspector_first_name, u.last_name as inspector_last_name,
                 v.plate as vehicle_plate, v.brand as vehicle_brand, v.model as vehicle_model
                 FROM "${tenantId}".trip_logs tl
                 LEFT JOIN "${tenantId}".users u ON tl.inspector_id = u.id
                 LEFT JOIN "${tenantId}".vehicles v ON tl.vehicle_id = v.id
                 WHERE 1=1`;

    const params: any[] = [];
    let paramIndex = 1;

    if (filters?.inspectorId) {
      query += ` AND tl.inspector_id = $${paramIndex}`;
      params.push(filters.inspectorId);
      paramIndex++;
    }

    if (filters?.vehicleId) {
      query += ` AND tl.vehicle_id = $${paramIndex}`;
      params.push(filters.vehicleId);
      paramIndex++;
    }

    if (filters?.status) {
      query += ` AND tl.status = $${paramIndex}`;
      params.push(filters.status);
      paramIndex++;
    }

    query += ` ORDER BY tl.start_time DESC LIMIT 100`;

    const trips = await prisma.$queryRawUnsafe<any[]>(query, ...params);
    return trips;
  }

  async findById(id: string, tenantId: string) {
    const [trip] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT tl.*,
       u.first_name as inspector_first_name, u.last_name as inspector_last_name, u.phone as inspector_phone,
       v.plate as vehicle_plate, v.brand as vehicle_brand, v.model as vehicle_model
       FROM "${tenantId}".trip_logs tl
       LEFT JOIN "${tenantId}".users u ON tl.inspector_id = u.id
       LEFT JOIN "${tenantId}".vehicles v ON tl.vehicle_id = v.id
       WHERE tl.id = $1`,
      id
    );

    if (!trip) {
      throw new Error('Bitácora no encontrada');
    }

    // Get entries
    const entries = await prisma.$queryRawUnsafe<any[]>(
      `SELECT * FROM "${tenantId}".trip_log_entries WHERE trip_id = $1 ORDER BY created_at ASC`,
      id
    );

    return { ...trip, entries };
  }

  async findMyActive(inspectorId: string, tenantId: string) {
    const [trip] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT tl.*,
       v.plate as vehicle_plate, v.brand as vehicle_brand, v.model as vehicle_model
       FROM "${tenantId}".trip_logs tl
       LEFT JOIN "${tenantId}".vehicles v ON tl.vehicle_id = v.id
       WHERE tl.inspector_id = $1 AND tl.status = 'active'
       LIMIT 1`,
      inspectorId
    );

    if (!trip) {
      return null;
    }

    // Get entries
    const entries = await prisma.$queryRawUnsafe<any[]>(
      `SELECT * FROM "${tenantId}".trip_log_entries WHERE trip_id = $1 ORDER BY created_at ASC`,
      trip.id
    );

    return { ...trip, entries };
  }

  async endTrip(id: string, data: EndTripLogDto, inspectorId: string, tenantId: string) {
    const [trip] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".trip_logs
       SET status = 'completed',
           end_time = NOW(),
           end_location_lat = $1,
           end_location_lng = $2,
           end_address = $3,
           end_km = $4,
           notes = $5,
           updated_at = NOW()
       WHERE id = $6 AND inspector_id = $7 AND status = 'active'
       RETURNING *`,
      data.endLocationLat || null,
      data.endLocationLng || null,
      data.endAddress || null,
      data.endKm || null,
      data.notes || null,
      id,
      inspectorId
    );

    if (!trip) {
      throw new Error('Bitácora no encontrada o no puedes finalizarla');
    }

    return trip;
  }

  async cancelTrip(id: string, inspectorId: string, tenantId: string) {
    const [trip] = await prisma.$queryRawUnsafe<any[]>(
      `UPDATE "${tenantId}".trip_logs
       SET status = 'cancelled', updated_at = NOW()
       WHERE id = $1 AND inspector_id = $2 AND status = 'active'
       RETURNING *`,
      id,
      inspectorId
    );

    if (!trip) {
      throw new Error('Bitácora no encontrada o no puedes cancelarla');
    }

    return trip;
  }

  async addEntry(tripId: string, data: CreateTripEntryDto, inspectorId: string, tenantId: string) {
    // Verify trip belongs to inspector and is active
    const [trip] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT id FROM "${tenantId}".trip_logs WHERE id = $1 AND inspector_id = $2 AND status = 'active'`,
      tripId,
      inspectorId
    );

    if (!trip) {
      throw new Error('Bitácora no encontrada o no está activa');
    }

    const [entry] = await prisma.$queryRawUnsafe<any[]>(
      `INSERT INTO "${tenantId}".trip_log_entries
       (trip_id, entry_type, latitude, longitude, address, description, linked_report_id, linked_infraction_id, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, NOW())
       RETURNING *`,
      tripId,
      data.entryType,
      data.latitude || null,
      data.longitude || null,
      data.address || null,
      data.description,
      data.linkedReportId || null,
      data.linkedInfractionId || null
    );

    return entry;
  }

  async getStats(tenantId: string, inspectorId?: string) {
    let query = `SELECT
      COUNT(*) as total,
      COUNT(*) FILTER (WHERE status = 'active') as active,
      COUNT(*) FILTER (WHERE status = 'completed') as completed,
      COUNT(*) FILTER (WHERE start_time >= NOW() - INTERVAL '7 days') as last_7d,
      COUNT(*) FILTER (WHERE start_time >= NOW() - INTERVAL '30 days') as last_30d,
      COALESCE(SUM(end_km - start_km) FILTER (WHERE status = 'completed' AND end_km IS NOT NULL AND start_km IS NOT NULL), 0) as total_km
      FROM "${tenantId}".trip_logs`;

    const params: any[] = [];

    if (inspectorId) {
      query += ` WHERE inspector_id = $1`;
      params.push(inspectorId);
    }

    const [stats] = await prisma.$queryRawUnsafe<any[]>(query, ...params);

    return {
      total: parseInt(stats?.total || '0'),
      active: parseInt(stats?.active || '0'),
      completed: parseInt(stats?.completed || '0'),
      last7d: parseInt(stats?.last_7d || '0'),
      last30d: parseInt(stats?.last_30d || '0'),
      totalKm: parseFloat(stats?.total_km || '0'),
    };
  }
}
