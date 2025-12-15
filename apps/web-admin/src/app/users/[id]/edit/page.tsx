import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import AppLayout from '@/components/layout/AppLayout';
import UserForm from '@/components/users/UserForm';

const API_URL = process.env.API_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

async function getUser(token: string, userId: string) {
  try {
    const response = await fetch(`${API_URL}/api/users/${userId}`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Tenant-ID': 'santa_juana',
      },
      cache: 'no-store',
    });

    if (!response.ok) return null;
    return await response.json();
  } catch (error) {
    console.error('Error fetching user:', error);
    return null;
  }
}

export default async function EditUserPage({ params }: { params: { id: string } }) {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    redirect('/login');
  }

  const user = await getUser(accessToken, params.id);

  if (!user) {
    redirect('/users');
  }

  return (
    <AppLayout>
      <div className="space-y-6">
        {/* Page Header */}
        <div>
          <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            Editar Usuario
          </h2>
          <p className="mt-1 text-sm text-gray-500">
            Modifica la información del usuario {user.first_name} {user.last_name}
          </p>
        </div>

        {/* User Form */}
        <div className="bg-white shadow rounded-lg">
          <UserForm user={user} />
        </div>
      </div>
    </AppLayout>
  );
}
