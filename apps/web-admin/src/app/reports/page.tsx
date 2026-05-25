import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import AppLayout from '@/components/layout/AppLayout';
import ReportsClient from '@/components/reports/ReportsClient';
import { TENANTS, DEFAULT_TENANT } from '@/config/tenants';

type Loose = Record<string, unknown>;
function unwrap(payload: unknown): Loose[] {
  if (Array.isArray(payload)) return payload as Loose[];
  if (payload && typeof payload === 'object') {
    const p = payload as Record<string, unknown>;
    if (Array.isArray(p.data)) return p.data as Loose[];
    if (Array.isArray(p.items)) return p.items as Loose[];
    if (Array.isArray(p.reports)) return p.reports as Loose[];
    if (Array.isArray(p.users)) return p.users as Loose[];
  }
  return [];
}

async function getReports(token: string, tenantId: string) {
  const apiUrl = TENANTS[tenantId]?.apiUrl || TENANTS[DEFAULT_TENANT].apiUrl;
  try {
    const response = await fetch(`${apiUrl}/api/reports`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Tenant-ID': tenantId,
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

async function getInspectors(token: string, tenantId: string) {
  const apiUrl = TENANTS[tenantId]?.apiUrl || TENANTS[DEFAULT_TENANT].apiUrl;
  try {
    const response = await fetch(`${apiUrl}/api/users?role=inspector`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Tenant-ID': tenantId,
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
  const tenantId = cookieStore.get('tenantId')?.value || DEFAULT_TENANT;

  if (!accessToken) {
    redirect('/login');
  }

  const [reports, inspectors] = await Promise.all([
    getReports(accessToken, tenantId),
    getInspectors(accessToken, tenantId),
  ]);

  return (
    <AppLayout>
      <ReportsClient
        initialReports={reports as unknown as Parameters<typeof ReportsClient>[0]['initialReports']}
        initialInspectors={inspectors as unknown as Parameters<typeof ReportsClient>[0]['initialInspectors']}
      />
    </AppLayout>
  );
}
