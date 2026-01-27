'use client';

import { useState, useCallback, useEffect } from 'react';
import Link from 'next/link';
import { useAutoRefresh } from '@/hooks/useAutoRefresh';
import StatCard from '@/components/ui/StatCard';
import { StatusBadge, PriorityBadge } from '@/components/ui/Badge';
import {
  ReportsByStatusChart,
  CitationsByStatusChart,
  UsersByRoleChart,
} from '@/components/charts/DashboardCharts';
import {
  DocumentTextIcon,
  ScaleIcon,
  UserGroupIcon,
  TruckIcon,
  ClockIcon,
  CheckCircleIcon,
  PlusIcon,
  ArrowRightIcon,
  ArrowPathIcon,
} from '@heroicons/react/24/outline';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

interface DashboardData {
  reports: any[];
  citations: any[];
  users: any[];
  vehicles: any[];
}

interface DashboardClientProps {
  initialData: DashboardData;
}

export default function DashboardClient({ initialData }: DashboardClientProps) {
  const [data, setData] = useState<DashboardData>(initialData);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [lastUpdate, setLastUpdate] = useState(new Date());

  const fetchData = useCallback(async () => {
    try {
      setIsRefreshing(true);
      const token = document.cookie
        .split('; ')
        .find(row => row.startsWith('accessToken='))
        ?.split('=')[1];

      if (!token) return;

      const [reportsRes, citationsRes, usersRes, vehiclesRes] = await Promise.all([
        fetch(`${API_URL}/api/reports`, {
          headers: {
            'Authorization': `Bearer ${token}`,
            'X-Tenant-ID': 'santa_juana',
          },
        }),
        fetch(`${API_URL}/api/citations`, {
          headers: {
            'Authorization': `Bearer ${token}`,
            'X-Tenant-ID': 'santa_juana',
          },
        }),
        fetch(`${API_URL}/api/users`, {
          headers: {
            'Authorization': `Bearer ${token}`,
            'X-Tenant-ID': 'santa_juana',
          },
        }),
        fetch(`${API_URL}/api/vehicles`, {
          headers: {
            'Authorization': `Bearer ${token}`,
            'X-Tenant-ID': 'santa_juana',
          },
        }),
      ]);

      const reports = reportsRes.ok ? await reportsRes.json() : data.reports;
      const citations = citationsRes.ok ? await citationsRes.json() : data.citations;
      const users = usersRes.ok ? await usersRes.json() : data.users;
      const vehicles = vehiclesRes.ok ? await vehiclesRes.json() : data.vehicles;

      setData({ reports, citations, users, vehicles });
      setLastUpdate(new Date());
    } catch (error) {
      console.error('Error refreshing dashboard:', error);
    } finally {
      setIsRefreshing(false);
    }
  }, [data]);

  useAutoRefresh(fetchData, { interval: 3000 });

  const { reports, citations, users, vehicles } = data;

  // Calculate statistics
  const stats = {
    totalReports: reports.length,
    pendingReports: reports.filter((r: any) => r.status === 'pendiente').length,
    resolvedReports: reports.filter((r: any) => r.status === 'resuelto').length,
    inProgressReports: reports.filter((r: any) => r.status === 'en_proceso').length,
    totalCitations: citations.length,
    pendingCitations: citations.filter((c: any) => c.status === 'pendiente').length,
    totalUsers: users.length,
    activeUsers: users.filter((u: any) => u.isActive).length,
    totalVehicles: vehicles.length,
  };

  const recentReports = reports.slice(0, 5);

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-foreground tracking-tight">
            Dashboard
          </h1>
          <p className="mt-1 text-sm text-muted-foreground flex items-center gap-2">
            Resumen general del sistema de gestión municipal
            <span className="inline-flex items-center gap-1 text-xs">
              <ArrowPathIcon className={`w-3 h-3 ${isRefreshing ? 'animate-spin' : ''}`} />
              {lastUpdate.toLocaleTimeString('es-CL')}
            </span>
          </p>
        </div>
        <Link
          href="/reports/new"
          className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-primary text-primary-foreground rounded-lg font-medium text-sm shadow-sm hover:opacity-90 active:scale-[0.98] transition-all"
        >
          <PlusIcon className="w-4 h-4" />
          Nuevo Reporte
        </Link>
      </div>

      {/* Primary Stats Grid */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Reportes"
          value={stats.totalReports}
          icon={<DocumentTextIcon className="h-6 w-6" />}
          color="primary"
          href="/reports"
          subtitle="Todos los reportes"
        />
        <StatCard
          title="Pendientes"
          value={stats.pendingReports}
          icon={<ClockIcon className="h-6 w-6" />}
          color="warning"
          href="/reports?status=pendiente"
          subtitle="Requieren atención"
        />
        <StatCard
          title="En Proceso"
          value={stats.inProgressReports}
          icon={<DocumentTextIcon className="h-6 w-6" />}
          color="info"
          href="/reports?status=en_proceso"
          subtitle="Siendo atendidos"
        />
        <StatCard
          title="Resueltos"
          value={stats.resolvedReports}
          icon={<CheckCircleIcon className="h-6 w-6" />}
          color="success"
          href="/reports?status=resuelto"
          subtitle="Completados"
        />
      </div>

      {/* Secondary Stats */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard
          title="Total Citaciones"
          value={stats.totalCitations}
          icon={<ScaleIcon className="h-6 w-6" />}
          color="warning"
          href="/citations"
        />
        <StatCard
          title="Usuarios"
          value={`${stats.activeUsers}/${stats.totalUsers}`}
          icon={<UserGroupIcon className="h-6 w-6" />}
          color="info"
          href="/users"
          subtitle="Activos / Total"
        />
        <StatCard
          title="Vehículos"
          value={stats.totalVehicles}
          icon={<TruckIcon className="h-6 w-6" />}
          color="muted"
          href="/fleet"
        />
      </div>

      {/* Quick Actions */}
      <div className="bg-card rounded-xl border border-border/50 shadow-card overflow-hidden">
        <div className="px-5 py-4 border-b border-border/50">
          <h3 className="text-base font-semibold text-foreground">
            Acciones Rápidas
          </h3>
        </div>
        <div className="p-4">
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
            {[
              { href: '/reports', icon: DocumentTextIcon, label: 'Reportes', color: 'text-primary' },
              { href: '/citations', icon: ScaleIcon, label: 'Citaciones', color: 'text-warning' },
              { href: '/fleet', icon: TruckIcon, label: 'Flota', color: 'text-info' },
              { href: '/users', icon: UserGroupIcon, label: 'Usuarios', color: 'text-primary' },
            ].map((item) => (
              <Link
                key={item.href}
                href={item.href}
                className="group flex flex-col items-center gap-2 p-4 rounded-xl border border-border/50 bg-background hover:bg-accent hover:border-primary/20 transition-all duration-200"
              >
                <item.icon className={`h-7 w-7 ${item.color} group-hover:scale-110 transition-transform`} />
                <span className="text-sm font-medium text-foreground">
                  {item.label}
                </span>
              </Link>
            ))}
          </div>
        </div>
      </div>

      {/* Charts Section */}
      <div className="grid grid-cols-1 gap-5 lg:grid-cols-3">
        <ReportsByStatusChart
          data={[
            { name: 'Pendientes', value: stats.pendingReports, color: '#F59E0B' },
            { name: 'En Proceso', value: stats.inProgressReports, color: '#3B82F6' },
            { name: 'Resueltos', value: stats.resolvedReports, color: '#1B5E20' },
            { name: 'Rechazados', value: reports.filter((r: any) => r.status === 'rechazado').length, color: '#EF4444' },
          ].filter(d => d.value > 0)}
        />
        <CitationsByStatusChart
          data={[
            { name: 'Pendientes', value: stats.pendingCitations, color: '#F59E0B' },
            { name: 'Notificadas', value: citations.filter((c: any) => c.status === 'notificada').length, color: '#3B82F6' },
            { name: 'Comparecidas', value: citations.filter((c: any) => c.status === 'comparecida').length, color: '#1B5E20' },
            { name: 'No Comparecidas', value: citations.filter((c: any) => c.status === 'no_comparecida').length, color: '#EF4444' },
          ].filter(d => d.value > 0)}
        />
        <UsersByRoleChart
          data={[
            { name: 'Ciudadanos', value: users.filter((u: any) => u.role === 'citizen').length, color: '#3B82F6' },
            { name: 'Inspectores', value: users.filter((u: any) => u.role === 'inspector').length, color: '#1B5E20' },
            { name: 'Administradores', value: users.filter((u: any) => u.role === 'admin').length, color: '#8B5CF6' },
          ].filter(d => d.value > 0)}
        />
      </div>

      {/* Recent Reports Table */}
      <div className="bg-card rounded-xl border border-border/50 shadow-card overflow-hidden">
        <div className="px-5 py-4 border-b border-border/50">
          <div className="flex items-center justify-between">
            <h3 className="text-base font-semibold text-foreground">
              Reportes Recientes
            </h3>
            <Link
              href="/reports"
              className="inline-flex items-center gap-1 text-sm font-medium text-primary hover:underline"
            >
              Ver todos
              <ArrowRightIcon className="w-4 h-4" />
            </Link>
          </div>
        </div>
        <div className="overflow-x-auto">
          {recentReports.length === 0 ? (
            <div className="px-6 py-12 text-center">
              <div className="w-12 h-12 mx-auto rounded-xl bg-muted flex items-center justify-center mb-4">
                <DocumentTextIcon className="h-6 w-6 text-muted-foreground" />
              </div>
              <p className="text-sm text-muted-foreground">No hay reportes disponibles</p>
            </div>
          ) : (
            <table className="table-minimal">
              <thead>
                <tr>
                  <th>Título</th>
                  <th>Tipo</th>
                  <th>Estado</th>
                  <th>Prioridad</th>
                  <th>Fecha</th>
                </tr>
              </thead>
              <tbody>
                {recentReports.map((report: any) => (
                  <tr key={report.id}>
                    <td>
                      <span className="font-medium text-foreground">{report.title}</span>
                    </td>
                    <td>
                      <span className="text-muted-foreground">{report.type || 'General'}</span>
                    </td>
                    <td>
                      <StatusBadge status={report.status} />
                    </td>
                    <td>
                      <PriorityBadge priority={report.priority} />
                    </td>
                    <td>
                      <span className="text-muted-foreground">
                        {new Date(report.createdAt).toLocaleDateString('es-CL')}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}
