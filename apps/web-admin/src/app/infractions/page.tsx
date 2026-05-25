import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import AppLayout from '@/components/layout/AppLayout';
import { TENANTS, DEFAULT_TENANT } from '@/config/tenants';
import InfractionsClient from '@/components/infractions/InfractionsClient';

type Loose = Record<string, unknown> & { data?: unknown; items?: unknown; infractions?: unknown };
function unwrap(payload: unknown): Loose[] {
  if (Array.isArray(payload)) return payload as Loose[];
  if (payload && typeof payload === 'object') {
    const p = payload as Loose;
    if (Array.isArray(p.data)) return p.data as Loose[];
    if (Array.isArray(p.items)) return p.items as Loose[];
    if (Array.isArray(p.infractions)) return p.infractions as Loose[];
  }
  return [];
}

async function getInfractions(token: string, tenantId: string) {
  try {
    const apiUrl = TENANTS[tenantId]?.apiUrl || TENANTS[DEFAULT_TENANT].apiUrl;
    const response = await fetch(`${apiUrl}/api/infractions`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Tenant-ID': tenantId,
      },
      cache: 'no-store',
    });

    if (!response.ok) return [];
    return unwrap(await response.json());
  } catch (error) {
    console.error('Error fetching infractions:', error);
    return [];
  }
}

export default async function InfractionsPage() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;
  const tenantId = cookieStore.get('tenantId')?.value || DEFAULT_TENANT;

  if (!accessToken) {
    redirect('/login');
  }

  const infractions = await getInfractions(accessToken, tenantId);

  return (
    <AppLayout>
      <InfractionsClient initialInfractions={infractions as unknown as Parameters<typeof InfractionsClient>[0]['initialInfractions']} />
    </AppLayout>
  );
}
