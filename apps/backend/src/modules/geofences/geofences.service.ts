import { PrismaClient } from '@prisma/client';
import {
  CreateGeofenceDto,
  UpdateGeofenceDto,
  Geofence,
  GeofenceEvent,
  GeofenceCheckResult,
} from './geofences.types';

const prisma = new PrismaClient();

export class GeofencesService {
  // Create a new geofence
  async create(tenantId: string, data: CreateGeofenceDto): Promise<Geofence> {
    const {
      name,
      description,
      geofenceType,
      centerLat,
      centerLng,
      radiusMeters,
      polygonCoordinates,
      isActive = true,
      alertOnEnter = true,
      alertOnExit = true,
    } = data;

    // Validate based on type
    if (geofenceType === 'circle') {
      if (!centerLat || !centerLng || !radiusMeters) {
        throw new Error('Circle geofence requires centerLat, centerLng, and radiusMeters');
      }
    } else if (geofenceType === 'polygon') {
      if (!polygonCoordinates || polygonCoordinates.length < 3) {
        throw new Error('Polygon geofence requires at least 3 coordinates');
      }
    }

    const query = `
      INSERT INTO "${tenantId}".geofences
        (name, description, geofence_type, center_lat, center_lng, radius_meters, polygon_coordinates, is_active, alert_on_enter, alert_on_exit)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
      RETURNING
        id, name, description,
        geofence_type as "geofenceType",
        center_lat as "centerLat",
        center_lng as "centerLng",
        radius_meters as "radiusMeters",
        polygon_coordinates as "polygonCoordinates",
        is_active as "isActive",
        alert_on_enter as "alertOnEnter",
        alert_on_exit as "alertOnExit",
        created_at as "createdAt",
        updated_at as "updatedAt"
    `;

    const result = await prisma.$queryRawUnsafe<Geofence[]>(
      query,
      name,
      description || null,
      geofenceType,
      centerLat || null,
      centerLng || null,
      radiusMeters || null,
      polygonCoordinates ? JSON.stringify(polygonCoordinates) : null,
      isActive,
      alertOnEnter,
      alertOnExit
    );

    return result[0];
  }

  // Get all geofences
  async findAll(tenantId: string, activeOnly: boolean = false): Promise<Geofence[]> {
    const whereClause = activeOnly ? 'WHERE is_active = true' : '';

    const query = `
      SELECT
        id, name, description,
        geofence_type as "geofenceType",
        center_lat as "centerLat",
        center_lng as "centerLng",
        radius_meters as "radiusMeters",
        polygon_coordinates as "polygonCoordinates",
        is_active as "isActive",
        alert_on_enter as "alertOnEnter",
        alert_on_exit as "alertOnExit",
        created_at as "createdAt",
        updated_at as "updatedAt"
      FROM "${tenantId}".geofences
      ${whereClause}
      ORDER BY name ASC
    `;

    return prisma.$queryRawUnsafe<Geofence[]>(query);
  }

  // Get geofence by ID
  async findById(tenantId: string, id: string): Promise<Geofence | null> {
    const query = `
      SELECT
        id, name, description,
        geofence_type as "geofenceType",
        center_lat as "centerLat",
        center_lng as "centerLng",
        radius_meters as "radiusMeters",
        polygon_coordinates as "polygonCoordinates",
        is_active as "isActive",
        alert_on_enter as "alertOnEnter",
        alert_on_exit as "alertOnExit",
        created_at as "createdAt",
        updated_at as "updatedAt"
      FROM "${tenantId}".geofences
      WHERE id = $1::uuid
    `;

    const result = await prisma.$queryRawUnsafe<Geofence[]>(query, id);
    return result[0] || null;
  }

  // Update geofence
  async update(tenantId: string, id: string, data: UpdateGeofenceDto): Promise<Geofence | null> {
    const existing = await this.findById(tenantId, id);
    if (!existing) return null;

    const updates: string[] = [];
    const values: (string | number | boolean | null)[] = [];
    let paramIndex = 1;

    if (data.name !== undefined) {
      updates.push(`name = $${paramIndex++}`);
      values.push(data.name);
    }
    if (data.description !== undefined) {
      updates.push(`description = $${paramIndex++}`);
      values.push(data.description);
    }
    if (data.geofenceType !== undefined) {
      updates.push(`geofence_type = $${paramIndex++}`);
      values.push(data.geofenceType);
    }
    if (data.centerLat !== undefined) {
      updates.push(`center_lat = $${paramIndex++}`);
      values.push(data.centerLat);
    }
    if (data.centerLng !== undefined) {
      updates.push(`center_lng = $${paramIndex++}`);
      values.push(data.centerLng);
    }
    if (data.radiusMeters !== undefined) {
      updates.push(`radius_meters = $${paramIndex++}`);
      values.push(data.radiusMeters);
    }
    if (data.polygonCoordinates !== undefined) {
      updates.push(`polygon_coordinates = $${paramIndex++}`);
      values.push(JSON.stringify(data.polygonCoordinates));
    }
    if (data.isActive !== undefined) {
      updates.push(`is_active = $${paramIndex++}`);
      values.push(data.isActive);
    }
    if (data.alertOnEnter !== undefined) {
      updates.push(`alert_on_enter = $${paramIndex++}`);
      values.push(data.alertOnEnter);
    }
    if (data.alertOnExit !== undefined) {
      updates.push(`alert_on_exit = $${paramIndex++}`);
      values.push(data.alertOnExit);
    }

    if (updates.length === 0) {
      return existing;
    }

    updates.push(`updated_at = NOW()`);
    values.push(id);

    const query = `
      UPDATE "${tenantId}".geofences
      SET ${updates.join(', ')}
      WHERE id = $${paramIndex}::uuid
      RETURNING
        id, name, description,
        geofence_type as "geofenceType",
        center_lat as "centerLat",
        center_lng as "centerLng",
        radius_meters as "radiusMeters",
        polygon_coordinates as "polygonCoordinates",
        is_active as "isActive",
        alert_on_enter as "alertOnEnter",
        alert_on_exit as "alertOnExit",
        created_at as "createdAt",
        updated_at as "updatedAt"
    `;

    const result = await prisma.$queryRawUnsafe<Geofence[]>(query, ...values);
    return result[0] || null;
  }

  // Delete geofence
  async delete(tenantId: string, id: string): Promise<boolean> {
    const query = `
      DELETE FROM "${tenantId}".geofences
      WHERE id = $1::uuid
      RETURNING id
    `;

    const result = await prisma.$queryRawUnsafe<{ id: string }[]>(query, id);
    return result.length > 0;
  }

  // Check if a point is inside any active geofence
  async checkPoint(
    tenantId: string,
    latitude: number,
    longitude: number
  ): Promise<GeofenceCheckResult[]> {
    const geofences = await this.findAll(tenantId, true);
    const results: GeofenceCheckResult[] = [];

    for (const geofence of geofences) {
      let isInside = false;

      if (geofence.geofenceType === 'circle') {
        isInside = this.isPointInCircle(
          latitude,
          longitude,
          geofence.centerLat!,
          geofence.centerLng!,
          geofence.radiusMeters!
        );
      } else if (geofence.geofenceType === 'polygon' && geofence.polygonCoordinates) {
        isInside = this.isPointInPolygon(latitude, longitude, geofence.polygonCoordinates);
      }

      results.push({
        geofenceId: geofence.id,
        geofenceName: geofence.name,
        isInside,
      });
    }

    return results;
  }

  // Record a geofence event
  async recordEvent(
    tenantId: string,
    geofenceId: string,
    vehicleId: string,
    inspectorId: string,
    eventType: 'enter' | 'exit',
    latitude: number,
    longitude: number
  ): Promise<void> {
    const query = `
      INSERT INTO "${tenantId}".geofence_events
        (geofence_id, vehicle_id, inspector_id, event_type, latitude, longitude, recorded_at)
      VALUES ($1::uuid, $2::uuid, $3::uuid, $4, $5, $6, NOW())
    `;

    await prisma.$queryRawUnsafe(
      query,
      geofenceId,
      vehicleId,
      inspectorId,
      eventType,
      latitude,
      longitude
    );
  }

  // Get recent geofence events
  async getRecentEvents(
    tenantId: string,
    limit: number = 50
  ): Promise<GeofenceEvent[]> {
    const query = `
      SELECT
        ge.id,
        ge.geofence_id as "geofenceId",
        g.name as "geofenceName",
        ge.vehicle_id as "vehicleId",
        v.plate as "vehiclePlate",
        ge.inspector_id as "inspectorId",
        u.first_name || ' ' || u.last_name as "inspectorName",
        ge.event_type as "eventType",
        ge.latitude,
        ge.longitude,
        ge.recorded_at as "recordedAt",
        ge.created_at as "createdAt"
      FROM "${tenantId}".geofence_events ge
      JOIN "${tenantId}".geofences g ON ge.geofence_id = g.id
      JOIN "${tenantId}".vehicles v ON ge.vehicle_id = v.id
      JOIN "${tenantId}".users u ON ge.inspector_id = u.id
      ORDER BY ge.recorded_at DESC
      LIMIT $1
    `;

    return prisma.$queryRawUnsafe<GeofenceEvent[]>(query, limit);
  }

  // Get events for a specific geofence
  async getGeofenceEvents(
    tenantId: string,
    geofenceId: string,
    limit: number = 100
  ): Promise<GeofenceEvent[]> {
    const query = `
      SELECT
        ge.id,
        ge.geofence_id as "geofenceId",
        g.name as "geofenceName",
        ge.vehicle_id as "vehicleId",
        v.plate as "vehiclePlate",
        ge.inspector_id as "inspectorId",
        u.first_name || ' ' || u.last_name as "inspectorName",
        ge.event_type as "eventType",
        ge.latitude,
        ge.longitude,
        ge.recorded_at as "recordedAt",
        ge.created_at as "createdAt"
      FROM "${tenantId}".geofence_events ge
      JOIN "${tenantId}".geofences g ON ge.geofence_id = g.id
      JOIN "${tenantId}".vehicles v ON ge.vehicle_id = v.id
      JOIN "${tenantId}".users u ON ge.inspector_id = u.id
      WHERE ge.geofence_id = $1::uuid
      ORDER BY ge.recorded_at DESC
      LIMIT $2
    `;

    return prisma.$queryRawUnsafe<GeofenceEvent[]>(query, geofenceId, limit);
  }

  // Helper: Check if point is in circle
  private isPointInCircle(
    lat: number,
    lng: number,
    centerLat: number,
    centerLng: number,
    radiusMeters: number
  ): boolean {
    const R = 6371000; // Earth radius in meters
    const dLat = this.toRad(lat - centerLat);
    const dLng = this.toRad(lng - centerLng);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.toRad(centerLat)) *
        Math.cos(this.toRad(lat)) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    const distance = R * c;
    return distance <= radiusMeters;
  }

  // Helper: Check if point is in polygon (Ray casting algorithm)
  private isPointInPolygon(
    lat: number,
    lng: number,
    polygon: [number, number][]
  ): boolean {
    let inside = false;
    const n = polygon.length;

    for (let i = 0, j = n - 1; i < n; j = i++) {
      const [xi, yi] = polygon[i];
      const [xj, yj] = polygon[j];

      if (
        yi > lng !== yj > lng &&
        lat < ((xj - xi) * (lng - yi)) / (yj - yi) + xi
      ) {
        inside = !inside;
      }
    }

    return inside;
  }

  private toRad(deg: number): number {
    return (deg * Math.PI) / 180;
  }
}
