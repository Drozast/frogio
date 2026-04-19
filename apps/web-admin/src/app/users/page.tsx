import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import AppLayout from '@/components/layout/AppLayout';
import UsersClient from '@/components/users/UsersClient';
import { getCurrentUserFromToken } from '@/lib/admin-api';

const API_URL =
  process.env.API_URL ||
  process.env.NEXT_PUBLIC_API_URL ||
  'http://localhost:3000';

async function getUsers(token: string) {
  try {
    const response = await fetch(`${API_URL}/api/users`, {
      headers: {
        Authorization: `Bearer ${token}`,
        'X-Tenant-ID': 'santa_juana',
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

  if (!accessToken) {
    redirect('/login');
  }

  const [users, currentUser] = await Promise.all([
    getUsers(accessToken),
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
