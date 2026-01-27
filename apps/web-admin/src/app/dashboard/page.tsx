import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import AppLayout from '@/components/layout/AppLayout';
import DashboardClient from '@/components/dashboard/DashboardClient';

const API_URL = process.env.API_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

async function getDashboardData(token: string) {
  try {
    const [reportsRes, citationsRes, usersRes, vehiclesRes] = await Promise.all([
      fetch(`${API_URL}/api/reports`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Tenant-ID': 'santa_juana',
        },
        cache: 'no-store',
      }),
      fetch(`${API_URL}/api/citations`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Tenant-ID': 'santa_juana',
        },
        cache: 'no-store',
      }),
      fetch(`${API_URL}/api/users`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Tenant-ID': 'santa_juana',
        },
        cache: 'no-store',
      }),
      fetch(`${API_URL}/api/vehicles`, {
        headers: {
          'Authorization': `Bearer ${token}`,
          'X-Tenant-ID': 'santa_juana',
        },
        cache: 'no-store',
      }),
    ]);

    const reports = reportsRes.ok ? await reportsRes.json() : [];
    const citations = citationsRes.ok ? await citationsRes.json() : [];
    const users = usersRes.ok ? await usersRes.json() : [];
    const vehicles = vehiclesRes.ok ? await vehiclesRes.json() : [];

    return { reports, citations, users, vehicles };
  } catch (error) {
    console.error('Error fetching dashboard data:', error);
    return { reports: [], citations: [], users: [], vehicles: [] };
  }
}

export default async function DashboardPage() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    redirect('/login');
  }

  const initialData = await getDashboardData(accessToken);

  return (
    <AppLayout>
      <DashboardClient initialData={initialData} />
    </AppLayout>
  );
}
