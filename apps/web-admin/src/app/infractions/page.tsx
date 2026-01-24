import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import AppLayout from '@/components/layout/AppLayout';
import InfractionsTable from '@/components/infractions/InfractionsTable';
import StatCard from '@/components/ui/StatCard';
import { PlusIcon, ExclamationTriangleIcon, CurrencyDollarIcon, ClockIcon } from '@heroicons/react/24/outline';
import Link from 'next/link';

const API_URL = process.env.API_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

async function getInfractions(token: string) {
  try {
    const response = await fetch(`${API_URL}/api/infractions`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Tenant-ID': 'santa_juana',
      },
      cache: 'no-store',
    });

    if (!response.ok) return [];
    return await response.json();
  } catch (error) {
    console.error('Error fetching infractions:', error);
    return [];
  }
}

export default async function InfractionsPage() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    redirect('/login');
  }

  const infractions = await getInfractions(accessToken);

  const totalAmount = infractions.reduce((sum: number, i: any) => sum + parseFloat(i.amount || 0), 0);
  const pendingAmount = infractions
    .filter((i: any) => i.status === 'pendiente')
    .reduce((sum: number, i: any) => sum + parseFloat(i.amount || 0), 0);
  const paidAmount = infractions
    .filter((i: any) => i.status === 'pagada')
    .reduce((sum: number, i: any) => sum + parseFloat(i.amount || 0), 0);

  return (
    <AppLayout>
      <div className="space-y-6">
        {/* Page Header */}
        <div className="md:flex md:items-center md:justify-between">
          <div className="flex-1 min-w-0">
            <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
              Infracciones y Multas
            </h2>
            <p className="mt-1 text-sm text-gray-500">
              Gestiona infracciones, actualiza estados y monitorea pagos
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
    </AppLayout>
  );
}
