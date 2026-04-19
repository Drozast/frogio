import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import AppLayout from '@/components/layout/AppLayout';
import DashboardClient from '@/components/dashboard/DashboardClient';

export default function DashboardPage() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    redirect('/login');
  }

  return (
    <AppLayout>
      <DashboardClient />
    </AppLayout>
  );
}
