import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import AppLayout from '@/components/layout/AppLayout';
import UsersClient from '@/components/users/UsersClient';
import { getCurrentUserFromToken } from '@/lib/admin-api';
import { TENANTS, DEFAULT_TENANT } from '@/config/tenants';

async function getUsers(token: string, tenantId: string) {
  const apiUrl = TENANTS[tenantId]?.apiUrl || TENANTS[DEFAULT_TENANT].apiUrl;
  try {
    const response = await fetch(`${apiUrl}/api/users`, {
      headers: {
        Authorization: `Bearer ${token}`,
        'X-Tenant-ID': tenantId,
      },
      cache: 'no-store',
    });

    if (!response.ok) return [];
    const json = await response.json();
    if (Array.isArray(json)) return json;
    if (json && typeof json === 'object' && Array.isArray(json.data)) {
      return json.data;
    }
    return [];
  } catch (error) {
    console.error('Error fetching users:', error);
    return [];
  }
}

export default async function UsersPage() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;
  const tenantId = cookieStore.get('tenantId')?.value || DEFAULT_TENANT;

  if (!accessToken) {
    redirect('/login');
  }

  const [users, currentUser] = await Promise.all([
    getUsers(accessToken, tenantId),
    getCurrentUserFromToken(),
  ]);

  return (
    <AppLayout>
      <UsersClient
        initialUsers={users}
        currentUserId={currentUser?.userId ?? null}
      />
    </AppLayout>
  );
}
