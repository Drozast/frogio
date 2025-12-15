import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import Link from 'next/link';
import AppLayout from '@/components/layout/AppLayout';
import StatCard from '@/components/ui/StatCard';
import { StatusBadge, PriorityBadge } from '@/components/ui/Badge';
import {
  DocumentTextIcon,
  ExclamationTriangleIcon,
  UserGroupIcon,
  TruckIcon,
  ChartBarIcon,
  ClockIcon,
  CheckCircleIcon,
  HeartIcon,
} from '@heroicons/react/24/outline';

const API_URL = process.env.API_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

async function getDashboardData(token: string) {
  try {
    const [reportsRes, infractionsRes, usersRes, vehiclesRes] = await Promise.all([
      fetch(`${API_URL}/api/reports`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Tenant-ID': 'santa_juana',
        },
        cache: 'no-store',
      }),
      fetch(`${API_URL}/api/infractions`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Tenant-ID': 'santa_juana',
        },
        cache: 'no-store',
      }),
      fetch(`${API_URL}/api/users`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Tenant-ID': 'santa_juana',
        },
        cache: 'no-store',
      }),
      fetch(`${API_URL}/api/vehicles`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Tenant-ID': 'santa_juana',
        },
        cache: 'no-store',
      }),
    ]);

    const reports = reportsRes.ok ? await reportsRes.json() : [];
    const infractions = infractionsRes.ok ? await infractionsRes.json() : [];
    const users = usersRes.ok ? await usersRes.json() : [];
    const vehicles = vehiclesRes.ok ? await vehiclesRes.json() : [];

    return { reports, infractions, users, vehicles };
  } catch (error) {
    console.error('Error fetching dashboard data:', error);
    return { reports: [], infractions: [], users: [], vehicles: [] };
  }
}

export default async function DashboardPage() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    redirect('/login');
  }

  const { reports, infractions, users, vehicles } = await getDashboardData(accessToken);

  // Calcular estadísticas
  const stats = {
    totalReports: reports.length,
    pendingReports: reports.filter((r: any) => r.status === 'pendiente').length,
    resolvedReports: reports.filter((r: any) => r.status === 'resuelto').length,
    totalInfractions: infractions.length,
    pendingInfractions: infractions.filter((i: any) => i.status === 'pendiente').length,
    totalUsers: users.length,
    activeUsers: users.filter((u: any) => u.isActive).length,
    totalVehicles: vehicles.length,
  };

  // Reportes recientes
  const recentReports = reports.slice(0, 5);

  return (
    <AppLayout>
      <div className="space-y-6">
        {/* Page Header */}
        <div className="md:flex md:items-center md:justify-between">
          <div className="flex-1 min-w-0">
            <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
              Dashboard
            </h2>
            <p className="mt-1 text-sm text-gray-500">
              Resumen general del sistema de gestión municipal
            </p>
          </div>
          <div className="mt-4 flex md:mt-0 md:ml-4">
            <Link
              href="/reports/new"
              className="ml-3 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Nuevo Reporte
            </Link>
          </div>
        </div>

        {/* Stats Grid */}
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
          <StatCard
            title="Total Reportes"
            value={stats.totalReports}
            icon={<DocumentTextIcon className="h-6 w-6" />}
            color="blue"
          />
          <StatCard
            title="Reportes Pendientes"
            value={stats.pendingReports}
            icon={<ClockIcon className="h-6 w-6" />}
            color="yellow"
          />
          <StatCard
            title="Reportes Resueltos"
            value={stats.resolvedReports}
            icon={<CheckCircleIcon className="h-6 w-6" />}
            color="green"
          />
          <StatCard
            title="Total Infracciones"
            value={stats.totalInfractions}
            icon={<ExclamationTriangleIcon className="h-6 w-6" />}
            color="red"
          />
        </div>

        {/* Secondary Stats */}
        <div className="grid grid-cols-1 gap-5 sm:grid-cols-3">
          <StatCard
            title="Total Usuarios"
            value={stats.totalUsers}
            icon={<UserGroupIcon className="h-6 w-6" />}
            color="indigo"
          />
          <StatCard
            title="Usuarios Activos"
            value={stats.activeUsers}
            icon={<CheckCircleIcon className="h-6 w-6" />}
            color="green"
          />
          <StatCard
            title="Total Vehículos"
            value={stats.totalVehicles}
            icon={<TruckIcon className="h-6 w-6" />}
            color="purple"
          />
        </div>

        {/* Quick Actions */}
        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900 mb-4">
              Acciones Rápidas
            </h3>
            <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
              <Link
                href="/reports"
                className="relative group bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500 hover:bg-gray-50 rounded-lg border-2 border-gray-200 hover:border-indigo-300 transition-all"
              >
                <div className="flex flex-col items-center">
                  <DocumentTextIcon className="h-8 w-8 text-indigo-600 mb-2" />
                  <span className="text-sm font-medium text-gray-900 text-center">
                    Reportes
                  </span>
                </div>
              </Link>
              <Link
                href="/infractions"
                className="relative group bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500 hover:bg-gray-50 rounded-lg border-2 border-gray-200 hover:border-indigo-300 transition-all"
              >
                <div className="flex flex-col items-center">
                  <ExclamationTriangleIcon className="h-8 w-8 text-red-600 mb-2" />
                  <span className="text-sm font-medium text-gray-900 text-center">
                    Infracciones
                  </span>
                </div>
              </Link>
              <Link
                href="/vehicles"
                className="relative group bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500 hover:bg-gray-50 rounded-lg border-2 border-gray-200 hover:border-indigo-300 transition-all"
              >
                <div className="flex flex-col items-center">
                  <TruckIcon className="h-8 w-8 text-purple-600 mb-2" />
                  <span className="text-sm font-medium text-gray-900 text-center">
                    Vehículos
                  </span>
                </div>
              </Link>
              <Link
                href="/citations"
                className="relative group bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500 hover:bg-gray-50 rounded-lg border-2 border-gray-200 hover:border-indigo-300 transition-all"
              >
                <div className="flex flex-col items-center">
                  <ChartBarIcon className="h-8 w-8 text-green-600 mb-2" />
                  <span className="text-sm font-medium text-gray-900 text-center">
                    Citaciones
                  </span>
                </div>
              </Link>
              <Link
                href="/medical-records"
                className="relative group bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500 hover:bg-gray-50 rounded-lg border-2 border-gray-200 hover:border-indigo-300 transition-all"
              >
                <div className="flex flex-col items-center">
                  <HeartIcon className="h-8 w-8 text-pink-600 mb-2" />
                  <span className="text-sm font-medium text-gray-900 text-center">
                    Fichas Médicas
                  </span>
                </div>
              </Link>
              <Link
                href="/users"
                className="relative group bg-white p-6 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-500 hover:bg-gray-50 rounded-lg border-2 border-gray-200 hover:border-indigo-300 transition-all"
              >
                <div className="flex flex-col items-center">
                  <UserGroupIcon className="h-8 w-8 text-blue-600 mb-2" />
                  <span className="text-sm font-medium text-gray-900 text-center">
                    Usuarios
                  </span>
                </div>
              </Link>
            </div>
          </div>
        </div>

        {/* Recent Reports Table */}
        <div className="bg-white shadow rounded-lg">
          <div className="px-4 py-5 sm:px-6 border-b border-gray-200">
            <div className="flex items-center justify-between">
              <h3 className="text-lg leading-6 font-medium text-gray-900">
                Reportes Recientes
              </h3>
              <Link
                href="/reports"
                className="text-sm font-medium text-indigo-600 hover:text-indigo-500"
              >
                Ver todos →
              </Link>
            </div>
          </div>
          <div className="overflow-x-auto">
            {recentReports.length === 0 ? (
              <div className="px-6 py-12 text-center text-gray-500">
                <DocumentTextIcon className="mx-auto h-12 w-12 text-gray-400 mb-4" />
                <p>No hay reportes disponibles</p>
              </div>
            ) : (
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Título
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Tipo
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Estado
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Prioridad
                    </th>
                    <th scope="col" className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                      Fecha
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {recentReports.map((report: any) => (
                    <tr key={report.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm font-medium text-gray-900">{report.title}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <div className="text-sm text-gray-500">{report.type || 'General'}</div>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <StatusBadge status={report.status} />
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <PriorityBadge priority={report.priority} />
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {new Date(report.createdAt).toLocaleDateString('es-CL')}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>
    </AppLayout>
  );
}
