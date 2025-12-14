import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import Link from 'next/link';

async function getInfractions(token: string) {
  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

  try {
    const response = await fetch(`${API_URL}/api/infractions`, {
      headers: { Authorization: `Bearer ${token}` },
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

  return (
    <div className="min-h-screen bg-gray-100">
      <header className="bg-white shadow">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <Link href="/dashboard" className="text-sm text-gray-600 hover:text-gray-900">
            ← Volver al Dashboard
          </Link>
          <h1 className="text-2xl font-bold text-gray-900 mt-2">Infracciones y Multas</h1>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
          <div className="bg-white shadow rounded-lg p-6">
            <div className="text-sm font-medium text-gray-500">Total Infracciones</div>
            <div className="text-3xl font-semibold text-gray-900 mt-2">{infractions.length}</div>
          </div>
          <div className="bg-white shadow rounded-lg p-6">
            <div className="text-sm font-medium text-gray-500">Monto Total</div>
            <div className="text-3xl font-semibold text-gray-900 mt-2">
              ${totalAmount.toLocaleString('es-CL')}
            </div>
          </div>
          <div className="bg-white shadow rounded-lg p-6">
            <div className="text-sm font-medium text-gray-500">Pendiente de Pago</div>
            <div className="text-3xl font-semibold text-red-600 mt-2">
              ${pendingAmount.toLocaleString('es-CL')}
            </div>
          </div>
        </div>

        {/* Table */}
        <div className="bg-white shadow rounded-lg overflow-hidden">
          <div className="px-6 py-4 border-b border-gray-200 flex justify-between items-center">
            <h2 className="text-lg font-medium">Todas las Infracciones</h2>
            <Link
              href="/infractions/new"
              className="bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 text-sm"
            >
              + Nueva Infracción
            </Link>
          </div>

          {infractions.length === 0 ? (
            <div className="p-6 text-center text-gray-500">
              No hay infracciones registradas
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Tipo
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Descripción
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Usuario
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Monto
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Estado
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Patente
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">
                      Fecha
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {infractions.map((infraction: any) => (
                    <tr key={infraction.id} className="hover:bg-gray-50">
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                        {infraction.type}
                      </td>
                      <td className="px-6 py-4 text-sm text-gray-500 max-w-xs truncate">
                        {infraction.description}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {infraction.user_first_name} {infraction.user_last_name}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        ${parseFloat(infraction.amount).toLocaleString('es-CL')}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <StatusBadge status={infraction.status} />
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {infraction.vehicle_plate || '-'}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                        {new Date(infraction.created_at).toLocaleDateString('es-CL')}
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

function StatusBadge({ status }: { status: string }) {
  const colors: Record<string, string> = {
    pendiente: 'bg-yellow-100 text-yellow-800',
    pagada: 'bg-green-100 text-green-800',
    anulada: 'bg-gray-100 text-gray-800',
  };

  return (
    <span
      className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${colors[status]}`}
    >
      {status}
    </span>
  );
}
