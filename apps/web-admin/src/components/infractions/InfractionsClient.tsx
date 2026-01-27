'use client';

import { useState, useCallback } from 'react';
import Link from 'next/link';
import { useAutoRefresh } from '@/hooks/useAutoRefresh';
import InfractionsTable from './InfractionsTable';
import StatCard from '@/components/ui/StatCard';
import { PlusIcon, ExclamationTriangleIcon, CurrencyDollarIcon, ClockIcon, ArrowPathIcon } from '@heroicons/react/24/outline';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

interface Infraction {
  id: string;
  type: string;
  description: string;
  amount: string;
  status: string;
  user_id: string;
  vehicle_id: string | null;
  vehicle_plate: string | null;
  location: string | null;
  created_at: string;
  user_first_name?: string;
  user_last_name?: string;
}

interface InfractionsClientProps {
  initialInfractions: Infraction[];
}

export default function InfractionsClient({ initialInfractions }: InfractionsClientProps) {
  const [infractions, setInfractions] = useState<Infraction[]>(initialInfractions);
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

      const response = await fetch(`${API_URL}/api/infractions`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Tenant-ID': 'santa_juana',
        },
      });

      if (response.ok) {
        const newInfractions = await response.json();
        setInfractions(newInfractions);
        setLastUpdate(new Date());
      }
    } catch (error) {
      console.error('Error refreshing infractions:', error);
    } finally {
      setIsRefreshing(false);
    }
  }, []);

  useAutoRefresh(fetchData, { interval: 3000 });

  const totalAmount = infractions.reduce((sum: number, i: any) => sum + parseFloat(i.amount || 0), 0);
  const pendingAmount = infractions
    .filter((i: any) => i.status === 'pendiente')
    .reduce((sum: number, i: any) => sum + parseFloat(i.amount || 0), 0);
  const paidAmount = infractions
    .filter((i: any) => i.status === 'pagada')
    .reduce((sum: number, i: any) => sum + parseFloat(i.amount || 0), 0);

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="md:flex md:items-center md:justify-between">
        <div className="flex-1 min-w-0">
          <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            Infracciones y Multas
          </h2>
          <p className="mt-1 text-sm text-gray-500 flex items-center gap-2">
            Gestiona infracciones, actualiza estados y monitorea pagos
            <span className="inline-flex items-center gap-1 text-xs">
              <ArrowPathIcon className={`w-3 h-3 ${isRefreshing ? 'animate-spin' : ''}`} />
              {lastUpdate.toLocaleTimeString('es-CL')}
            </span>
          </p>
        </div>
        <div className="mt-4 flex md:mt-0 md:ml-4">
          <Link
            href="/infractions/new"
            className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
          >
            <PlusIcon className="h-5 w-5 mr-2" />
            Nueva Infracción
          </Link>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Total Infracciones"
          value={infractions.length}
          icon={<ExclamationTriangleIcon className="h-6 w-6" />}
          color="destructive"
        />
        <StatCard
          title="Monto Total"
          value={`$${totalAmount.toLocaleString('es-CL')}`}
          icon={<CurrencyDollarIcon className="h-6 w-6" />}
          color="info"
        />
        <StatCard
          title="Pendiente de Pago"
          value={`$${pendingAmount.toLocaleString('es-CL')}`}
          icon={<ClockIcon className="h-6 w-6" />}
          color="warning"
        />
        <StatCard
          title="Monto Pagado"
          value={`$${paidAmount.toLocaleString('es-CL')}`}
          icon={<CurrencyDollarIcon className="h-6 w-6" />}
          color="success"
        />
      </div>

      {/* Infractions Table */}
      <InfractionsTable infractions={infractions} />
    </div>
  );
}
