import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import AppLayout from '@/components/layout/AppLayout';
import UserForm from '@/components/users/UserForm';

export default async function NewUserPage() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    redirect('/login');
  }

  return (
    <AppLayout>
      <div className="space-y-6">
        {/* Page Header */}
        <div>
          <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
            Nuevo Usuario
          </h2>
          <p className="mt-1 text-sm text-gray-500">
            Crea un nuevo usuario en el sistema
          </p>
        </div>

        {/* User Form */}
        <div className="bg-white shadow rounded-lg">
          <UserForm />
        </div>
      </div>
    </AppLayout>
  );
}
