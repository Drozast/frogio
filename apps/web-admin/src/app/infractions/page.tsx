import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import AppLayout from '@/components/layout/AppLayout';
import InfractionsClient from '@/components/infractions/InfractionsClient';

const API_URL = process.env.API_URL || process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';

async function getInfractions(token: string) {
  try {
    const response = await fetch(`${API_URL}/api/infractions`, {
      headers: {
        'Authorization': `Bearer ${token}`,
        'X-Tenant-ID': 'santa_juana',
      },
      cache: 'no-store',
    });

    if (!response.ok) return [];
    return await response.json();
  } catch (error) {
    console.error('Error fetching infractions:', error);
    return [];
  }
}

export default async function InfractionsPage() {
  const cookieStore = cookies();
  const accessToken = cookieStore.get('accessToken')?.value;

  if (!accessToken) {
    redirect('/login');
  }

  const infractions = await getInfractions(accessToken);

  return (
    <AppLayout>
      <InfractionsClient initialInfractions={infractions} />
    </AppLayout>
  );
}
