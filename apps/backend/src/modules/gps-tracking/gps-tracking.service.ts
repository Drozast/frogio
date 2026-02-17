import prisma from '../../config/database.js';
import {
  GpsBatchDto,
  LiveVehiclePosition,
  GpsHistoryQuery,
  GpsStats,
  RouteHistory,
} from './gps-tracking.types.js';

export class GpsTrackingService {
  // Insert batch of GPS points
  async insertBatch(
    tenantId: string,
    inspectorId: string,
    batch: GpsBatchDto
  ): Promise<{ inserted: number; vehicleLogId: string | null }> {
    const { vehicleId, vehicleLogId, points } = batch;

    if (points.length === 0) {
      return { inserted: 0, vehicleLogId: vehicleLogId || null };
    }

    // Build values for batch insert
    const values = points.map((_, idx) => {
      const paramOffset = idx * 10;
      return `($${paramOffset + 1}, $${paramOffset + 2}, $${paramOffset + 3}, $${paramOffset + 4}, $${paramOffset + 5}, $${paramOffset + 6}, $${paramOffset + 7}, $${paramOffset + 8}, $${paramOffset + 9}, $${paramOffset + 10})`;
    }).join(', ');

    const params: (string | number | null)[] = [];
    points.forEach(p => {
      params.push(
        vehicleId,
        vehicleLogId || null,
        inspectorId,
        p.latitude,
        p.longitude,
        p.altitude ?? null,
        p.speed ?? null,
        p.heading ?? null,
        p.accuracy ?? null,
        p.recordedAt
      );
    });

    const query = `
      INSERT INTO "${tenantId}".vehicle_gps_points
        (vehicle_id, vehicle_log_id, inspector_id, latitude, longitude, altitude, speed, heading, accuracy, recorded_at)
      VALUES ${values}
      RETURNING id
    `;

    const result = await prisma.$queryRawUnsafe<{ id: string }[]>(query, ...params);

    // Update vehicle_log with latest stats if we have a log
    if (vehicleLogId && points.length > 0) {
      await this.updateVehicleLogStats(tenantId, vehicleLogId);
    }

    return { inserted: result.length, vehicleLogId: vehicleLogId || null };
  }

  // Update vehicle log stats (distance, avg speed, max speed)
  private async updateVehicleLogStats(tenantId: string, vehicleLogId: string): Promise<void> {
    const query = `
      WITH stats AS (
        SELECT
          COALESCE(MAX(speed), 0) as max_speed,
          COALESCE(AVG(speed) FILTER (WHERE speed > 0), 0) as avg_speed
        FROM "${tenantId}".vehicle_gps_points
        WHERE vehicle_log_id = $1::uuid
      ),
      distance AS (
        SELECT SUM(
          CASE
            WHEN prev_lat IS NOT NULL THEN
              6371 * 2 * ASIN(SQRT(
                POWER(SIN(RADIANS(latitude - prev_lat) / 2), 2) +
                COS(RADIANS(prev_lat)) * COS(RADIANS(latitude)) *
                POWER(SIN(RADIANS(longitude - prev_lng) / 2), 2)
              ))
            ELSE 0
          END
        ) as total_km
        FROM (
          SELECT
            latitude, longitude,
            LAG(latitude) OVER (ORDER BY recorded_at) as prev_lat,
            LAG(longitude) OVER (ORDER BY recorded_at) as prev_lng
          FROM "${tenantId}".vehicle_gps_points
          WHERE vehicle_log_id = $1::uuid
          ORDER BY recorded_at
        ) points
      )
      UPDATE "${tenantId}".vehicle_logs
      SET
        max_speed = stats.max_speed,
        avg_speed = stats.avg_speed,
        total_distance_km = distance.total_km
      FROM stats, distance
      WHERE id = $1::uuid
    `;

    await prisma.$queryRawUnsafe(query, vehicleLogId);
  }

  // Get live positions of all active vehicles
  async getLivePositions(tenantId: string): Promise<LiveVehiclePosition[]> {
    const query = `
      SELECT DISTINCT ON (vl.vehicle_id)
        vl.vehicle_id as "vehicleId",
        v.plate as "vehiclePlate",
        v.brand as "vehicleBrand",
        v.model as "vehicleModel",
        vl.driver_id as "inspectorId",
        u.first_name || ' ' || u.last_name as "inspectorName",
        gps.latitude,
        gps.longitude,
        gps.speed,
        gps.heading,
        gps.recorded_at as "lastUpdate",
        vl.id as "vehicleLogId",
        vl.start_time as "startTime",
        CASE
          WHEN gps.speed > 5 THEN 'moving'
          WHEN gps.speed > 0 THEN 'slow'
          ELSE 'stopped'
        END as status
      FROM "${tenantId}".vehicle_logs vl
      JOIN "${tenantId}".vehicles v ON vl.vehicle_id = v.id
      JOIN "${tenantId}".users u ON vl.driver_id = u.id
      LEFT JOIN LATERAL (
        SELECT latitude, longitude, speed, heading, recorded_at
        FROM "${tenantId}".vehicle_gps_points
        WHERE vehicle_id = vl.vehicle_id
        ORDER BY recorded_at DESC
        LIMIT 1
      ) gps ON true
      WHERE vl.status = 'active'
      ORDER BY vl.vehicle_id, gps.recorded_at DESC NULLS LAST
    `;

    const results = await prisma.$queryRawUnsafe<LiveVehiclePosition[]>(query);
    return results.filter(r => r.latitude !== null);
  }

  // Get latest position of a specific vehicle
  async getVehiclePosition(tenantId: string, vehicleId: string): Promise<LiveVehiclePosition | null> {
    const positions = await this.getLivePositions(tenantId);
    return positions.find(p => p.vehicleId === vehicleId) || null;
  }

  // Get route history for a vehicle log
  async getRouteHistory(
    tenantId: string,
    vehicleLogId: string
  ): Promise<RouteHistory | null> {
    // Get vehicle log info
    const logQuery = `
      SELECT
        vl.id as "vehicleLogId",
        vl.vehicle_id as "vehicleId",
        v.plate as "vehiclePlate",
        vl.driver_id as "inspectorId",
        u.first_name || ' ' || u.last_name as "inspectorName",
        vl.start_time as "startTime",
        vl.end_time as "endTime",
        COALESCE(vl.total_distance_km, 0) as "totalKm",
        COALESCE(vl.avg_speed, 0) as "avgSpeed",
        COALESCE(vl.max_speed, 0) as "maxSpeed"
      FROM "${tenantId}".vehicle_logs vl
      JOIN "${tenantId}".vehicles v ON vl.vehicle_id = v.id
      JOIN "${tenantId}".users u ON vl.driver_id = u.id
      WHERE vl.id = $1::uuid
    `;

    const logs = await prisma.$queryRawUnsafe<RouteHistory[]>(logQuery, vehicleLogId);
    if (logs.length === 0) return null;

    const log = logs[0];

    // Get GPS points
    const pointsQuery = `
      SELECT
        latitude, longitude, speed, recorded_at as "recordedAt"
      FROM "${tenantId}".vehicle_gps_points
      WHERE vehicle_log_id = $1::uuid
      ORDER BY recorded_at ASC
    `;

    const points = await prisma.$queryRawUnsafe<Array<{
      latitude: number;
      longitude: number;
      speed: number | null;
      recordedAt: Date;
    }>>(pointsQuery, vehicleLogId);

    return {
      ...log,
      points: points.map(p => ({
        ...p,
        recordedAt: p.recordedAt.toISOString(),
      })),
    };
  }

  // Get route history by date range
  async getRoutesByDateRange(
    tenantId: string,
    query: GpsHistoryQuery
  ): Promise<RouteHistory[]> {
    const { vehicleId, startDate, endDate } = query;

    const logsQuery = `
      SELECT
        vl.id as "vehicleLogId",
        vl.vehicle_id as "vehicleId",
        v.plate as "vehiclePlate",
        vl.driver_id as "inspectorId",
        u.first_name || ' ' || u.last_name as "inspectorName",
        vl.start_time as "startTime",
        vl.end_time as "endTime",
        COALESCE(vl.total_distance_km, 0) as "totalKm",
        COALESCE(vl.avg_speed, 0) as "avgSpeed",
        COALESCE(vl.max_speed, 0) as "maxSpeed"
      FROM "${tenantId}".vehicle_logs vl
      JOIN "${tenantId}".vehicles v ON vl.vehicle_id = v.id
      JOIN "${tenantId}".users u ON vl.driver_id = u.id
      WHERE vl.vehicle_id = $1::uuid
        AND vl.start_time >= $2::timestamptz
        AND vl.start_time <= $3::timestamptz
      ORDER BY vl.start_time DESC
    `;

    const logs = await prisma.$queryRawUnsafe<RouteHistory[]>(
      logsQuery,
      vehicleId,
      startDate,
      endDate
    );

    // For each log, fetch its points
    const results: RouteHistory[] = [];
    for (const log of logs) {
      const route = await this.getRouteHistory(tenantId, log.vehicleLogId);
      if (route) {
        results.push(route);
      }
    }

    return results;
  }

  // Get GPS statistics
  async getStats(
    tenantId: string,
    startDate?: string,
    endDate?: string
  ): Promise<GpsStats> {
    const hasDateFilter = startDate && endDate;
    const dateFilterClause = hasDateFilter ? 'AND vl.start_time >= $1 AND vl.start_time <= $2' : '';
    const dateParams = hasDateFilter ? [startDate, endDate] : [];

    // Overall stats
    const overallQuery = `
      SELECT
        COALESCE(SUM(total_distance_km), 0) as "totalKm",
        COUNT(*) as "totalTrips",
        COALESCE(AVG(avg_speed) FILTER (WHERE avg_speed > 0), 0) as "avgSpeed",
        COALESCE(MAX(max_speed), 0) as "maxSpeed",
        COALESCE(SUM(EXTRACT(EPOCH FROM (COALESCE(end_time, NOW()) - start_time)) / 60), 0) as "totalDuration"
      FROM "${tenantId}".vehicle_logs vl
      WHERE status IN ('active', 'completed')
      ${dateFilterClause}
    `;

    const overall = await prisma.$queryRawUnsafe<Array<{
      totalKm: number;
      totalTrips: string;
      avgSpeed: number;
      maxSpeed: number;
      totalDuration: number;
    }>>(overallQuery, ...dateParams);

    // By vehicle
    const byVehicleQuery = `
      SELECT
        v.id as "vehicleId",
        v.plate as "vehiclePlate",
        COALESCE(SUM(vl.total_distance_km), 0) as "totalKm",
        COUNT(*) as "totalTrips"
      FROM "${tenantId}".vehicle_logs vl
      JOIN "${tenantId}".vehicles v ON vl.vehicle_id = v.id
      WHERE vl.status IN ('active', 'completed')
      ${dateFilterClause}
      GROUP BY v.id, v.plate
      ORDER BY "totalKm" DESC
    `;

    const byVehicle = await prisma.$queryRawUnsafe<Array<{
      vehicleId: string;
      vehiclePlate: string;
      totalKm: number;
      totalTrips: string;
    }>>(byVehicleQuery, ...dateParams);

    // By inspector
    const byInspectorQuery = `
      SELECT
        u.id as "inspectorId",
        u.first_name || ' ' || u.last_name as "inspectorName",
        COALESCE(SUM(vl.total_distance_km), 0) as "totalKm",
        COUNT(*) as "totalTrips"
      FROM "${tenantId}".vehicle_logs vl
      JOIN "${tenantId}".users u ON vl.driver_id = u.id
      WHERE vl.status IN ('active', 'completed')
      ${dateFilterClause}
      GROUP BY u.id, u.first_name, u.last_name
      ORDER BY "totalKm" DESC
    `;

    const byInspector = await prisma.$queryRawUnsafe<Array<{
      inspectorId: string;
      inspectorName: string;
      totalKm: number;
      totalTrips: string;
    }>>(byInspectorQuery, ...dateParams);

    const o = overall[0];
    return {
      totalKm: Number(o.totalKm),
      totalTrips: Number(o.totalTrips),
      avgSpeed: Number(o.avgSpeed),
      maxSpeed: Number(o.maxSpeed),
      totalDuration: Number(o.totalDuration),
      byVehicle: byVehicle.map(v => ({
        ...v,
        totalKm: Number(v.totalKm),
        totalTrips: Number(v.totalTrips),
      })),
      byInspector: byInspector.map(i => ({
        ...i,
        totalKm: Number(i.totalKm),
        totalTrips: Number(i.totalTrips),
      })),
    };
  }

  // Get days with activity for a vehicle in a date range (for calendar highlighting)
  async getActivityDays(
    tenantId: string,
    vehicleId: string,
    year: number,
    month: number
  ): Promise<{ dates: string[]; activityByDate: Record<string, { trips: number; totalKm: number }> }> {
    // Build date range for the month
    const startDate = new Date(year, month - 1, 1);
    const endDate = new Date(year, month, 0, 23, 59, 59);

    const query = `
      SELECT
        DATE(vl.start_time AT TIME ZONE 'America/Santiago') as activity_date,
        COUNT(*) as trips,
        COALESCE(SUM(vl.total_distance_km), 0) as total_km
      FROM "${tenantId}".vehicle_logs vl
      WHERE vl.vehicle_id = $1::uuid
        AND vl.start_time >= $2::timestamptz
        AND vl.start_time <= $3::timestamptz
        AND vl.status IN ('active', 'completed')
      GROUP BY DATE(vl.start_time AT TIME ZONE 'America/Santiago')
      ORDER BY activity_date
    `;

    const results = await prisma.$queryRawUnsafe<Array<{
      activity_date: Date;
      trips: string;
      total_km: number;
    }>>(query, vehicleId, startDate.toISOString(), endDate.toISOString());

    const dates: string[] = [];
    const activityByDate: Record<string, { trips: number; totalKm: number }> = {};

    for (const row of results) {
      const dateStr = row.activity_date.toISOString().split('T')[0];
      dates.push(dateStr);
      activityByDate[dateStr] = {
        trips: Number(row.trips),
        totalKm: Number(row.total_km),
      };
    }

    return { dates, activityByDate };
  }

  // Delete old GPS points (for cleanup)
  async cleanupOldPoints(tenantId: string, daysToKeep: number = 90): Promise<number> {
    // Validate daysToKeep is a positive integer to prevent injection
    const safeDays = Math.max(1, Math.floor(Number(daysToKeep) || 90));

    const query = `
      DELETE FROM "${tenantId}".vehicle_gps_points
      WHERE recorded_at < NOW() - INTERVAL '1 day' * $1
      RETURNING id
    `;

    const result = await prisma.$queryRawUnsafe<{ id: string }[]>(query, safeDays);
    return result.length;
  }
}
