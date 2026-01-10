import prisma from '../../config/database.js';

export class ExportsService {
  async exportReports(tenantId: string, format: 'json' | 'csv', filters?: {
    status?: string;
    startDate?: string;
    endDate?: string;
  }) {
    let query = `SELECT r.*,
                 u.first_name as reporter_first_name, u.last_name as reporter_last_name, u.email as reporter_email
                 FROM "${tenantId}".reports r
                 LEFT JOIN "${tenantId}".users u ON r.user_id = u.id
                 WHERE 1=1`;

    const params: any[] = [];
    let paramIndex = 1;

    if (filters?.status) {
      query += ` AND r.status = $${paramIndex}`;
      params.push(filters.status);
      paramIndex++;
    }

    if (filters?.startDate) {
      query += ` AND r.created_at >= $${paramIndex}`;
      params.push(filters.startDate);
      paramIndex++;
    }

    if (filters?.endDate) {
      query += ` AND r.created_at <= $${paramIndex}`;
      params.push(filters.endDate);
      paramIndex++;
    }

    query += ` ORDER BY r.created_at DESC`;

    const reports = await prisma.$queryRawUnsafe<any[]>(query, ...params);

    if (format === 'csv') {
      return this.toCSV(reports, [
        'id', 'title', 'description', 'type', 'status', 'priority',
        'address', 'latitude', 'longitude',
        'reporter_first_name', 'reporter_last_name', 'reporter_email',
        'created_at', 'updated_at'
      ]);
    }

    return reports;
  }

  async exportInfractions(tenantId: string, format: 'json' | 'csv', filters?: {
    status?: string;
    type?: string;
    startDate?: string;
    endDate?: string;
  }) {
    let query = `SELECT i.*,
                 u.first_name as citizen_first_name, u.last_name as citizen_last_name, u.rut as citizen_rut,
                 ins.first_name as inspector_first_name, ins.last_name as inspector_last_name
                 FROM "${tenantId}".infractions i
                 LEFT JOIN "${tenantId}".users u ON i.user_id = u.id
                 LEFT JOIN "${tenantId}".users ins ON i.issued_by = ins.id
                 WHERE 1=1`;

    const params: any[] = [];
    let paramIndex = 1;

    if (filters?.status) {
      query += ` AND i.status = $${paramIndex}`;
      params.push(filters.status);
      paramIndex++;
    }

    if (filters?.type) {
      query += ` AND i.type = $${paramIndex}`;
      params.push(filters.type);
      paramIndex++;
    }

    if (filters?.startDate) {
      query += ` AND i.created_at >= $${paramIndex}`;
      params.push(filters.startDate);
      paramIndex++;
    }

    if (filters?.endDate) {
      query += ` AND i.created_at <= $${paramIndex}`;
      params.push(filters.endDate);
      paramIndex++;
    }

    query += ` ORDER BY i.created_at DESC`;

    const infractions = await prisma.$queryRawUnsafe<any[]>(query, ...params);

    if (format === 'csv') {
      return this.toCSV(infractions, [
        'id', 'type', 'description', 'address', 'amount', 'vehicle_plate', 'status',
        'citizen_first_name', 'citizen_last_name', 'citizen_rut',
        'inspector_first_name', 'inspector_last_name',
        'created_at', 'updated_at'
      ]);
    }

    return infractions;
  }

  async exportUsers(tenantId: string, format: 'json' | 'csv', filters?: {
    role?: string;
    isActive?: boolean;
  }) {
    let query = `SELECT id, email, rut, first_name, last_name, phone, address, role, is_active, created_at
                 FROM "${tenantId}".users WHERE 1=1`;

    const params: any[] = [];
    let paramIndex = 1;

    if (filters?.role) {
      query += ` AND role = $${paramIndex}`;
      params.push(filters.role);
      paramIndex++;
    }

    if (filters?.isActive !== undefined) {
      query += ` AND is_active = $${paramIndex}`;
      params.push(filters.isActive);
      paramIndex++;
    }

    query += ` ORDER BY created_at DESC`;

    const users = await prisma.$queryRawUnsafe<any[]>(query, ...params);

    if (format === 'csv') {
      return this.toCSV(users, [
        'id', 'email', 'rut', 'first_name', 'last_name', 'phone', 'address', 'role', 'is_active', 'created_at'
      ]);
    }

    return users;
  }

  async exportVehicles(tenantId: string, format: 'json' | 'csv') {
    const vehicles = await prisma.$queryRawUnsafe<any[]>(
      `SELECT v.*,
       u.first_name as owner_first_name, u.last_name as owner_last_name, u.rut as owner_rut
       FROM "${tenantId}".vehicles v
       LEFT JOIN "${tenantId}".users u ON v.owner_id = u.id
       ORDER BY v.created_at DESC`
    );

    if (format === 'csv') {
      return this.toCSV(vehicles, [
        'id', 'plate', 'brand', 'model', 'year', 'color', 'vehicle_type', 'vin',
        'owner_first_name', 'owner_last_name', 'owner_rut',
        'is_active', 'created_at'
      ]);
    }

    return vehicles;
  }

  async getStatisticsReport(tenantId: string) {
    const [reportsStats] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE status = 'pendiente') as pendiente,
        COUNT(*) FILTER (WHERE status = 'en_proceso') as en_proceso,
        COUNT(*) FILTER (WHERE status = 'resuelto') as resuelto,
        COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '30 days') as last_30d
       FROM "${tenantId}".reports`
    );

    const [infractionsStats] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE status = 'pendiente') as pendiente,
        COUNT(*) FILTER (WHERE status = 'pagado') as pagado,
        COALESCE(SUM(amount), 0) as total_amount,
        COALESCE(SUM(amount) FILTER (WHERE status = 'pagado'), 0) as paid_amount
       FROM "${tenantId}".infractions`
    );

    const [usersStats] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT
        COUNT(*) as total,
        COUNT(*) FILTER (WHERE role = 'citizen') as citizens,
        COUNT(*) FILTER (WHERE role = 'inspector') as inspectors,
        COUNT(*) FILTER (WHERE role = 'admin') as admins,
        COUNT(*) FILTER (WHERE is_active = true) as active
       FROM "${tenantId}".users`
    );

    const [vehiclesStats] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT COUNT(*) as total, COUNT(*) FILTER (WHERE is_active = true) as active
       FROM "${tenantId}".vehicles`
    );

    return {
      generatedAt: new Date().toISOString(),
      reports: {
        total: parseInt(reportsStats?.total || '0'),
        pendiente: parseInt(reportsStats?.pendiente || '0'),
        enProceso: parseInt(reportsStats?.en_proceso || '0'),
        resuelto: parseInt(reportsStats?.resuelto || '0'),
        last30Days: parseInt(reportsStats?.last_30d || '0'),
      },
      infractions: {
        total: parseInt(infractionsStats?.total || '0'),
        pendiente: parseInt(infractionsStats?.pendiente || '0'),
        pagado: parseInt(infractionsStats?.pagado || '0'),
        totalAmount: parseFloat(infractionsStats?.total_amount || '0'),
        paidAmount: parseFloat(infractionsStats?.paid_amount || '0'),
      },
      users: {
        total: parseInt(usersStats?.total || '0'),
        citizens: parseInt(usersStats?.citizens || '0'),
        inspectors: parseInt(usersStats?.inspectors || '0'),
        admins: parseInt(usersStats?.admins || '0'),
        active: parseInt(usersStats?.active || '0'),
      },
      vehicles: {
        total: parseInt(vehiclesStats?.total || '0'),
        active: parseInt(vehiclesStats?.active || '0'),
      },
    };
  }

  private toCSV(data: any[], columns: string[]): string {
    if (data.length === 0) {
      return columns.join(',') + '\n';
    }

    const header = columns.join(',');
    const rows = data.map(row =>
      columns.map(col => {
        const value = row[col];
        if (value === null || value === undefined) return '';
        if (typeof value === 'string') {
          // Escape quotes and wrap in quotes if contains comma
          const escaped = value.replace(/"/g, '""');
          return escaped.includes(',') || escaped.includes('\n') ? `"${escaped}"` : escaped;
        }
        if (value instanceof Date) {
          return value.toISOString();
        }
        return String(value);
      }).join(',')
    );

    return [header, ...rows].join('\n');
  }
}
