import prisma from '../../config/database.js';

export class DashboardService {
  async getStats(tenantId: string, userRole: string) {
    // Get counts based on role
    const [usersCount] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT COUNT(*) as count FROM "${tenantId}".users WHERE is_active = true`
    );

    const [infractionsCount] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT COUNT(*) as count FROM "${tenantId}".infractions`
    );

    const [reportsCount] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT COUNT(*) as count FROM "${tenantId}".reports`
    );

    const [vehiclesCount] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT COUNT(*) as count FROM "${tenantId}".vehicles WHERE is_active = true`
    );

    // Get infractions by status
    const infractionsByStatus = await prisma.$queryRawUnsafe<any[]>(
      `SELECT status, COUNT(*) as count FROM "${tenantId}".infractions GROUP BY status`
    );

    // Get reports by status
    const reportsByStatus = await prisma.$queryRawUnsafe<any[]>(
      `SELECT status, COUNT(*) as count FROM "${tenantId}".reports GROUP BY status`
    );

    // Get recent activity (last 7 days)
    const [recentInfractions] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT COUNT(*) as count FROM "${tenantId}".infractions WHERE created_at >= NOW() - INTERVAL '7 days'`
    );

    const [recentReports] = await prisma.$queryRawUnsafe<any[]>(
      `SELECT COUNT(*) as count FROM "${tenantId}".reports WHERE created_at >= NOW() - INTERVAL '7 days'`
    );

    // Get infractions by type
    const infractionsByType = await prisma.$queryRawUnsafe<any[]>(
      `SELECT type, COUNT(*) as count FROM "${tenantId}".infractions GROUP BY type ORDER BY count DESC LIMIT 5`
    );

    // Get daily activity for the last 30 days
    const dailyActivity = await prisma.$queryRawUnsafe<any[]>(
      `SELECT
        DATE(created_at) as date,
        COUNT(*) as count
       FROM "${tenantId}".infractions
       WHERE created_at >= NOW() - INTERVAL '30 days'
       GROUP BY DATE(created_at)
       ORDER BY date ASC`
    );

    // Admin-only stats
    let adminStats = {};
    if (userRole === 'admin') {
      const [inspectorsCount] = await prisma.$queryRawUnsafe<any[]>(
        `SELECT COUNT(*) as count FROM "${tenantId}".users WHERE role = 'inspector' AND is_active = true`
      );

      const [citizensCount] = await prisma.$queryRawUnsafe<any[]>(
        `SELECT COUNT(*) as count FROM "${tenantId}".users WHERE role = 'citizen' AND is_active = true`
      );

      // Top inspectors by infractions
      const topInspectors = await prisma.$queryRawUnsafe<any[]>(
        `SELECT
          u.id, u.first_name, u.last_name, u.email,
          COUNT(i.id) as infraction_count
         FROM "${tenantId}".users u
         LEFT JOIN "${tenantId}".infractions i ON u.id = i.inspector_id
         WHERE u.role = 'inspector'
         GROUP BY u.id, u.first_name, u.last_name, u.email
         ORDER BY infraction_count DESC
         LIMIT 5`
      );

      adminStats = {
        inspectorsCount: parseInt(inspectorsCount?.count || '0'),
        citizensCount: parseInt(citizensCount?.count || '0'),
        topInspectors: topInspectors.map((i: any) => ({
          id: i.id,
          name: `${i.first_name || ''} ${i.last_name || ''}`.trim() || i.email,
          infractionCount: parseInt(i.infraction_count || '0'),
        })),
      };
    }

    return {
      summary: {
        totalUsers: parseInt(usersCount?.count || '0'),
        totalInfractions: parseInt(infractionsCount?.count || '0'),
        totalReports: parseInt(reportsCount?.count || '0'),
        totalVehicles: parseInt(vehiclesCount?.count || '0'),
      },
      recentActivity: {
        infractionsLast7Days: parseInt(recentInfractions?.count || '0'),
        reportsLast7Days: parseInt(recentReports?.count || '0'),
      },
      infractionsByStatus: infractionsByStatus.reduce((acc: any, item: any) => {
        acc[item.status] = parseInt(item.count || '0');
        return acc;
      }, {}),
      reportsByStatus: reportsByStatus.reduce((acc: any, item: any) => {
        acc[item.status] = parseInt(item.count || '0');
        return acc;
      }, {}),
      infractionsByType: infractionsByType.map((item: any) => ({
        type: item.type,
        count: parseInt(item.count || '0'),
      })),
      dailyActivity: dailyActivity.map((item: any) => ({
        date: item.date,
        count: parseInt(item.count || '0'),
      })),
      ...adminStats,
    };
  }
}
