import bcrypt from 'bcryptjs';
import prisma from '../../config/database.js';
import { logger } from '../../config/logger.js';

export interface ImportResult {
  inserted: number;
  failed: number;
  errors: string[];
}

const MAX_ERRORS = 50;

/**
 * Normalize a value to a string or null.
 */
function str(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  const s = String(value).trim();
  return s.length === 0 ? null : s;
}

/**
 * Parse a date that may come as ISO string, null/undefined or empty.
 * Returns Date or null.
 */
function parseDate(value: unknown): Date | null {
  const s = str(value);
  if (!s) return null;
  const d = new Date(s);
  if (isNaN(d.getTime())) return null;
  return d;
}

function parseInteger(value: unknown): number | null {
  const s = str(value);
  if (!s) return null;
  const n = parseInt(s, 10);
  return isNaN(n) ? null : n;
}

function pushError(errors: string[], index: number, err: unknown) {
  if (errors.length >= MAX_ERRORS) return;
  const message = err instanceof Error ? err.message : String(err);
  errors.push(`Fila ${index + 1}: ${message}`);
}

export class AdminImportsService {
  // ============================================================
  // CITATIONS (court_citations)
  // ============================================================
  // CSV headers: number, target_name, target_rut, target_address,
  //              reason, citation_type, created_at
  async importCitations(
    rows: Record<string, unknown>[],
    tenantId: string,
    adminUserId: string
  ): Promise<ImportResult> {
    const result: ImportResult = { inserted: 0, failed: 0, errors: [] };

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i] || {};
      try {
        const number = str(row.number) || str(row.citation_number);
        const targetName = str(row.target_name);
        const targetRut = str(row.target_rut);
        const targetAddress = str(row.target_address);
        const reason = str(row.reason);
        const citationType = str(row.citation_type) || 'citacion';
        const createdAt = parseDate(row.created_at);

        if (!reason) {
          throw new Error('Falta campo obligatorio: reason');
        }

        // citation_number is NOT NULL + UNIQUE.
        // If not provided, auto-generate a historical number.
        const citationNumber =
          number ||
          `HIST-${Date.now()}-${Math.floor(Math.random() * 1_000_000)
            .toString()
            .padStart(6, '0')}`;

        // Try to resolve user_id from target_rut (optional FK, nullable)
        let userId: string | null = null;
        if (targetRut) {
          const [existingUser] = await prisma.$queryRawUnsafe<{ id: string }[]>(
            `SELECT id FROM "${tenantId}".users WHERE rut = $1 LIMIT 1`,
            targetRut
          );
          if (existingUser) userId = existingUser.id;
        }

        await prisma.$queryRawUnsafe(
          `INSERT INTO "${tenantId}".court_citations
             (id, user_id, citation_number, reason, citation_type,
              target_name, target_rut, target_address,
              status, issued_by, created_at, updated_at)
           VALUES (gen_random_uuid(), $1::uuid, $2::text, $3::text, $4::text,
                   $5::text, $6::text, $7::text,
                   'notificado', $8::uuid, COALESCE($9::timestamptz, NOW()), NOW())`,
          userId,
          citationNumber,
          reason,
          citationType,
          targetName,
          targetRut,
          targetAddress,
          adminUserId,
          createdAt
        );

        result.inserted++;
      } catch (err) {
        result.failed++;
        pushError(result.errors, i, err);
      }
    }

    logger.info(
      `[admin-imports] citations: inserted=${result.inserted} failed=${result.failed} tenant=${tenantId}`
    );
    return result;
  }

  // ============================================================
  // REPORTS
  // ============================================================
  // CSV headers: title, description, category, priority, status,
  //              latitude, longitude, address, citizen_name,
  //              citizen_phone, created_at
  async importReports(
    rows: Record<string, unknown>[],
    tenantId: string,
    adminUserId: string
  ): Promise<ImportResult> {
    const result: ImportResult = { inserted: 0, failed: 0, errors: [] };

    const ALLOWED_TYPES = new Set([
      'denuncia',
      'sugerencia',
      'emergencia',
      'infraestructura',
      'otro',
    ]);
    const ALLOWED_PRIORITIES = new Set([
      'baja',
      'media',
      'alta',
      'urgente',
      'low',
      'medium',
      'high',
      'urgent',
    ]);
    const ALLOWED_STATUS = new Set([
      'pendiente',
      'en_proceso',
      'resuelto',
      'rechazado',
      'pending',
      'in_progress',
      'resolved',
      'rejected',
    ]);

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i] || {};
      try {
        const title = str(row.title);
        const description = str(row.description);
        let type = (str(row.category) || 'otro').toLowerCase();
        let priority = (str(row.priority) || 'media').toLowerCase();
        let status = (str(row.status) || 'pendiente').toLowerCase();
        const latitude = str(row.latitude);
        const longitude = str(row.longitude);
        const address = str(row.address);
        const citizenName = str(row.citizen_name);
        const citizenPhone = str(row.citizen_phone);
        const createdAt = parseDate(row.created_at);

        if (!title) throw new Error('Falta campo obligatorio: title');
        if (!description) throw new Error('Falta campo obligatorio: description');

        if (!ALLOWED_TYPES.has(type)) type = 'otro';
        if (!ALLOWED_PRIORITIES.has(priority)) priority = 'media';
        if (!ALLOWED_STATUS.has(status)) status = 'pendiente';

        // reports.user_id is NOT NULL. Since historical rows may not have a
        // registered citizen, fall back to the admin performing the import.
        // If citizen_name contains a match with an existing user, we'd need
        // more info to resolve; keep simple and use admin as the author.
        const userId = adminUserId;

        // Append citizen metadata to description so data isn't lost.
        const descSuffix: string[] = [];
        if (citizenName) descSuffix.push(`Ciudadano: ${citizenName}`);
        if (citizenPhone) descSuffix.push(`Teléfono: ${citizenPhone}`);
        const finalDescription =
          descSuffix.length > 0
            ? `${description}\n\n[Importado] ${descSuffix.join(' · ')}`
            : description;

        await prisma.$queryRawUnsafe(
          `INSERT INTO "${tenantId}".reports
             (id, user_id, type, title, description, address,
              latitude, longitude, priority, status,
              created_at, updated_at)
           VALUES (gen_random_uuid(), $1::uuid, $2::text, $3::text, $4::text, $5::text,
                   $6::numeric, $7::numeric, $8::text, $9::text,
                   COALESCE($10::timestamptz, NOW()), NOW())`,
          userId,
          type,
          title,
          finalDescription,
          address,
          latitude,
          longitude,
          priority,
          status,
          createdAt
        );

        result.inserted++;
      } catch (err) {
        result.failed++;
        pushError(result.errors, i, err);
      }
    }

    logger.info(
      `[admin-imports] reports: inserted=${result.inserted} failed=${result.failed} tenant=${tenantId}`
    );
    return result;
  }

  // ============================================================
  // VEHICLES
  // ============================================================
  // CSV headers: plate, brand, model, year, type, status,
  //              current_km, color
  async importVehicles(
    rows: Record<string, unknown>[],
    tenantId: string,
    adminUserId: string
  ): Promise<ImportResult> {
    const result: ImportResult = { inserted: 0, failed: 0, errors: [] };

    const ALLOWED_VEHICLE_TYPES = new Set([
      'auto',
      'moto',
      'camion',
      'camioneta',
      'bus',
      'otro',
    ]);

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i] || {};
      try {
        const plateRaw = str(row.plate);
        if (!plateRaw) throw new Error('Falta campo obligatorio: plate');
        const plate = plateRaw.toUpperCase();

        const brand = str(row.brand);
        const model = str(row.model);
        const year = parseInteger(row.year);
        let vehicleType = (str(row.type) || 'otro').toLowerCase();
        const color = str(row.color);
        const statusRaw = (str(row.status) || 'activo').toLowerCase();
        // Vehicles table has no status column; map to is_active boolean.
        const isActive = statusRaw !== 'inactivo' && statusRaw !== 'inactive';

        if (!ALLOWED_VEHICLE_TYPES.has(vehicleType)) vehicleType = 'otro';

        // Skip if plate already exists
        const [existing] = await prisma.$queryRawUnsafe<{ id: string }[]>(
          `SELECT id FROM "${tenantId}".vehicles WHERE plate = $1 LIMIT 1`,
          plate
        );
        if (existing) {
          throw new Error(`Patente ya existe: ${plate}`);
        }

        // owner_id is NOT NULL. Use admin performing the import as owner.
        await prisma.$queryRawUnsafe(
          `INSERT INTO "${tenantId}".vehicles
             (id, owner_id, plate, brand, model, year, color,
              vehicle_type, is_active, created_at, updated_at)
           VALUES (gen_random_uuid(), $1::uuid, $2::text, $3::text, $4::text,
                   $5::int, $6::text, $7::text, $8::boolean, NOW(), NOW())`,
          adminUserId,
          plate,
          brand,
          model,
          year,
          color,
          vehicleType,
          isActive
        );

        result.inserted++;
      } catch (err) {
        result.failed++;
        pushError(result.errors, i, err);
      }
    }

    logger.info(
      `[admin-imports] vehicles: inserted=${result.inserted} failed=${result.failed} tenant=${tenantId}`
    );
    return result;
  }

  // ============================================================
  // USERS
  // ============================================================
  // CSV headers: email, first_name, last_name, rut, phone, role, password
  async importUsers(
    rows: Record<string, unknown>[],
    tenantId: string
  ): Promise<ImportResult> {
    const result: ImportResult = { inserted: 0, failed: 0, errors: [] };

    const ALLOWED_ROLES = new Set(['citizen', 'inspector', 'admin']);

    for (let i = 0; i < rows.length; i++) {
      const row = rows[i] || {};
      try {
        const emailRaw = str(row.email);
        if (!emailRaw) throw new Error('Falta campo obligatorio: email');
        const email = emailRaw.toLowerCase();

        const firstName = str(row.first_name);
        const lastName = str(row.last_name);
        let rut = str(row.rut);
        const phone = str(row.phone);
        let role = (str(row.role) || 'citizen').toLowerCase();
        const password = str(row.password);

        if (!ALLOWED_ROLES.has(role)) role = 'citizen';

        // rut is NOT NULL + UNIQUE. Generate a placeholder if missing.
        if (!rut) {
          rut = `IMPORT_${Date.now()}_${i}`;
        }

        // Skip if email already exists (case-insensitive)
        const [existingEmail] = await prisma.$queryRawUnsafe<{ id: string }[]>(
          `SELECT id FROM "${tenantId}".users WHERE LOWER(email) = $1 LIMIT 1`,
          email
        );
        if (existingEmail) {
          throw new Error(`Email ya existe: ${email}`);
        }

        // Skip if rut already exists
        const [existingRut] = await prisma.$queryRawUnsafe<{ id: string }[]>(
          `SELECT id FROM "${tenantId}".users WHERE rut = $1 LIMIT 1`,
          rut
        );
        if (existingRut) {
          throw new Error(`RUT ya existe: ${rut}`);
        }

        // Hash the provided password, or generate a placeholder hash.
        // Note: existing auth service uses 12 rounds. Using same.
        const passwordToHash = password || `import_${Date.now()}_${i}`;
        const passwordHash = await bcrypt.hash(passwordToHash, 12);

        await prisma.$queryRawUnsafe(
          `INSERT INTO "${tenantId}".users
             (id, email, password_hash, rut, first_name, last_name,
              phone, role, is_active, created_at, updated_at)
           VALUES (gen_random_uuid(), $1::text, $2::text, $3::text, $4::text, $5::text,
                   $6::text, $7::text, true, NOW(), NOW())`,
          email,
          passwordHash,
          rut,
          firstName || '',
          lastName || '',
          phone,
          role
        );

        result.inserted++;
      } catch (err) {
        result.failed++;
        pushError(result.errors, i, err);
      }
    }

    logger.info(
      `[admin-imports] users: inserted=${result.inserted} failed=${result.failed} tenant=${tenantId}`
    );
    return result;
  }
}
