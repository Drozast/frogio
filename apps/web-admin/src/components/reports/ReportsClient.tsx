'use client';

import { useState, useCallback } from 'react';
import { useAutoRefresh } from '@/hooks/useAutoRefresh';
import ReportsTable from './ReportsTable';
import { ArrowPathIcon } from '@heroicons/react/24/outline';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

interface Report {
  id: string;
  title: string;
  description: string;
  type: string;
  status: string;
  priority: string;
  user_id: string;
  assigned_to: string | null;
  latitude: number | null;
  longitude: number | null;
  created_at: string;
  updated_at: string;
  first_name?: string;
  last_name?: string;
}

interface Inspector {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  isActive?: boolean;
}

interface ReportsClientProps {
  initialReports: Report[];
  initialInspectors: Inspector[];
}

export default function ReportsClient({ initialReports, initialInspectors }: ReportsClientProps) {
  const [reports, setReports] = useState<Report[]>(initialReports);
  const [inspectors, setInspectors] = useState<Inspector[]>(initialInspectors);
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

      const [reportsRes, inspectorsRes] = await Promise.all([
        fetch(`${API_URL}/api/reports`, {
          headers: {
            'Authorization': `Bearer ${token}`,
            'X-Tenant-ID': 'santa_juana',
          },
        }),
        fetch(`${API_URL}/api/users?role=inspector`, {
          headers: {
            'Authorization': `Bearer ${token}`,
            'X-Tenant-ID': 'santa_juana',
          },
        }),
      ]);

      if (reportsRes.ok) {
        const newReports = await reportsRes.json();
        setReports(newReports);
      }
      if (inspectorsRes.ok) {
        const newInspectors = await inspectorsRes.json();
        setInspectors(newInspectors);
      }
      setLastUpdate(new Date());
    } catch (error) {
      console.error('Error refreshing reports:', error);
    } finally {
      setIsRefreshing(false);
    }
  }, []);

  useAutoRefresh(fetchData, { interval: 3000 });

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="md:flex md:items-center md:justify-between">
        <div className="flex-1 min-w-0">
          <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            Reportes Ciudadanos
          </h2>
          <p className="mt-1 text-sm text-gray-500 flex items-center gap-2">
            Gestiona reportes, asigna inspectores y actualiza estados
            <span className="inline-flex items-center gap-1 text-xs text-muted-foreground">
              <ArrowPathIcon className={`w-3 h-3 ${isRefreshing ? 'animate-spin' : ''}`} />
              {lastUpdate.toLocaleTimeString('es-CL')}
            </span>
          </p>
        </div>
      </div>

      {/* Reports Table */}
      <ReportsTable reports={reports} inspectors={inspectors} />
    </div>
  );
}
