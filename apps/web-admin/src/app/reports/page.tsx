import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import AppLayout from '@/components/layout/AppLayout';
import ReportsClient from '@/components/reports/ReportsClient';
import { API_URL } from '@/lib/api-config';

function unwrap(payload: unknown): unknown[] {
  if (Array.isArray(payload)) return payload;
  if (payload && typeof payload === 'object') {
    const p = payload as Record<string, unknown>;
    if (Array.isArray(p.data)) return p.data;
    if (Array.isArray(p.items)) return p.items;
    if (Array.isArray(p.reports)) return p.reports;
    if (Array.isArray(p.users)) return p.users;
  }
  return [];
}

async function getReports(token: string) {
  try {
    const response = await fetch(`${API_URL}/api/reports`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Tenant-ID': 'santa_juana',
      },
      cache: 'no-store',
    });

    if (!response.ok) return [];
    return unwrap(await response.json());
  } catch (error) {
    console.error('Error fetching reports:', error);
    return [];
  }
}

async function getInspectors(token: string) {
  try {
    const response = await fetch(`${API_URL}/api/users?role=inspector`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Tenant-ID': 'santa_juana',
      },
      cache: 'no-store',
    });

    if (!response.ok) return [];
    return unwrap(await response.json());
  } catch (error) {
    console.error('Error fetching inspectors:', error);
    return [];
  }
}

export default async function ReportsPage() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    redirect('/login');
  }

  const [reports, inspectors] = await Promise.all([
    getReports(accessToken),
    getInspectors(accessToken),
  ]);

  return (
    <AppLayout>
      <ReportsClient initialReports={reports} initialInspectors={inspectors} />
    </AppLayout>
  );
}
