import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import AppLayout from '@/components/layout/AppLayout';
import UsersTable from '@/components/users/UsersTable';
import { PlusIcon } from '@heroicons/react/24/outline';
import Link from 'next/link';

const API_URL = process.env.API_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

async function getUsers(token: string) {
  try {
    const response = await fetch(`${API_URL}/api/users`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Tenant-ID': 'santa_juana',
      },
      cache: 'no-store',
    });

    if (!response.ok) return [];
    return await response.json();
  } catch (error) {
    console.error('Error fetching users:', error);
    return [];
  }
}

export default async function UsersPage() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    redirect('/login');
  }

  const users = await getUsers(accessToken);

  return (
    <AppLayout>
      <div className="space-y-6">
        {/* Page Header */}
        <div className="md:flex md:items-center md:justify-between">
          <div className="flex-1 min-w-0">
            <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
              Gestión de Usuarios
            </h2>
            <p className="mt-1 text-sm text-gray-500">
              Administra usuarios, roles y permisos del sistema
            </p>
          </div>
          <div className="mt-4 flex md:mt-0 md:ml-4">
            <Link
              href="/users/new"
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              <PlusIcon className="h-5 w-5 mr-2" />
              Nuevo Usuario
            </Link>
          </div>
        </div>

        {/* Users Table */}
        <UsersTable users={users} />
      </div>
    </AppLayout>
  );
}

function RoleBadge({ role }: { role: string }) {
  const colors: Record<string, string> = {
    citizen: 'bg-blue-100 text-blue-800',
    inspector: 'bg-purple-100 text-purple-800',
    admin: 'bg-red-100 text-red-800',
  };

  const labels: Record<string, string> = {
    citizen: 'Ciudadano',
    inspector: 'Inspector',
    admin: 'Administrador',
  };

  return (
    <span
      className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${colors[role]}`}
    >
      {labels[role] || role}
    </span>
  );
}
