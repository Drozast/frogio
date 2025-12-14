import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import Link from 'next/link';

async function getDashboardData(token: string) {
  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

  try {
    const [reportsRes, infractionsStatsRes] = await Promise.all([
      fetch(`${API_URL}/api/reports`, {
        headers: { Authorization: `Bearer ${token}` },
        cache: 'no-store',
      }),
      fetch(`${API_URL}/api/infractions/stats`, {
        headers: { Authorization: `Bearer ${token}` },
        cache: 'no-store',
      }),
    ]);

    const reports = reportsRes.ok ? await reportsRes.json() : [];
    const infractionsStats = infractionsStatsRes.ok ? await infractionsStatsRes.json() : {};

    return { reports, infractionsStats };
  } catch (error) {
    console.error('Error fetching dashboard data:', error);
    return { reports: [], infractionsStats: {} };
  }
}

export default async function DashboardPage() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    redirect('/login');
  }

  const { reports, infractionsStats } = await getDashboardData(accessToken);

  const reportsByStatus = {
    pendiente: reports.filter((r: any) => r.status === 'pendiente').length,
    en_proceso: reports.filter((r: any) => r.status === 'en_proceso').length,
    resuelto: reports.filter((r: any) => r.status === 'resuelto').length,
  };

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Header */}
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-900">FROGIO Admin</h1>
          <div className="flex items-center gap-4">
            <Link
              href="/notifications"
              className="text-gray-600 hover:text-gray-900 relative"
            >
              <span className="text-xl">🔔</span>
            </Link>
            <form action="/api/auth/logout" method="POST">
              <button
                type="submit"
                className="text-sm text-gray-600 hover:text-gray-900"
              >
                Cerrar Sesión
              </button>
            </form>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
          <StatCard
            title="Reportes Totales"
            value={reports.length}
            color="blue"
          />
          <StatCard
            title="Reportes Pendientes"
            value={reportsByStatus.pendiente}
            color="yellow"
          />
          <StatCard
            title="Multas Pendientes"
            value={infractionsStats.pendientes || 0}
            color="red"
          />
          <StatCard
            title="Multas Pagadas"
            value={infractionsStats.pagadas || 0}
            color="green"
          />
        </div>

        {/* Quick Actions */}
        <div className="bg-white shadow rounded-lg p-6 mb-8">
          <h2 className="text-lg font-semibold mb-4">Acciones Rápidas</h2>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
            <Link
              href="/reports"
              className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 text-center"
            >
              <div className="text-2xl mb-2">📋</div>
              <div className="text-sm font-medium">Reportes</div>
            </Link>
            <Link
              href="/infractions"
              className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 text-center"
            >
              <div className="text-2xl mb-2">🚨</div>
              <div className="text-sm font-medium">Infracciones</div>
            </Link>
            <Link
              href="/vehicles"
              className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 text-center"
            >
              <div className="text-2xl mb-2">🚗</div>
              <div className="text-sm font-medium">Vehículos</div>
            </Link>
            <Link
              href="/citations"
              className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 text-center"
            >
              <div className="text-2xl mb-2">⚖️</div>
              <div className="text-sm font-medium">Citaciones</div>
            </Link>
            <Link
              href="/medical-records"
              className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 text-center"
            >
              <div className="text-2xl mb-2">🏥</div>
              <div className="text-sm font-medium">Fichas Médicas</div>
            </Link>
            <Link
              href="/users"
              className="p-4 border border-gray-200 rounded-lg hover:bg-gray-50 text-center"
            >
              <div className="text-2xl mb-2">👥</div>
              <div className="text-sm font-medium">Usuarios</div>
            </Link>
          </div>
        </div>

        {/* Recent Reports */}
        <div className="bg-white shadow rounded-lg p-6">
          <h2 className="text-lg font-semibold mb-4">Reportes Recientes</h2>
          {reports.length === 0 ? (
            <p className="text-gray-500">No hay reportes disponibles</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Título
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Tipo
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Estado
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Prioridad
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {reports.slice(0, 5).map((report: any) => (
                    <tr key={report.id}>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        {report.title}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {report.type}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <StatusBadge status={report.status} />
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <PriorityBadge priority={report.priority} />
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}

function StatCard({
  title,
  value,
  color,
}: {
  title: string;
  value: number;
  color: string;
}) {
  const colors: Record<string, string> = {
    blue: 'bg-blue-500',
    yellow: 'bg-yellow-500',
    red: 'bg-red-500',
    green: 'bg-green-500',
  };

  return (
    <div className="bg-white overflow-hidden shadow rounded-lg">
      <div className="p-5">
        <div className="flex items-center">
          <div className="flex-shrink-0">
            <div className={`h-12 w-12 ${colors[color]} rounded-md`}></div>
          </div>
          <div className="ml-5 w-0 flex-1">
            <dl>
              <dt className="text-sm font-medium text-gray-500 truncate">
                {title}
              </dt>
              <dd className="text-3xl font-semibold text-gray-900">{value}</dd>
            </dl>
          </div>
        </div>
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const colors: Record<string, string> = {
    pendiente: 'bg-yellow-100 text-yellow-800',
    en_proceso: 'bg-blue-100 text-blue-800',
    resuelto: 'bg-green-100 text-green-800',
    rechazado: 'bg-red-100 text-red-800',
  };

  return (
    <span
      className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${colors[status] || 'bg-gray-100 text-gray-800'}`}
    >
      {status}
    </span>
  );
}

function PriorityBadge({ priority }: { priority: string }) {
  const colors: Record<string, string> = {
    baja: 'bg-gray-100 text-gray-800',
    media: 'bg-blue-100 text-blue-800',
    alta: 'bg-orange-100 text-orange-800',
    urgente: 'bg-red-100 text-red-800',
  };

  return (
    <span
      className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${colors[priority] || 'bg-gray-100 text-gray-800'}`}
    >
      {priority}
    </span>
  );
}
