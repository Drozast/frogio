'use client';

import { useState, useCallback } from 'react';
import Link from 'next/link';
import { useAutoRefresh } from '@/hooks/useAutoRefresh';
import UsersTable from './UsersTable';
import { PlusIcon, ArrowPathIcon } from '@heroicons/react/24/outline';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

interface User {
  id: string;
  email: string;
  first_name: string;
  last_name: string;
  rut: string;
  phone: string | null;
  role: string;
  is_active: boolean;
  email_verified: boolean;
  created_at: string;
}

interface UsersClientProps {
  initialUsers: User[];
}

export default function UsersClient({ initialUsers }: UsersClientProps) {
  const [users, setUsers] = useState<User[]>(initialUsers);
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

      const response = await fetch(`${API_URL}/api/users`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Tenant-ID': 'santa_juana',
        },
      });

      if (response.ok) {
        const newUsers = await response.json();
        setUsers(newUsers);
        setLastUpdate(new Date());
      }
    } catch (error) {
      console.error('Error refreshing users:', error);
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
            Gestión de Usuarios
          </h2>
          <p className="mt-1 text-sm text-gray-500 flex items-center gap-2">
            Administra usuarios, roles y permisos del sistema
            <span className="inline-flex items-center gap-1 text-xs">
              <ArrowPathIcon className={`w-3 h-3 ${isRefreshing ? 'animate-spin' : ''}`} />
              {lastUpdate.toLocaleTimeString('es-CL')}
            </span>
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
  );
}
